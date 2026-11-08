#!/bin/sh
# Certify books with the WebAssembly ACL2, one process per book, each started
# in the book's own directory.
#
#   wasm/certify-books.sh books/textbook/chap11/perm books/textbook/chap11/qsort
#
# Why one process per book, started there: ACL2 takes its connected book
# directory from the directory it was started in (see the note at the end of
# wasm/acl2-wasm.lsp), and (certify-book "perm" 0 nil) resolves "perm" against
# it.  cert.pl would do the same thing, but it drives ACL2 through
# build/make_cert's own script, and that script asks ACL2 to leave and re-enter
# its loop first, which in this build ends in a raw-Lisp error ("The Live State
# Itself is not of type SEQUENCE").
#
# ACL2_SAVE_EXPANSION=1 keeps <book>@expansion.lsp, which is what
# wasm/aot-book.sh compiles: a module built from the book's *source* re-runs its
# macros and events at load time (ACL2: "It is illegal to execute make-event in
# raw Lisp"), while one built from the expansion contains the events ACL2 itself
# would load.
#
# Environment:
#   ACL2_WASM_ECL  the wasm ECL to run (default /opt/eclwasm/dist/node-raw-dylink2,
#                  since ACL2's own compiled files are wasm modules)
#   JOBS           unused; books certify one at a time because they share the
#                  directory they write certificates into
#
# Each book costs about 45 s of start-up plus its own proof time.  Logs are
# written next to the books as <book>.certify.log.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
ACL2_WASM_ECL=${ACL2_WASM_ECL:-/opt/eclwasm/dist/node-raw-dylink2}

if [ $# -eq 0 ]; then
  echo "usage: $0 <book> [<book> ...]     e.g. $0 books/textbook/chap11/perm" >&2
  exit 2
fi

status=0
for book in "$@"; do
  dir=$(dirname "$book")
  name=$(basename "$book" .lisp)
  name=$(basename "$name" .acl2)
  cert="$ROOT/$dir/$name.cert"
  log="$ROOT/$dir/$name.certify.log"
  echo "== $dir/$name"
  if [ -f "$cert" ]; then
    echo "   already certified: $cert"
    continue
  fi
  if (
    cd "$ROOT/$dir" || exit 1
    printf '(certify-book "%s" ? t)\n(quit)\n' "$name" |
      env -u ACL2_WORLD_IMAGE -u ACL2_NO_LP -u ACL2_WASM_INVOCATION_DIR \
      ACL2_SAVE_EXPANSION=1 \
      ACL2_WASM_DRIVER="$HERE/acl2-wasm.lsp" \
      ACL2_WASM_ECL="$ACL2_WASM_ECL" \
      ACL2_WASM_DIR="$ROOT" \
      "$HERE/acl2-wasm" > "$log" 2>&1
  ); then
    if [ -f "$cert" ]; then
      echo "   certified ($(wc -c < "$cert") bytes)"
      [ -f "$ROOT/$dir/$name@expansion.lsp" ] &&
        echo "   expansion file kept: $name@expansion.lsp"
    else
      echo "   FAILED: no $cert (see $log)" >&2
      status=1
    fi
  else
    echo "   FAILED: see $log" >&2
    status=1
  fi
done
exit $status
