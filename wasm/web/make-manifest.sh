#!/bin/sh
# Generate wasm/web/files.json, the list of files the browser harness copies
# into its in-memory filesystem before starting ACL2, plus gzipped copies of
# them in wasm/web/files/.  40 MB of sources and compiled files is a lot to
# pull through a dev-container port forward; gzip makes it ~9 MB.
#
# Usage:
#
#   ./wasm/web/make-manifest.sh                      # ACL2 only + fact book
#   ./wasm/web/make-manifest.sh textbook/chap10/fact arithmetic/top
#
# Each book argument is a path under books/ (no extension); its .lisp, .cert
# and .fasc are included when present.

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
OUT=${OUT:-$HERE/files.json}
STAGE=$HERE/files

if [ $# -eq 0 ]; then
  set -- textbook/chap10/fact
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"

first=1
emit() {
  if [ "$first" = 1 ]; then first=0; else printf ',\n'; fi
  printf '  {"src": "%s", "dst": "%s"}' "$1" "$2"
}

# One packed file per payload file: fetch and decompress are per file, so a
# retry stays cheap.
pack() {
  src=$1
  dst=$2
  name=$(printf '%s' "$dst" | sed 's|^/||; s|/|_|g')
  gzip -9 -c "$src" > "$STAGE/$name.gz"
  emit "/wasm/web/files/$name.gz" "$dst"
}

{
  printf '[\n'
  # ACL2 itself: initialize-acl2 ld's the sources, so both are needed.
  #
  # One exception: Chrome refuses to compile a wasm module larger than 8 MB
  # synchronously on the main thread, and doc.fasc is 8,418,742 bytes -- 30 KB
  # over.  The page has to use the main thread (a worker gets half the stack),
  # so ship the bytecode build of that one file instead; the load hook
  # dispatches on the file's magic, so a tree of modules may contain it.
  BYTECODE=${BYTECODE:-/opt/eclwasm/bytecode}
  for f in "$ROOT"/*.lisp "$ROOT"/*.fasc; do
    b=${f##*/}
    src=$f
    if [ "$b" = "doc.fasc" ] && [ -f "$BYTECODE/doc.fasc" ]; then
      src="$BYTECODE/doc.fasc"
    fi
    pack "$src" "/acl2/$b"
  done
  pack "$HERE/acl2-web.lsp" "/acl2/web-acl2.lsp"
  # The world-image replay: the web wrapper, the shared driver, and the image
  # the driver installs.  The image is built by ACL2_WRITE_WORLD_IMAGE in
  # wasm/acl2-wasm.lsp; WORLD_IMAGE overrides where it is read from.
  pack "$HERE/replay-web.lsp" "/acl2/web-replay.lsp"
  pack "$ROOT/wasm/world-replay.lsp" "/acl2/wasm/world-replay.lsp"
  if [ -f "${WORLD_IMAGE:-/tmp/world2.ser}" ]; then
    pack "${WORLD_IMAGE:-/tmp/world2.ser}" "/acl2/world-image.ser"
  else
    echo "warning: no world image at ${WORLD_IMAGE:-/tmp/world2.ser}" >&2
  fi
  # Book bundles.
  for book in "$@"; do
    for ext in lisp cert fasc; do
      if [ -f "$ROOT/books/$book.$ext" ]; then
        pack "$ROOT/books/$book.$ext" "/acl2/books/$book.$ext"
      elif [ "$ext" != lisp ]; then
        echo "note: books/$book.$ext not present (not certified?)" >&2
      fi
    done
  done
  printf '\n]\n'
} > "$OUT"

packed=$(du -sb "$STAGE" | cut -f1)
echo "wrote $OUT ($(grep -c 'src' "$OUT") entries, $((packed / 1048576)) MB packed)"
