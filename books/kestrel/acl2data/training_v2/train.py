"""
Train Graph2Tocopo v2 — PLUR-compatible architecture.

Key differences from v1:
  - hidden_dim=128 (not 256) — matches PLUR
  - 1 attention head (not 8) — PLUR standard
  - Fixed-size global padding — no per-batch dynamic collate
  - Map-style Dataset over uniform .pt files — no IterableDataset
  - Fixed number of steps (not epochs) — 50K default
  - Adam LR=1e-5 with linear warmup — PLUR defaults
  - Gradient clipping at 1.0 — PLUR standard

Usage:
  python training_v2/train.py --data-dir /path/to/preprocessed --steps 50000
"""

import json, argparse, logging, sys, time
from pathlib import Path

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR.parent))

from training_v2.dense_model import DenseGraph2Tocopo

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# Model
# ═══════════════════════════════════════════════════════════════════════════════

# DenseGraph2Tocopo handles all batching internally (pure einsum, no Python loops)


def compute_loss(dec_out, tgt_out, pad_idx=0):
    token_logits = dec_out["token_logits"]  # (B, S, V)
    loss = nn.functional.cross_entropy(
        token_logits.reshape(-1, token_logits.size(-1)),
        tgt_out.reshape(-1),
        ignore_index=pad_idx)
    return loss


# ═══════════════════════════════════════════════════════════════════════════════
# Dataset — uniform fixed-size .pt files, simple map-style
# ═══════════════════════════════════════════════════════════════════════════════

class FixedDataset(Dataset):
    """Map-style Dataset over globally-padded .pt files.

    Edges are stored sparsely per-file.  __getitem__ builds a dense
    (E, N, N) adjacency for the single item — small and fast."""

    def __init__(self, file_list, preproc_dir, num_edge_types=10):
        tensors = []
        for rel_path in file_list:
            data = torch.load(Path(preproc_dir) / rel_path,
                              weights_only=True)
            tensors.append(data)

        self.node_types = torch.cat([t["node_types"] for t in tensors])
        self.subtoken_ids = torch.cat([t["subtoken_ids"] for t in tensors])
        self.tgt_ids = torch.cat([t["tgt_ids"] for t in tensors])
        self.action_types = torch.cat([t["action_types"] for t in tensors])
        self.copy_mask = torch.cat([t["copy_mask"] for t in tensors])
        self.edge_counts = torch.cat([t["edge_counts"] for t in tensors])
        self.edge_index = torch.cat(
            [t["edge_index"] for t in tensors], dim=1)
        self.edge_types = torch.cat([t["edge_types"] for t in tensors])

        self.N = self.node_types.size(1)
        self.E = num_edge_types

    def __len__(self):
        return len(self.node_types)

    def __getitem__(self, idx):
        # Build dense edges for this one item (fast — just scatter)
        start = self.edge_counts[:idx].sum().item()
        count = self.edge_counts[idx].item()
        dense = torch.zeros(self.E, self.N, self.N, dtype=torch.float32)
        if count > 0:
            ei = self.edge_index[:, start:start + count]
            et = self.edge_types[start:start + count]
            # Only include edges within N bounds
            valid = (ei[0] < self.N) & (ei[1] < self.N)
            dense[et[valid], ei[0, valid], ei[1, valid]] = 1.0

        return {
            "node_types": self.node_types[idx],
            "subtoken_ids": self.subtoken_ids[idx],
            "edges": dense,
            "tgt_ids": self.tgt_ids[idx],
            "copy_mask": self.copy_mask[idx],
        }


def collate_fixed(batch):
    """Stack tensors (all items same shape).  model ignores action_type."""
    return {
        "node_types": torch.stack([b["node_types"] for b in batch]),
        "subtoken_ids": torch.stack([b["subtoken_ids"] for b in batch]),
        "edges": torch.stack([b["edges"] for b in batch]),
        "tgt_ids": torch.stack([b["tgt_ids"] for b in batch]),
        "copy_mask": torch.stack([b["copy_mask"] for b in batch]),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--data-dir", required=True,
                   help="Preprocessed directory with manifest.json")
    p.add_argument("--output-dir", default="./models_v6")
    p.add_argument("--steps", type=int, default=50000,
                   help="Training steps (not epochs)")
    p.add_argument("--batch-size", type=int, default=8)
    p.add_argument("--lr", type=float, default=1e-5)
    p.add_argument("--warmup-frac", type=float, default=0.0)
    p.add_argument("--hidden-dim", type=int, default=128)
    p.add_argument("--num-workers", type=int, default=4)
    p.add_argument("--valid-steps", type=int, default=5000)
    p.add_argument("--log-steps", type=int, default=1000)
    p.add_argument("--checkpoint-steps", type=int, default=10000)
    p.add_argument("--max-items", type=int, default=None)
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    # device = torch.device("cpu")
    device = torch.device("cuda" if torch.cuda.is_available() else
                          "mps" if torch.backends.mps.is_available() else
                          "cpu")
    logger.info(f"Device: {device}")

    preproc_dir = Path(args.data_dir)
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load manifest + vocab
    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)
    with open(preproc_dir / "vocab.json") as f:
        vocab_data = json.load(f)

    vocab_size = len(vocab_data["token_to_id"])
    num_edge_types = vocab_data["num_edge_types"]

    logger.info(
        f"Files: train={len(manifest.get('train',[]))} "
        f"val={len(manifest.get('val',[]))} "
        f"test={len(manifest.get('test',[]))}, "
        f"vocab={vocab_size}, edge_types={num_edge_types}")

    # Load datasets (into memory — global padding makes this feasible)
    logger.info("Loading training data...")
    t0 = time.time()
    train_ds = FixedDataset(
        manifest.get("train", []), preproc_dir,
        num_edge_types=num_edge_types)
    if args.max_items and len(train_ds) > args.max_items:
        train_ds.node_types = train_ds.node_types[:args.max_items]
        train_ds.subtoken_ids = train_ds.subtoken_ids[:args.max_items]
        train_ds.edges = train_ds.edges[:args.max_items]
        train_ds.tgt_ids = train_ds.tgt_ids[:args.max_items]
        train_ds.action_types = train_ds.action_types[:args.max_items]
        train_ds.copy_mask = train_ds.copy_mask[:args.max_items]

    val_files = manifest.get("val", manifest.get("test", []))
    val_ds = FixedDataset(val_files, preproc_dir,
                          num_edge_types=num_edge_types) if val_files else None

    logger.info(f"  {len(train_ds):,} train items ({time.time()-t0:.1f}s)")

    train_loader = DataLoader(
        train_ds, batch_size=args.batch_size, shuffle=True,
        collate_fn=collate_fixed, num_workers=args.num_workers,
        pin_memory=(device.type != "mps"), drop_last=True)

    if val_ds:
        val_loader = DataLoader(
            val_ds, batch_size=args.batch_size, shuffle=False,
            collate_fn=collate_fixed, num_workers=0,
            pin_memory=(device.type != "mps"), drop_last=True)
    else:
        val_loader = None

    # Model
    logger.info("Creating model...")
    model = DenseGraph2Tocopo(
        hidden_dim=args.hidden_dim,
        num_edge_types=num_edge_types,
        vocab_size=vocab_size,
    ).to(device)
    n_params = sum(p.numel() for p in model.parameters())
    logger.info(f"  Parameters: {n_params:,}")

    optimizer = optim.Adam(model.parameters(), lr=args.lr)
    warmup_steps = int(args.steps * args.warmup_frac)
    base_lr = args.lr

    # Training loop (PLUR-style: fixed steps, n
    global_step = 0
    best_loss = float("inf")
    pbar = tqdm(total=args.steps, desc="Training")

    model.train()
    data_iter = iter(train_loader)

    while global_step < args.steps:
        try:
            batch = next(data_iter)
        except StopIteration:
            data_iter = iter(train_loader)
            batch = next(data_iter)

        batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                 for k, v in batch.items()}

        dec_out = model(batch)
        tgt_out = batch["tgt_ids"][:, 1:]
        loss = compute_loss(dec_out, tgt_out)

        optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()

        # Linear warmup
        global_step += 1
        if global_step < warmup_steps:
            lr = base_lr * global_step / max(1, warmup_steps)
            for pg in optimizer.param_groups:
                pg["lr"] = lr

        pbar.set_postfix({"loss": f"{loss.item():.4f}"})
        pbar.update(1)

        # Logging
        if global_step % args.log_steps == 0:
            logger.info(f"  step {global_step}/{args.steps} loss={loss.item():.4f}")

        # Validation
        if val_loader and global_step % args.valid_steps == 0:
            model.eval()
            val_loss = 0.0
            val_count = 0
            with torch.no_grad():
                for val_batch in val_loader:
                    val_batch = {k: v.to(device) if isinstance(v, torch.Tensor) else v
                                 for k, v in val_batch.items()}
                    vd = model(val_batch)
                    val_loss += compute_loss(vd, val_batch["tgt_ids"][:, 1:]).item()
                    val_count += 1
                    if val_count >= 50:  # PLUR: max 50 validation batches
                        break
            val_loss /= max(val_count, 1)
            logger.info(f"  val_step={global_step} val_loss={val_loss:.4f}")
            if val_loss < best_loss:
                best_loss = val_loss
                torch.save({
                    "step": global_step,
                    "model_state": model.state_dict(),
                    "optimizer_state": optimizer.state_dict(),
                    "val_loss": val_loss,
                    "args": vars(args),
                }, out_dir / "best_model.pt")
                logger.info(f"  New best model (val_loss={val_loss:.4f})")
            model.train()

        # Checkpoint
        if global_step % args.checkpoint_steps == 0:
            torch.save({
                "step": global_step,
                "model_state": model.state_dict(),
                "optimizer_state": optimizer.state_dict(),
                "args": vars(args),
            }, out_dir / f"checkpoint_step{global_step}.pt")

    pbar.close()
    logger.info(f"Training complete. Best val_loss={best_loss:.4f}")


if __name__ == "__main__":
    main()
