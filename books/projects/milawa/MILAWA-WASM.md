# Running the Milawa checker on WebAssembly

Milawa's standalone checker (`milawa.lsp`) is a Common Lisp program, so it can
run under WebAssembly using ECL compiled for `wasm32-unknown-emscripten`, as
described in Daniel Kochmański's
[*Common Lisp and WebAssembly*](https://turtleware.eu/posts/Common-Lisp-and-WebAssembly.html).
This directory holds the pieces needed to do that; the result is a Node program
that behaves like `milawa-ecl`: it restores an image's state and replays an
`.events` file.

## Prerequisites

- `emscripten` (`emcc`, `emconfigure`, `emmake`) and `nodejs`
  (`apt install emscripten nodejs` is enough; the Ubuntu packages include
  Binaryen and `llvm-nm`)
- `git`, `make`, and a native C toolchain
- ECL sources: the fork at <https://gitlab.com/jimwhite/ecl> is used by
  default (set `MILAWA_ECL_SRC` to reuse a clone, or `MILAWA_ECL_URL` to point
  somewhere else)

## Building

```sh
cd books/projects/milawa
./wasm/build.sh
```

Everything is built under `.wasm-build/` (override with `MILAWA_WASM_BUILD`):

1. a native ECL (the cross-compiler),
2. ECL configured with `--host=wasm32-unknown-emscripten`, `--disable-shared
   --with-tcp=no --with-cmp=no` and ECL's own
   `src/util/wasm32-unknown-emscripten.cross_config`,
3. `milawa.o` and `run.o`, the kernel and the driver (see below)
   cross-compiled for the target, with `milawa.lsp`'s `defun-comp` expanding
   to plain definitions so that the target compiler actually compiles them,
4. `milawa-wasm.js` / `milawa-wasm.wasm`, linked from `milawa-wasm.c`,
   `milawa.o` and the wasm ECL libraries.

The build takes a few minutes; ECL itself is the slow part.

### Why ECL is patched

Emscripten implements `setrlimit` as a stub, so ECL's C stack size is fixed
when ECL is compiled.  `build.sh` raises it in the copy of ECL that is built
for the target: `ECL_DEFAULT_C_STACK_SIZE` and `-sSTACK_SIZE` are both set to
1 GB (override with `MILAWA_WASM_C_STACK`), and `ac_cv_have_decl_RLIMIT_STACK=no`
keeps ECL from thinking it can resize the stack at run time.  Level10 needs
more than 64 MB natively, and the compiled wasm frames are bigger, so the
default 1 MB would not get far.

## Running

```sh
# an image made by the native ECL checker works as-is ...
./milawa-wasm base.ecl-linux-aarch64 < Proofs/utilities.events

# ... or copy it so that later, wasm-built images get their own names
cp -r base.ecl-linux-aarch64 base.wasm
./milawa-wasm base.wasm < Proofs/utilities.events   # writes utilities.wasm/
```

The extension is taken from the image directory name and is used at `FINISH`,
exactly as in `milawa-ecl`, and the state format is shared: an image written
by native ECL can be continued under wasm and vice versa.

Because `milawa-wasm` reads standard input when no events file is given, it
plugs into `final-checks.sh`:

```sh
cp -r base.ecl-linux-aarch64 base.wasm
./final-checks.sh wasm wasm
```

(`final-checks.sh` requires `base.<ext>`, so seed the first image.)

The V8 and OS stacks are raised by the launcher, because ECL's `apply` path
crosses back into JavaScript; see `MILAWA_WASM_OS_STACK` and
`MILAWA_WASM_JS_STACK` in the script.

## How it works

- `wasm/build-kernel.lisp` cross-compiles `milawa.lsp` with the host ECL and a
  `target-info.lsp` from the wasm build.  Two details matter:
  - `compile-file` does not run `(import ...)` at compile time, but the reader
    switches to the `MILAWA` package part way through the file, so the script
    creates that package with the same imports first.  Without this, `NIL` and
    friends would be interned as `MILAWA::NIL` and the constants would not
    match the symbols in the proof files.
  - The `:milawa-cross-compiling` feature makes `defun-comp` expand to `defun`
    instead of `(compile (defun ...))`; otherwise the definitions would be
    compiled again at startup, by ECL's bytecodes compiler.
- `wasm/milawa-wasm.c` boots ECL with `argc = 1` (so ECL does not treat the
  paths as Lisp files), sets `*loading-image*` so the kernel does not dump a
  base image, installs the bytecodes compiler (for the definitions that
  `DEFINE` events create at run time), initializes the two compiled modules,
  and calls `milawa-wasm-run` with the image directory, its extension, and
  the events file.
- `wasm/run.lisp` is that driver: it restores `<image>/state.lisp` and then
  reads and executes commands.  It handles `FINISH` itself by calling
  `dump-ecl-image` rather than going through `save-and-exit`, because that
  ends with `(quit)`, and ECL's `quit` unwinds to the bottom of its own
  toplevel -- an unwind that does not exist in this embedding and crashes
  under emscripten.  Milawa's `main` is not used for the same reason (it
  quits at end of input).
- `wasm/pre.js` mounts the real filesystem with `NODEFS` at `/real` and starts
  there.  `-sNODERAWFS` looks simpler, but its `select()` has no poll
  operations for the standard streams, and ECL's `LISTEN` on them fails.
  Absolute paths are redirected into `/real` by the C driver.

## Performance and limitations

- The kernel is compiled, so this is far faster than loading `milawa.lsp` and
  letting ECL's bytecodes compiler handle it, but the wasm build of ECL uses
  `-O0` (ECL's emscripten configuration does) and ECL itself is much slower
  than CCL.  Expect a level to take several times longer than the same level
  under native ECL.
- The stack is fixed when the program is linked; there is no `setrlimit` under
  wasm and so no automatic growth.  If a proof needs more than
  `MILAWA_WASM_C_STACK`, rebuild with a larger value.
- Only the checker is supported.  Building ACL2 for wasm is a much larger
  project and is not attempted here.
