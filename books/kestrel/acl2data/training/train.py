"""
Training script for Graph2Tocopo model on ACL2 proof data.

Trains the GGNN encoder + Tocopo decoder on .mli files to predict
proof fixes.  Implements the training procedure from Thompson (2023):

- Graph construction from broken theorems + checkpoints (Section 5.3)
- Subtokenization by splitting on dashes (Section 5.3)
- GGNN message-passing encoder (Section 5.2)
- Tocopo decoder with copy mechanism (Section 5.4)
- Adam optimizer with linear warmup (Section 6.1)
- Book-level train/eval split to avoid data leakage

Usage:
  python -m training.train \\
      --data-dir /workspaces/acl2-jupyter/data/books \\
      --output-dir ./models_v5 \\
      --epochs 20 --batch-size 8 \\
      --hidden-dim 256 --lr 1e-4
"""

import os
import sys
import json
import hashlib
import argparse
import logging
import time
from pathlib import Path
from collections import defaultdict

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, IterableDataset
from tqdm import tqdm
import ijson

# Add parent to path for imports
SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

from training.data_utils import (
    GraphBuilder, FixVocab, build_target_sequence,
    ACTION_TYPES, ACTION_PREFIXES,
)
from training.graph2tocopo_model import Graph2Tocopo, compute_loss

logger = logging.getLogger(__name__)

# ── defaults ─────────────────────────────────────────────────────────────────

DEFAULT_HIDDEN_DIM = 256
DEFAULT_BATCH_SIZE = 8
DEFAULT_EPOCHS = 20
DEFAULT_LR = 1e-4
DEFAULT_WARMUP_STEPS = 10000
DEFAULT_MAX_NODES = 512
DEFAULT_EVAL_FRAC = 0.05


def collate_graphs(batch):
    """Collate: concatenate without padding (PyG diagonal-stacking pattern).

    Node data is flat-concatenated.  Edge indices are offset.  num_nodes list
    tracks per-graph sizes.  Padding happens only for the decoder, AFTER the
    GGNN encoder — so the expensive message passing skips dummy nodes."""
    max_s = max(len(b["tgt_ids"]) for b in batch)

    all_nt = []
    all_st = []
    all_ei0, all_ei1, all_et = [], [], []
    all_nn = []
    all_tgt = []
    all_at, all_ao, all_cm = [], [], []
    off = 0

    for b in batch:
        nn = b["num_nodes"]
        all_nn.append(nn)

        # Concatenate without padding — GGNN only processes real nodes
        all_nt.extend(b["node_types"].tolist())
        all_st.extend(b["subtoken_ids"].tolist())

        # Offset edge indices by cumulative node count
        ei = b["edge_index"]
        all_ei0.extend((ei[0] + off).tolist())
        all_ei1.extend((ei[1] + off).tolist())
        all_et.extend(b["edge_types"].tolist())
        off += nn

        # Pad target sequences to uniform length
        t = b["tgt_ids"].tolist()
        all_tgt.append(t + [0] * (max_s - len(t)))

        all_at.append(b["action_type"])
        all_ao.append(b["action_obj"])
        all_cm.append(b["copy_mask"])  # vary-size, padded later

    return {
        "node_types": torch.tensor(all_nt, dtype=torch.long),
        "subtoken_ids": torch.tensor(all_st, dtype=torch.long),
        "edge_index": torch.tensor([all_ei0, all_ei1], dtype=torch.long),
        "edge_types": torch.tensor(all_et, dtype=torch.long),
        "num_nodes": all_nn,
        "tgt_tokens": torch.tensor(all_tgt, dtype=torch.long),
        "copy_masks": all_cm,  # list of 1D tensors
        "action_types": all_at,
        "action_objs": all_ao,
    }


# ── data loading (preprocessed) ──────────────────────────────────────────────

class PreprocessedDataset(torch.utils.data.IterableDataset):
    """IterableDataset over pre-built .pt files.

    Each .pt file contains `{"items": [item1, item2, ...]}` where each item
    is a dict with its own graph tensors (node_types, edge_index, etc.).
    Yields individual items — collate handles batching."""

    def __init__(self, file_list, output_dir, max_items=None):
        self.file_list = list(file_list)
        self.output_dir = Path(output_dir)
        self.max_items = max_items

    def __iter__(self):
        worker_info = torch.utils.data.get_worker_info()
        files = self._split_files(worker_info)

        rng = np.random.RandomState()
        rng.shuffle(files)

        count = 0
        for rel_path in files:
            pt_path = self.output_dir / rel_path
            try:
                data = torch.load(pt_path, weights_only=True)
            except Exception:
                continue
            for item in data["items"]:
                yield item
                count += 1
                if self.max_items and count >= self.max_items:
                    return

    def _split_files(self, worker_info):
        if worker_info is None:
            return list(self.file_list)
        per = len(self.file_list) // worker_info.num_workers
        start = worker_info.id * per
        end = start + per if worker_info.id < worker_info.num_workers - 1 else len(self.file_list)
        return list(self.file_list[start:end])


# ── training loop ────────────────────────────────────────────────────────────

def train_epoch(model, dataloader, optimizer, device, epoch,
                warmup_steps=10000, global_step=0):
    """Train one epoch."""
    model.train()
    total_loss = 0.0
    pbar = tqdm(dataloader, desc=f"Epoch {epoch}")

    for batch in pbar:
        # Move to device
        batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                 for k, v in batch.items()}

        # Shift targets (teacher forcing)
        tgt_in = batch["tgt_tokens"][:, :-1]
        tgt_out = batch["tgt_tokens"][:, 1:]

        # Forward
        batch["tgt_tokens"] = tgt_in
        output = model(batch)
        loss, gen_loss, cp_loss, pt_loss = compute_loss(
            output, tgt_out)

        # Backward
        optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()

        # Warmup
        global_step += 1
        if global_step < warmup_steps:
            lr_scale = global_step / max(1, warmup_steps)
            for param_group in optimizer.param_groups:
                param_group["lr"] = param_group["initial_lr"] * lr_scale

        total_loss += loss.item()
        pbar.set_postfix({"loss": f"{loss.item():.4f}",
                          "gen": f"{gen_loss.item():.4f}"})

    return total_loss / len(dataloader), global_step


@torch.no_grad()
def evaluate_fast(model, dataloader, device, vocab):
    """Fast evaluation: token prediction accuracy on eval set (no generation).

    This runs in seconds even on large eval sets.  Measures whether the
    model assigns highest probability to the correct next token given
    teacher-forced context — a reliable proxy for model quality.
    """
    model.eval()
    total_tokens = 0
    correct_tokens = 0

    for batch in dataloader:
        batch_t = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                    for k, v in batch.items()}
        tgt_in = batch_t["tgt_tokens"][:, :-1]
        tgt_out = batch_t["tgt_tokens"][:, 1:]
        batch_t["tgt_tokens"] = tgt_in

        out = model(batch_t)
        # Token logits: (B, S, V) — argmax over vocab
        preds = out["token_logits"].argmax(dim=-1)  # (B, S)
        mask = tgt_out != 0  # ignore padding
        correct_tokens += (preds[mask] == tgt_out[mask]).sum().item()
        total_tokens += mask.sum().item()

    if total_tokens == 0:
        return -1.0  # signal: no eval data
    return correct_tokens / total_tokens


@torch.no_grad()
def evaluate_full(model, dataloader, device, vocab, max_items: int = None):
    """Full evaluation: autoregressive generation, measures exact match.

    Slow — use sparingly (every N epochs, or at the end).
    Set max_items to cap eval examples."""
    model.eval()
    correct_top1 = 0
    correct_action_type = 0
    total = 0

    for batch in tqdm(dataloader, desc="Eval (gen)"):
        batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                 for k, v in batch.items()}

        for i in range(len(batch["action_types"])):
            total += 1
            if max_items and total > max_items:
                break

            single = {
                k: v[i:i+1] if isinstance(v, torch.Tensor) else [v[i]]
                for k, v in batch.items()
            }

            try:
                output_ids = model.generate(single, temperature=1.0)
                pred_tokens = []
                for tok_id, is_copy, _ in output_ids:
                    if is_copy:
                        pred_tokens.append("<COPY>")
                    else:
                        pred_tokens.append(
                            vocab.id_to_token.get(tok_id, "<unk>"))

                pred_str = " ".join(pred_tokens)
                action_type = batch["action_types"][i]
                action_obj = str(batch["action_objs"][i])

                if action_type in pred_str:
                    correct_action_type += 1
                if action_type in pred_str and action_obj in pred_str:
                    correct_top1 += 1

            except Exception as e:
                logger.debug(f"  Generation failed: {e}")
                continue

        if max_items and total >= max_items:
            break

    top1_acc = correct_top1 / max(total, 1)
    at_acc = correct_action_type / max(total, 1)
    return {"top1": top1_acc, "action_type": at_acc, "total": total}


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description="Train Graph2Tocopo model for ACL2 proof fixing")
    p.add_argument("--data-dir", default="../../../../../data/preprocessed",
                   help="Preprocessed .pt directory (output of preprocess.py)")
    p.add_argument("--output-dir", default="./models_v5",
                   help="Output directory for model checkpoints")
    p.add_argument("--resume", default=None,
                   help="Resume from checkpoint")
    p.add_argument("--hidden-dim", type=int, default=DEFAULT_HIDDEN_DIM)
    p.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    p.add_argument("--epochs", type=int, default=DEFAULT_EPOCHS)
    p.add_argument("--lr", type=float, default=DEFAULT_LR)
    p.add_argument("--max-nodes", type=int, default=DEFAULT_MAX_NODES)
    p.add_argument("--eval-frac", type=float, default=DEFAULT_EVAL_FRAC)
    p.add_argument("--exclude", nargs="*", default=["kestrel/helpers"])
    p.add_argument("--max-items", type=int, default=None,
                   help="Max items to load (for testing)")
    p.add_argument("--num-workers", type=int, default=2)
    p.add_argument("--eval-full-every", type=int, default=5,
                   help="Run full generation eval every N epochs (0=never, "
                        "default: every 5)")
    p.add_argument("--eval-max-items", type=int, default=200,
                   help="Max items for full generation eval (default: 200)")
    p.add_argument("--encoder-type", default="ggnn",
                   choices=["ggnn", "great"])
    p.add_argument("--log-level", default="INFO",
                   choices=["DEBUG", "INFO", "WARNING"])
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    if torch.cuda.is_available():
        device = torch.device("cuda")
    elif torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    # device = torch.device("cpu")
    logger.info(f"Using device: {device}")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # ── Load preprocessed data (manifest + vocab) ────────────────────────
    preproc_dir = Path(args.data_dir)  # now points to preprocessed dir
    manifest_path = preproc_dir / "manifest.json"
    vocab_path = preproc_dir / "vocab.json"

    if not manifest_path.exists():
        logger.error(
            "Manifest not found at %s.  Run preprocessing first:\n"
            "  python training/preprocess.py --data-dir /path/to/books "
            "--output-dir /path/to/preprocessed", manifest_path)
        sys.exit(1)

    with open(manifest_path) as f:
        manifest = json.load(f)
    with open(vocab_path) as f:
        vocab_data = json.load(f)

    token_to_id = vocab_data["token_to_id"]
    id_to_token = {v: k for k, v in token_to_id.items()}
    vocab_size = len(token_to_id)

    # Create minimal vocab wrapper for eval functions
    class MinimalVocab:
        def __init__(self):
            self.id_to_token = id_to_token
            self.token_to_id = token_to_id
        def encode(self, tokens):
            return [self.token_to_id.get(t, 3) for t in tokens]
    vocab = MinimalVocab()
    logger.info(
        f"  Manifest: train={len(manifest.get('train',[]))} "
        f"val={len(manifest.get('val',[]))} "
        f"test={len(manifest.get('test',[]))} files, vocab={vocab_size}")

    # ── Create datasets from preprocessed .pt files ──────────────────────
    logger.info("Creating preprocessed datasets...")
    train_dataset = PreprocessedDataset(
        manifest.get("train", []), preproc_dir, max_items=args.max_items)
    val_files = manifest.get("val", [])
    if not val_files:
        logger.warning("  No validation split — using test files for eval.")
        val_files = manifest.get("test", [])
    val_dataset = PreprocessedDataset(
        val_files, preproc_dir, max_items=args.max_items)

    train_loader = DataLoader(
        train_dataset, batch_size=args.batch_size,
        collate_fn=collate_graphs, num_workers=args.num_workers,
        pin_memory=(device.type == "cuda"))

    val_loader = DataLoader(
        val_dataset, batch_size=args.batch_size,
        collate_fn=collate_graphs, num_workers=0,
        pin_memory=(device.type == "cuda"))

    # Determine num_edge_types from first batch
    first_batch = next(iter(train_loader))
    num_edge_types = max(10, first_batch["edge_types"].max().item() + 1)
    logger.info(f"  Num edge types: {num_edge_types}")

    # Create model
    logger.info("Creating model...")
    model = Graph2Tocopo(
        hidden_dim=args.hidden_dim,
        vocab_size=vocab_size,
        num_edge_types=num_edge_types,
        encoder_type=args.encoder_type,
    ).to(device)

    n_params = sum(p.numel() for p in model.parameters())
    logger.info(f"  Parameters: {n_params:,}")

    # Optimizer
    optimizer = optim.Adam(model.parameters(), lr=args.lr)
    for pg in optimizer.param_groups:
        pg["initial_lr"] = args.lr

    # ── resume / auto-resume ─────────────────────────────────────────────
    start_epoch = 1
    global_step = 0
    best_acc = 0.0

    # Auto-detect latest checkpoint if --resume not specified
    resume_path = args.resume
    if resume_path is None and out_dir.exists():
        epoch_ckpts = sorted(out_dir.glob("checkpoint_epoch*.pt"))
        if epoch_ckpts:
            resume_path = str(epoch_ckpts[-1])
            logger.info(f"Auto-resuming from {resume_path}")

    if resume_path:
        resume_path = Path(resume_path)
        if resume_path.exists():
            logger.info(f"Loading checkpoint: {resume_path}")
            ckpt = torch.load(resume_path, map_location=device, weights_only=False)

            model.load_state_dict(ckpt["model_state"])
            optimizer.load_state_dict(ckpt["optimizer_state"])
            # Restore optimizer state to correct device
            for pg_state in optimizer.state.values():
                for k, v in pg_state.items():
                    if isinstance(v, torch.Tensor):
                        pg_state[k] = v.to(device)

            # Restore vocab from checkpoint (vocab is serialized as dict)
            if "vocab" in ckpt:
                vocab.token_to_id = ckpt["vocab"]
                vocab.id_to_token = {v: k for k, v in vocab.token_to_id.items()}
                vocab.next_id = max(vocab.token_to_id.values()) + 1

            # Restore training state
            old_epoch = ckpt.get("epoch", 0)
            start_epoch = old_epoch + 1
            best_acc = ckpt.get("metrics", {}).get("action_type", 0.0)
            global_step = old_epoch * len(train_loader)  # approximate

            logger.info(f"  Resumed from epoch {old_epoch}, "
                         f"best_acc={best_acc:.4f}, "
                         f"starting at epoch {start_epoch}")
        else:
            logger.warning(f"Resume path not found: {resume_path}")

    if start_epoch > args.epochs:
        logger.info("All epochs already completed.  Done.")
        return

    for epoch in range(start_epoch, args.epochs + 1):
        logger.info(f"\n=== Epoch {epoch}/{args.epochs} ===")

        avg_loss, global_step = train_epoch(
            model, train_loader, optimizer, device, epoch,
            warmup_steps=10000, global_step=global_step)
        logger.info(f"  Avg train loss: {avg_loss:.4f}")

        # Fast eval every epoch (token accuracy — runs in seconds)
        token_acc = evaluate_fast(model, val_loader, device, vocab)
        if token_acc < 0:
            logger.info("  Eval: (no eval items — book-level split may "
                         "put all early books in training)")
            token_acc = 0.0  # placeholder
        else:
            logger.info(f"  Eval: token_acc={token_acc:.4f}")
        metrics = {"token_acc": token_acc}

        # Full generation eval every N epochs (slow but meaningful)
        if args.eval_full_every > 0 and epoch % args.eval_full_every == 0:
            gen_metrics = evaluate_full(
                model, val_loader, device, vocab,
                max_items=args.eval_max_items)
            metrics.update(gen_metrics)
            if gen_metrics["total"] == 0:
                logger.info("  Eval (gen): (no eval items)")
            else:
                logger.info(
                    f"  Eval: token_acc={token_acc:.4f}  "
                    f"Top-1={gen_metrics['top1']:.4f}  "
                    f"ActionType={gen_metrics['action_type']:.4f}  "
                    f"({gen_metrics['total']} items)")

        # Save checkpoint
        checkpoint = {
            "epoch": epoch,
            "model_state": model.state_dict(),
            "optimizer_state": optimizer.state_dict(),
            "vocab": vocab.token_to_id,
            "metrics": metrics,
            "args": vars(args),
        }

        checkpoint_path = out_dir / f"checkpoint_epoch{epoch}.pt"
        torch.save(checkpoint, checkpoint_path)
        logger.info(f"  Saved checkpoint to {checkpoint_path}")

        # Save best
        current_acc = metrics.get("action_type", best_acc)
        if current_acc > best_acc:
            best_acc = current_acc
            best_path = out_dir / "best_model.pt"
            torch.save(checkpoint, best_path)
            logger.info(f"  New best model (accuracy={best_acc:.4f})")

    logger.info(f"\nTraining complete. Best accuracy: {best_acc:.4f}")


if __name__ == "__main__":
    main()
