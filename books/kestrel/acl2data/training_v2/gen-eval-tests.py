"""Generate ACL2 eval test forms from the test split.

Maps .pt paths directly to .lisp source:
  test/centaur/tutorial/booth-support__acl2data.pt
  -> /home/acl2/books/centaur/tutorial/booth-support.lisp

Usage:
  python training_v2/gen-eval-tests.py --preproc-dir /path --max-books 5
"""

import json
import random
import argparse
from pathlib import Path
from collections import defaultdict


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

    books_dir = Path("/home/acl2/books")
    book_lisp_files = defaultdict(set)

    for rel_path in manifest["test"]:
        p = Path(rel_path)
        stem = p.stem
        if not stem.endswith("__acl2data"):
            continue
        source_name = stem[:-len("__acl2data")]
        parts = p.parts[1:-1]
        lisp_path = books_dir / Path(*parts) / (source_name + ".lisp")
        if lisp_path.exists():
            book_lisp_files[str(lisp_path)].add(rel_path)

    books = sorted(book_lisp_files.keys())
    random.shuffle(books)

    found = 0
    entries = []
    for lisp_path in books:
        if found >= args.max_books:
            break
        pt_count = len(book_lisp_files[lisp_path])
        rel = str(Path(lisp_path).relative_to(books_dir))
        found += 1
        print("; {}: {} test files".format(rel, pt_count))
        entries.append('("{}" . :all)'.format(rel))

    if entries:
        print("")
        for ent in entries:
            print("    {}".format(ent))

    print("")
    print("; Generated {} eval forms (seed={}, from {} test books)".format(
        found, args.seed, len(book_lisp_files)))


if __name__ == "__main__":
    main()
