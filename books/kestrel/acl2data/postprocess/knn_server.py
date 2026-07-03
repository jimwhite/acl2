#!/usr/bin/env python3
"""
k-NN Model Server for ACL2 eval-models integration.

HTTP server that loads the k-NN FAISS index, accepts checkpoint clauses
from ACL2's eval-models framework, and returns ranked recommendations.

API (POST /):
  Request: x-www-form-urlencoded with keys:
    - "use-group": model name string (ignored, we only serve one model)
    - "n": number of recommendations to return
    - "broken-theorem": serialized broken theorem (used for goal-str)
    - "0", "1", ...: serialized checkpoint clauses (S-expression strings)

  Response: JSON array of recommendation strings, each formatted as:
    "(NAME TYPE OBJECT CONFIDENCE BOOK-MAP)"

    Example:
    ["(CDR-CONS :USE-LEMMA CDR-CONS 95 ((\"list\" . :SYSTEM)))", ...]

Usage:
  python knn_server.py --index ./models_v4 --port 8765

  # Or with custom settings:
  python knn_server.py --index ./models_v4 --port 8765 --n-neighbors 50
"""

import sys, os, json, argparse, logging
from pathlib import Path
from collections import Counter

# Must add the postprocess directory to import train_model_v4
SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from train_model_v4 import CheckpointEmbedder, KNNIndex, features_from_item, flatten_seq


class KNNModelServer:
    """Wraps the k-NN index with an HTTP-ready predict method."""

    def __init__(self, model_dir, n_neighbors=50):
        model_dir = Path(model_dir)
        logging.info(f"Loading embedder from {model_dir}/embedder.pkl ...")
        self.embedder = CheckpointEmbedder.load(model_dir / "embedder.pkl")
        logging.info(f"Loading index from {model_dir}/knn_index ...")
        self.index = KNNIndex.load(model_dir / "knn_index")
        self.n_neighbors = n_neighbors
        logging.info("  loaded.")

    def checkpoint_clauses_to_features(self, clauses, broken_theorem):
        """Convert ACL2 checkpoint clauses to the feature format used by train_model_v4.

        clauses: list of clause strings like ["(NOT (NATP X))", "(EQUAL ...)"]
        broken_theorem: the broken theorem string

        Returns a text feature string suitable for the embedder.
        """
        # Build a synthetic item matching the .mli format
        checkpoint_sequence = []
        for clause in clauses:
            # Tokenize the clause string into a sequence
            tokens = []
            clause = clause.strip()
            # Simple tokenization: split on parens and spaces
            i = 0
            while i < len(clause):
                if clause[i] in '()':
                    tokens.append(clause[i])
                    i += 1
                elif clause[i] in ' \n\t':
                    i += 1
                else:
                    # read a token
                    start = i
                    while i < len(clause) and clause[i] not in '() \n\t':
                        i += 1
                    token = clause[start:i].upper()
                    tokens.append(token)
            checkpoint_sequence.append(tokens)

        # Flatten: ACL2 checkpoints are lists of clauses, each clause is a list of terms
        # The .mli format stores the entire checkpoint as nested lists
        # Here clauses is already a list, each clause is a string
        # We wrap it to match: checkpoint-sequence = flattened nested list
        flat_seq = []
        for tokens in checkpoint_sequence:
            flat_seq.append('(')
            flat_seq.extend(tokens)
            flat_seq.append(')')

        item = {
            "input": {
                "checkpoint-sequence": flat_seq,
                "checkpoint-type": "top",
            },
            "metadata": {
                "goal-str": broken_theorem or "",
            },
        }
        return features_from_item(item)

    def predict(self, clauses, broken_theorem, n=20):
        """Return ranked recommendations for the given checkpoint clauses.

        Returns list of dicts with action_type, action_obj, score.
        """
        features = self.checkpoint_clauses_to_features(clauses, broken_theorem)
        vec = self.embedder.transform([features])
        preds = self.index.predict(vec, k=self.n_neighbors)
        # preds[0] is a list of {"action_type", "action_obj", "score"}
        return preds[0][:n]

    def format_recommendation(self, action_type, action_obj, score, rank):
        """Format a prediction as a dict for the advice framework.

        The framework's parse-recommendation expects JSON objects with keys:
          type, object, confidence (0–1), book_map
        See *rec-to-symbol-alist* in kestrel/helpers/recommendations.lisp
        for valid type strings.
        """
        # FAISS scores are distances; normalize to 0–1 based on rank
        confidence = max(0.0, min(1.0, 1.0 / (1.0 + float(score))))
        return {
            "type": action_type,
            "object": str(action_obj),
            "confidence": confidence,
            "book_map": {},
        }


# ─── HTTP Server ────────────────────────────────────────────────────────────

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs


class KNNRequestHandler(BaseHTTPRequestHandler):
    model = None  # set by main()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8', errors='replace')
        params = parse_qs(body)

        # Extract parameters
        n = int(params.get('n', ['20'])[0])
        broken_theorem = params.get('broken-theorem', [''])[0]

        # Collect checkpoint clauses
        clauses = []
        i = 0
        while str(i) in params:
            clauses.append(params[str(i)][0])
            i += 1

        if not self.model:
            self.send_error(500, "Model not loaded")
            return

        try:
            preds = self.model.predict(clauses, broken_theorem, n=n)
            recs = []
            for rank, p in enumerate(preds):
                rec = self.model.format_recommendation(
                    p["action_type"], p["action_obj"], p.get("score", 0.0), rank + 1
                )
                recs.append(rec)

            response = json.dumps(recs)
            body = response.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Connection', 'close')
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            logging.error(f"Error processing request: {e}", exc_info=True)
            self.send_error(500, str(e))

    def log_message(self, format, *args):
        logging.info(f"  {args[0]}")


def main():
    parser = argparse.ArgumentParser(description="k-NN Model Server for ACL2")
    parser.add_argument("--index", default="./models_v4", help="Path to model directory")
    parser.add_argument("--port", type=int, default=8765, help="HTTP port (default: 8765)")
    parser.add_argument("--n-neighbors", type=int, default=50, help="FAISS neighbors")
    parser.add_argument("--log-level", default="INFO",
                        choices=["DEBUG", "INFO", "WARNING"])
    args = parser.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level),
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        datefmt="%H:%M:%S")

    model = KNNModelServer(args.index, n_neighbors=args.n_neighbors)
    KNNRequestHandler.model = model

    server = HTTPServer(('', args.port), KNNRequestHandler)
    logging.info(f"k-NN model server listening on port {args.port}")
    logging.info(f"Register in ACL2 with: (table acl2::advice-server :knn '(\"http://localhost:{args.port}\" \"knn\"))")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
