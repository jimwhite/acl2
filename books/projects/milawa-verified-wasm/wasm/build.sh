#!/bin/sh
# Assemble milawa-verified.wat into milawa-verified.wasm.
#
#   ./wasm/build.sh [outfile]
#
# wat2wasm comes from WABT, which is NOT a trusted component and does not need to
# be: the module this produces is checked by L1, and the text it was assembled
# from is in version control next to it.  A buggy assembler can only produce a
# module that fails the proof, never one that passes it.
#
# WABT is not installed by .devcontainer/setup.sh because it is only needed to
# build the artifact, not to certify the books.  On Ubuntu: apt-get install wabt.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
out=${1:-"$here/milawa-verified.wasm"}

if ! command -v wat2wasm >/dev/null 2>&1; then
  echo "wat2wasm not found; install WABT (apt-get install wabt)" >&2
  exit 1
fi

wat2wasm "$here/milawa-verified.wat" -o "$out"
echo "wrote $out"
