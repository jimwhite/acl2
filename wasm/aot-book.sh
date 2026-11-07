#!/bin/sh
# AOT Lisp files -- certified books, and ACL2's own ahead-of-time files -- into
# WebAssembly modules.
#
#   wasm/aot-book.sh books/textbook/chap10/fact ...
#   wasm/aot-book.sh acl2-exec-aot.lisp
#
# An argument that names a book (with or without ".lisp") is compiled through
# the book's "<book>@expansion.lsp", which is left behind by certifying with
# save-expansion-file on (ACL2_SAVE_EXPANSION=1).  The module is named
# "<book>.fasc", which is the file include-book loads, so the book then runs
# compiled instead of interpreted (measured 77-124x on small functions; see
# WASM-PORT-NOTES.md).
#
# An argument that is already a Lisp file with no expansion file next to it --
# ACL2-EXEC-AOT.LISP, say, the executable counterparts the boot-strap uses --
# is compiled as it is, keeping its name.
#
# Why a book is compiled from its expansion file rather than from its own
# .lisp: the expansion file is the book's events with the macros already
# expanded and the prover's serialized data attached, which is what ACL2 itself
# compiles; and it is what the bookmark machinery already knows how to load.
#
# Environment:
#
#   ACL2_AOT_ECL    host ECL to use (default /opt/eclwasm/ecl-host/bin/ecl)
#   ACL2_AOT_HOME   ACL2 source directory (default: the parent of this script)
#   ACL2_AOT_TARGET target-info file, only used to decide whether to regenerate
#                   (default /tmp/wasm32.target)
#   ACL2_AOT_DELTA  delta file (default /tmp/wasm32.delta)
#   ACL2_AOT_BYTECODE_DIR
#                   where wasm/acl2-wasm-compile keeps bytecode copies of
#                   ACL2's compiled files (default /opt/eclwasm/bytecode).
#                   The driver loads ACL2 from there: the .fasc files in the
#                   ACL2 directory may already be wasm modules, which a native
#                   ECL cannot load.
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
ACL2_AOT_BYTECODE_DIR=${ACL2_AOT_BYTECODE_DIR:-/opt/eclwasm/bytecode}

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
  # A book compiles through its expansion file, which the certificate leaves
  # behind when certified with ACL2_SAVE_EXPANSION=1.  Anything else that is
  # already a Lisp file (ACL2-EXEC-AOT.LISP, for instance) is compiled as it is.
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
  case $book in
    /*) plain=$book ;;
    *)  plain="$ACL2_AOT_HOME/$book" ;;
  esac
  if [ -f "$expansion" ]; then
    source=$expansion
  elif [ -f "$plain" ]; then
    source=$plain
  else
    MISSING="$MISSING $expansion"
    continue
  fi
  if [ -z "$FILES" ]; then
    FILES=$source
  else
    FILES="$FILES $source"
  fi
done

if [ -n "$MISSING" ]; then
  echo "aot-book: no source for:$MISSING" >&2
  echo "aot-book: for books, certify with ACL2_SAVE_EXPANSION=1 so that the" >&2
  echo "aot-book: expansion file is kept" >&2
  exit 1
fi

# The C stack: load-acl2 needs far more than ECL's default 8 MB.  Both the
# shell limit and ECL's own limit are raised, as in wasm/acl2-wasm.
ulimit -s 1048576 2>/dev/null || true

ACL2_AOT_HOME=$ACL2_AOT_HOME \
ACL2_AOT_DELTA=$ACL2_AOT_DELTA \
ACL2_AOT_BYTECODE_DIR=$ACL2_AOT_BYTECODE_DIR \
ACL2_AOT_FILES="$FILES" \
  exec "$ACL2_AOT_ECL" -norc -load "$THISDIR/aot-host.lsp" </dev/null
