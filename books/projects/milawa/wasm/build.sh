#!/bin/sh
#
# Build the WebAssembly version of the Milawa proof checker.
#
#   ./wasm/build.sh
#
# Requirements: git, make, a native C toolchain, emscripten (emcc,
# emconfigure, emmake -- `apt install emscripten` is fine), nodejs, and
# llvm-nm.  See MILAWA-WASM.md.
#
# Everything is built under ${MILAWA_WASM_BUILD:-<milawa>/.wasm-build}:
#
#   host/bin/ecl          native ECL, used as the cross-compiler
#   wasm/                 ECL cross-compiled for wasm32-unknown-emscripten
#   milawa.o              milawa.lsp cross-compiled for wasm
#   milawa-wasm.js/.wasm  the checker itself
#
# ECL is taken from https://gitlab.com/jimwhite/ecl; set MILAWA_ECL_SRC to
# reuse a clone, or MILAWA_ECL_URL to use another repository.
#
# Two edits are made to the copy of ECL used for the target build.  Emscripten
# implements setrlimit as a stub, so ECL's stack limit is fixed when it is
# compiled; it has to be raised from the 1 MB default to something that can
# hold the deeper proofs (level10 needs far more than 64 MB natively).  The
# wasm stack in the link flags is raised to match.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
milawa=$(cd "$here/.." && pwd)
build=${MILAWA_WASM_BUILD:-$milawa/.wasm-build}
ecl_src=${MILAWA_ECL_SRC:-$build/ecl}
ecl_url=${MILAWA_ECL_URL:-https://gitlab.com/jimwhite/ecl.git}

stack_bytes=${MILAWA_WASM_C_STACK:-1073741824}           # 1 GB
initial_memory=${MILAWA_WASM_INITIAL_MEMORY:-1342177280} # stack + heap room

jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)

mkdir -p "$build"

if [ ! -d "$ecl_src" ]; then
  echo "== cloning ECL from $ecl_url"
  git clone --depth 1 "$ecl_url" "$ecl_src"
fi

# 1. Native ECL, the cross-compiler.
if [ ! -x "$build/host/bin/ecl" ]; then
  echo "== building host ECL"
  rm -rf "$build/ecl-host"
  cp -a "$ecl_src" "$build/ecl-host"
  ( cd "$build/ecl-host" \
    && ./configure --prefix="$build/host" \
    && make -j"$jobs" \
    && make install )
fi

# 2. ECL for wasm32-unknown-emscripten.
if [ ! -f "$build/wasm/ecl.wasm" ]; then
  echo "== building ECL for wasm"
  rm -rf "$build/ecl-target" "$build/wasm"
  cp -a "$ecl_src" "$build/ecl-target"

  sed -i "s/-sSTACK_SIZE=1048576/-sSTACK_SIZE=$stack_bytes/" \
      "$build/ecl-target/src/configure"
  sed -i "s/ECL_DEFAULT_C_STACK_SIZE=1048576/ECL_DEFAULT_C_STACK_SIZE=$stack_bytes/" \
      "$build/ecl-target/src/configure"

  if ! grep -q -- "-sSTACK_SIZE=$stack_bytes" "$build/ecl-target/src/configure"; then
    echo "wasm/build.sh: ECL's configure no longer matches the sed patterns" >&2
    exit 1
  fi

  ( cd "$build/ecl-target" \
    && ECL_TO_RUN="$build/host/bin/ecl" LDFLAGS="-sALLOW_MEMORY_GROWTH=1" \
       emconfigure ./configure \
         --host=wasm32-unknown-emscripten \
         --build="$(cc -dumpmachine)" \
         --with-cross-config="$build/ecl-target/src/util/wasm32-unknown-emscripten.cross_config" \
         --prefix="$build/wasm" \
         --disable-shared --with-tcp=no --with-cmp=no \
         ac_cv_have_decl_RLIMIT_STACK=no \
    && emmake make -j"$jobs" \
    && emmake make flatinstall )
fi

# 3. Cross-compile the kernel to a wasm object.
echo "== cross-compiling milawa.lsp"
MILAWA_WASM_BUILD="$build" \
MILAWA_WASM_TARGET_INFO="$build/ecl-target/build/target-info.lsp" \
MILAWA_WASM_KERNEL="$milawa/milawa.lsp" \
MILAWA_WASM_DRIVER="$here/run.lisp" \
  "$build/host/bin/ecl" -norc -load "$here/build-kernel.lisp"

# 4. Link the checker.  The module's init function name contains a hash, so it
#    is extracted from the object instead of being hard-coded.
nm=${MILAWA_WASM_NM:-$(command -v llvm-nm || command -v llvm-nm-19)}
init=$("$nm" "$build/milawa.o" | awk '$3 ~ /^__ecl_init/ { print $3; exit }')
run_init=$("$nm" "$build/run.o" | awk '$3 ~ /^__ecl_init/ { print $3; exit }')
if [ -z "$init" ] || [ -z "$run_init" ]; then
  echo "wasm/build.sh: could not find the module init symbols" >&2
  exit 1
fi
{
  printf '#define MILAWA_INIT %s\nextern void MILAWA_INIT(cl_object);\n' "$init"
  printf '#define DRIVER_INIT %s\nextern void DRIVER_INIT(cl_object);\n' "$run_init"
} > "$build/milawa-init.h"

echo "== linking milawa-wasm"
emcc -o "$build/milawa-wasm.js" \
     -I"$build/wasm" -I"$build" \
     "$here/milawa-wasm.c" "$build/milawa.o" "$build/run.o" \
     -L"$build/wasm" -lecl -leclgc -leclgmp -lm \
     -sALLOW_MEMORY_GROWTH=1 \
     -sSTACK_SIZE="$stack_bytes" \
     -sINITIAL_MEMORY="$initial_memory" \
     -sFORCE_FILESYSTEM=1 -lnodefs.js \
     --pre-js "$here/pre.js" \
     --profiling-funcs \
     -sBINARYEN_EXTRA_PASSES=--spill-pointers,--strip-debug \
     -sERROR_ON_UNDEFINED_SYMBOLS=0

echo "== done: $build/milawa-wasm.js"
