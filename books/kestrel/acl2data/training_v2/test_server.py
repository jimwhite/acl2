"""
Test Advice Server — returns ground-truth tocopos from pre-built index.

Loads a pre-built index from JSON (built by build_test_index.py)
and serves it via HTTP.  Startup is instant since indexing is done offline.

Usage:
  # First, build the index (one-time):
  python -m training_v2.build_test_index \
      --mli-dir /workspaces/acl2-jupyter/data/books \
      --output test_index.json \
      --workers 8

  # Then run the server:
  python -m training_v2.test_server \
      --index test_index.json \
      --port 8765
"""

import sys
import os
import json
import argparse
import logging
import time
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

logger = logging.getLogger(__name__)


# ── S-expression helpers ─────────────────────────────────────────────────────

def _parse_clause(clause_str):
    """Parse ACL2 clause string into nested list."""
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


def _extract_theorem_name(broken_theorem):
    """Extract theorem name from a broken-theorem S-expression.

    '(DEFTHM FOO (NATP X) ...)' → 'FOO'
    """
    try:
        parsed = _parse_clause(broken_theorem)
    except Exception:
        return None
    if isinstance(parsed, list) and len(parsed) > 0:
        expr = parsed[0]
        if isinstance(expr, list) and len(expr) >= 2:
            name = expr[1]
            if isinstance(name, str):
                return name.upper()
    return None


def _can_parse_as_single(obj_str):
    if not obj_str or not obj_str.strip():
        return False
    for bad in ('"', "'", "#", "|"):
        if bad in obj_str:
            return False
    if not obj_str.startswith('(') and ' ' in obj_str:
        return False
    depth = 0
    for c in obj_str:
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


# ── Model ────────────────────────────────────────────────────────────────────

class TestAdviceModel:
    """Returns ground-truth tocopos from a pre-built index."""

    def __init__(self, index_path):
        logger.info(f"Loading index from {index_path}...")
        t0 = time.time()
        with open(index_path, "r") as f:
            self.index = json.load(f)
        elapsed = time.time() - t0
        size_mb = Path(index_path).stat().st_size / (1024 * 1024)
        total_entries = sum(len(v) for v in self.index.values())
        logger.info(
            f"  Loaded {size_mb:.0f}MB index: {total_entries} entries, "
            f"{len(self.index)} theorems ({elapsed:.0f}s)"
        )

    def predict(self, clauses, broken_theorem, n=10):
        """Look up ground-truth tocopos by theorem name."""
        theorem_name = _extract_theorem_name(broken_theorem)

        if theorem_name and theorem_name in self.index:
            entries = self.index[theorem_name]
            logger.info(f"  MATCH: {theorem_name} → {len(entries)} tocopos")
            recs = []
            seen = set()
            for action_type, action_obj in entries:
                if not action_type or not action_obj:
                    continue
                key = (action_type, action_obj)
                if key in seen:
                    continue
                seen.add(key)
                obj = action_obj if action_obj and action_obj != "NIL" else "NIL"
                if not _can_parse_as_single(obj):
                    obj = "NIL"
                recs.append({
                    "type": action_type,
                    "object": obj,
                    "confidence": 1.0,
                    "book_map": {},
                })
            while len(recs) < n:
                recs.append({
                    "type": "use-lemma", "object": "NIL",
                    "confidence": 0.0, "book_map": {},
                })
            return recs[:n]

        logger.warning(f"  NO MATCH: theorem_name={theorem_name}")
        return [
            {"type": "use-lemma", "object": "NIL",
             "confidence": 0.0, "book_map": {}}
        ] * n


# ── HTTP Handler ─────────────────────────────────────────────────────────────

class AdviceHandler(BaseHTTPRequestHandler):
    model: TestAdviceModel = None

    def do_POST(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            params = parse_qs(body)

            n = int(params.get("n", [10])[0])
            broken_theorem = params.get("broken-theorem", [""])[0]

            clauses = []
            for key in sorted(params.keys()):
                if key.startswith("checkpoint_"):
                    clauses.append(params[key][0])

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
            error_body = json.dumps({"error": str(e)}).encode("utf-8")
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(error_body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(error_body)

    def log_message(self, format, *args):
        logger.info(f"HTTP: {args[0]}")


def main():
    p = argparse.ArgumentParser(
        description="Test advice server — returns ground-truth tocopos from pre-built index"
    )
    p.add_argument("--index", default="test_index.json",
                   help="Path to pre-built index JSON (built by build_test_index.py)")
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )

    logger.info(f"=== Test Advice Server ===")

    if not Path(args.index).exists():
        logger.error(
            f"Index file not found: {args.index}\n"
            f"  Build it first with: python -m training_v2.build_test_index "
            f"--output {args.index}"
        )
        sys.exit(1)

    AdviceHandler.model = TestAdviceModel(args.index)

    server = HTTPServer(("0.0.0.0", args.port), AdviceHandler)
    logger.info(f"Server listening on port {args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down")
        server.shutdown()


if __name__ == "__main__":
    main()
