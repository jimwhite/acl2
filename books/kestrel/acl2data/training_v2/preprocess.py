"""
Preprocess v2: global-padding, fixed-size .pt files.

Two passes:
  1. Scan all .mli → build vocab + find global max_nodes
  2. Convert each .mli → fixed-size .pt (every item padded to max_nodes)

This mirrors PLUR's approach: pad to dataset global max, so every
batch has identical shape — no dynamic collate, just torch.stack.

Output per .pt file: dict with all tensors at uniform size.
{
  "node_types":    (N_items, max_nodes)  int64
  "subtoken_ids":  (N_items, max_nodes)  int64
  "edges":         (N_items, edge_types, max_nodes, max_nodes)  float32
  "tgt_ids":       (N_items, max_seq)  int64
  "action_types":  (N_items,)  int64
  "action_objs":   (N_items,)  int64
  "copy_mask":     (N_items, max_nodes)  bool
}
"""

import os, sys, json, hashlib, argparse, logging, time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
import multiprocessing

import ijson
import numpy as np
import torch

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR.parent))

from training.data_utils import (
    GraphBuilder, build_target_sequence, subtokenize,
)

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# Pass 1: vocab + global stats
# ═══════════════════════════════════════════════════════════════════════════════

def scan_dataset(data_dir, exclude_dirs, max_items=None):
    """Stream all .mli: build vocab + find max_nodes + max_seq."""
    root = Path(data_dir)
    token_to_id = {"<pad>": 0, "<sos>": 1, "<eos>": 2, "<unk>": 3}
    next_tid = 4
    attr_to_id = {}    # action type → id
    aobj_to_id = {}    # action obj token → id
    edge_type_max = 0
    global_max_nodes = 0
    global_max_seq = 0
    count = 0

    gb = GraphBuilder(max_nodes=10000)  # no limit during scan

    for mli_path in sorted(root.rglob("*.mli")):
        rel = mli_path.relative_to(root)
        if _is_excluded(rel, exclude_dirs):
            continue
        try:
            with open(mli_path, "rb") as f:
                for item in ijson.items(f, "item"):
                    at = item.get("output", {}).get("action-type", "")
                    ao = item.get("output", {}).get("action-obj", "")
                    if not at or not ao:
                        continue

                    # Vocab for action type
                    if at not in attr_to_id:
                        attr_to_id[at] = len(attr_to_id)

                    # Vocab for output tokens
                    if isinstance(ao, list):
                        ao = " ".join(str(x) for x in ao)
                    ao_str = str(ao)
                    tgt = build_target_sequence(
                        {"output": {"action-type": at, "action-obj": ao_str}})
                    for tok in tgt:
                        if tok not in token_to_id:
                            token_to_id[tok] = next_tid
                            next_tid += 1

                    # Track max seq len
                    global_max_seq = max(global_max_seq, len(tgt))

                    # Build graph to track node count
                    graph = gb.build_graph(item, max_nodes=10000)
                    global_max_nodes = max(global_max_nodes,
                                           graph["num_nodes"])
                    edge_type_max = max(edge_type_max,
                                        max(graph["edge_types"]) + 1
                                        if graph["edge_types"] else 0)

                    count += 1
                    if max_items and count >= max_items:
                        logger.info(f"Scan: {count:,} items")
                        return token_to_id, attr_to_id, global_max_nodes, \
                            global_max_seq, edge_type_max

        except Exception:
            continue

    logger.info(f"Scan: {count:,} items, max_nodes={global_max_nodes}, "
                 f"max_seq={global_max_seq}, edge_types={edge_type_max}")
    return token_to_id, attr_to_id, global_max_nodes, global_max_seq, edge_type_max


def _is_excluded(rel, exclude_dirs):
    parts = rel.parts
    return any(
        parts[:len(tuple(exc.strip("/").split("/")))] ==
        tuple(exc.strip("/").split("/"))
        for exc in exclude_dirs)


# ═══════════════════════════════════════════════════════════════════════════════
# Pass 2: convert .mli → fixed-size .pt
# ═══════════════════════════════════════════════════════════════════════════════

_WORKER_VOCAB = None
_WORKER_ATTR_VOCAB = None
_WORKER_GB = None
_WORKER_MAX_NODES = None
_WORKER_MAX_SEQ = None


def _worker_init(token_to_id, attr_to_id, max_nodes, max_seq):
    global _WORKER_VOCAB, _WORKER_ATTR_VOCAB, _WORKER_GB
    global _WORKER_MAX_NODES, _WORKER_MAX_SEQ
    _WORKER_VOCAB = token_to_id
    _WORKER_ATTR_VOCAB = attr_to_id
    _WORKER_GB = GraphBuilder(max_nodes=max_nodes)
    _WORKER_MAX_NODES = max_nodes
    _WORKER_MAX_SEQ = max_seq


def _process_one_file(args):
    mli_path_str, output_path_str = args
    mli_path = Path(mli_path_str)
    output_path = Path(output_path_str)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    vocab = _WORKER_VOCAB
    attr_vocab = _WORKER_ATTR_VOCAB
    gb = _WORKER_GB
    max_n = _WORKER_MAX_NODES
    max_s = _WORKER_MAX_SEQ

    items = []
    try:
        with open(mli_path, "rb") as f:
            for item in ijson.items(f, "item"):
                at = item.get("output", {}).get("action-type", "")
                ao = item.get("output", {}).get("action-obj", "")
                if not at or not ao:
                    continue
                if isinstance(ao, list):
                    ao = " ".join(str(x) for x in ao)
                ao_str = str(ao)
                tgt = build_target_sequence(
                    {"output": {"action-type": at, "action-obj": ao_str}})
                tgt_ids = [vocab.get(t, 3) for t in tgt]
                graph = gb.build_graph(item, max_nodes=max_n)
                items.append((at, ao_str, tgt_ids, graph))
    except Exception:
        return mli_path_str, 0

    if not items:
        return mli_path_str, 0

    n = len(items)
    nt = torch.full((n, max_n), 0, dtype=torch.long)
    st = torch.full((n, max_n), -1, dtype=torch.long)
    # Store sparse edges: (2, total_E) + (total_E,) edge types per item
    ei0_all, ei1_all, et_all = [], [], []
    edge_counts = torch.zeros(n, dtype=torch.long)  # edges per item
    tgt = torch.full((n, max_s), 0, dtype=torch.long)
    at_ids = torch.zeros(n, dtype=torch.long)
    cm = torch.zeros((n, max_n), dtype=torch.bool)

    for i, (at, ao_str, tgt_ids, graph) in enumerate(items):
        nn = graph["num_nodes"]
        nt[i, :nn] = torch.tensor(
            [_nt(ntype) for ntype in graph["node_types"]], dtype=torch.long)
        st[i, :nn] = torch.tensor(graph["subtoken_ids"], dtype=torch.long)

        # Sparse edges
        ei0_all.extend(graph["edge_index"][0])
        ei1_all.extend(graph["edge_index"][1])
        et_all.extend(graph["edge_types"])
        edge_counts[i] = len(graph["edge_types"])

        tgt[i, :len(tgt_ids)] = torch.tensor(tgt_ids, dtype=torch.long)
        at_ids[i] = attr_vocab.get(at, 0)
        token_mask = [1 if nt == "token" else 0 for nt in graph["node_types"]]
        cm[i, :nn] = torch.tensor(token_mask, dtype=torch.bool)

    torch.save({
        "node_types": nt,
        "subtoken_ids": st,
        "edge_index": torch.tensor([ei0_all, ei1_all], dtype=torch.long),
        "edge_types": torch.tensor(et_all, dtype=torch.long),
        "edge_counts": edge_counts,
        "tgt_ids": tgt,
        "action_types": at_ids,
        "copy_mask": cm,
    }, output_path)
    return mli_path_str, n


def _nt(nt: str) -> int:
    return {"token": 0, "subtoken": 1, "root": 2}[nt]


# ═══════════════════════════════════════════════════════════════════════════════
# Orchestration
# ═══════════════════════════════════════════════════════════════════════════════

def run_preprocess(data_dir, output_dir, train_frac=0.90, val_frac=0.05,
                   test_frac=0.05, exclude_dirs=None, max_workers=None,
                   max_items=None):
    if max_workers is None:
        max_workers = max(4, multiprocessing.cpu_count() // 2)

    root = Path(data_dir)
    output_dir = Path(output_dir)
    if exclude_dirs is None:
        exclude_dirs = {"kestrel/helpers"}

    # ── Pass 1 ──────────────────────────────────────────────────────────
    logger.info("=== Pass 1: vocab + global stats ===")
    t0 = time.time()
    token_to_id, attr_to_id, max_nodes, max_seq, num_edge_types = \
        scan_dataset(data_dir, exclude_dirs, max_items=max_items)
    max_nodes = min(max_nodes, 512)  # clamp per thesis
    max_seq = min(max_seq, 256)

    output_dir.mkdir(parents=True, exist_ok=True)
    json.dump({
        "token_to_id": token_to_id,
        "attr_to_id": attr_to_id,
        "max_nodes": max_nodes,
        "max_seq": max_seq,
        "num_edge_types": max(num_edge_types, 10),
    }, open(output_dir / "vocab.json", "w"))
    logger.info(
        f"  vocab={len(token_to_id):,} attrs={len(attr_to_id)} "
        f"max_nodes={max_nodes} max_seq={max_seq} "
        f"({time.time()-t0:.1f}s)")

    # ── Scan files + assign splits ───────────────────────────────────────
    logger.info(f"=== Pass 2: convert to fixed-size .pt ({max_workers} workers) ===")
    tasks = []

    for mli_path in sorted(root.rglob("*.mli")):
        try:
            rel = mli_path.relative_to(root)
        except ValueError:
            continue
        if _is_excluded(rel, exclude_dirs):
            continue

        book_key = str(rel.parent) if str(rel.parent) != "." else str(rel.stem)
        h = int(hashlib.md5(book_key.encode()).hexdigest(), 16) % 1000
        if h < train_frac * 1000:
            split = "train"
        elif h < (train_frac + val_frac) * 1000:
            split = "val"
        else:
            split = "test"

        out_path = output_dir / split / rel.with_suffix(".pt")
        tasks.append((str(mli_path), str(out_path)))

        if max_items and len(tasks) >= max_items // 50:
            break

    logger.info(f"  {len(tasks)} files, {max_workers} workers")

    # ── Process in parallel ──────────────────────────────────────────────
    t0 = time.time()
    total = 0
    completed = 0

    with ProcessPoolExecutor(
            max_workers=max_workers,
            initializer=_worker_init,
            initargs=(token_to_id, attr_to_id, max_nodes, max_seq)) as pool:
        futures = {pool.submit(_process_one_file, t): t for t in tasks}
        for future in as_completed(futures):
            completed += 1
            path, nitems = future.result()
            total += nitems
            if completed % 200 == 0 or completed <= 10:
                elapsed = (time.time() - t0) / 60
                logger.info(
                    f"  [{completed}/{len(tasks)}] "
                    f"{Path(path).name} ({nitems} items) — {elapsed:.1f}m")

    elapsed = (time.time() - t0) / 60
    logger.info(
        f"  Done: {total:,} items in {elapsed:.1f}m "
        f"({total/max(elapsed,0.1)/60:.0f} items/s)")

    # ── Manifest ────────────────────────────────────────────────────────
    manifest = {"train": [], "val": [], "test": []}
    for split_name in ("train", "val", "test"):
        split_dir = output_dir / split_name
        if split_dir.exists():
            manifest[split_name] = sorted(
                str(p.relative_to(output_dir))
                for p in split_dir.rglob("*.pt") if p.is_file())

    json.dump(manifest, open(output_dir / "manifest.json", "w"), indent=2)
    for k, v in manifest.items():
        logger.info(f"    {k}: {len(v)} files")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--data-dir", required=True)
    p.add_argument("--output-dir", required=True)
    p.add_argument("--train-frac", type=float, default=0.90)
    p.add_argument("--val-frac", type=float, default=0.05)
    p.add_argument("--test-frac", type=float, default=0.05)
    p.add_argument("--max-workers", type=int, default=None)
    p.add_argument("--max-items", type=int, default=None)
    p.add_argument("--exclude", nargs="*", default=["kestrel/helpers"])
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    run_preprocess(
        args.data_dir, args.output_dir,
        train_frac=args.train_frac,
        val_frac=args.val_frac,
        test_frac=args.test_frac,
        exclude_dirs=set(args.exclude),
        max_workers=args.max_workers,
        max_items=args.max_items,
    )


if __name__ == "__main__":
    main()
