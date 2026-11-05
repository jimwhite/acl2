#!/usr/bin/env bash
#
# Build ECL for WebAssembly (Emscripten) so that ACL2 can run under Node.js.
#
# This does two builds of the same ECL source tree:
#
#   1. a native "host" ECL, used only as a cross-compilation driver, and
#   2. a wasm32-unknown-emscripten ECL, whose Lisp core is cross-compiled by
#      the host ECL and compiled to wasm by Emscripten.
#
# The result is a JavaScript loader plus a wasm module:
#
#   $WORK/dist/node-raw/ecl.js
#   $WORK/dist/node-raw/ecl.wasm
#
# See WASM-PORT-NOTES.md for the reasoning behind each flag.
#
# Usage:
#
#   ECL_SRC=/path/to/ecl-source ./wasm/build-ecl-wasm.sh
#
# Environment variables:
#
#   ECL_SRC      ECL source tree (required; must match the host ECL version)
#   WORK         build/install root (default /opt/eclwasm)
#   EMSDK_DIR    Emscripten SDK (default /opt/emsdk)
#   JOBS         parallel make jobs (default: nproc)
#   REBUILD      1 to rebuild the host ECL even if it is installed
#
set -euo pipefail

: "${ECL_SRC:?Set ECL_SRC to the ECL source tree}"
WORK=${WORK:-/opt/eclwasm}
EMSDK_DIR=${EMSDK_DIR:-/opt/emsdk}
JOBS=${JOBS:-$(nproc)}
REBUILD=${REBUILD:-0}

HOST_PREFIX=$WORK/ecl-host
NODE_PREFIX=$WORK/ecl-node
NODE_SRC=$WORK/ecl-node-src
DIST=$WORK/dist/node-raw
CROSS_CONFIG=$WORK/wasm32.cross_config

# Emscripten settings for the wasm build.
#
#   -fwasm-exceptions -mllvm -wasm-use-legacy-eh=false
#       ECL uses setjmp/longjmp for its condition system.  Without these,
#       Emscripten compiles every setjmp into a call to a JavaScript
#       trampoline (env::invoke_*), which both costs a JS frame per
#       interpreted call and prevents the module from ever running outside a
#       JS engine.
#   -sSUPPORT_LONGJMP=wasm
#       Use the wasm-based longjmp implementation that matches the above.
#   -sNODERAWFS=1
#       Give the module the real host filesystem (ACL2 must read sources and
#       write .fasc/.cert files).  Without this, Node's MEMFS is empty.
#   -sSTACK_SIZE=1.5GB, -sINITIAL_MEMORY=2GB, -sMAXIMUM_MEMORY=4GB
#       ACL2's bootstrap recurses far more deeply than any normal program.
#       The C stack must also cover V8's stack-size setting used by the
#       launcher (see wasm/acl2-wasm).
#   -sEXIT_RUNTIME=1
#       (quit) must really exit the Node process.
WFLAGS="-fwasm-exceptions -mllvm -wasm-use-legacy-eh=false \
-sSUPPORT_LONGJMP=wasm -sNODERAWFS=1 -sALLOW_MEMORY_GROWTH=1 \
-sMAXIMUM_MEMORY=4GB -sSTACK_SIZE=1610612736 -sINITIAL_MEMORY=2147483648 \
-sEXIT_RUNTIME=1"
EHFLAGS="-fwasm-exceptions -mllvm -wasm-use-legacy-eh=false"

log() { printf '\n=== %s ===\n' "$*" >&2; }

if [ ! -f "$EMSDK_DIR/emsdk_env.sh" ]; then
  echo "error: Emscripten SDK not found at $EMSDK_DIR" >&2
  echo "       git clone https://github.com/emscripten-core/emsdk.git $EMSDK_DIR" >&2
  echo "       cd $EMSDK_DIR && ./emsdk install latest && ./emsdk activate latest" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$EMSDK_DIR/emsdk_env.sh" >/dev/null 2>&1

# ---------------------------------------------------------------------------
# Cross-compilation configuration
# ---------------------------------------------------------------------------
#
# ECL's configure accepts a shell-sourceable "cross config" describing the
# target ABI.  The shipped wasm32 config does not set ECL_TO_RUN, so configure
# tries to run an empty command and fails with "-norc: command not found".
# Append the host ECL path.

if [ ! -f "$CROSS_CONFIG" ]; then
  cp "$ECL_SRC/src/util/wasm32-unknown-emscripten.cross_config" "$CROSS_CONFIG"
  echo "ECL_TO_RUN=$HOST_PREFIX/bin/ecl" >> "$CROSS_CONFIG"
fi

# ---------------------------------------------------------------------------
# Host ECL
# ---------------------------------------------------------------------------

if [ "$REBUILD" = 1 ] || [ ! -x "$HOST_PREFIX/bin/ecl" ]; then
  log "Building host ECL in $WORK/ecl-host-src"
  rm -rf "$WORK/ecl-host-src"
  mkdir -p "$WORK/ecl-host-src"
  tar -C "$ECL_SRC" -cf - --exclude='./build' --exclude='./.git' . |
    tar -C "$WORK/ecl-host-src" -xf -
  (
    cd "$WORK/ecl-host-src"
    ./configure --prefix="$HOST_PREFIX" > "$WORK/ecl-host-configure.log" 2>&1
    make -j"$JOBS" > "$WORK/ecl-host-make.log" 2>&1
    make install > "$WORK/ecl-host-install.log" 2>&1
  )
fi

export PATH="$HOST_PREFIX/bin:$PATH"

# ---------------------------------------------------------------------------
# Target (wasm) ECL
# ---------------------------------------------------------------------------
#
# Start from a pristine copy of the sources: emconfigure and emmake write into
# the source tree, and configure's results are not reusable between the host
# and target builds.

log "Copying ECL sources to $NODE_SRC"
rm -rf "$NODE_SRC"
mkdir -p "$NODE_SRC"
tar -C "$ECL_SRC" -cf - --exclude='./build' --exclude='./.git' . |
  tar -C "$NODE_SRC" -xf -

# The target Lisp->C compiler is disabled (--with-cmp=no): ACL2 only needs the
# C-implemented bytecodes compiler, and the native compiler cannot spawn a C
# compiler inside the browser anyway.

log "Applying ECL wasm patches"
for p in "$(dirname "$0")/ecl-patches"/*.patch; do
  [ -e "$p" ] || continue
  patch -d "$NODE_SRC" -p1 < "$p"
done

# Put the wasm link settings where COMPILER::BUILD-PROGRAM will find them.
# They cannot be passed to configure as LDFLAGS: configure links a test
# program for every feature check, and each of those links would then run a
# full Emscripten link with a 640 MB initial memory.  Two files need the
# change because build/compile.lsp overrides the value recorded in
# build/cmp/cmpdefs.lsp.

sed -i "s|^(defconfig \*ld-flags\* \"@LDFLAGS@\")|(defconfig *ld-flags* \"@LDFLAGS@ $WFLAGS\")|" \
  "$NODE_SRC/src/cmp/cmpdefs.lsp"
sed -i "s|^(setf c::\*ld-flags\* \"@LDFLAGS@\")|(setf c::*ld-flags* \"@LDFLAGS@ $WFLAGS\")|" \
  "$NODE_SRC/src/compile.lsp.in"

if ! grep -q NODERAWFS "$NODE_SRC/src/cmp/cmpdefs.lsp" ||
   ! grep -q NODERAWFS "$NODE_SRC/src/compile.lsp.in"; then
  echo "error: failed to patch ECL's linker flags (source layout changed?)" >&2
  exit 1
fi

# ECL's configure hard-codes -O0 for wasm32-unknown-emscripten, with a note
# that non-zero optimization levels are slower together with the binaryen
# spill-pointers pass.  Measurements here disagree in the direction that
# matters most: at -O0 the interpreter needs roughly 5-10 KB of C stack per
# interpreted frame in wasm, so ACL2's bootstrap exhausts any practical stack.
# -O2 shrinks the frames substantially (and runs faster).
sed -i 's|-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -O0|-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -O2|' \
  "$NODE_SRC/src/configure"

log "Configuring the wasm target"
(
  cd "$NODE_SRC"
  # CC_FOR_BUILD: GMP builds host-side generators; without this it picks the
  # wasm-targeting clang from the Emscripten PATH and the build fails with
  # "Specified HOST_CC doesn't seem to work".
  #
  # CFLAGS: the exception flags must apply to every object, including the
  # files ECL generates for the Lisp library and the compiler.
  #
  # </dev/null: on error the ECL build script drops into an interactive
  # debugger and make would wait forever.
  CC_FOR_BUILD=gcc \
  ECL_TO_RUN="$HOST_PREFIX/bin/ecl" \
  CFLAGS="$EHFLAGS" \
    emconfigure ./configure \
      --host=wasm32-unknown-emscripten \
      --build="$(uname -m)-unknown-linux-gnu" \
      --with-cross-config="$CROSS_CONFIG" \
      --prefix="$NODE_PREFIX" \
      --disable-shared --with-tcp=no --with-cmp=no \
      > "$WORK/ecl-node-configure.log" 2>&1

  log "Building the wasm target"
  emmake make -j"$JOBS" </dev/null > "$WORK/ecl-node-make.log" 2>&1

  log "Installing the wasm target to $NODE_PREFIX"
  emmake make install </dev/null >> "$WORK/ecl-node-make.log" 2>&1
)

mkdir -p "$DIST"
cp "$NODE_SRC/build/bin/ecl.js" "$NODE_SRC/build/bin/ecl.wasm" "$DIST/"

log "Done"
echo "wasm ECL: $DIST/ecl.js and $DIST/ecl.wasm"
echo "run ACL2 with: ./wasm/acl2-wasm"
