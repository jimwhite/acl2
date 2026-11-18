#!/bin/sh
#
# Build the browser (WebAssembly) version of the Milawa proof checker.
#
#   ./wasm/build-web.sh
#
# This is the browser counterpart of wasm/build.sh: same ECL source, same
# cross-compiled milawa.lsp, but the wasm ECL is built with a fixed-size
# in-memory stack and the longjmp implementation that stays inside wasm, and
# the checker is linked as a MODULARIZE module with no Node filesystem.  A
# page writes the image, the events file and the proofs into MEMFS under
# /real, changes to that directory, and calls main with paths relative to it
# (milawa-wasm.c prefixes absolute paths with /real).
#
# Everything is built under ${MILAWA_WASM_WEB_BUILD:-<milawa>/.wasm-build/web}:
#
#   host/bin/ecl          native ECL, used as the cross-compiler (shared with
#                         wasm/build.sh when that has been run)
#   wasm/                 ECL cross-compiled for wasm32-unknown-emscripten
#   milawa.o              milawa.lsp cross-compiled for wasm
#   milawa-wasm.js/.wasm  the checker itself
#
# Requirements: git, make, a native C toolchain, emscripten (emcc,
# emconfigure, emmake), llvm-nm and the ECL fork at
# https://gitlab.com/jimwhite/ecl.  Set MILAWA_ECL_SRC to reuse a clone.
#
# In a browser the wasm linear stack is fixed at link time, but the JS
# engine's native stack (about 1 MB in a page) is the scarce resource: every
# interpreted Lisp call otherwise costs two JavaScript frames (setjmp
# trampolines).  Hence -fwasm-exceptions / -sSUPPORT_LONGJMP=wasm and -O2.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
milawa=$(cd "$here/.." && pwd)
build=${MILAWA_WASM_BUILD:-$milawa/.wasm-build}
web=${MILAWA_WASM_WEB_BUILD:-$build/web}
ecl_src=${MILAWA_ECL_SRC:-$build/ecl}
ecl_url=${MILAWA_ECL_URL:-https://gitlab.com/jimwhite/ecl.git}

stack_bytes=$(( ${MILAWA_WEB_STACK_MB:-512} * 1048576 ))
initial_memory=$(( ${MILAWA_WEB_MEMORY_MB:-1024} * 1048576 ))

jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)

mkdir -p "$build" "$web"

if [ ! -d "$ecl_src" ]; then
  echo "== cloning ECL from $ecl_url"
  git clone --depth 1 "$ecl_url" "$ecl_src"
fi

# 1. Native ECL, the cross-compiler.  wasm/build.sh builds the same thing;
#    reuse it rather than spending another minute on it.
if [ ! -x "$build/host/bin/ecl" ]; then
  echo "== building host ECL"
  rm -rf "$build/ecl-host"
  cp -a "$ecl_src" "$build/ecl-host"
  ( cd "$build/ecl-host" \
    && ./configure --prefix="$build/host" \
    && make -j"$jobs" \
    && make install )
fi

# 2. ECL for wasm32-unknown-emscripten, sized and compiled for a browser.
if [ ! -f "$web/wasm/libecl.a" ]; then
  echo "== building ECL for wasm (web)"
  rm -rf "$web/ecl-target" "$web/wasm"
  cp -a "$ecl_src" "$web/ecl-target"

  sed -i "s/-sSTACK_SIZE=1048576/-sSTACK_SIZE=$stack_bytes/" \
      "$web/ecl-target/src/configure"
  sed -i "s/ECL_DEFAULT_C_STACK_SIZE=1048576/ECL_DEFAULT_C_STACK_SIZE=$stack_bytes/" \
      "$web/ecl-target/src/configure"
  # ECL's wasm configuration pins -O0; the shipped browser builds use -O2,
  # which shrinks the frames substantially.
  sed -i "s/-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -O0/-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -O2/" \
      "$web/ecl-target/src/configure"

  if ! grep -q -- "-sSTACK_SIZE=$stack_bytes" "$web/ecl-target/src/configure"; then
    echo "wasm/build-web.sh: ECL's configure no longer matches the sed patterns" >&2
    exit 1
  fi
  if grep -q -- "-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -O0" "$web/ecl-target/src/configure"; then
    echo "wasm/build-web.sh: could not raise ECL's wasm optimisation level" >&2
    exit 1
  fi

  ( cd "$web/ecl-target" \
    && ECL_TO_RUN="$build/host/bin/ecl" \
       CFLAGS="-fwasm-exceptions -O2" \
       LDFLAGS="-fwasm-exceptions -sSUPPORT_LONGJMP=wasm -sALLOW_MEMORY_GROWTH=1" \
       emconfigure ./configure \
         --host=wasm32-unknown-emscripten \
         --build="$(cc -dumpmachine)" \
         --with-cross-config="$web/ecl-target/src/util/wasm32-unknown-emscripten.cross_config" \
         --prefix="$web/wasm" \
         --disable-shared --with-tcp=no --with-cmp=no \
         ac_cv_have_decl_RLIMIT_STACK=no \
    && emmake make -j"$jobs" \
    && emmake make flatinstall )
fi

# 3. Cross-compile the kernel and the driver for the web target.
echo "== cross-compiling milawa.lsp"
MILAWA_WASM_BUILD="$web" \
MILAWA_WASM_TARGET_INFO="$web/ecl-target/build/target-info.lsp" \
MILAWA_WASM_KERNEL="$milawa/milawa.lsp" \
MILAWA_WASM_DRIVER="$here/run.lisp" \
  "$build/host/bin/ecl" -norc -load "$here/build-kernel.lisp"

# 4. Link the browser module.  The module's init function names contain a
#    hash, so they are extracted from the objects instead of being hard-coded.
nm=${MILAWA_WASM_NM:-$(command -v llvm-nm || command -v llvm-nm-19)}
init=$("$nm" "$web/milawa.o" | awk '$3 ~ /^__ecl_init/ { print $3; exit }')
run_init=$("$nm" "$web/run.o" | awk '$3 ~ /^__ecl_init/ { print $3; exit }')
if [ -z "$init" ] || [ -z "$run_init" ]; then
  echo "wasm/build-web.sh: could not find the module init symbols" >&2
  exit 1
fi
{
  printf '#define MILAWA_INIT %s\nextern void MILAWA_INIT(cl_object);\n' "$init"
  printf '#define DRIVER_INIT %s\nextern void DRIVER_INIT(cl_object);\n' "$run_init"
} > "$web/milawa-init.h"

echo "== linking milawa-wasm (web)"
emcc -o "$web/milawa-wasm.js" \
     -I"$web/wasm" -I"$web" \
     "$here/milawa-wasm.c" "$web/milawa.o" "$web/run.o" \
     -L"$web/wasm" -lecl -leclgc -leclgmp -lm \
     -fwasm-exceptions \
     -sSUPPORT_LONGJMP=wasm \
     -sALLOW_MEMORY_GROWTH=1 \
     -sMAXIMUM_MEMORY=4GB \
     -sSTACK_SIZE="$stack_bytes" \
     -sINITIAL_MEMORY="$initial_memory" \
     -sFORCE_FILESYSTEM=1 \
     -sENVIRONMENT=web,worker,node \
     -sMODULARIZE=1 -sINVOKE_RUN=0 \
     -sEXPORTED_RUNTIME_METHODS=FS,callMain,ccall \
     --profiling-funcs \
     -sBINARYEN_EXTRA_PASSES=--spill-pointers,--strip-debug \
     -sERROR_ON_UNDEFINED_SYMBOLS=0

echo "== done: $web/milawa-wasm.js"
