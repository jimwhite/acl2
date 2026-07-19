"""
Unit tests for Graph2Tocopo model pipeline.

Runs quick, CPU-friendly tests on tiny inputs.  Designed for the
devcontainer — does not need GPU.  All tests should complete in
under 10 seconds.

Usage:
  cd /workspaces/acl2-jupyter/context/acl2/books/kestrel/acl2data
  source /workspaces/acl2-jupyter/.venv/bin/activate
  python training/test_model.py
"""

import sys, logging
from pathlib import Path
import torch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training.data_utils import GraphBuilder, FixVocab, build_target_sequence
from training.ggnn_encoder import GGNNEncoder
from training.tocopo_decoder import TocopoDecoder
from training.graph2tocopo_model import Graph2Tocopo

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── tiny test item ───────────────────────────────────────────────────────────

ITEM = {
    "input": {
        "checkpoint-sequence": [
            ["NOT", ["INTEGERP", "X"]],
            ["EQUAL", ["FOO", "X"], ["BAR", "X"]],
        ],
        "checkpoint-type": "Goal",
    },
    "metadata": {"goal-str": "(defthm foo-thm (equal (foo x) (bar x)))"},
    "output": {"action-type": "use-lemma", "action-obj": "FOO-IS-BAR"},
}


def _nt_int(nt: str) -> int:
    return {"token": 0, "subtoken": 1, "root": 2}[nt]


# ═══════════════════════════════════════════════════════════════════════════════
# 1. Graph construction
# ═══════════════════════════════════════════════════════════════════════════════

def test_graph_construction():
    log.info("=== 1. Graph Construction ===")
    gb = GraphBuilder(max_nodes=128)
    g = gb.build_graph(ITEM)

    log.info("  nodes=%d  edges=%d  edge_types=%s",
             g["num_nodes"], len(g["edge_types"]), set(g["edge_types"]))
    log.info("  token=%d  subtoken=%d  root=%d",
             sum(1 for nt in g["node_types"] if nt == "token"),
             sum(1 for nt in g["node_types"] if nt == "subtoken"),
             sum(1 for nt in g["node_types"] if nt == "root"))
    log.info("  copy_candidates=%d", len(g["copy_candidates"]))

    assert g["num_nodes"] > 5, "too few nodes"
    assert any(nt == "subtoken" for nt in g["node_types"]), "no subtokens"
    log.info("  PASSED\n")
    return g


# ═══════════════════════════════════════════════════════════════════════════════
# 2. GGNN Encoder
# ═══════════════════════════════════════════════════════════════════════════════

def test_ggnn_encoder(graph):
    log.info("=== 2. GGNN Encoder ===")
    model = GGNNEncoder(
        hidden_dim=64, num_edge_types=10, num_timesteps=4,
        num_node_types=3, subtoken_vocab_size=1000,
    )

    nt = torch.tensor([_nt_int(x) for x in graph["node_types"]])
    st = torch.tensor(graph["subtoken_ids"], dtype=torch.long)
    ei = torch.tensor(graph["edge_index"], dtype=torch.long)
    et = torch.tensor(graph["edge_types"], dtype=torch.long)
    nn_list = [graph["num_nodes"]]

    with torch.no_grad():
        out = model(nt, st, ei, et, nn_list)

    assert out.shape == (graph["num_nodes"], 64), f"bad shape {out.shape}"
    log.info("  shape=%s  PASSED\n", out.shape)


# ═══════════════════════════════════════════════════════════════════════════════
# 3. Tocopo Decoder (forward pass only — no generation)
# ═══════════════════════════════════════════════════════════════════════════════

def test_tocopo_decoder():
    log.info("=== 3. Tocopo Decoder ===")
    dec = TocopoDecoder(
        hidden_dim=64, vocab_size=100, num_heads=4, num_layers=2)

    # encoder output: flat (total_nodes, dim) = (5, 64) — what GGNN produces
    enc = torch.randn(5, 64)
    # tgt_tokens: batch=1, seq_len=5
    tgt = torch.tensor([[1, 4, 5, 6, 2]])
    # copy_mask: batch=1, max_nodes=5
    cm = torch.ones(1, 5, dtype=torch.bool)

    with torch.no_grad():
        out = dec(enc, tgt, cm)

    assert out["token_logits"].shape == (1, 5, 100), (
        f"bad token_logits {out['token_logits'].shape}")
    assert out["pointer_logits"].shape == (1, 5, 5), (
        f"bad pointer_logits {out['pointer_logits'].shape}")
    log.info("  token_logits=%s  pointer_logits=%s  PASSED\n",
             out["token_logits"].shape, out["pointer_logits"].shape)


# ═══════════════════════════════════════════════════════════════════════════════
# 4. Full Graph2Tocopo forward pass (tiny model, CPU-friendly)
# ═══════════════════════════════════════════════════════════════════════════════

def test_full_model(graph):
    log.info("=== 4. Full Graph2Tocopo Forward Pass ===")

    vocab = FixVocab()
    tgt = build_target_sequence(ITEM)
    for tok in tgt:
        vocab.add_token(tok)

    num_etyp = max(set(graph["edge_types"])) + 1 if graph["edge_types"] else 10

    # Tiny model: 1 decoder layer, 2 heads, 2 GGNN timesteps
    model = Graph2Tocopo(
        hidden_dim=32,
        vocab_size=len(vocab),
        num_edge_types=max(10, num_etyp),
        num_timesteps=2,
        num_decoder_layers=1,
        num_heads=2,
        encoder_type="ggnn",
    )
    model.eval()

    nt = torch.tensor([_nt_int(x) for x in graph["node_types"]])
    st = torch.tensor(graph["subtoken_ids"], dtype=torch.long)
    ei = torch.tensor(graph["edge_index"], dtype=torch.long)
    et = torch.tensor(graph["edge_types"], dtype=torch.long)

    tgt_ids = vocab.encode(tgt)
    tgt_t = torch.tensor([tgt_ids], dtype=torch.long)

    cm = torch.zeros(1, graph["num_nodes"], dtype=torch.bool)
    for idx in graph["copy_candidates"]:
        if idx < graph["num_nodes"]:
            cm[0, idx] = True

    batch = {
        "node_types": nt, "subtoken_ids": st,
        "edge_index": ei, "edge_types": et,
        "num_nodes": [graph["num_nodes"]],
        "tgt_tokens": tgt_t[:, :-1],
        "copy_mask": cm,
    }

    with torch.no_grad():
        out = model(batch)

    log.info("  token_logits=%s  copy_logits=%s  pointer_logits=%s",
             out["token_logits"].shape, out["copy_logits"].shape,
             out["pointer_logits"].shape)
    assert out["token_logits"].shape[0] == 1, "bad batch dim"
    log.info("  PASSED\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 5. Vocabulary + target sequence
# ═══════════════════════════════════════════════════════════════════════════════

def test_vocab_and_target():
    log.info("=== 5. Vocabulary & Target Sequence ===")
    vocab = FixVocab()

    tokens = ["<sos>", ":hint", "-setting", "-alist",
              " (", ":enable", " ", "factorial", ")", "<eos>"]
    for t in tokens:
        vocab.add_token(t)
    ids = vocab.encode(tokens)
    dec = vocab.decode(ids)

    assert dec == tokens, f"round-trip failed: {dec}"
    log.info("  vocab size=%d  roundtrip OK", len(vocab))

    seq = build_target_sequence(ITEM)
    assert seq[0] == "<sos>" and seq[-1] == "<eos>", f"bad seq: {seq}"
    log.info("  target seq=%s", seq)
    log.info("  PASSED\n")


# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    g = test_graph_construction()
    test_ggnn_encoder(g)
    test_tocopo_decoder()
    test_full_model(g)
    test_vocab_and_target()
    log.info("═════════════════════════════════════")
    log.info("All tests passed!")
