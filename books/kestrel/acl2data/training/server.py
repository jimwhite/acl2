"""
Advice Server - HTTP API for ACL2 Graph2Tocopo Proof Recommendations

Provides a REST API that the ACL2 advice tool queries to get fix
recommendations for broken proofs.

API (POST /):
  Request: x-www-form-urlencoded
    - "use-group": model name (for multi-model routing)
    - "n": number of recommendations to return
    - "broken-theorem": serialized broken theorem string
    - "0", "1", ...: serialized checkpoint clauses (S-expressions)

  Response: JSON array of recommendation objects:
    [{"type": "use-lemma", "object": "LEMMA-NAME",
      "confidence": 0.53, "book_map": {}}]

Usage:
  python -m training.server --model ./models_v5/best_model.pt --port 8765
"""

import sys
import os
import json
import argparse
import logging
import pickle
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

import torch
import numpy as np

# Ensure training package is importable
SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

from training.data_utils import (
    GraphBuilder, FixVocab, build_target_sequence,
    ACTION_TYPES, ACTION_PREFIXES,
)
from training.graph2tocopo_model import Graph2Tocopo

logger = logging.getLogger(__name__)


class AdviceModel:
    """Wraps the Graph2Tocopo model for serving."""

    def __init__(self, model_path: str, device: str = "cpu"):
        self.device = torch.device(device)
        self.model_path = Path(model_path)

        # Load checkpoint
        logger.info(f"Loading model from {model_path}...")
        checkpoint = torch.load(model_path, map_location=self.device,
                                weights_only=False)

        # Reconstruct vocab
        self.vocab = FixVocab()
        if "vocab" in checkpoint:
            self.vocab.token_to_id = checkpoint["vocab"]
            self.vocab.id_to_token = {
                v: k for k, v in self.vocab.token_to_id.items()}
            self.vocab.next_id = len(self.vocab.token_to_id)

        # Reconstruct model
        args = checkpoint.get("args", {})
        self.model = Graph2Tocopo(
            hidden_dim=args.get("hidden_dim", 256),
            vocab_size=len(self.vocab),
            num_edge_types=args.get("num_edge_types", 10),
            encoder_type=args.get("encoder_type", "ggnn"),
        ).to(self.device)
        self.model.load_state_dict(checkpoint["model_state"])
        self.model.eval()

        self.graph_builder = GraphBuilder(max_nodes=512)
        logger.info("  Model loaded.")

        # Default book map (maps lemma names to their book paths)
        self.default_book_map = {}

        logger.info(f"AdviceModel ready (vocab={len(self.vocab)}, "
                      f"device={self.device})")

    def predict(self, clauses: list, broken_theorem: str, n: int = 10):
        """Generate proof fix recommendations for a broken theorem.

        Args:
            clauses: list of checkpoint S-expression strings
            broken_theorem: the broken theorem text
            n: number of recommendations to return

        Returns:
            list of dicts: [{"type": "...", "object": "...",
                             "confidence": ..., "book_map": {}}]
        """
        # Build the input graph from checkpoint clauses
        # Parse each clause as an S-expression
        parsed_clauses = []
        for clause in clauses:
            try:
                parsed = self._parse_clause(clause)
                parsed_clauses.append(parsed)
            except Exception as e:
                logger.warning(f"  Failed to parse clause: {e}")

        if not parsed_clauses:
            return []

        # Build graph
        item = {
            "input": {"checkpoint-sequence": parsed_clauses,
                      "checkpoint-type": "Goal"},
            "metadata": {"goal-str": broken_theorem},
            "output": {"action-type": "", "action-obj": ""},
        }

        graph = self.graph_builder.build_graph(item)

        # Convert to tensors
        node_types = torch.tensor(
            [_node_type_to_int(nt) for nt in graph["node_types"]],
            dtype=torch.long, device=self.device)
        subtoken_ids = torch.tensor(
            graph["subtoken_ids"], dtype=torch.long, device=self.device)
        edge_index = torch.tensor(
            graph["edge_index"], dtype=torch.long, device=self.device)
        edge_types = torch.tensor(
            graph["edge_types"], dtype=torch.long, device=self.device)
        copy_mask = torch.tensor(
            [1 if nt == "token" else 0 for nt in graph["node_types"]],
            dtype=torch.bool, device=self.device)

        num_nodes = graph["num_nodes"]

        batch = {
            "node_types": node_types,
            "subtoken_ids": subtoken_ids,
            "edge_index": edge_index,
            "edge_types": edge_types,
            "num_nodes": [num_nodes],
            "copy_mask": copy_mask.unsqueeze(0),
        }

        # Generate: try each action type prefix
        recommendations = []
        top_n_per_type = max(1, n // len(ACTION_TYPES) + 1)

        with torch.no_grad():
            for action_type in ACTION_TYPES:
                prefix = ACTION_PREFIXES.get(action_type, action_type)
                prefix_tokens = [self.vocab.sos_idx] + self.vocab.encode(
                    build_target_sequence({
                        "output": {"action-type": prefix, "action-obj": ""}
                    })[:5])

                tgt = torch.tensor(
                    [prefix_tokens], dtype=torch.long, device=self.device)

                batch["tgt_tokens"] = tgt
                try:
                    output = self.model.generate(batch, temperature=1.0)
                    # Decode output
                    rec = self._decode_recommendation(
                        output, action_type, graph)
                    if rec and rec["object"]:
                        recommendations.append(rec)
                except Exception as e:
                    logger.warning(
                        f"  Generation failed for {action_type}: {e}")
                    continue

        # Sort by confidence
        recommendations.sort(key=lambda r: -r["confidence"])

        # Limit to n
        recommendations = recommendations[:n]

        # Normalize confidence to 0-1 range
        if recommendations:
            max_conf = max(r["confidence"] for r in recommendations)
            if max_conf > 0:
                for r in recommendations:
                    r["confidence"] = r["confidence"] / max_conf

        return recommendations

    def _decode_recommendation(self, output_tokens, action_type, graph):
        """Decode generated tokens into a recommendation object."""
        tokens = []
        copies = []
        for tok_id, is_copy, copy_idx in output_tokens:
            if tok_id == self.vocab.eos_idx:
                break
            if is_copy and 0 <= copy_idx < len(graph["node_labels"]):
                label = graph["node_labels"][copy_idx]
                tokens.append(label)
                copies.append(label)
            elif tok_id >= 0:
                token = self.vocab.id_to_token.get(tok_id, "")
                if token not in ("<sos>", "<pad>"):
                    tokens.append(token)

        if not tokens:
            return None

        # Join tokens to form recommendation object
        obj_str = " ".join(tokens)

        # Compute confidence (heuristic based on copy count relevance)
        confidence = min(1.0, len(copies) / max(1, len(tokens)) * 0.8 + 0.2)

        return {
            "type": action_type,
            "object": obj_str,
            "confidence": confidence,
            "book_map": self.default_book_map,
        }

    @staticmethod
    def _parse_clause(clause_str: str):
        """Parse an ACL2 checkpoint clause string into nested list."""
        clause_str = clause_str.strip()
        if not clause_str.startswith("("):
            return clause_str

        i = 0
        result = []

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
                        i += 1  # skip ')'
                    return sub
                elif c == ")":
                    return result if result else []
                elif c in " \n\t":
                    i += 1
                elif c == '"':
                    # Read string
                    start = i
                    i += 1
                    while i < len(clause_str) and clause_str[i] != '"':
                        i += 1
                    i += 1
                    return clause_str[start:i]
                else:
                    # Read symbol
                    start = i
                    while i < len(clause_str) and clause_str[i] not in "() \n\t":
                        i += 1
                    return clause_str[start:i]

        # Parse multiple top-level expressions
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


def _node_type_to_int(nt: str) -> int:
    return {"token": 0, "subtoken": 1, "root": 2}.get(nt, 0)


# ── HTTP Handler ─────────────────────────────────────────────────────────────

class AdviceHandler(BaseHTTPRequestHandler):
    """HTTP handler for ACL2 advice requests."""

    model: AdviceModel = None

    def do_POST(self):
        """Handle POST / request from ACL2 eval-models framework."""
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")

            # Parse form data
            params = parse_qs(body)

            # Extract fields
            n = int(params.get("n", [10])[0])
            broken_theorem = params.get("broken-theorem", [""])[0]

            # Extract checkpoint clauses (keys "0", "1", "2", ...)
            clauses = []
            for key in sorted(params.keys()):
                if key.isdigit() and int(key) >= 0:
                    clauses.append(params[key][0])

            logger.info(
                f"Request: n={n}, clauses={len(clauses)}, "
                f"theorem_len={len(broken_theorem)}")

            # Generate recommendations
            recommendations = self.model.predict(
                clauses, broken_theorem, n=n)

            # Format response
            response = json.dumps(recommendations)
            response_bytes = response.encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(response_bytes)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(response_bytes)

        except Exception as e:
            logger.error(f"Error handling request: {e}", exc_info=True)
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(
                {"error": str(e)}).encode("utf-8"))

    def log_message(self, format, *args):
        """Suppress default logging."""
        logger.debug(f"HTTP: {format % args}")


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description="Start Graph2Tocopo advice server")
    p.add_argument("--model", required=True,
                   help="Path to trained model checkpoint")
    p.add_argument("--port", type=int, default=8765,
                   help="Server port")
    p.add_argument("--host", default="0.0.0.0",
                   help="Server host")
    p.add_argument("--device", default="cpu",
                   help="Device to run inference on")
    p.add_argument("--log-level", default="INFO",
                   choices=["DEBUG", "INFO", "WARNING"])
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    # Initialize model
    AdviceHandler.model = AdviceModel(
        args.model, device=args.device)

    # Start server
    server = HTTPServer((args.host, args.port), AdviceHandler)
    logger.info(
        f"Advice server listening on {args.host}:{args.port}")
    logger.info(
        "POST / with form data: use-group, n, broken-theorem, 0, 1, ...")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
