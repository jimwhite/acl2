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
from torch.utils.data import DataLoader, Dataset
from tqdm import tqdm

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


# ── dataset ──────────────────────────────────────────────────────────────────

class Acl2ProofDataset(Dataset):
    """PyTorch dataset wrapping .mli records as graph tensors."""

    def __init__(self, items: list, graph_builder: GraphBuilder,
                 vocab: FixVocab, max_nodes: int = 512, max_seq_len: int = 256):
        self.items = items
        self.graph_builder = graph_builder
        self.vocab = vocab
        self.max_nodes = max_nodes
        self.max_seq_len = max_seq_len

    def __len__(self):
        return len(self.items)

    def __getitem__(self, idx):
        item = self.items[idx]

        # Build graph
        graph = self.graph_builder.build_graph(item, max_nodes=self.max_nodes)

        # Build target sequence
        tgt_tokens = build_target_sequence(item)
        tgt_ids = self.vocab.encode(tgt_tokens[:self.max_seq_len])

        return {
            "graph": graph,
            "tgt_ids": tgt_ids,
            "action_type": item.get("output", {}).get("action-type", ""),
            "action_obj": item.get("output", {}).get("action-obj", ""),
        }


def collate_graphs(batch):
    """Collate function: merges variable-size graphs into batched tensors."""

    # Collect graph data
    all_node_types = []
    all_subtoken_ids = []
    all_edge_index_0 = []
    all_edge_index_1 = []
    all_edge_types = []
    num_nodes = []
    node_offsets = [0]

    # Target sequences
    max_seq_len = max(len(b["tgt_ids"]) for b in batch)
    tgt_padded = []
    copy_masks = []  # per graph, per node

    for b in batch:
        g = b["graph"]
        n = len(g["node_types"])
        num_nodes.append(n)

        # Accumulate with offset
        all_node_types.extend(
            _node_type_to_int(nt) for nt in g["node_types"])
        all_subtoken_ids.extend(g["subtoken_ids"])
        offset = node_offsets[-1]
        all_edge_index_0.extend(e + offset for e in g["edge_index"][0])
        all_edge_index_1.extend(e + offset for e in g["edge_index"][1])
        all_edge_types.extend(g["edge_types"])
        node_offsets.append(offset + n)

        # Target
        tgt_ids = b["tgt_ids"][:max_seq_len]
        pad_len = max_seq_len - len(tgt_ids)
        tgt_padded.append(tgt_ids + [0] * pad_len)

        # Copy mask: which nodes can be copied (TOKEN nodes)
        mask = [1 if nt == "token" else 0
                for nt in g["node_types"]]
        copy_masks.append(torch.tensor(mask, dtype=torch.bool))

    # Stack targets
    tgt_tokens = torch.tensor(tgt_padded, dtype=torch.long)

    # Pad copy masks to same max_nodes
    max_n = max(num_nodes)
    copy_mask_padded = torch.zeros(len(batch), max_n, dtype=torch.bool)
    for i, mask in enumerate(copy_masks):
        copy_mask_padded[i, :len(mask)] = mask

    # Pad node types + subtoken_ids to max_n * batch_size
    padded_node_types = torch.zeros(
        len(batch) * max_n, dtype=torch.long)
    padded_subtoken_ids = torch.full(
        (len(batch) * max_n,), -1, dtype=torch.long)
    for i, (n, b) in enumerate(zip(num_nodes, batch)):
        g = b["graph"]
        start = i * max_n
        padded_node_types[start:start + n] = torch.tensor(
            [_node_type_to_int(nt) for nt in g["node_types"]],
            dtype=torch.long)
        padded_subtoken_ids[start:start + n] = torch.tensor(
            g["subtoken_ids"], dtype=torch.long)

    return {
        "node_types": padded_node_types,
        "subtoken_ids": padded_subtoken_ids,
        "edge_index": torch.tensor(
            [all_edge_index_0, all_edge_index_1], dtype=torch.long),
        "edge_types": torch.tensor(all_edge_types, dtype=torch.long),
        "num_nodes": num_nodes,
        "tgt_tokens": tgt_tokens,
        "copy_mask": copy_mask_padded,
        "action_types": [b["action_type"] for b in batch],
        "action_objs": [b["action_obj"] for b in batch],
    }


def _node_type_to_int(nt: str) -> int:
    return {"token": 0, "subtoken": 1, "root": 2}.get(nt, 0)


# ── data loading ─────────────────────────────────────────────────────────────

def load_items(data_dir: str, eval_frac: float = 0.05,
               exclude_dirs: set = None, max_items: int = None):
    """Stream .mli files and split into train/eval by book hash."""
    import ijson
    root = Path(data_dir)
    if exclude_dirs is None:
        exclude_dirs = {"kestrel/helpers"}

    train_items = []
    eval_items = []
    count = 0

    for mli_path in sorted(root.rglob("*.mli")):
        # Check exclusion
        try:
            rel = mli_path.relative_to(root)
        except ValueError:
            continue
        parts = rel.parts
        excluded = any(
            parts[:len(tuple(exc.strip("/").split("/")))] ==
            tuple(exc.strip("/").split("/"))
            for exc in exclude_dirs)
        if excluded:
            continue

        # Book-level split
        book_key = str(rel.parent) if str(rel.parent) != "." else str(rel.stem)
        split_hash = hashlib.md5(book_key.encode()).hexdigest()
        is_eval = int(split_hash, 16) % 1000 < int(eval_frac * 1000)

        # Stream items from file
        try:
            with open(mli_path, "rb") as f:
                for item in ijson.items(f, "item"):
                    at = item.get("output", {}).get("action-type", "")
                    ao = item.get("output", {}).get("action-obj", "")
                    if not at or not ao:
                        continue
                    if is_eval:
                        eval_items.append(item)
                    else:
                        train_items.append(item)
                    count += 1
                    if max_items and count >= max_items:
                        logger.info(
                            f"  Reached max_items={max_items}, stopping.")
                        return train_items, eval_items
        except Exception as e:
            logger.warning(f"  Skipping {mli_path}: {e}")

        if count % 100000 == 0:
            logger.info(
                f"  Loaded {count} items ({len(train_items)} train, "
                f"{len(eval_items)} eval)")

    logger.info(
        f"  Total: {len(train_items)} train, {len(eval_items)} eval items")
    return train_items, eval_items


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
def evaluate(model, dataloader, device, vocab):
    """Evaluate model: compute exact match accuracy."""
    model.eval()
    correct_top1 = 0
    correct_action_type = 0
    total = 0

    for batch in tqdm(dataloader, desc="Eval"):
        batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                 for k, v in batch.items()}

        # Generate for each example (batch_size=1 for generation)
        for i in range(len(batch["action_types"])):
            total += 1

            # Build single-example batch
            single = {
                k: v[i:i+1] if isinstance(v, torch.Tensor) else [v[i]]
                for k, v in batch.items()
            }

            try:
                output_ids = model.generate(single, temperature=1.0)
                # Decode prediction
                pred_tokens = []
                for tok_id, is_copy, _ in output_ids:
                    if is_copy:
                        pred_tokens.append("<COPY>")
                    else:
                        pred_tokens.append(vocab.id_to_token.get(tok_id, "<unk>"))

                # Check if matches ground truth
                # (simplified: compare action type only for now)
                pred_str = " ".join(pred_tokens)
                action_type = batch["action_types"][i]
                action_obj = str(batch["action_objs"][i])

                if action_type in pred_str:
                    correct_action_type += 1
                if action_type in pred_str and action_obj in pred_str:
                    correct_top1 += 1

            except Exception as e:
                logger.warning(f"  Generation failed: {e}")
                continue

    top1_acc = correct_top1 / max(total, 1)
    at_acc = correct_action_type / max(total, 1)
    logger.info(
        f"  Eval: Top-1={top1_acc:.4f}, ActionType={at_acc:.4f} "
        f"({total} examples)")
    return {"top1": top1_acc, "action_type": at_acc}


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description="Train Graph2Tocopo model for ACL2 proof fixing")
    p.add_argument("--data-dir", default="/workspaces/acl2-jupyter/data/books",
                   help="Root .mli directory")
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
    p.add_argument("--encoder-type", default="ggnn",
                   choices=["ggnn", "great"])
    p.add_argument("--log-level", default="INFO",
                   choices=["DEBUG", "INFO", "WARNING"])
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"Using device: {device}")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load data
    logger.info("Loading data...")
    train_items, eval_items = load_items(
        args.data_dir, eval_frac=args.eval_frac,
        exclude_dirs=set(args.exclude), max_items=args.max_items)

    # Build vocabulary from training data
    logger.info("Building vocabulary...")
    vocab = FixVocab()
    graph_builder = GraphBuilder(max_nodes=args.max_nodes)

    for item in tqdm(train_items, desc="Vocab"):
        tgt = build_target_sequence(item)
        for tok in tgt:
            vocab.add_token(tok)
    logger.info(f"  Vocab size: {len(vocab)}")

    # Create datasets
    logger.info("Creating datasets...")
    train_dataset = Acl2ProofDataset(
        train_items, graph_builder, vocab, max_nodes=args.max_nodes)
    eval_dataset = Acl2ProofDataset(
        eval_items, graph_builder, vocab, max_nodes=args.max_nodes)

    train_loader = DataLoader(
        train_dataset, batch_size=args.batch_size, shuffle=True,
        collate_fn=collate_graphs, num_workers=args.num_workers,
        pin_memory=True)

    eval_loader = DataLoader(
        eval_dataset, batch_size=args.batch_size, shuffle=False,
        collate_fn=collate_graphs, num_workers=args.num_workers,
        pin_memory=True)

    # Determine num_edge_types from first batch
    first_batch = next(iter(train_loader))
    # Count distinct edge types used
    num_edge_types = max(10, first_batch["edge_types"].max().item() + 1)
    logger.info(f"  Num edge types: {num_edge_types}")

    # Create model
    logger.info("Creating model...")
    model = Graph2Tocopo(
        hidden_dim=args.hidden_dim,
        vocab_size=len(vocab),
        num_edge_types=num_edge_types,
        encoder_type=args.encoder_type,
    ).to(device)

    n_params = sum(p.numel() for p in model.parameters())
    logger.info(f"  Parameters: {n_params:,}")

    # Optimizer
    optimizer = optim.Adam(model.parameters(), lr=args.lr)
    for pg in optimizer.param_groups:
        pg["initial_lr"] = args.lr

    # Training
    global_step = 0
    best_acc = 0.0

    for epoch in range(1, args.epochs + 1):
        logger.info(f"\n=== Epoch {epoch}/{args.epochs} ===")

        avg_loss, global_step = train_epoch(
            model, train_loader, optimizer, device, epoch,
            warmup_steps=10000, global_step=global_step)
        logger.info(f"  Avg train loss: {avg_loss:.4f}")

        # Evaluate
        metrics = evaluate(model, eval_loader, device, vocab)

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
        if metrics["action_type"] > best_acc:
            best_acc = metrics["action_type"]
            best_path = out_dir / "best_model.pt"
            torch.save(checkpoint, best_path)
            logger.info(f"  New best model (accuracy={best_acc:.4f})")

    logger.info(f"\nTraining complete. Best accuracy: {best_acc:.4f}")


if __name__ == "__main__":
    main()
