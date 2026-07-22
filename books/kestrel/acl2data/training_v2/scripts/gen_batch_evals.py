#!/usr/bin/env python3
"""Generate per-batch ACL2 eval scripts for the validation set.

Usage:
  python training_v2/scripts/gen_batch_evals.py \
      --books training_v2/eval-val.lisp \
      --batches 8 \
      --port 8765 \
      --output-dir eval-outputs-parallel
"""

import sys
import os
from pathlib import Path

# Validation set books — extracted from eval-val.lisp
VALIDATION_BOOKS = [
    "arithmetic-2/meta/integerp.lisp",
    "arithmetic-2/meta/expt.lisp",
    "arithmetic-2/meta/numerator-and-denominator.lisp",
    "centaur/nrev/fast.lisp",
    "kestrel/arithmetic-light/ash.lisp",
    "kestrel/arithmetic-light/ceiling.lisp",
    "kestrel/evaluators/if-eval.lisp",
    "kestrel/htclient/post-light.lisp",
    "centaur/fty/baselists.lisp",
    "centaur/fty/deftypes.lisp",
]

LISP_TEMPLATE = """(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:{port}/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 — Validation Set Eval (Batch {batch_num}/{total_batches}) ===~%")

(eval-models-on-books
  '({book_list})
  "/home/acl2/books"
  10        ; num-recs-per-model
  t         ; print
  nil       ; debug
  nil nil   ; step-limit, time-limit
  (help::make-model-info-alist :all (w state))
  40        ; model-query-timeout
  :goal-partial  ; breakage-plan
  0         ; done-book-count
  {batch_count}   ; total-book-count
  nil       ; result-alist-acc
  1         ; rand seed
  state)

(cw "~%=== Done Batch {batch_num}/{total_batches} ===~%")
"""


def main():
    import argparse
    p = argparse.ArgumentParser(description="Generate per-batch ACL2 eval scripts")
    p.add_argument("--batches", type=int, default=8)
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--output-dir", default="eval-outputs-parallel")
    args = p.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    books = VALIDATION_BOOKS
    total = len(books)
    per_batch = (total + args.batches - 1) // args.batches

    for batch_num in range(1, args.batches + 1):
        start = (batch_num - 1) * per_batch
        end = min(start + per_batch, total)
        if start >= total:
            break

        batch_books = books[start:end]

        # Build quoted alist
        book_entries = " ".join(f'("{b}" . :all)' for b in batch_books)

        content = LISP_TEMPLATE.format(
            port=args.port,
            batch_num=batch_num,
            total_batches=args.batches,
            book_list=book_entries,
            batch_count=len(batch_books),
        )

        out_path = output_dir / f"eval-batch-{batch_num:02d}.lisp"
        out_path.write_text(content)
        print(f"  Batch {batch_num}: {len(batch_books)} books → {out_path}")


if __name__ == "__main__":
    main()
