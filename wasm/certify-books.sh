#!/bin/sh
# Certify books with the WebAssembly ACL2, keeping each book's expansion file.
#
#   wasm/certify-books.sh books/textbook/chap11/perm books/textbook/chap11/qsort
#
# Why the expansion file: a compiled book that ACL2 loads has to be built from
# <book>@expansion.lsp (ACL2's own expanded events), not from the book's .lisp.
# A module built from the source re-runs the book's macros and events when the
# module initialises, and ACL2 refuses ("It is illegal to execute make-event in
# raw Lisp ... consider loading a corresponding file *@expansion.lsp instead").
# ACL2_SAVE_EXPANSION=1 keeps the file, and wasm/aot-book.sh compiles it.
#
# All the books are certified in ONE ACL2 process, one
#   (set-cbd "<dir>/") (certify-book "<name>" ? t)
# pair per book, because about 45 s of the cost of each book is start-up.  Give
# the books in dependency order; a book that fails prints an error and the rest
# of the batch still runs (ACL2 keeps reading the script).
#
# Two things had to be right, both about where ACL2 thinks it is:
#
#   * the connected book directory.  ACL2 takes it from OUR-PWD, which is
#     (TRUENAME "") -- i.e. from *DEFAULT-PATHNAME-DEFAULTS*, which loading the
#     sources leaves pointing at the source tree, not from the process's working
#     directory.  wasm/acl2-wasm.lsp sets it from the directory the process was
#     started in, and each (set-cbd ...) below moves it per book.
#   * the third argument of certify-book is compile-flg (the second is the
#     expected make-event world).  With it nil ACL2 never compiles, so no
#     expansion file is created at all.
#
# cert.pl's own route does not work in this build: its script starts with
# (acl2::value :q) and (acl2::lp), and the certification then dies in raw Lisp
# with "The Live State Itself is not of type SEQUENCE".
#
# Environment:
#   ACL2_WASM_ECL  the wasm ECL to run (default /opt/eclwasm/dist/node-raw-dylink2,
#                  since ACL2's own compiled files are wasm modules)
#   LOG            where the ACL2 output goes (default /tmp/certify.log)
#   FORCE          1 to re-certify books that already have both files
#   ONE            1 to use one process per book instead of one batch
#
# A book is skipped when it already has both <book>.cert and
# <book>@expansion.lsp.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
ACL2_WASM_ECL=${ACL2_WASM_ECL:-/opt/eclwasm/dist/node-raw-dylink2}
LOG=${LOG:-/tmp/certify.log}
FORCE=${FORCE:-0}
ONE=${ONE:-0}

if [ $# -eq 0 ]; then
  echo "usage: $0 <book> [<book> ...]     e.g. $0 books/textbook/chap11/perm" >&2
  exit 2
fi

# The books to certify, as "<dir> <name>" lines, in the order given.
TODO=""
for book in "$@"; do
  dir=$(dirname "$book")
  name=$(basename "$(basename "$book" .lisp)" .acl2)
  if [ "$FORCE" != 1 ] && [ -f "$ROOT/$dir/$name.cert" ] &&
     [ -f "$ROOT/$dir/$name@expansion.lsp" ]; then
    echo "== $dir/$name: already certified, with expansion"
    continue
  fi
  TODO="$TODO$dir $name
"
done

if [ -z "$TODO" ]; then
  echo "certify-books: nothing to do"
  exit 0
fi

echo "== certifying $(printf '%s' "$TODO" | grep -c .) book(s); log: $LOG"

if [ "$ONE" = 1 ]; then
  printf '%s' "$TODO" | while read -r dir name; do
    echo "-- $dir/$name"
    (
      cd "$ROOT/$dir" || exit 1
      # A book's .acl2 file is its portcullis (packages, included books);
      # cert.pl inlines it into its script before certifying, so do the same.
      # Without it, books whose .acl2 creates a package fail to read
      # (tools/flag: IN-PACKAGE "FLAG"), and books whose .acl2 includes a
      # dependency fail its proofs (system/apply/apply).
      {
        [ -f "$name.acl2" ] &&
          printf '(ld "%s/%s/%s.acl2")\n' "$ROOT" "$dir" "$name"
        printf '(certify-book "%s" ? t)\n(quit)\n' "$name"
      } |
        env -u ACL2_WORLD_IMAGE -u ACL2_NO_LP -u ACL2_WASM_INVOCATION_DIR \
        ACL2_SAVE_EXPANSION=1 \
        ACL2_WASM_DRIVER="$HERE/acl2-wasm.lsp" \
        ACL2_WASM_ECL="$ACL2_WASM_ECL" \
        ACL2_WASM_DIR="$ROOT" \
        "$HERE/acl2-wasm" > "$ROOT/$dir/$name.certify.log" 2>&1
    )
  done
else
  # One process for the whole batch.  It starts in the first book's directory,
  # which is where its initial cbd comes from; every book then sets the cbd
  # explicitly.
  firstdir=$(printf '%s' "$TODO" | head -1 | cut -d' ' -f1)
  (
    printf '%s' "$TODO" | while read -r dir name; do
      printf '(set-cbd "%s/%s/")\n' "$ROOT" "$dir"
      [ -f "$ROOT/$dir/$name.acl2" ] &&
        printf '(ld "%s/%s/%s.acl2")\n' "$ROOT" "$dir" "$name"
      printf '(certify-book "%s" ? t)\n' "$name"
    done
    printf '(quit)\n'
  ) | (
    cd "$ROOT/$firstdir" || exit 1
    env -u ACL2_WORLD_IMAGE -u ACL2_NO_LP -u ACL2_WASM_INVOCATION_DIR \
      ACL2_SAVE_EXPANSION=1 \
      ACL2_WASM_DRIVER="$HERE/acl2-wasm.lsp" \
      ACL2_WASM_ECL="$ACL2_WASM_ECL" \
      ACL2_WASM_DIR="$ROOT" \
      "$HERE/acl2-wasm" > "$LOG" 2>&1
  )
fi

# Report what came out.
status=0
printf '%s' "$TODO" | while read -r dir name; do
  cert="$ROOT/$dir/$name.cert"
  exp="$ROOT/$dir/$name@expansion.lsp"
  if [ ! -f "$cert" ]; then
    echo "FAIL $dir/$name"
  elif [ ! -f "$exp" ]; then
    echo "ok   $dir/$name ($(wc -c < "$cert") B cert, NO expansion file)"
  else
    echo "ok   $dir/$name ($(wc -c < "$cert") B cert, expansion kept)"
  fi
done
printf '%s' "$TODO" | while read -r dir name; do
  [ -f "$ROOT/$dir/$name.cert" ] || status=1
done
exit $status
