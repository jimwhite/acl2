"""
Preprocess .mli files into pre-built graph tensors (.pt files).

TWO-PASS design:
  Pass 1: Stream all .mli files to build a GLOBAL vocabulary (token strings only).
  Pass 2: Multiprocess: each worker loads the vocab, processes .mli files,
          builds graphs + encodes targets with global vocab, saves as .pt.

Each .pt file contains batched tensors for ALL items in one .mli:
  node_types, subtoken_ids, edge_index, edge_types, num_nodes,
  tgt_ids, action_types, action_objs, copy_masks

Training then loads .pt files directly — no Python graph construction,
no ijson parsing, pure tensor I/O.

Usage:
  python training/preprocess.py \
      --data-dir /path/to/data/books \
      --output-dir /path/to/data/preprocessed \
      --max-workers 8
"""

import os, sys, json, hashlib, argparse, logging, time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
import multiprocessing

import ijson
import torch

SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

from training.data_utils import (
    GraphBuilder, build_target_sequence, subtokenize,
)

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# Pass 1: build global vocab
# ═══════════════════════════════════════════════════════════════════════════════

def build_global_vocab(data_dir, exclude_dirs=None, max_items=None):
    """Stream all .mli files, collect target token strings only → global vocab."""
    root = Path(data_dir)
    if exclude_dirs is None:
        exclude_dirs = {"kestrel/helpers"}

    token_to_id = {"<pad>": 0, "<sos>": 1, "<eos>": 2, "<unk>": 3}
    next_id = 4
    count = 0

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
                    if isinstance(ao, list):
                        ao = " ".join(str(x) for x in ao)
                    ao = str(ao)

                    tgt = build_target_sequence(
                        {"output": {"action-type": at, "action-obj": ao}})
                    for tok in tgt:
                        if tok not in token_to_id:
                            token_to_id[tok] = next_id
                            next_id += 1
                    count += 1
                    if max_items and count >= max_items:
                        logger.info(f"Vocab: {count:,} items, size={next_id:,}")
                        return token_to_id
        except Exception:
            continue

    logger.info(f"Pass 1 done: {count:,} items, vocab size={next_id:,}")
    return token_to_id


def _is_excluded(rel, exclude_dirs):
    parts = rel.parts
    return any(
        parts[:len(tuple(exc.strip("/").split("/")))] ==
        tuple(exc.strip("/").split("/"))
        for exc in exclude_dirs)


# ═══════════════════════════════════════════════════════════════════════════════
# Pass 2: preprocess files → .pt (multiprocess)
# ═══════════════════════════════════════════════════════════════════════════════

# Global variable for worker-initialized state
_WORKER_VOCAB = None
_WORKER_GB = None
_WORKER_MAX_NODES = None


def _worker_init(vocab_dict, max_nodes):
    global _WORKER_VOCAB, _WORKER_GB, _WORKER_MAX_NODES
    _WORKER_VOCAB = vocab_dict
    _WORKER_GB = GraphBuilder(max_nodes=max_nodes)
    _WORKER_MAX_NODES = max_nodes


def _process_one_file(args):
    """Process one .mli → .pt (runs in worker process)."""
    mli_path_str, output_path_str = args
    mli_path = Path(mli_path_str)
    output_path = Path(output_path_str)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    vocab = _WORKER_VOCAB
    gb = _WORKER_GB
    max_nodes = _WORKER_MAX_NODES

    # Collect all items
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
                ao = str(ao)

                graph = gb.build_graph(item, max_nodes=max_nodes)
                tgt = build_target_sequence(
                    {"output": {"action-type": at, "action-obj": ao}})
                tgt_ids = [vocab.get(t, 3) for t in tgt]  # 3 = <unk>

                items.append({
                    "graph": graph,
                    "tgt_ids": tgt_ids,
                    "action_type": at,
                    "action_obj": ao,
                })
    except Exception as e:
        return mli_path_str, 0

    if not items:
        return mli_path_str, 0

    # Collate into batched tensors
    n_items = len(items)
    max_n = max(it["graph"]["num_nodes"] for it in items)
    max_s = max(len(it["tgt_ids"]) for it in items)

    all_nt, all_st = [], []
    all_ei0, all_ei1, all_et = [], [], []
    all_nn, all_tgt, all_at, all_ao, all_cm = [], [], [], [], []
    off = 0

    for it in items:
        g = it["graph"]
        n = g["num_nodes"]
        all_nt.extend(_nt(nt) for nt in g["node_types"])
        all_st.extend(g["subtoken_ids"])
        all_ei0.extend(e + off for e in g["edge_index"][0])
        all_ei1.extend(e + off for e in g["edge_index"][1])
        all_et.extend(g["edge_types"])
        all_nn.append(n)
        off += n

        t = it["tgt_ids"][:max_s]
        all_tgt.append(t + [0] * (max_s - len(t)))
        all_at.append(it["action_type"])
        all_ao.append(it["action_obj"])
        cm = [1 if nt == "token" else 0 for nt in g["node_types"]]
        all_cm.append(cm + [0] * (max_n - len(cm)))

    data = {
        "node_types": torch.tensor(all_nt, dtype=torch.long),
        "subtoken_ids": torch.tensor(all_st, dtype=torch.long),
        "edge_index": torch.tensor([all_ei0, all_ei1], dtype=torch.long),
        "edge_types": torch.tensor(all_et, dtype=torch.long),
        "num_nodes": all_nn,
        "tgt_ids": torch.tensor(all_tgt, dtype=torch.long),
        "action_types": all_at,
        "action_objs": all_ao,
        "copy_masks": torch.tensor(all_cm, dtype=torch.bool),
        "max_nodes": max_n,
        "max_seq_len": max_s,
        "n_items": n_items,
    }
    torch.save(data, output_path)
    return mli_path_str, n_items


def _nt(nt: str) -> int:
    return {"token": 0, "subtoken": 1, "root": 2}[nt]


# ═══════════════════════════════════════════════════════════════════════════════
# Orchestration
# ═══════════════════════════════════════════════════════════════════════════════

def run_preprocess(data_dir, output_dir, train_frac=0.90, val_frac=0.05,
                   test_frac=0.05, exclude_dirs=None, max_nodes=512,
                   max_workers=None, max_items=None):
    if max_workers is None:
        max_workers = max(4, multiprocessing.cpu_count() // 2)

    root = Path(data_dir)
    output_dir = Path(output_dir)
    if exclude_dirs is None:
        exclude_dirs = {"kestrel/helpers"}

    # ── Pass 1: global vocab ─────────────────────────────────────────────
    logger.info("=== Pass 1: Building global vocabulary (single-threaded) ===")
    t0 = time.time()
    token_to_id = build_global_vocab(data_dir, exclude_dirs,
                                     max_items=max_items)
    vocab_path = output_dir / "vocab.json"
    output_dir.mkdir(parents=True, exist_ok=True)
    with open(vocab_path, "w") as f:
        json.dump({"token_to_id": token_to_id}, f)
    logger.info(
        f"  Vocab size: {len(token_to_id):,} → {vocab_path} "
        f"({time.time()-t0:.1f}s)")

    # ── Scan files + assign splits ───────────────────────────────────────
    logger.info("=== Pass 2: Preprocessing .mli → .pt (%d workers) ===",
                 max_workers)
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

        # If max_items is set, limit files (~50 items/file avg)
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
            initargs=(token_to_id, max_nodes)) as pool:

        futures = {pool.submit(_process_one_file, t): t for t in tasks}
        for future in as_completed(futures):
            completed += 1
            path, nitems = future.result()
            total += nitems
            if completed % 200 == 0 or completed <= 10:
                elapsed = (time.time() - t0) / 60
                rate = completed / max(elapsed, 0.01)
                logger.info(
                    f"  [{completed}/{len(tasks)}] {Path(path).name} "
                    f"({nitems} items) — {elapsed:.1f}m, {rate:.0f} files/m")

    elapsed = (time.time() - t0) / 60
    logger.info(
        f"  Done: {total:,} items from {len(tasks)} files "
        f"in {elapsed:.1f}m")

    # ── Manifest ────────────────────────────────────────────────────────
    manifest = {"train": [], "val": [], "test": []}
    for split_name in ("train", "val", "test"):
        split_dir = output_dir / split_name
        if split_dir.exists():
            manifest[split_name] = sorted(
                str(p.relative_to(output_dir))
                for p in split_dir.rglob("*.pt")
                if p.is_file())

    manifest_path = output_dir / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    logger.info(f"  Manifest → {manifest_path}")
    for k, v in manifest.items():
        logger.info(f"    {k}: {len(v)} files")

    return manifest, token_to_id


def main():
    p = argparse.ArgumentParser(
        description="Preprocess .mli files → graph tensors")
    p.add_argument("--data-dir", required=True)
    p.add_argument("--output-dir", required=True)
    p.add_argument("--train-frac", type=float, default=0.90)
    p.add_argument("--val-frac", type=float, default=0.05)
    p.add_argument("--test-frac", type=float, default=0.05)
    p.add_argument("--max-nodes", type=int, default=512)
    p.add_argument("--max-workers", type=int, default=None)
    p.add_argument("--max-items", type=int, default=None,
                   help="Max items (for smoke testing)")
    p.add_argument("--exclude", nargs="*", default=["kestrel/helpers"])
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    assert abs(args.train_frac + args.val_frac + args.test_frac - 1.0) < 0.01

    run_preprocess(
        args.data_dir, args.output_dir,
        train_frac=args.train_frac,
        val_frac=args.val_frac,
        test_frac=args.test_frac,
        exclude_dirs=set(args.exclude),
        max_nodes=args.max_nodes,
        max_workers=args.max_workers,
        max_items=args.max_items,
    )


if __name__ == "__main__":
    main()
