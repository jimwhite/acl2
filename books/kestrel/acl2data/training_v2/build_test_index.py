#!/usr/bin/env python3
"""
Build the test-server index from .mli files — parallel, streaming.

Uses multiprocessing with imap_unordered so results stream back one file
at a time (no pipe overflow).  Saves to a JSON file for fast server startup.

Usage:
  python -m training_v2.build_test_index \
      --mli-dir /workspaces/acl2-jupyter/data/books \
      --output test_index.json \
      --workers 8
"""

import sys
import os
import json
import argparse
import logging
import time
from pathlib import Path
from multiprocessing import Pool, cpu_count

import ijson

SCRIPT_DIR = Path(__file__).resolve().parent
PARENT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(PARENT_DIR))

logger = logging.getLogger(__name__)


# ── Worker (module-level for pickling) ───────────────────────────────────────

def _index_one_file(mli_path_str):
    """Process one .mli file → list of (theorem_name, action_type, action_obj)."""
    mli_path = Path(mli_path_str)
    results = []
    try:
        with open(mli_path, "rb") as f:
            for item in ijson.items(f, "item"):
                at = item.get("output", {}).get("action-type", "")
                ao = item.get("output", {}).get("action-obj", "")
                rune = item.get("metadata", {}).get("rune", "")
                if not at or not ao or not rune:
                    continue
                if isinstance(ao, list):
                    ao = " ".join(str(x) for x in ao)
                ao = str(ao)
                results.append((rune.upper(), at, ao))
    except Exception as e:
        return (str(mli_path), None, str(e))
    return (str(mli_path), results, None)


def build_index(mli_dir, output_path, num_workers=None):
    """
    Build index from all .mli files under mli_dir.

    Uses imap_unordered: results stream back one file at a time,
    avoiding the Pipe overflow that kills pool.map() on large datasets.
    """
    mli_dir = Path(mli_dir)
    mli_files = sorted(mli_dir.rglob("*.mli"))
    logger.info(f"Found {len(mli_files)} .mli files")

    if num_workers is None:
        num_workers = min(cpu_count(), 16)
    logger.info(f"Using {num_workers} workers")

    index = {}          # theorem_name → list of [action_type, action_obj]
    total_items = 0
    errors = 0
    t0 = time.time()

    chunksize = max(1, len(mli_files) // (num_workers * 16))

    with Pool(processes=num_workers) as pool:
        it = pool.imap_unordered(
            _index_one_file,
            [str(p) for p in mli_files],
            chunksize=chunksize,
        )
        for i, (fname, results, err) in enumerate(it):
            if err:
                if errors < 5:
                    logger.warning(f"  ERROR {Path(fname).name}: {err}")
                errors += 1
                continue

            file_items = len(results) if results else 0
            if results:
                for theorem_name, atype, aobj in results:
                    if theorem_name not in index:
                        index[theorem_name] = []
                    index[theorem_name].append([atype, aobj])
            total_items += file_items

            if (i + 1) % 500 == 0 or (i + 1) == len(mli_files):
                elapsed = time.time() - t0
                rate = (i + 1) / elapsed if elapsed > 0 else 0
                logger.info(
                    f"  [{i+1}/{len(mli_files)}] {total_items} items, "
                    f"{len(index)} theorems, {errors} errors "
                    f"({rate:.0f} files/s)"
                )

    elapsed = time.time() - t0
    logger.info(
        f"Done: {total_items} items → {len(index)} unique theorems "
        f"in {elapsed:.0f}s ({errors} errors)"
    )

    # Save index
    logger.info(f"Saving index to {output_path}...")
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        json.dump(index, f)

    size_mb = output_path.stat().st_size / (1024 * 1024)
    logger.info(f"Saved: {output_path} ({size_mb:.1f} MB)")
    return index


def main():
    p = argparse.ArgumentParser(description="Build test-server index from .mli files")
    p.add_argument("--mli-dir", default="/workspaces/acl2-jupyter/data/books",
                   help="Directory containing .mli files")
    p.add_argument("--output", default="test_index.json",
                   help="Output JSON file path")
    p.add_argument("--workers", type=int, default=None,
                   help="Number of parallel workers (default: cpu_count)")
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )

    build_index(args.mli_dir, args.output, args.workers)


if __name__ == "__main__":
    main()
