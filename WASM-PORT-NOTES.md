# Porting ACL2 to WebAssembly

Last updated: 2026-11-05
Branch: `ecl` (this document describes the `ecl-wasm` work, now merged into
`ecl`; the native ECL port is in `ECL-PORT-NOTES.md`)

This document describes running ACL2 on ECL compiled to WebAssembly with
Emscripten, and running the result under Node.js. It is a work log: several
obstacles below are Emscripten or ECL limitations rather than ACL2 problems,
and some may be lifted by upstream work.

## Status

| Piece | Status |
| --- | --- |
| ECL 26.5.5 cross-compiled to `wasm32-unknown-emscripten` | works |
| ECL wasm under Node.js (real filesystem) | works |
| ECL wasm under Wasmtime | starts, aborts: the standalone Emscripten runtime has no `getcwd`/filesystem (see below) |
| ACL2 `compile-acl2` in wasm (82 source files to `.fasc`) | works, ~1 minute |
| ACL2 `initialize-acl2` in wasm | works, ~7 minutes (measured before the boot-strap fix of 2026-11-05; see "Next steps") |
| `defun`, `thm`, induction proofs in the ACL2 loop | works |
| Book certification (`cert.pl`) in wasm | not tried yet |
| Browser (no Node) | not started (needs a filesystem layer and a way to feed the loop) |

Startup is slow because ECL cannot dump an image: every start loads the
compiled sources and re-runs `initialize-acl2` (about 18 s natively, about
7 minutes in wasm). This is the architectural limitation described in
`ECL-PORT-NOTES.md`, amplified by the interpreter and compiler being several
times slower in wasm.

## Toolchain

* Emscripten SDK (6.0.13 at the time of writing) — <https://emscripten.org>
* Node.js (the one shipped with the SDK is fine) — the only runtime used today
* A native ECL built from the *same source tree*, used as the cross-compilation
  driver. ECL refuses to cross-compile if the versions differ.

Wasmtime is not used yet; see the last section for why.

## Building

```sh
git clone https://github.com/emscripten-core/emsdk.git /opt/emsdk
cd /opt/emsdk && ./emsdk install latest && ./emsdk activate latest

# ECL_SRC must point at an ECL tree that already contains the native port
# patch (widened bytecode operands).
ECL_SRC=/path/to/ecl ./wasm/build-ecl-wasm.sh
```

The script builds, in order:

1. `$WORK/ecl-host` — a native ECL, used only as the cross compiler.
2. `$WORK/ecl-node-src` — the wasm target, configured with
   `--host=wasm32-unknown-emscripten --disable-shared --with-cmp=no`.
3. `$WORK/dist/node-raw/ecl.js` and `ecl.wasm` — the artefacts ACL2 uses.

Then

```sh
echo '(defun triple (x) (* 3 x))' | ./wasm/acl2-wasm
```

starts ACL2. `wasm/acl2-wasm` sets the stack limits (see below), points
`ACL2_WASM_DIR` at the ACL2 source directory, and loads
`wasm/acl2-wasm.lsp`, which is the wasm analogue of `nsaved_acl2.lsp`.

## Design decisions

### `--with-cmp=no`: the bytecodes compiler is the only compiler

ECL's default compiler emits C and spawns a C compiler; there is no C compiler
inside wasm. `ext:install-bytecodes-compiler` is implemented in C inside
`libecl`, so it is always available and is the only compiler in this build.
Consequences:

* ACL2 must not restore the C compiler at the end of initialization, and must
  use the bytecodes compiler for its on-the-fly `compile`/`compile-file`.
* `*compiled-file-extension*` is `"fasc"` and `load-compiled` loads portable
  bytecode files.
* Portable `.fasc` files are *not* portable across fixnum widths: a `.fasc`
  built by a native (62-bit fixnum) ECL fails to load in the wasm (30-bit
  fixnum) ECL with `536870912 is not of type fixnum`. So ACL2's sources must be
  compiled *by the wasm ECL itself*; the build is not host-compiled.

### Emscripten flags

All are set by `wasm/build-ecl-wasm.sh`. The link settings are written into
`src/cmp/cmpdefs.lsp` and `src/compile.lsp.in` (both are used by
`compiler::build-program`) rather than passed as `LDFLAGS` to configure,
because configure links a test program for every feature check and each of
those links would then run a full Emscripten link with a 2 GB initial memory.

| Flag | Why |
| --- | --- |
| `-fwasm-exceptions -mllvm -wasm-use-legacy-eh=false` | ECL implements its condition system with `setjmp`/`longjmp`. Without these, every `setjmp` becomes a call into JavaScript (`env::invoke_*`), which adds a JS frame to every interpreted call and makes the module unusable outside a JS engine. |
| `-sSUPPORT_LONGJMP=wasm` | Selects the wasm `longjmp` matching the above. On its own, LLVM emits *legacy* `try` instructions, which Wasmtime 50 rejects; `-mllvm -wasm-use-legacy-eh=false` emits `try_table` instead. |
| `-sNODERAWFS=1` | Gives the module the real filesystem. Node's default FS is an empty in-memory filesystem, so ACL2 could not read its sources or write `.fasc` files. |
| `-sALLOW_MEMORY_GROWTH=1 -sMAXIMUM_MEMORY=4GB` | ACL2's heap must grow; wasm32 tops out at 4 GB. |
| `-sSTACK_SIZE=1610612736` (1.5 GB) | ACL2's bootstrap recursion is much deeper than ordinary programs, and Node also needs its own stack for `--stack-size`. |
| `-sINITIAL_MEMORY=2147483648` (2 GB) | Must be at least the stack size plus a working heap. |
| `-sEXIT_RUNTIME=1` | `(quit)` must terminate Node. |
| `-O2` instead of ECL's `-O0` | See "Optimization, and why it matters for the stack" below. |

### Optimization, and why it matters for the stack

ECL's configure hard-codes `-O0` for `wasm32-unknown-emscripten`, with a note
that non-zero optimization levels are slower together with the binaryen
`--spill-pointers` pass. Measurements here disagree in the direction that
matters most: at `-O0`, one interpreted frame costs about 5-10 KB of C stack in
wasm (against roughly 100 bytes natively), so ACL2's bootstrap exhausted every
practical stack. `wasm/build-ecl-wasm.sh` therefore patches the generated
`configure` to use `-O2`, which also makes the build and the prover faster.

### Node.js stack limits

Two independent limits apply:

* the module's C stack (`-sSTACK_SIZE`), and
* the V8 stack, which V8 checks while executing wasm frames.

Without raising the latter, deep interpreter recursion dies with
`RangeError: Maximum call stack size exceeded` after only a few thousand
frames. `wasm/acl2-wasm` runs Node with `--stack-size=524288` (512 MB) after
raising the shell limit with `ulimit -s 1048576`. `--stack-size` without the
`ulimit` segfaults, because V8 allocates the stack on the native stack.

## ECL patches needed for wasm

`wasm/ecl-patches/` (applied by the build script; each is conditional on
`__EMSCRIPTEN__`):

1. `0001-emscripten-internal-run-time.patch` — Emscripten has no
   `getrusage`, so every `get-internal-run-time` call (ACL2 makes several per
   event) printed `warning: unsupported syscall: __syscall_getrusage` and
   returned an undefined value. Use `clock()`.
2. `0002-emscripten-set-c-stack-limit.patch` — `ext:set-limit` for the C stack
   went through `getrlimit`, which under Emscripten reports the module's fixed
   stack size and silently discarded the requested value. (Not required by
   ACL2 today — the default limit of the whole stack is what we want — but it
   is needed to experiment with smaller limits and is clearly a bug.)

Caveat for 0002: with a smaller limit, ECL's `ecl_cs_overflow` can take its
"internal error" path, because `ecl_cs_init` takes `org` from
`GC_get_stack_base` (bdwgc's stack *base*, the low address) while the
bookkeeping assumes the address where the stack started (the high address).
Do not set a C stack limit below the real stack size until that is sorted out.

## ACL2 changes

All are conditional on the host Lisp; nothing changes for other hosts.

### `acl2.lisp`

* **No package locks.** ECL's package-locks module is separately loadable and
  its portable FASL contains `C-INLINE` forms, which the bytecodes compiler
  cannot handle; it is not linked into the wasm build. Under `:emscripten`,
  set `si::*ignore-package-locks*` instead of `(require :package-locks)` /
  `ext:unlock-package`, and leave `with-suppression` a plain `progn`.
* **No `mv` subprocess for `acl2-fns`.** The ECL branch compiles `acl2-fns` to
  a process-specific file and moves it into place with `ext:run-program "mv"`.
  The wasm build reports `:unix` but cannot spawn processes, so it uses
  `rename-file` (the `#-unix` path) instead.

### `interface-raw.lisp`

* **Floating-point exceptions.** WebAssembly cannot observe IEEE exception
  flags, so ECL cannot signal overflow or division of zero by zero, and ACL2's
  suitability check (`check-fp-signals`) rejects the host: `(DF/ 0 0)` returns
  a NaN and `(DF-EXPT 2 10000)` returns infinity instead of signalling.
  `df-signal?` gets an `:emscripten` branch that checks the result for
  NaN/infinity explicitly — the same approach ACL2 already uses for Allegro CL
  and LispWorks.

### `.gitignore`

Add `*.fasc` (ECL's portable FASL), which the wasm build produces in the
source directory.

## Measurements

Environment: aarch64, 16 cores. Wasm ECL built with the flags above.

| Action | Time |
| --- | --- |
| Build host ECL (first time) | ~4 min |
| Build wasm ECL | ~5 min |
| `compile-acl2` in wasm (82 files -> `.fasc`) | 66 s at `-O2` (96 s at `-O0`) |
| `load-acl2` + `initialize-acl2` in wasm | 6 min 53 s |
| Same, native ECL 26.5.5, standard build (C `.fas`, bytecoded `*1*`) | 16.4 s |
| ACL2 start-to-prompt through `wasm/acl2-wasm` | ~6 min 40 s |

Interpreted recursion depth before the C stack is exhausted: natively about
20 000 frames per 2 MB; in wasm at `-O0` about 2 000 frames per 100 MB. At
`-O2` the wasm stack is no longer the binding limit; V8's `--stack-size` is.

## Where the 24x slowdown comes from

The wasm build is about 24x slower than a native ECL build. That factor
decomposes into two nearly independent parts, which is important because only
one of them is about WebAssembly. (An earlier revision of these notes reported
56.5 s for the all-bytecode native row; that run turned out to have used more
than one core -- `user` 2m02 against `real` 56 s -- and is not reproducible.
The table below has been re-measured, each row three times, single core.)

The first factor is that the wasm build has **no native compiler**: every
function, including the `*1*` executable counterparts that ACL2 compiles
during `initialize-acl2`, is bytecode. Native ECL has a third configuration
available, which isolates the factor:

| Configuration | `load-acl2` + `initialize-acl2` |
| --- | --- |
| native, sources compiled to C (`.fas`), bytecoded `*1*` (the standard ECL build) | 16.4 s |
| native, everything bytecoded (`.fasc`) | 119 s |
| wasm, everything bytecoded (`.fasc`) | 413 s |

So bytecode-only costs **7.3x**, and wasm on top of bytecode costs **3.5x**.
Raw event processing (the sum of ACL2's own per-event `Time:` lines) is 1.0 s,
18.9 s and 70.6 s respectively, i.e. only about 6% of init is proving or guard
checking.

An earlier revision of this section attributed the remaining 15 s of the
native row to "compiling and installing the `*1*` definitions". That is wrong,
and it mattered: a source-level profile of `initialize-acl2` on native ECL
(see `ECL-PORT-NOTES.md`, "Where `initialize-acl2` spends its time") shows
that the single `(comp-fn :exec ...)` step at the end of the boot-strap, which
regenerates, compiles and loads the `*1*` definitions, is only 1.35 s of
15.3 s. Most of the rest was ACL2's own analysis of every `defun` event, in
particular the irrelevant-formals check, which is super-linear in the size of
a clique; skipping that check during the boot-strap took native startup from
17 s to 6.5 s. In the wasm build those same analysis functions run as
bytecode, so a good part of the 7.3x is spent there, and the skip should help
wasm at least as much as it helps native ECL. This has not been re-measured
in wasm yet.

### The standard ECL build runs ACL2's executable counterparts as bytecode

`acl2-init.lisp` installs the bytecodes compiler around `(eval mode)` and then
restores the C compiler, because compiling the `*1*` functions with ECL's C
compiler on every start would take far too long. (The boot-strap's `TMP1.lisp`
holds about 1,600 of them -- the logic-mode ones -- and the image ends up with
about 6,800 bytecode functions, the remainder being compiled one at a time as
events are admitted.) The consequence is visible in
the released build: `(si::bc-split (symbol-function 'ACL2_*1*_ACL2::REWRITE))`
returns a bytecode vector, and so does `EV-FNCALL`. In other words the prover
core of ACL2-on-ECL is bytecoded, which is worth remembering when comparing
prover speed with SBCL or CCL (where those functions are native).

Compiling those functions ahead of time therefore has two payoffs on native
ECL -- a faster prover, and about 1.2 s of the 5.7 s that `initialize-acl2`
now takes -- and the same change ported to wasm would replace bytecode with
wasm code. It is no longer the lever for *startup*; the boot-strap analysis
was.

The second factor is how ECL's bytecode interpreter behaves in wasm. It is not
that wasm is slow: a plain C `fib` compiled with emcc is within 1.5-2x of gcc,
and allocation-heavy Lisp is only ~2x slower. It is the interpreter loop in
particular:

| Benchmark (bytecodes compiler both sides) | native | wasm | ratio |
| --- | --- | --- | --- |
| 1e6-iteration fixnum loop | 0.032 s | 0.394 s | 12x |
| `fib 30` (call heavy) | 0.192 s | 3.502 s | 18x |
| 300k hash-table inserts | 0.033 s | 0.256 s | 7.8x |
| 300k conses | 0.119 s | 0.255 s | 2.1x |
| full GC | 0.005 s | 0.001 s | - |

The more dispatch-bound the code, the worse the ratio, while allocation and
GC are fine. ACL2 proofs show the same factor as the call-heavy benchmark:
`app-assoc` takes 0.01 s natively and 0.11 s in wasm; `app-len` 0.02 s vs
0.16 s.

Two Emscripten details matter here, and both were measured:

* Direct-threaded dispatch is unavailable: `ECL_THREADED_INTERPRETER` is
  disabled for clang/LLVM in `src/h/bytecodes.h`, so the wasm build runs the
  `switch`-based interpreter while the native gcc build uses computed gotos.
* Removing ECL's binaryen passes (`--spill-pointers`, `--profiling-funcs`)
  makes the interpreter 1.5-2x faster, but `--spill-pointers` is **required**
  for GC correctness: without it ECL aborts early in `load-acl2` with
  `BUFFER-STRING is not a string`, i.e. bdwgc collected live data because no
  pointer to it was visible on the wasm shadow stack.
* V8's optimizing tier is not helping this code: `node --liftoff-only` is
  about 1.5x faster than the default tiered pipeline on the interpreter
  benchmarks, which suggests TurboFan produces worse code for `ecl_interpret`
  than the baseline compiler.

Finally, wasm32's 30-bit fixnums (see `ACL2_SMALL_FIXNUMS`) turn arithmetic
that stays fixnum on a native 64-bit build into bignum arithmetic; the
`sum of i*i` benchmark is 25x slower in wasm against 8x for a fixnum-only
loop. wasm64 (memory64) would remove that tax and allow 62-bit fixnums.

## Wasmtime

Wasmtime is attractive: a plain CLI with WASI and no JavaScript. The module
links and starts, but ECL cannot initialize:

* The default Emscripten `longjmp` imports `env::invoke_iii` from JavaScript.
  The exception flags above remove that.
* `-sSTANDALONE_WASM` modules still import
  `env::emscripten_notify_memory_growth` when memory growth is enabled;
  Wasmtime absorbs that with `-W unknown-imports-default=y`.
* The showstopper: Emscripten's standalone runtime implements no filesystem
  and no `getcwd`. `--embed-file`/`--preload-file` are implemented in
  JavaScript (`env::_emscripten_fs_load_embedded_files`), and WASI directory
  preopens are not mapped into ECL's view of the filesystem. ECL calls
  `getcwd()` during module initialization (`si_get_library_pathname`) and
  aborts with `Can't work without CWD`.

A Wasmtime build therefore needs either a WASI port of ECL (the ECL author
describes WASI as still in progress) or a real filesystem layer inside the
module. Node is used instead for this first pass.

## Next steps

1. **Split init properly, on native ECL.** *Done.* The tool is
   `ecl-tools/init-profile.lsp`, and the numbers are in `ECL-PORT-NOTES.md`
   ("Where `initialize-acl2` spends its time"): of the 15.3 s, 11.8 s was the
   first pass over the sources, 1.4 s the second pass, 1.35 s the `*1*`
   compile step, and the rest overhead. Two thirds of the first pass turned
   out to be `chk-irrelevant-formals`, which ACL2 now skips during the
   boot-strap, taking startup from 17 s to 6.5 s. Wrapping
   `compile`/`compile-file` does not work (they are called directly in
   compiled code, or inside ECL's evaluator); wrapping `ld-fn` and the
   `compile-uncompiled-*` functions does, and `gdb` stack sampling fills in
   what neither sees.
2. **Re-measure initialization in wasm with the boot-strap fix.** The
   irrelevant-formals check is bytecode there, so it should account for a
   larger share of the 413 s than it did natively. Rebuild the wasm ECL,
   re-run `compile-acl2` and time `initialize-acl2` before deciding anything
   else; this is the cheapest remaining experiment and it may make the wasm
   startup acceptable without any of the machinery below.
3. **Prototype ahead-of-time compilation of the `*1*` functions on native
   ECL.** Still worth doing, but no longer as a startup fix: it is now worth
   ~1.2 s of the 5.7 s, and a native prover core (the prover is bytecode
   today). Capture the forms that `compile-uncompiled-*1*-defuns` compiles
   during a build run, ship them as compiled code, and have `comp-fn` install
   them instead of compiling. The same design would let wasm ship wasm code
   produced by ECL's cross compilation.
4. Image save is now the only way to remove the remaining ~5.7 s. The options
   are ACL2-level serialization of the world (data only, no code pointers), an
   image facility in ECL, or a wasm memory snapshot (Wizer-style
   preinitialization). Each has a different platform payoff.
5. Certify books under wasm (`cert.pl`) once startup is acceptable.
6. Wasmtime/WASI: blocked on ECL (see above).
7. Upstream: the two ECL patches, the ACL2 `:emscripten` branches, and the
   boot-strap skip of the irrelevant-formals check (which helps every host)
   are small and self-contained; the `-O0` override in ECL's configure is
   worth revisiting upstream.
