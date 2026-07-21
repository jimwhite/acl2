"""
Generate ACL2 eval test forms from known-good test books.

Scans the test split to find books with data, then maps them to
actual .lisp files in the ACL2 books directory.

Usage:
  python training_v2/gen-eval-tests.py \
      --preproc-dir /path/to/preprocessed_v4 \
      --max-books 5 --seed 42

Output: eval-models-on-book calls for eval-graph2tocopo.lisp
"""

import json
import random
import argparse
import subprocess
from pathlib import Path
from collections import defaultdict


def find_lisp_file(book_name, books_dir="/home/acl2/books/kestrel"):
    """Find a .lisp file matching a book name from the preprocessed data."""
    book_path = Path(books_dir) / book_name
    
    # Try direct .lisp file
    candidates = list(book_path.parent.glob(f"{book_path.name}.lisp"))
    if candidates:
        return str(candidates[0])
    
    # Try subdirectories
    if book_path.is_dir():
        candidates = list(book_path.glob("*.lisp"))
        if candidates:
            return str(candidates[0])
    
    return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--preproc-dir", required=True)
    p.add_argument("--max-books", type=int, default=5)
    p.add_argument("--seed", type=int, default=42)
    args = p.parse_args()

    preproc_dir = Path(args.preproc_dir)
    random.seed(args.seed)

    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)

    # Group test files by book, count items
    book_counts = defaultdict(int)
    for rel_path in manifest["test"]:
        parts = Path(rel_path).parts
        if len(parts) >= 2:
            book_counts[parts[1]] += 1

    # Shuffle and pick books that have matching .lisp files
    books = sorted(book_counts.keys())
    random.shuffle(books)

    found = 0
    for book in books:
        if found >= args.max_books:
            break
        
        lisp_file = find_lisp_file(book)
        if not lisp_file:
            continue
        
        # Check it has theorems with hints (quick grep)
        try:
            result = subprocess.run(
                ["grep", "-c", ":hints", lisp_file],
                capture_output=True, text=True, timeout=5)
            hint_count = int(result.stdout.strip() or 0)
        except Exception:
            hint_count = 0
        
        if hint_count == 0:
            continue
        
        found += 1
        print(f'; {book}: {book_counts[book]} test files, {hint_count} hinted theorems')
        print(f'(eval-models-on-book')
        print(f'  "{lisp_file}"')
        print(f'  :all 10 t nil nil nil')
        print(f'  (help::make-model-info-alist :all (w state))')
        print(f'  40 :goal-partial 1 state)')
        print()

    print(f'; Generated {found} eval forms (seed={args.seed})')


if __name__ == "__main__":
    main()
