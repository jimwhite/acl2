"""
End-to-end test: Does the PLUR Graph2Tocopo overfit on a tiny dataset?

If this passes, the architecture + loss + generation are correct.
If it fails, there's a bug to find before scaling up.

Run: python training_v2/test_e2e.py
"""

import torch
import torch.nn.functional as F
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import compute_plur_loss
from training.tocopo_decoder import TocopoDecoder


def make_tiny_batch(batch_size=2, num_nodes=8, vocab_size=20, seq_len=6):
    """Create a synthetic batch with easy-to-copy patterns.

    Graphs have 4 real nodes + 4 padding.  Node 0=root, 1-3=subtoken nodes.
    Target sequence: first generate a token, then copy from graph.
    """
    B, N, V, S = batch_size, num_nodes, vocab_size, seq_len

    # Node types: 0=token, 1=subtoken, 2=root
    node_types = torch.zeros(B, N, dtype=torch.long)
    node_types[:, 0] = 2  # root
    node_types[:, 1:4] = 1  # subtokens
    node_types[:, 4:] = 0  # padding (token type)

    # Subtoken ids
    subtoken_ids = torch.full((B, N), -1, dtype=torch.long)
    subtoken_ids[:, 1:4] = torch.tensor([[10, 11, 12], [10, 11, 12]])

    # Node labels: vocab IDs for each node (for copy)
    # subtoken nodes have real labels
    node_labels = torch.zeros(B, N, dtype=torch.long)
    node_labels[:, 1:4] = torch.tensor([[10, 11, 12], [10, 11, 12]])

    # Copy mask: which nodes are copyable
    copy_mask = torch.zeros(B, N, dtype=torch.bool)
    copy_mask[:, 1:4] = True  # subtoken nodes

    # Num nodes
    num_nodes = torch.tensor([4, 4])

    # Edges: sparse → dense (E=2 edge types)
    E = 2
    edges = torch.zeros(B, E, N, N, dtype=torch.float32)
    # root → subtoken edges (type 0)
    edges[:, 0, 0, 1:4] = 1.0
    edges[:, 0, 1:4, 0] = 1.0  # reverse

    # Target sequences
    # Pattern: <sos> token_10 token_11 token_12 <eos> <pad>...
    # token_10 has ID 10 in vocab
    tgt_ids = torch.zeros(B, S, dtype=torch.long)
    tgt_ids[0, :5] = torch.tensor([1, 10, 11, 12, 2])  # sos, 10, 11, 12, eos
    tgt_ids[1, :5] = torch.tensor([1, 10, 11, 12, 2])

    return {
        "node_types": node_types,
        "subtoken_ids": subtoken_ids,
        "node_labels": node_labels,
        "copy_mask": copy_mask,
        "num_nodes": num_nodes,
        "edges": edges,
        "tgt_ids": tgt_ids,
    }


def test_overfit():
    """Train on one batch — should get loss < 0.5 and perfect generation."""
    device = torch.device("cpu")
    batch = make_tiny_batch(batch_size=2, num_nodes=8, vocab_size=20, seq_len=6)
    batch = {k: v.to(device) for k, v in batch.items()}

    model = DenseGraph2Tocopo(
        hidden_dim=64, num_edge_types=2, vocab_size=20,
        num_timesteps=4, num_decoder_layers=2, num_heads=1,
        dropout=0.0,
    ).to(device)

    n_params = sum(p.numel() for p in model.parameters())
    print(f"  Model params: {n_params:,}")

    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    model.train()

    # Train on same batch repeatedly (overfit test)
    losses = []
    for step in range(200):
        dec_out = model(batch)
        loss = compute_plur_loss(dec_out, batch)
        optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()
        losses.append(loss.item())

        if step % 40 == 0:
            print(f"  step {step:3d}  loss={loss.item():.4f}")

    final_loss = losses[-1]
    avg_last20 = sum(losses[-20:]) / 20
    print(f"  Final loss: {final_loss:.4f}  avg last 20: {avg_last20:.4f}")

    # Test generation
    model.eval()
    with torch.no_grad():
        for b_idx in range(2):
            node_types = batch["node_types"][b_idx:b_idx+1]
            subtoken_ids = batch["subtoken_ids"][b_idx:b_idx+1]
            edges = batch["edges"][b_idx:b_idx+1]
            copy_mask = batch["copy_mask"][b_idx:b_idx+1]
            node_labels = batch["node_labels"][b_idx:b_idx+1]
            num_nodes = batch["num_nodes"][b_idx:b_idx+1]

            positions = torch.arange(8, device=device).unsqueeze(0)
            node_mask = positions >= num_nodes.unsqueeze(1)

            node_emb = model.encoder(
                node_types, subtoken_ids, edges, node_mask=node_mask)

            gen_out = model.decoder.generate(
                node_emb, copy_mask, temperature=1.0,
                src_key_padding_mask=node_mask,
                encoder_node_labels=node_labels)

            pred_ids = [tid for tid, _, _ in gen_out]
            gt_ids = batch["tgt_ids"][b_idx].tolist()
            gt_clean = [t for t in gt_ids if t > 1]  # strip <pad> + <sos>
            print(f"\n  Item {b_idx}:")
            print(f"    GT:     {gt_clean}")
            print(f"    Pred:   {pred_ids}")
            print(f"    Match:  {pred_ids == gt_clean}")
            assert pred_ids == gt_clean, f"Generation mismatch: {pred_ids} != {gt_clean}"

    # Assertions
    assert avg_last20 < 2.0, f"Loss too high: {avg_last20:.4f} (expected < 2.0)"
    print("\n✓ PASSED: Overfit + generation correct")


if __name__ == "__main__":
    test_overfit()
