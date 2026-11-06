#!/bin/sh
# AOT certified books into WebAssembly modules.
#
#   wasm/aot-book.sh books/textbook/chap10/fact ...
#
# Each argument is a book (with or without ".lisp") that was certified with
# save-expansion-file on, i.e. that has a "<book>@expansion.lsp" next to it.
# The expansion file is compiled into a wasm side module named "<book>.fasc",
# which is the file include-book loads, so the book then runs compiled instead
# of interpreted (measured 77-124x on small functions; see WASM-PORT-NOTES.md).
#
# Why not compile the book's own .lisp: the expansion file is the book's events
# with the macros already expanded and the prover's serialized data attached,
# which is what ACL2 itself compiles; and it is what the bookmark machinery
# already knows how to load.
#
# Environment:
#
#   ACL2_AOT_ECL    host ECL to use (default /opt/eclwasm/ecl-host/bin/ecl)
#   ACL2_AOT_HOME   ACL2 source directory (default: the parent of this script)
#   ACL2_AOT_TARGET target-info file, only used to decide whether to regenerate
#                   (default /tmp/wasm32.target)
#   ACL2_AOT_DELTA  delta file (default /tmp/wasm32.delta)
#
# The target files come from wasm/mk-wasm32-target.lsp, which needs the wasm
# build's own target-info.lsp ($WORK/ecl-node/target-info.lsp); this script
# regenerates them if they are missing.

set -e

THISDIR=$(cd "$(dirname "$0")" && pwd)
ACL2_AOT_HOME=${ACL2_AOT_HOME:-$(cd "$THISDIR/.." && pwd)}
ACL2_AOT_ECL=${ACL2_AOT_ECL:-/opt/eclwasm/ecl-host/bin/ecl}
ACL2_AOT_TARGET=${ACL2_AOT_TARGET:-/tmp/wasm32.target}
ACL2_AOT_DELTA=${ACL2_AOT_DELTA:-/tmp/wasm32.delta}

if [ $# -eq 0 ]; then
  echo "usage: $0 <book> [<book> ...]" >&2
  echo "  e.g. $0 books/textbook/chap10/fact" >&2
  exit 2
fi

if [ ! -x "$ACL2_AOT_ECL" ]; then
  echo "aot-book: no host ECL at $ACL2_AOT_ECL" >&2
  echo "aot-book: build it with wasm/build-ecl-wasm.sh (it installs ecl-host/)" >&2
  exit 1
fi

if [ ! -f "$ACL2_AOT_TARGET" ] || [ ! -f "$ACL2_AOT_DELTA" ]; then
  echo "aot-book: writing $ACL2_AOT_TARGET and $ACL2_AOT_DELTA"
  "$ACL2_AOT_ECL" -norc -load "$THISDIR/mk-wasm32-target.lsp" \
                  -eval '(wasm-target:main)' </dev/null
fi

FILES=
MISSING=
for book in "$@"; do
  case $book in
    *@expansion.lsp) expansion=$book ;;
    *.lisp)          expansion="${book%@expansion.lisp}@expansion.lsp" ;;
    *)               expansion="$book@expansion.lsp" ;;
  esac
  # Relative paths are relative to ACL2's directory, since that is where the
  # compile happens.
  case $expansion in
    /*) ;;
    *)  expansion="$ACL2_AOT_HOME/$expansion" ;;
  esac
  if [ -f "$expansion" ]; then
    if [ -z "$FILES" ]; then
      FILES=$expansion
    else
      FILES="$FILES $expansion"
    fi
  else
    MISSING="$MISSING $expansion"
  fi
done

if [ -n "$MISSING" ]; then
  echo "aot-book: no expansion file for:$MISSING" >&2
  echo "aot-book: certify with ACL2_SAVE_EXPANSION=1 so that it is kept" >&2
  exit 1
fi

# The C stack: load-acl2 needs far more than ECL's default 8 MB.  Both the
# shell limit and ECL's own limit are raised, as in wasm/acl2-wasm.
ulimit -s 1048576 2>/dev/null || true

ACL2_AOT_HOME=$ACL2_AOT_HOME \
ACL2_AOT_DELTA=$ACL2_AOT_DELTA \
ACL2_AOT_FILES="$FILES" \
  exec "$ACL2_AOT_ECL" -norc -load "$THISDIR/aot-host.lsp" </dev/null
