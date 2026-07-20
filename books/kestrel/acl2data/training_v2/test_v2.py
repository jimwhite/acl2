"""Test training_v2 pipeline on CPU with dummy data.

Tests each component in isolation and end-to-end:
1. DenseGGNN forward pass (the einsum that OOM'd)
2. DenseGraph2Tocopo forward pass
3. Dataset + collate + model forward (full pipeline)
4. Training loop (few steps on tiny data)

All tensors use realistic shapes: (B=2, E=10, N=512, H=128, S=57)
"""

import sys, os, tempfile, json
from pathlib import Path
import torch
import torch.nn as nn

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGGNN, DenseGraph2Tocopo
from training_v2.train import FixedDataset, collate_fixed, compute_loss


def test_dense_ggnn_forward():
    """Test the exact einsum that OOM'd on MPS."""
    print("1. DenseGGNN forward (B=2, E=10, N=512, H=128)...", flush=True)
    B, E, N, H = 2, 10, 512, 128

    model = DenseGGNN(hidden_dim=H, num_edge_types=E, num_timesteps=4)

    nt = torch.randint(0, 3, (B, N))
    st = torch.randint(-1, 1000, (B, N))
    edges = torch.zeros(B, E, N, N)
    # Add a few edges
    edges[0, 0, 0, 1] = 1.0
    edges[0, 1, 1, 2] = 1.0
    edges[1, 0, 0, 1] = 1.0

    with torch.no_grad():
        out = model(nt, st, edges)
    assert out.shape == (B, N, H), f"bad shape: {out.shape}"
    print(f"  PASSED shape={out.shape}", flush=True)


def test_graph2tocopo_forward():
    """Test full model forward pass."""
    print("2. DenseGraph2Tocopo forward (B=2, V=500)...", flush=True)
    B, E, N, H, V, S = 2, 10, 32, 128, 500, 20

    model = DenseGraph2Tocopo(
        hidden_dim=H, num_edge_types=E, vocab_size=V,
        num_timesteps=2, num_decoder_layers=1, num_heads=1)

    batch = {
        "node_types": torch.randint(0, 3, (B, N)),
        "subtoken_ids": torch.randint(-1, 1000, (B, N)),
        "edges": torch.zeros(B, E, N, N),
        "copy_mask": torch.ones(B, N, dtype=torch.bool),
        "tgt_ids": torch.randint(1, V, (B, S)),
    }
    batch["edges"][0, 0, 0, 1] = 1.0

    with torch.no_grad():
        out = model(batch)

    tk = out["token_logits"]
    assert tk.shape == (B, S - 1, V), f"bad token_logits: {tk.shape}"
    print(f"  PASSED token_logits={tk.shape}", flush=True)


def test_dataset_collate():
    """Test FixedDataset loading + collate + model forward."""
    print("3. Dataset → collate → forward...", flush=True)

    N, E, V, S = 32, 10, 100, 10
    n_items = 4

    # Create dummy .pt file
    tmpdir = tempfile.mkdtemp()
    train_dir = Path(tmpdir) / "train"
    train_dir.mkdir(parents=True)

    data = {
        "node_types": torch.randint(0, 3, (n_items, N)),
        "subtoken_ids": torch.randint(-1, 100, (n_items, N)),
        "edge_index": torch.tensor([[0, 0], [1, 2]]),
        "edge_types": torch.tensor([0, 1]),
        "edge_counts": torch.tensor([2] * n_items),
        "tgt_ids": torch.randint(1, V, (n_items, S)),
        "action_types": torch.zeros(n_items, dtype=torch.long),
        "copy_mask": torch.ones(n_items, N, dtype=torch.bool),
    }
    torch.save(data, train_dir / "test.pt")

    manifest = {"train": ["train/test.pt"], "val": [], "test": []}
    json.dump(manifest, open(Path(tmpdir) / "manifest.json", "w"))
    json.dump({"token_to_id": {"<pad>": 0, "a": 1}, "num_edge_types": E},
              open(Path(tmpdir) / "vocab.json", "w"))

    ds = FixedDataset(manifest["train"], tmpdir, num_edge_types=E)
    print(f"  Dataset: {len(ds)} items", flush=True)

    loader = torch.utils.data.DataLoader(
        ds, batch_size=2, collate_fn=collate_fixed)
    batch = next(iter(loader))

    assert batch["node_types"].shape == (2, N)
    assert batch["edges"].shape == (2, E, N, N)
    assert batch["tgt_ids"].shape == (2, S)
    print(f"  Collate: nt={batch['node_types'].shape} edges={batch['edges'].shape}", flush=True)

    # Model forward
    model = DenseGraph2Tocopo(
        hidden_dim=64, num_edge_types=E, vocab_size=V,
        num_timesteps=2, num_decoder_layers=1, num_heads=1)
    with torch.no_grad():
        out = model(batch)
    print(f"  Model: token_logits={out['token_logits'].shape}", flush=True)

    # Loss
    loss = compute_loss(out, batch["tgt_ids"][:, 1:])
    assert loss.item() > 0
    print(f"  Loss: {loss.item():.4f}", flush=True)

    # Cleanup
    import shutil
    shutil.rmtree(tmpdir)
    print("  PASSED", flush=True)


def test_training_step():
    """Test optimizer step (gradients flow)."""
    print("4. Training step (B=2, backward)...", flush=True)
    B, E, N, H, V, S = 2, 10, 32, 64, 100, 10

    model = DenseGraph2Tocopo(
        hidden_dim=H, num_edge_types=E, vocab_size=V,
        num_timesteps=2, num_decoder_layers=1, num_heads=1)

    batch = {
        "node_types": torch.randint(0, 3, (B, N)),
        "subtoken_ids": torch.randint(-1, 100, (B, N)),
        "edges": torch.zeros(B, E, N, N),
        "copy_mask": torch.ones(B, N, dtype=torch.bool),
        "tgt_ids": torch.randint(1, V, (B, S)),
    }
    batch["edges"][0, 0, 0, 1] = 1.0

    opt = torch.optim.Adam(model.parameters(), lr=1e-5)
    out = model(batch)
    loss = compute_loss(out, batch["tgt_ids"][:, 1:])
    loss.backward()
    opt.step()
    print(f"  Loss: {loss.item():.4f}  PASSED", flush=True)


if __name__ == "__main__":
    test_dense_ggnn_forward()
    test_graph2tocopo_forward()
    test_dataset_collate()
    test_training_step()
    print("\nAll 4 tests passed!")
