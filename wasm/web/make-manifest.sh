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
  # Default: the books ACL2 itself reports for (include-book "projects/apply/top"
  # :dir :system) -- see books.txt, which says where the list comes from.
  set -- $(grep -v '^#' "$HERE/books.txt" | grep -v '^$')
fi

rm -rf "$STAGE"
mkdir -p "$STAGE"

first=1
emit() {
  if [ "$first" = 1 ]; then first=0; else printf ',\n'; fi
  printf '  {"src": "%s", "dst": "%s"}' "$1" "$2"
}
emit_mtime() {
  if [ "$first" = 1 ]; then first=0; else printf ',\n'; fi
  printf '  {"src": "%s", "dst": "%s", "mtime": %s}' "$1" "$2" "$3"
}

# One packed file per payload file: fetch and decompress are per file, so a
# retry stays cheap.
pack() {
  src=$1
  dst=$2
  name=$(printf '%s' "$dst" | sed 's|^/||; s|/|_|g')
  gzip -9 -c "$src" > "$STAGE/$name.gz"
  # The mtime travels with the file.  include-book's book-hash is
  # ((:BOOK-LENGTH . n) (:BOOK-WRITE-DATE . t)), so a book unpacked into MEMFS
  # with today's date is 'Uncertified' and every include-book of it fails.  The
  # harness puts this back with FS.utimes.
  mtime=$(stat -c %Y "$src" 2>/dev/null || stat -f %m "$src")
  emit_mtime "/wasm/web/files/$name.gz" "$dst" "$mtime"
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

# ---------------------------------------------------------------------------
# books.html: the book list, as a page.
#
# "What can I include-book?" should be answerable from the site, not from a
# shell command over files.json.  Generated here, with the manifest, so the
# page cannot drift from what is actually shipped: a book is includable only
# when its .cert and its wasm .fasc are both present.
# ---------------------------------------------------------------------------
LISTING=$(mktemp)
for book in "$@"; do
  if [ -f "$ROOT/books/$book.cert" ] && [ -f "$ROOT/books/$book.fasc" ]; then
    printf '%s\tcertified\n' "$book" >> "$LISTING"
  else
    printf '%s\tsource-only\n' "$book" >> "$LISTING"
  fi
done
sort -o "$LISTING" "$LISTING"
certified=$(awk -F'\t' '$2 == "certified"' "$LISTING" | wc -l)
total=$(wc -l < "$LISTING")

{
  cat <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Books in the ACL2-in-the-browser payload</title>
<style>
  body { font-family: system-ui, sans-serif; margin: 0 auto; padding: 2rem 1rem;
         max-width: 52rem; background: #10131a; color: #d6dbe5;
         line-height: 1.55; }
  h1 { font-size: 1.4rem; margin: 0 0 .25rem; }
  p { font-size: .92rem; }
  code { font-family: ui-monospace, monospace; font-size: .85rem; }
  .lede { color: #9aa7ba; margin: 0 0 1.5rem; }
  table { border-collapse: collapse; font-size: .85rem; width: 100%; }
  th, td { text-align: left; padding: .3rem .75rem .3rem 0;
           border-bottom: 1px solid #222b38; vertical-align: top; }
  td.form { white-space: nowrap; }
  tr.source-only td { color: #9aa7ba; }
  .ok { color: #6fcf97; }
  a { color: #7fb2ff; }
</style>
</head>
<body>
<h1>Books the browser payload can include</h1>
<p class="lede">Generated from the payload manifest when the site is built, so
this is what is present, not what is intended. A book is includable when both
its <code>.cert</code> (ACL2's certificate) and its wasm <code>.fasc</code>
(compiled from ACL2's own expansion file) are shipped.</p>
<p>Type any line below at the prompt in
<a href="acl2-main.html">ACL2 in the browser</a>. <code>:dir :system</code>
resolves to the payload's <code>books/</code> tree. <code>include-book</code>
may be used as often as you like in one session; it is <em>certification</em>,
not inclusion, that is limited to one book per ACL2 session.</p>
HEAD
  printf '<p class="ok">%s of %s books certified and compiled.</p>\n' \
    "$certified" "$total"
  cat <<'TABLE'
<table>
  <tr><th>book</th><th>form</th></tr>
TABLE
  while IFS='	' read -r book status; do
    if [ "$status" = certified ]; then
      printf '  <tr><td><code>%s</code></td><td class="form"><code>(include-book "%s" :dir :system)</code></td></tr>\n' \
        "$book" "$book"
    else
      printf '  <tr class="source-only"><td><code>%s</code></td><td>source only -- no <code>.cert</code> or no wasm <code>.fasc</code>; not includable</td></tr>\n' \
        "$book"
    fi
  done < "$LISTING"
  cat <<'TAIL'
</table>
<p><b>Stack.</b> Including a book loads its compiled module, and a Chrome page
has about 1 MB of engine stack for that. The tutorial books and the small
<code>system/</code> and <code>tools/</code> books fit. Two do not, measured:
<code>projects/apply/base</code> needs ~1.05 MB and
<code>projects/apply/top</code> ~1.09 MB, so in Chrome they are refused with a
message; a Firefox page has about three times Chrome's stack and loads them
(<code>top</code> takes 4.4 s there). This is a limit of the engine's recursion
while loading a module, not of the book's own events.</p>
<p>Not every book in ACL2's community <code>books/</code> tree is here: each
one has to be certified and compiled ahead of time, and the page preloads the
whole list into memory. The list is
<code>wasm/web/books.txt</code> in the port; adding a book is
<code>wasm/certify-books.sh</code>, <code>wasm/aot-book.sh</code>, one line in
that file, and a rebuild of the payload. Thinking in terms of a book set per
use case is the right shape: this payload is one such set.</p>
<p><a href="index.html">back to the front page</a></p>
</body>
</html>
TAIL
} > "$HERE/books.html"
rm -f "$LISTING"
echo "wrote $HERE/books.html ($certified of $total books certified)"
