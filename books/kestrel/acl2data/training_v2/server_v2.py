"""
Advice Server v2 — HTTP API for DenseGraph2Tocopo Proof Recommendations

Wraps the training_v2 DenseGraph2Tocopo model (PLUR-compatible GGNN + Tocopo).
Same HTTP API as training/server.py so ACL2's advice tool can query it.

Usage:
  python -m training_v2.server_v2 \
      --model ./models_v7/best_model.pt \
      --vocab /path/to/preprocessed_v4/vocab.json \
      --port 8765
"""

import sys
import os
import json
import argparse
import logging
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

import torch

SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

from training_v2.dense_model import DenseGraph2Tocopo
from training.data_utils import GraphBuilder

logger = logging.getLogger(__name__)


class AdviceModelV2:
    """Wraps DenseGraph2Tocopo for serving."""

    def __init__(self, model_path, vocab_path, device="cpu"):
        self.device = torch.device(device)
        self.model_path = Path(model_path)

        # Load vocab
        with open(vocab_path) as f:
            vocab_data = json.load(f)
        self.token_to_id = vocab_data["token_to_id"]
        self.attr_to_id = vocab_data["attr_to_id"]
        self.id_to_token = {int(v): k for k, v in self.token_to_id.items()}
        self.id_to_attr = {int(v): k for k, v in self.attr_to_id.items()}
        self.vocab_size = len(self.token_to_id)
        self.num_edge_types = vocab_data["num_edge_types"]

        # Load model
        logger.info(f"Loading model from {model_path}...")
        ckpt = torch.load(model_path, map_location=self.device,
                          weights_only=False)

        self.model = DenseGraph2Tocopo(
            hidden_dim=128,
            num_edge_types=self.num_edge_types,
            vocab_size=self.vocab_size,
        ).to(self.device)
        self.model.load_state_dict(ckpt["model_state"])
        self.model.eval()

        self.max_nodes = 512
        self.graph_builder = GraphBuilder(max_nodes=self.max_nodes)

        logger.info(f"  Model loaded (step {ckpt.get('step', '?')}), "
                      f"vocab={self.vocab_size}")

    def predict(self, clauses, broken_theorem, n=10):
        """Generate proof fix recommendations."""
        if not clauses:
            return []

        # Parse clauses as S-expressions
        parsed = []
        for clause in clauses:
            try:
                parsed.append(self._parse_clause(clause))
            except Exception as e:
                logger.warning(f"  Parse failed: {e}")

        if not parsed:
            return []

        # Build graph
        item = {
            "input": {"checkpoint-sequence": parsed},
            "metadata": {"goal-str": broken_theorem},
        }
        graph = self.graph_builder.build_graph(item)
        nn = graph["num_nodes"]

        # Build tensors (B=1)
        node_types = torch.zeros(1, self.max_nodes, dtype=torch.long)
        subtoken_ids = torch.full((1, self.max_nodes), -1, dtype=torch.long)

        nt_map = {"token": 0, "subtoken": 1, "root": 2}
        for i, nt in enumerate(graph["node_types"][:nn]):
            node_types[0, i] = nt_map.get(nt, 0)
        for i, sid in enumerate(graph["subtoken_ids"][:nn]):
            subtoken_ids[0, i] = sid

        # Node labels (for copy mechanism)
        node_labels = torch.zeros(1, self.max_nodes, dtype=torch.long)
        for i, label in enumerate(graph["node_labels"][:nn]):
            node_labels[0, i] = self.token_to_id.get(label, 3)  # 3 = <unk>

        # Copy mask (subtoken nodes)
        copy_mask = torch.zeros(1, self.max_nodes, dtype=torch.bool)
        for i, nt in enumerate(graph["node_types"][:nn]):
            if nt == "subtoken":
                copy_mask[0, i] = True

        # Build dense edges
        E = max(graph["num_edge_types"], self.num_edge_types)
        edges = torch.zeros(1, E, self.max_nodes, self.max_nodes,
                            dtype=torch.float32)
        ei = graph["edge_index"]
        et = graph["edge_types"]
        for j in range(len(et)):
            if ei[0][j] < self.max_nodes and ei[1][j] < self.max_nodes:
                edges[0, et[j], ei[0][j], ei[1][j]] = 1.0

        node_mask = torch.zeros(1, self.max_nodes, dtype=torch.bool)
        node_mask[0, nn:] = True  # padding nodes

        # Move to device
        node_types = node_types.to(self.device)
        subtoken_ids = subtoken_ids.to(self.device)
        edges = edges.to(self.device)
        copy_mask = copy_mask.to(self.device)
        node_mask = node_mask.to(self.device)
        node_labels = node_labels.to(self.device)

        # Generate
        with torch.no_grad():
            emb = self.model.encoder(
                node_types, subtoken_ids, edges, node_mask=node_mask)
            gen_out = self.model.decoder.generate(
                emb, copy_mask,
                src_key_padding_mask=node_mask,
                encoder_node_labels=node_labels,
                temperature=1.0)

        # Decode
        tokens = []
        for tid, _, _ in gen_out:
            if tid <= 0:
                continue
            tok = self.id_to_token.get(tid, "<unk>")
            if tok in ("<sos>", "<eos>", "<pad>"):
                if tok == "<eos>":
                    break
                continue
            tokens.append(tok)

        if not tokens:
            return []

        # Parse action type + object from tokens
        action_type = tokens[0] if tokens else ""
        action_obj = " ".join(tokens[1:]) if len(tokens) > 1 else ""

        return [{
            "type": action_type,
            "object": action_obj,
            "confidence": 0.5,
            "book_map": {},
        }]

    @staticmethod
    def _parse_clause(clause_str):
        """Parse ACL2 checkpoint clause string into nested list."""
        clause_str = clause_str.strip()
        if not clause_str.startswith("("):
            return clause_str
        i = 0
        def read_sexpr():
            nonlocal i
            while i < len(clause_str):
                c = clause_str[i]
                if c == "(":
                    i += 1
                    sub = []
                    while i < len(clause_str) and clause_str[i] != ")":
                        sub.append(read_sexpr())
                    if i < len(clause_str):
                        i += 1
                    return sub
                elif c == ")":
                    return []
                elif c in " \n\t":
                    i += 1
                elif c == '"':
                    start = i
                    i += 1
                    while i < len(clause_str) and clause_str[i] != '"':
                        i += 1
                    i += 1
                    return clause_str[start:i]
                else:
                    start = i
                    while i < len(clause_str) and clause_str[i] not in "() \n\t":
                        i += 1
                    return clause_str[start:i]
        result = []
        while i < len(clause_str):
            c = clause_str[i]
            if c in " \n\t":
                i += 1
            elif c == "(":
                result.append(read_sexpr())
            elif c == ")":
                break
            else:
                result.append(read_sexpr())
        return result


# ── HTTP Handler ─────────────────────────────────────────────────────────────

class AdviceHandler(BaseHTTPRequestHandler):
    model: AdviceModelV2 = None

    def do_POST(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            params = parse_qs(body)

            n = int(params.get("n", [10])[0])
            broken_theorem = params.get("broken-theorem", [""])[0]

            clauses = []
            for key in sorted(params.keys()):
                if key.isdigit():
                    clauses.append(params[key][0])

            logger.info(f"Request: n={n}, clauses={len(clauses)}")
            recs = self.model.predict(clauses, broken_theorem, n=n)

            response = json.dumps(recs)
            response_bytes = response.encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(response_bytes)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(response_bytes)

        except Exception as e:
            logger.error(f"Error: {e}", exc_info=True)
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps(
                {"error": str(e)}).encode("utf-8"))

    def log_message(self, format, *args):
        logger.info(f"HTTP: {args[0]}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--model", required=True, help="Model checkpoint (.pt)")
    p.add_argument("--vocab", required=True, help="vocab.json path")
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--device", default="cpu")
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    AdviceHandler.model = AdviceModelV2(
        args.model, args.vocab, device=args.device)

    server = HTTPServer(("0.0.0.0", args.port), AdviceHandler)
    logger.info(f"Server listening on port {args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down")
        server.shutdown()


if __name__ == "__main__":
    main()
