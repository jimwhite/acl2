#!/bin/sh
# Stage the browser harness into a directory that can be published as a static
# site (the gh-pages branch).  Everything is copied flat: the site root is the
# branch root, so the pages, worker.js, lib/ and files/ are siblings.
#
#   ./wasm/web/publish-gh-pages.sh /path/to/gh-pages-worktree
#
# Prerequisites, all of which the build already produces:
#
#   /opt/eclwasm/dist/web-dylink/{ecl.js,ecl.wasm}   WEB=1 DYLINK=1 build
#   wasm/web/files.json, wasm/web/files/            from make-manifest.sh
#   wasm/web/files/dylink-test.fas                  built by aot-book.sh
#
# The dynamic-linking build is used for every page, so only one copy of the
# module is shipped.

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
DEST=${1:-}
if [ -z "$DEST" ]; then
  echo "usage: $0 <destination directory>" >&2
  exit 2
fi

if [ ! -f "$HERE/files.json" ]; then
  echo "publish: no $HERE/files.json; run wasm/web/make-manifest.sh first" >&2
  exit 1
fi

mkdir -p "$DEST/lib" "$DEST/files"

# Pages.  index-gh.html becomes the site root.
cp "$HERE/index-gh.html" "$DEST/index.html"
cp "$HERE/smoke.html" "$DEST/smoke.html"
cp "$HERE/dylink.html" "$DEST/dylink.html"
cp "$HERE/acl2.html" "$DEST/acl2.html"

# One worker, pointed at the dynamic-linking build for every mode, so the site
# does not have to carry two copies of the ECL module.
sed -e "s|lib/ecl-1536\.js|lib/ecl-dylink.js|g" \
    -e "s|lib/ecl-1536\.|lib/ecl-dylink.|g" \
    "$HERE/worker.js" > "$DEST/worker.js"

cp /opt/eclwasm/dist/web-dylink/ecl.js "$DEST/lib/ecl-dylink.js"
cp /opt/eclwasm/dist/web-dylink/ecl.wasm "$DEST/lib/ecl-dylink.wasm"

# The preloaded ACL2 tree (already gzipped, see make-manifest.sh) and its list.
cp "$HERE/files.json" "$DEST/files.json"
cp "$HERE/files"/*.gz "$DEST/files/"

# The module the dynamic-linking page loads, if it is present.
if [ -f "$HERE/files/dylink-test.fas" ]; then
  cp "$HERE/files/dylink-test.fas" "$DEST/files/dylink-test.fas"
fi

# GitHub Pages runs Jekyll unless told not to; it is not wanted here.
: > "$DEST/.nojekyll"

echo "staged $(find "$DEST" -type f | wc -l) files, $(du -sh "$DEST" | cut -f1) in $DEST"
