#!/bin/sh
# Certify the `basic` book suite with the WebAssembly build of ACL2 running
# under Node, i.e. the same pipeline as `make -j 16 basic` but with
#
#     ACL2=/workspaces/acl2-ecl/wasm/acl2-wasm
#
# Usage:
#
#   CLEAN=1 ./wasm/run-basic-wasm.sh            # first run: start from scratch
#   ./wasm/run-basic-wasm.sh                    # resume (cert.pl skips built books)
#   JOBS=8 LOG=/tmp/my.log ./wasm/run-basic-wasm.sh
#
# Environment:
#   JOBS     parallel jobs (default 16; each job needs ~1 GB of RAM)
#   LOG      log file (default /tmp/wasm-basic.log)
#   CLEAN    1 = delete existing book certificates/compiled files first
#   TARGETS  make targets (default "basic")
#
# Why CLEAN matters: the tree normally holds certificates produced by the
# native ECL build.  cert.pl treats those as up to date and would skip every
# book, and a native .fas cannot be loaded by the wasm build anyway (its
# fixnums are 62 bits, the wasm build's are 30).  CLEAN=1 removes them; the
# native suite can be rebuilt later with `make -j 16 basic ACL2=../saved_acl2`
# (about 23 minutes).
#
# Expect roughly 6 minutes per book (about 6 of those are ACL2 start-up, since
# this path still re-runs the boot-strap for every book).  With 1,486 books
# that is about 10 hours at JOBS=16, 20 hours at JOBS=8.

set -eu

THISDIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$THISDIR/.." && pwd)
JOBS=${JOBS:-16}
LOG=${LOG:-/tmp/wasm-basic.log}
CLEAN=${CLEAN:-0}
TARGETS=${TARGETS:-basic}
ACL2_WASM="$THISDIR/acl2-wasm"

if [ -n "${ACL2_WASM_ECL:-}" ]; then
  ECL_DIR=$ACL2_WASM_ECL
else
  ECL_DIR=/opt/eclwasm/dist/node-raw
fi

if [ ! -f "$ECL_DIR/ecl.wasm" ]; then
  echo "error: no WebAssembly ECL in $ECL_DIR (set ACL2_WASM_ECL)" >&2
  exit 1
fi

echo "== refreshing ACL2 .fasc files with the wasm compiler (about 90 s)"
"$THISDIR/acl2-wasm-compile" > /tmp/wasm-compile.log 2>&1 ||
  { tail -20 /tmp/wasm-compile.log; echo "error: compile failed" >&2; exit 1; }

if [ "$CLEAN" = 1 ]; then
  echo "== deleting existing book certificates and compiled files"
  cd "$ROOT/books"
  find . -type f \( -name '*.cert' -o -name '*.cert.out' -o -name '*.cert.dep' \
       -o -name '*.cert.marks' -o -name '*.fas' -o -name '*.fasc' \
       -o -name '*.o' -o -name '*.port' -o -name '*.dpart' \
       -o -name '*.pcert0' -o -name '*.pcert1' -o -name 'workxxx.*' \) -delete
  cd "$ROOT"
fi

echo "== targets: $TARGETS"
echo "== jobs:    $JOBS"
echo "== log:     $LOG"
echo "== started: $(date)"

cd "$ROOT/books"
# -k keeps going after a failed book; features.sh and the dependency scan are
# re-run by the Makefile with each invocation (a few minutes under wasm).
status=0
make -k -j "$JOBS" $TARGETS ACL2="$ACL2_WASM" > "$LOG" 2>&1 || status=$?

echo "== finished: $(date) (make exit status $status)"
echo "== certificates now present: $(find "$ROOT/books" -name '*.cert' | wc -l)"
exit $status
