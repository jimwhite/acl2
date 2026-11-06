# ACL2 in a browser (experimental)

A page that loads the WebAssembly ECL build with an in-memory filesystem,
preloads the ACL2 sources and compiled files into it, and drives ACL2 from a
script.  Two pages:

- `smoke.html` -- ECL only: instantiates the module and evaluates
  `(+ 1 2)` / `(print 42)`.  Takes about a second.  **This works.**
- `index.html` -- ACL2: preloads ~40 MB (9 MB gzipped) and runs the driver
  `acl2-web.lsp`.  **This currently stops** in `load-acl2` with
  `RangeError: Maximum call stack size exceeded`; see "Browser, first attempt"
  in `WASM-PORT-NOTES.md` for the measurements.  In short: the boot-strap needs
  a raised V8 stack (between 128 MB and 512 MB of native stack in the Node
  build), and a page cannot ask for that, so the browser needs a prepared base
  (the snapshot/world-image work) rather than a boot-strap.

## Build the module

```sh
WEB=1 ECL_SRC=/path/to/ecl ./wasm/build-ecl-wasm.sh
# -> /opt/eclwasm/dist/web/{ecl.js,ecl.wasm}
cp /opt/eclwasm/dist/web/ecl.js   wasm/web/lib/ecl-1536.js
cp /opt/eclwasm/dist/web/ecl.wasm wasm/web/lib/ecl-1536.wasm
```

`WEB_STACK_MB` and `WEB_MEMORY_MB` (default 512/1024) size the module; the
values above (from a `WEB_STACK_MB=1536 WEB_MEMORY_MB=2048` build, hence the
`-1536` in the file names) carry over from the Node build, since the wasm stack
turned out not to be the constraint.

## Generate the payload and serve it

```sh
./wasm/web/make-manifest.sh                       # ACL2 + textbook/chap10/fact
./wasm/web/make-manifest.sh arithmetic/top ...    # other bundles
python3 -m http.server 8765 --directory .         # serve the repository root
```

Then open `http://localhost:8765/wasm/web/smoke.html` or `.../index.html`.
`make-manifest.sh` writes gzipped copies into `wasm/web/files/` and the list the
harness fetches into `wasm/web/files.json`; both are generated and git-ignored.

## Notes for whoever picks this up

- The worker fetches everything itself: inside a worker, Emscripten cannot
  locate the module, so `locateFile` is set explicitly and the payload is
  fetched with retries (the dev-container port forward truncates some
  responses).
- A page has no environment: `ACL2_SMALL_FIXNUMS` and `ACL2_SNAPSHOT_INFO` are
  set with `ext:setenv` at the top of `acl2-web.lsp`.
- ACL2 reads its commands from stdin; the worker passes a `stdin` callback that
  feeds `demo.lsp`.  Interactive use would need a queue and a way to run the
  loop without blocking the worker's message pump.
