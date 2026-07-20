"""Test evaluate.py — runs eval on a tiny dummy model."""

import json, tempfile, shutil
from pathlib import Path
import torch

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import FixedDataset
from training_v2.evaluate import evaluate, decode_action


def test_decode_action():
    """Test action type decoding from token IDs."""
    to_id = {"<pad>": 0, "<sos>": 1, "<eos>": 2, "use-lemma": 3, "FOO-IS-BAR": 4}
    attr = {"use-lemma": 0}
    id2tok = {v: k for k, v in to_id.items()}

    at, ao = decode_action([3, 4], attr, id2tok)
    assert at == "use-lemma", f"bad action type: {at}"
    assert ao == "FOO-IS-BAR", f"bad action obj: {ao}"
    print("1. decode_action: PASSED")


def test_evaluate():
    """Test evaluate() with autoregressive generation on dummy model."""
    tmp = tempfile.mkdtemp()
    train_dir = Path(tmp) / "train"
    train_dir.mkdir()

    N, E, V, S = 16, 10, 20, 8
    n = 2

    data = {
        "node_types": torch.randint(0, 3, (n, N)),
        "subtoken_ids": torch.randint(-1, 100, (n, N)),
        "edge_index": torch.tensor([[0, 0], [1, 1]]),
        "edge_types": torch.tensor([0, 1]),
        "edge_counts": torch.tensor([2] * n),
        "tgt_ids": torch.full((n, S), 0, dtype=torch.long),
        "action_types": torch.zeros(n, dtype=torch.long),
        "copy_mask": torch.ones(n, N, dtype=torch.bool),
    }
    # Set target: <sos>=1, use-lemma=3, FOO-IS-BAR=4, <eos>=2
    data["tgt_ids"][0, :4] = torch.tensor([1, 3, 4, 2])
    data["tgt_ids"][1, :4] = torch.tensor([1, 3, 4, 2])

    torch.save(data, train_dir / "test.pt")
    json.dump({"train": ["train/test.pt"], "val": [], "test": ["train/test.pt"]},
              open(Path(tmp) / "manifest.json", "w"))
    json.dump({
        "token_to_id": {"<pad>": 0, "<sos>": 1, "<eos>": 2, "use-lemma": 3,
                        "FOO-IS-BAR": 4},
        "attr_to_id": {"use-lemma": 0},
        "num_edge_types": E,
    }, open(Path(tmp) / "vocab.json", "w"))

    ds = FixedDataset(["train/test.pt"], tmp, num_edge_types=E)
    model = DenseGraph2Tocopo(
        hidden_dim=16, num_edge_types=E, vocab_size=V,
        num_timesteps=2, num_decoder_layers=1, num_heads=1,
    )
    model.eval()

    attr = {"use-lemma": 0}
    id2tok = {0: "<pad>", 1: "<sos>", 2: "<eos>", 3: "use-lemma", 4: "FOO-IS-BAR"}

    top1, at_acc, total = evaluate(
        model, ds, "cpu", attr, id2tok, max_items=2)

    print(f"2. evaluate: Top-1={top1:.4f} ActionType={at_acc:.4f} total={total}")
    assert total == 2, f"expected 2 items, got {total}"
    print("   PASSED")

    shutil.rmtree(tmp)


if __name__ == "__main__":
    test_decode_action()
    test_evaluate()
    print("\nAll evaluate tests passed!")
