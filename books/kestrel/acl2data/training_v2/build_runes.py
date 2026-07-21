"""
Build symbol→book mapping from .mli training data.

Each .mli record maps an action-obj to its source file. We extract
these pairs to build the book_map that ACL2's eval-models expects.

Usage:
  python training_v2/build_runes.py \
      --mli-dir /workspaces/acl2-jupyter/data/books \
      --output runes-acl2data.json
"""

import sys, json, argparse, logging
from pathlib import Path
from collections import defaultdict
from concurrent.futures import ProcessPoolExecutor, as_completed

import ijson

logger = logging.getLogger(__name__)


def scan_mli(mli_path):
    """Extract (symbol, source_file) pairs from one .mli file."""
    pairs = []
    try:
        with open(mli_path, "rb") as f:
            for item in ijson.items(f, "item"):
                ao = item.get("output", {}).get("action-obj", "")
                src = item.get("metadata", {}).get("file", "")
                if not ao or not src:
                    continue
                # Normalize action-obj: if it's a list, join; if string, use as-is
                if isinstance(ao, list):
                    ao = " ".join(str(x) for x in ao)
                ao = str(ao).strip()
                if ao and src:
                    # Extract just the symbol part for use-lemma type objects
                    # e.g., "(INTEGERP var-0)" → we only want "INTEGERP" for book_map
                    symbol = ao.split()[0].strip("()") if ao.startswith("(") else ao.split()[0]
                    if symbol:
                        pairs.append((symbol.upper(), src))
    except Exception as e:
        logger.debug(f"  Skipping {mli_path}: {e}")
    return pairs


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--mli-dir", required=True, help="Directory with .mli files")
    p.add_argument("--output", default="runes-acl2data.json")
    p.add_argument("--workers", type=int, default=4)
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level))

    mli_dir = Path(args.mli_dir)
    mli_files = sorted(mli_dir.glob("**/*.mli"))
    logger.info(f"Found {len(mli_files)} .mli files")

    # Collect symbol → [file1, file2, ...] mappings
    symbol_files = defaultdict(set)

    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(scan_mli, f): f for f in mli_files}
        for i, future in enumerate(as_completed(futures)):
            pairs = future.result()
            for symbol, src in pairs:
                # Strip [books] prefix
                if src.startswith("[books]/"):
                    src = src[len("[books]/"):]
                symbol_files[symbol].add(src)
            if (i + 1) % 100 == 0:
                logger.info(f"  Processed {i+1}/{len(mli_files)} files, "
                            f"{len(symbol_files)} unique symbols")

    # Convert to collect_runes format: {SYMBOL: [{"file": path, ...}]}
    runes = {}
    for symbol, files in sorted(symbol_files.items()):
        runes[symbol] = [
            {"file": f, "local": False, "command": "unknown"}
            for f in sorted(files)[:5]  # limit to 5 books per symbol
        ]

    with open(args.output, "w") as f:
        json.dump(runes, f)

    logger.info(f"Wrote {len(runes)} symbols to {args.output}")


if __name__ == "__main__":
    main()
