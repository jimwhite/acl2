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
| ACL2 `initialize-acl2` in wasm | works, 352 s with the boot-strap fix of 2026-11-05 (382 s without) |
| `defun`, `thm`, induction proofs in the ACL2 loop | works |
| Book certification (`cert.pl`) in wasm | works (2026-11-05): four dependency-free books certified, 375-384 s per book at `-j 4`, of which ~361 s is startup |
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
| `compile-acl2` in wasm (41 sources plus `acl2-fns` to `.fasc`) | 66 s at `-O2` (96 s at `-O0`) |
| `load-acl2` + `initialize-acl2` in wasm | 6 min 53 s (2026-11-04, before the boot-strap fix; `initialize-acl2` alone is 382 s then and 352 s now) |
| Same, native ECL 26.5.5, standard build (C `.fas`, bytecoded `*1*`) | 16.4 s before the boot-strap fix of 2026-11-05, 5.8 s after (4.3 s with the ahead-of-time counterparts) |
| ACL2 start-to-prompt through `wasm/acl2-wasm` | ~6 min 1 s (361 s, measured 2026-11-05) |

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
(These rows were measured on 2026-11-04, before the boot-strap fix, and
include `load-acl2`; they are not directly comparable with the
`initialize-acl2`-only figures later in this document.  After the fix, native
bytecode-only `initialize-acl2` is 40.0 s and wasm is 352 s, i.e. ~6.9x from
native C and ~8.8x from native bytecode on the aggregate.)
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
17 s to 6.5 s.

### Measured: wasm initialization, with and without the boot-strap fix

The same profiler runs in wasm, after `./wasm/acl2-wasm-compile`:

```sh
ACL2_WASM_DRIVER=ecl-tools/init-profile.lsp ./wasm/acl2-wasm
```

| phase | wasm, check on | wasm, check off | native, check off |
| --- | --- | --- | --- |
| pass 1: `ld` of the sources | 207 s | 160 s | 2.0 s |
| pass 2: `ld` of the pass-2 forms | 145 s | 156 s | 1.4 s |
| `(comp-fn :exec ...)`: the `*1*` definitions | 9.7 s | 15.5 s | 1.26 s |
| **`initialize-acl2`** | **382 s** | **352 s** | **5.8 s** |

So the irrelevant-formals check costs about 30 s in wasm (it costs 9.6 s
natively, so roughly the interpreter factor), but it was never the dominant
wasm cost. Two numbers stand out:

* Pass 2 is 145-156 s in wasm against 1.4 s natively: over 100x, not the
  3.5x implied by the interpreter benchmarks, and 44% of the whole boot-strap.
* Pass 1 without the check is 160 s against 2.0 s natively: 80x.

Both are far beyond what the interpreter penalty explains (12-18x on
dispatch-bound microbenchmarks), so the wasm startup problem is not simply
"wasm is slow"; something specific to the boot-strap is much worse there.
Candidates, none yet tested: wasm32's 30-bit fixnums turning counts and
positions in the world bookkeeping into bignum arithmetic; GC behavior with
the 4 GB heap; and the slowdown that made it necessary to keep
`--spill-pointers` (required for GC correctness, but it inhibits
optimization). Pass 2 is the first thing to profile in detail.

The `*1*` step is 12x its native cost, which is the bytecodes compiler running
under the interpreter; the difference between the two wasm columns there is
mostly variance in V8's tiering and GC, not an effect of the boot-strap fix.

### What the wasm pass-2 time is spent in

`ACL2_INIT_PROFILE_EXTRA` (a comma-separated list of ACL2 function names)
adds timers to named functions; in the bytecodes-only wasm build every call
goes through the function cell, so this reaches code that a native build
compiles into direct C calls. Timed in wasm:

| function | calls | inclusive time |
| --- | --- | --- |
| `defun-fn` (one per `defun` event) | 6,699 | 129.0 s |
| `chk-acceptable-defuns1` | 7,273 | 72.4 s |
| `install-event` | 12,470 | 32.7 s |
| `add-trip` | 150,441 | 30.3 s |
| `oneify-cltl-code` | 9,604 | 23.9 s |
| `type-set-and-returned-formals` | 59,745 | the largest of all |

The same wrappers in the native build timed `defun-fn` at 6,699 calls and
1.313 s inclusive, and `install-event` at 0.650 s, so these are 98x and 50x
slower in wasm.  The next subsection shows that this decomposes into two
interpreter factors. (`chk-acceptable-defuns1`
and `type-set-and-returned-formals` do not show up natively: they are called
from within `defuns.lisp`, so a native build turns those calls into direct C
calls and the wrapper never sees them.) Note that the inclusive times nest and
must not be added.

So pass 2 is the admission of each `defun` event, and inside that the type-set
computation in `chk-acceptable-defuns1` (`type-set-and-returned-formals` is
called about nine times per defun) dominates.

### Measured: the 98x decomposes into two interpreter factors

The same timers in a *native bytecodes-only* build (the tree described in
"Certifying books in wasm") separate the two multipliers:

| | native C | native bytecodes | wasm bytecodes |
| --- | --- | --- | --- |
| `initialize-acl2` | 5.8 s | 40.0 s | 352 s |
| `defun-fn` (6,699 calls) | 1.313 s | 16.6 s | 129.0 s |
| `chk-acceptable-defuns1` (7,273 calls) | -- | 9.68 s | 72.4 s |

native C to native bytecodes is ~12.6x and native bytecodes to wasm is ~7.8x;
12.6 x 7.8 = 98x.  Nothing size-dependent appears that would point at bignum
arithmetic or GC: the wasm-on-bytecode factor stays in the same 6-8x band for
real book proofs:

| book | native C | native bytecodes | wasm bytecodes |
| --- | --- | --- | --- |
| `fact` | 0.16 s (prove 0.01) | 0.09 s (0.03) | 0.66 s (0.42) |
| `insertion-sort` | 0.27 s (0.02) | 0.38 s (0.20) | 1.59 s (1.20) |
| `tree` | 0.30 s (0.05) | 0.93 s (0.63) | 5.92 s (5.21) |
| `adder` | 0.39 s (0.06) | 0.77 s (0.56) | 4.94 s (4.21) |

So the dominant fixed cost is that the wasm build has no native compiler and
the prover itself is bytecode; wasm's own interpreter adds the expected
factor on top.  Making this better needs either a native backend for wasm or
the interpreter improvements listed in "Where the 24x slowdown comes from".

### The standard ECL build runs ACL2's executable counterparts as bytecode

`acl2-init.lisp` installs the bytecodes compiler around `(eval mode)` and then
restores the C compiler, because compiling the `*1*` functions with ECL's C
compiler on every start would take far too long. (The boot-strap's `TMP1.lisp`
holds about 1,600 of them -- the logic-mode ones -- and the image ends up with
about 6,800 bytecode functions, the remainder being compiled one at a time as
events are admitted.) The consequence is visible in
the released build: `(si::bc-split (symbol-function 'ACL2_*1*_ACL2::REWRITE))`
returns a bytecode vector.

Only the counterparts are bytecode, though. The systems functions that the
prover actually calls are compiled to C from the sources: `(si::bc-split
(symbol-function 'REWRITE))` and the same for `EV-FNCALL` both return `NIL`.
An earlier revision of this section said the prover core was bytecoded; that
was wrong, and it matters for judging the value of compiling the counterparts
ahead of time.

Those counterparts are what `ev-fncall` runs, so compiling them ahead of time
pays off in evaluation -- `defconst`, `make-event`, guard checking, clause
processors, the boot-strap itself -- rather than in rewriting. On native ECL
the measured gain is 1.2 s of startup (see `ECL-PORT-NOTES.md`, "Ahead-of-time
compilation of the executable counterparts"); it has not been tried in wasm,
where the counterparts are wasm bytecode executed by an interpreter that is
itself wasm, so the relative gain should be larger.

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

## Certifying books in wasm (fixed 2026-11-05)

Until 2026-11-05, `certify-book` passed steps 1-4 and failed at step 5
("compile the functions defined in the book") with

```
An error occurred during initialization:
The variable PROGN is unbound.
```

`test.cert.temp` was written, no `.cert` or compiled book file appeared, and
the process still exited 0.

Cause: the ECL branch of `acl2-compile-file` (`interface-raw.lisp`) was a
COND clause written as `#+ecl (progn ...)` when commit 9937f90c96 replaced the
original `(t (compile-file ...))` clause.  A COND clause `(progn ...)` has the
symbol PROGN as its *test* and the other forms as its body, so the test reads
PROGN as a variable.  ECL's C compiler tolerates that -- it only warns
`Variable PROGN was undefined. Compiler assumes it is a global.` and
evaluates the body -- which is why the native build certified books.  The
bytecodes compiler and the interpreter follow ANSI and signal an unbound
variable.  The fix keeps the clause well formed: `(t (progn ...))`, and
`(t (compile-file ...))` for the other-host clause.

A reproduction that does not need wasm is a *native bytecodes-only* tree: copy
the sources without `.fas` files, install `ext:install-bytecodes-compiler`
before loading `init.lisp` (so that `*compiled-file-extension*` is `"fasc"`),
and run `make compile`.  Startup is ~42 s instead of ~6.5 s, and step 5 fails
the same way.  Two traps found the hard way:

- Installed after `init.lisp`, the extension is `"fas"` while the bytecodes
  compiler writes `"fasc"`, and certification fails at step 5 with
  `Could not load .../test.fas (invalid ELF header)` -- a different failure.
- Installed before `init.lisp` in the `.fas` tree itself, `load-acl2` looks
  for `interface-raw.fasc`, which that tree does not have, so ACL2 does not
  load at all.  Hence the copy.

### Extension: `fasc`

A bytecodes-only build computes `*compiled-file-extension*` as `"fasc"`
(`(pathname-type (compile-file-pathname "foo.lisp"))` in `acl2.lisp`, after
the bytecodes compiler is installed).  `books/build/cert_features.lsp` writes
that same value to `ACL2_COMP_EXT`, so `books/build/features.sh` run with the
bytecodes ACL2 (or with `./wasm/acl2-wasm`) produces `ACL2_COMP_EXT := fasc`.
`cert.pl` itself works from `.cert` files and does not consult
`ACL2_COMP_EXT`; the variable is informational.

### Measured: cert.pl under wasm

Four dependency-free books (`textbook/chap10/{fact,insertion-sort,tree,adder}`)
with `./build/cert.pl -j 4 --acl2 <timing wrapper around ./wasm/acl2-wasm>`:

| book | wall on wasm | wall natively |
| --- | --- | --- |
| `fact` | 381.0 s | 6.1 s |
| `insertion-sort` | 380.7 s | 6.2 s |
| `tree` | 375.0 s | 6.4 s |
| `adder` | 384.0 s | 6.3 s |

All four wrote `.cert` and `.fasc`; the parallel run was 384 s in total.  The
ACL2-level `certify-book` times are 0.66 s, 1.59 s, 5.92 s and 4.94 s, so
everything else is initialization (~361 s for a single trivial book).  This
makes certification possible, not yet practical; the startup work below is
the prerequisite for a full suite.

### Options for cutting the ~361 s startup

`compile-acl2` -- the ahead-of-time step the build already performs -- is not
what is missing: it removes a 66 s compile from each start, and loading the
resulting `.fasc` files costs ~10 s.  The 352 s is `initialize-acl2`'s two
`ld` passes plus the `*1*` step, and no amount of source AOT removes that.
The realistic options are:

- **AOT of the `*1*` counterparts** (`make exec-aot`) already exists for
  native ECL; porting it to wasm would replace the `(comp-fn :exec ...)`
  step, which is 15.5 s of the wasm 352 s (~4%).  Worth doing eventually,
  but it does not change the order of magnitude.
- **Wasm memory snapshot (Wizer-style).**  Run `initialize-acl2` at module
  build time, return to the top level, snapshot linear memory, and ship a
  module that starts initialized.  Largest payoff (seconds instead of
  minutes) and no ACL2 changes; the work is in the Emscripten glue (JS
  imports, NODERAWFS, and getting GC roots and the C stack into the
  snapshot correctly).
- **Serialize the post-boot state.**  Either an image facility in ECL or an
  ACL2-level dump of the world and the globals holding live data (arrays,
  hash tables, streams, function objects).  More portable, but the live
  objects are the hard part; the payoff is the same as a snapshot.
- **Amortize startup over books.**  `certify-book!` certifies and then undoes
  the book, so a batch driver could start ACL2 once and certify many books
  in one process, paying 361 s per worker instead of per book (50 books per
  worker would cut suite startup ~50x).  It needs its own driver (`cert.pl`
  assumes one process per book) and is only sound for books whose side
  effects undo cleanly: packages cannot be undefined, `include-raw`
  redefinitions persist, and memory accumulates against the 4 GB wasm
  limit.  Validate on a book family before relying on it.
- **Interpreter only.**  `--liftoff-only` was ~1.5x on the interpreter
  benchmarks, direct threading is unavailable for LLVM, and wasm64 would
  remove the 30-bit-fixnum bignum tax.  These multiply the ~8.8x wasm
  factor; the larger ~7x that comes from having the prover in bytecode at
  all is only removed by a native backend for wasm.

## Avoiding the boot-strap: research and the next experiment (2026-11-05)

Both builds pay for `initialize-acl2` on every start (352 s of the wasm 361 s;
5.0-5.5 s native with `exec-aot`).  Native ECL has no image dump --
`compiler::build-program` only links a `cl_boot` plus a list of `.fas` files
into a new executable, so it cannot capture state that was computed at run
time -- and `save-exec` is unimplemented for ECL.  The three facts below
change the shape of the problem.

### 1. The post-boot world is ordinary data, and ACL2 already saves it

`(w state)` after `initialize-acl2` is 138,373 triples.  ACL2's own
`serialize`/`deserialize` round-trips it on native ECL:

| operation | time | size |
| --- | --- | --- |
| `serialize-write` | 5.1-10.7 s | 21.7 MB |
| `serialize-read` | 0.40 s | -- |

Two host details: raise the C stack first
(`(ext:set-limit 'ext:c-stack (* 1000 1024 1024))`; the 8 MB default overflows
on the 138k-long list), and `(ext:unlock-package "COMMON-LISP")` before
reading (package locks; the wasm build has them off).  Spot checks after the
round-trip pass (`append`'s formals, `'world-globals`, and `defun-fn`'s
theorem are `equal`).  So an image of ACL2's *logical* state needs no ECL
support and works identically in wasm.

### 2. Replaying the world with `set-w` does not skip the raw-Lisp work

`(set-w 'extension saved-world state)` installs the world, but
`extend-world1` calls `add-trip` per triple and `add-trip` re-evaluates each
`'cltl-command`, so every `defun` is reinstalled and recompiled (natively we
watched `gcc` run once per source function).  Replay therefore removes ACL2's
translation and type-set analysis -- the 80-100x part -- but not code
installation.  The missing primitive is an *install-properties-only* path:
push each triple into the symbol's world alist (the code `add-trip` already
has) without evaluating anything, since `load-acl2` has already installed
every compiled function from the `.fasc` files and `exec-aot` supplies the
`*1*` counterparts.

### 3. An Emscripten memory snapshot works and does not need WASI

A probe (16 MB module, `-sMODULARIZE=1 -sINVOKE_RUN=0
-sEXPORTED_RUNTIME_METHODS=HEAPU8,wasmMemory`) establishes the mechanics:

- `ecl.wasm` has **no wasm `start` section**; `__wasm_call_ctors` is called by
  the JS glue in `initRuntime()`, and it runs even when
  `Module.noInitialRun` is set.
- The driver can therefore copy a saved linear-memory image into a fresh
  instance *after* the ctors have run (`onRuntimeInitialized`) and *before*
  invoking anything, then call a fresh exported entry point.  A global int
  and a `strdup`'d string survive, i.e. the snapshot wins.
- The data segments and ctors re-run against the initial memory and are then
  overwritten, which is exactly the ordering the trick needs.

### Can ECL simply grow a save-image?

Not as a small maintenance item, and not portably.  `cl_boot`
(`src/c/main.d`) constructs the whole runtime from compiled-in tables: it
installs `NIL`/`T`, builds every package and stream, initialises bdwgc and the
module tables; there is no restore path, and calling `main` a second time in
the same process aborts with `RuntimeError: unreachable` (measured).  The only
"image" ECL offers is compile-time linking -- `compile-file :system-p t` plus
`c:build-static-library` / `c:build-program` -- and the resulting executable
still calls `cl_boot` and loads its modules, so it captures code, never state.

The reason a general dump is hard is the heap.  It is bdwgc-managed and
conservative, objects are private C structs, and the pointers in it include C
function entry points (compiled Lisp functions), file descriptors and module
registrations.  A *relocating* dumper would need per-object type and pointer
metadata that ECL does not keep.  An *address-preserving* dumper (Emacs
"unexec" style) needs the data at the same addresses on restore, which is
brittle for a PIE executable with ASLR but is exactly true for wasm32, where
linear memory always starts at 0 and indirect calls go through a stable
function table.  So "ECL lacks a save-image" is a consequence of its design,
and the wasm-shaped version of a save-image *is* E1.

### Measurements (2026-11-05)

| what | result |
| --- | --- |
| post-init world | 138,373 triples, 21.7 MB serialized |
| `serialize-write` (native; build time only) | 5.1-10.7 s |
| `serialize-read` (native, fresh session) | 0.39-0.43 s |
| `enter-boot-strap-mode` (primordial world) | 0.02 s |
| `set-w 'extension` replay of the whole world with the bytecodes compiler (native) | 0.65 s |
| wasm memory after init | 2 GB reserved, ~720 MB resident (host RSS) |
| a second call of ECL's `main` (i.e. `cl_boot` again) | `RuntimeError: unreachable` |

Two details the experiments turned up:

* `serialize-read` cannot run its package check before a world is installed
  (`PKG-IMPORTS` is a world function).  Call `ser-decode-from-stream` with
  `check-packagesp = nil`, or install the primordial world first; package
  locks must be off or undone either way (the wasm build has them off).
* A **cold** replay is not correct yet.  Replaying the world right after
  `load-acl2` trips the pass-1 gates in `install-defs-for-add-trip`
  (`"*system-verify-guards-alist-1* is not boundp!"`): some raw definitions
  in the world were created by the boot-strap's `ld`, so they do not exist
  after loading the compiled files.  In a session that has already run
  `initialize-acl2`, the same replay installs the world in 0.65 s and proofs
  work, but the raw-install path leaves later `defun`s broken (`defun-fn`'s
  function cell ends up being its `*1*` definition).

**World replay therefore needs a small "replay mode" in `add-trip` /
`install-defs-for-add-trip`** (the `boot-strap-flg` gates at roughly lines
7163, 7224 and 7547 of `interface-raw.lisp`), rather than being a drop-in.

### Plan, in priority order

**E1 -- a wasm memory snapshot ("the image").**  Best payoff: startup becomes
a copy plus one entry call.  Sketch:

1. Add a small C shim to the wasm ECL link (same place the existing
   `-sSUPPORT_LONGJMP` flags are injected, `src/cmp/cmpdefs.lsp` and
   `src/compile.lsp.in`) exposing two functions to Lisp via ECL's FFI:
   `acl2_snapshot(path)`, which writes `[0, __data_end)` and
   `[__heap_base, sbrk(0))` (skipping the 1.5 GB stack region), and
   `acl2_resume()`, which re-registers the GC stack bottom
   (`GC_get_stack_base` + `GC_set_stackbottom`) and evaluates the resume
   driver.
2. Link with `-sINVOKE_RUN=0 -sEXPORTED_FUNCTIONS=_main,_acl2_resume
   -sEXPORTED_RUNTIME_METHODS=HEAPU8,wasmMemory`.
3. Build step: run the normal driver with `initialize-acl2`, then
   `(acl2_snapshot "/opt/eclwasm/dist/acl2.snap")` from a hook placed where
   `acl2-wasm.lsp` now calls `acl2-default-restart`, then `(ext:quit)`.
   Stamp the file with the module hash and the ACL2 source hashes, as
   `acl2-*1*-aot-file` does.
4. Runtime: instantiate with `noInitialRun`, copy the snapshot into
   `HEAPU8` (growing memory first if `brk` exceeded the initial size), call
   `_acl2_resume`, which re-enters `acl2-default-restart`.
5. Validate with the four `textbook/chap10` books and the `defun`/`thm`
   smoke tests, then re-run `cert.pl -j 16`.

Risks, in decreasing order: bdwgc may cache a stack bottom taken at snapshot
time (fix in the resume shim, then force a `GC_gcollect`); open file
descriptors and ECL streams are only sound if nothing is open at snapshot
time (true immediately after initialization); snapshot size (measure
`sbrk(0)`; expected a few hundred MB, and it must be rebuilt whenever
`sources` or `ecl.wasm` change).

**E2 -- a portable world image (fallback, also good for native ECL).**  Add
`*acl2-saved-world-file*` to `initialize-acl2`: when the file is current,
`serialize-read` the world and install it with the properties-only path from
fact 2, then `update-wrld-structures`, `exit-boot-strap-mode`,
`initialize-pc-acl2`, `f-put-ld-specials`, `check-acl2-initialization`.
Expected wasm cost: ~10 s loading `.fasc` + ~4 s reading 21.7 MB + property
installation (must be measured), versus 352 s.  It is portable, but
`defattach`/`memoize`/`defttag` raw effects must be shown to be rebuilt by
`load-acl2` + `update-wrld-structures` or replayed explicitly.

#### Prototype: a world replay reaches the loop in 1.8 s (2026-11-05)

Implemented in `interface-raw.lisp` behind a new `*world-image-replay*` flag:

* `add-trip` installs only the world properties during a replay.  Its
  `cltl-command` block (which re-runs events) is skipped: the compiled sources
  plus the ahead-of-time `*1*` file already provide the code, and the live
  world is stale while `extend-world1` is running, so re-evaluating definitions
  there is both redundant and wrong (doing it produced a segfault, then a
  wrong function cell for `defun-fn`).
* `compile-uncompiled-*1*-defuns` takes part in the replay: it explores the
  whole world instead of stopping at the `exit-boot-strap-mode` landmark, and
  it writes counterparts for functions that do not have one yet (normally it
  only rewrites counterparts that exist but are uncompiled).
* The driver must (i) load `acl2-exec-aot.fas`, (ii) call `(memoize-init)`
  (the boot-strap normally does that when it processes its `memoize` events),
  and (iii) generate the missing counterparts oldest-first, evaluating each as
  it is generated, because `oneify-cltl-code` itself needs counterparts such as
  `let-mbe-guard-form` and `defun-fn`.

Measured natively, image = 138,373 triples:

| step | time |
| --- | --- |
| `load-acl2` | 0.75 s |
| load `acl2-exec-aot.fas` | 0.02 s |
| deserialize the world (21.7 MB) | 0.40 s |
| install the properties (`set-w` replay) | 0.18 s |
| generate 4,827 missing `*1*` counterparts | ~0.4 s |
| **start to the first ACL2 prompt** | **1.78 s** |

`initialize-acl2` is 5.4-6.5 s on the same machine, so this is already a 3x
native win; the wasm win should be much larger because all of the boot-strap's
analysis is skipped.  A `thm` proves in the replayed image and the world comes
out right.

Remaining defect: admitting a new `defun` breaks with "Fast alist discipline
violated in HONS-GET" -- the hons/fast-alist bookkeeping that the boot-strap
performs when it compresses the world's alists has not been redone for the
deserialized world.  Next: find the re-registration the `include-book` path
performs (or deserialize with hons mode `:always` and recompress the affected
alists), then validate with `make -k -j 16 basic` before porting to wasm.

#### Verification: not yet sound-equivalent (2026-11-05)

Soundness comes first here, so the replay is held to ACL2's own checks rather
than to "it can prove a theorem".

Passing:

* `(check-acl2-initialization)` returns NIL on the replayed world, i.e.
  `check-built-in-constants`, `plist-worldp-with-formals`,
  `check-state-globals-initialized`, `check-none-ideal`, `check-slashable`,
  `check-some-builtins-for-executability` and `check-fp-signals` all succeed
  (0.8 s).
* `defun`, a ground call, and an inductive `thm` work in the loop.

Failing (found by running the `devel-check` checks, after certifying
`books/system/devel-check`):

* Including an apply$ book fails on the replayed image but succeeds on the
  normal one.  Isolated repro: `(include-book "projects/apply/base" :dir
  :system)` gives
  "ACL2 cannot ev the call of non-executable function :BADGE-USERFN-STRUCTURE"
  / "The TABLE :guard for BADGE-TABLE on the key :BADGE-USERFN-STRUCTURE ...
  could not be evaluated", from the `(table badge-table
  :badge-userfn-structure ... :put)` event in
  `books/projects/apply-model-2/apply.lisp`.
* The base-world state compared identical in both images (`badge-table-guard`
  is `:program` with a `*1*`, the `'table-guard` and `'table-alist` of
  `badge-table` match), so the divergence is in the book-include machinery --
  most plausibly the attachment (`defattach`) bookkeeping that the skipped
  `cltl-command` block normally performs, since `*defattach-fns*` is empty
  after a replay.  That is the next thing to chase.
* `hons-get` falls back to `hons-assoc-equal` (the "Fast alist discipline"
  warnings).  That fallback is correct, so it is a performance issue rather
  than a soundness one: the faltable entries for the world's fast alists are
  lost by serialization.  A normal image also has `slow-alist-warning` set to
  `:break`, so the difference is that a normal image never encounters a slow
  alist.

Acceptance gate before this ships: `make devel-check` (chk-new-verified-guards
and check-system-events) plus `make -k -j 16 basic` with the replay launcher,
compared against the same run with `saved_acl2`.  The image must also be
stamped with the source and host-Lisp hashes, like `acl2-exec-aot.stamp`, and
ignored when stale.

**E3 -- amortize startup over books (no new machinery).**  `certify-book!`
certifies and then undoes a book, so one process can certify many books; a
driver around it would pay 361 s per worker rather than per book.  Sound only
for books whose side effects undo cleanly (packages cannot be reincarnated,
`include-raw` persists, memory accumulates against the 4 GB limit), so
validate on a book family first.

**E0 -- measurements.**  *Done (2026-11-05); see the table above.*  One more
is still worth having: the exact `sbrk(0)`/`__heap_base` difference in wasm,
which is the snapshot size (the 720 MB RSS above includes node and the touched
parts of the 1.5 GB stack).  `(room)` cannot supply it: ECL reports that it
has no way to measure memory when linked against bdwgc.

### Decision (2026-11-05): E2 first, E1 later

The numbers above settle the choice:

* **E2's cost is not the replay.**  The world round-trips in 0.4 s and is
  reinstalled in 0.65 s natively, so in wasm the estimate is `load-acl2`
  (10 s) + deserialize (~3 s) + replay (~5 s) = **18-20 s, against 361 s**
  today.  The work is a bounded change in ACL2's world-install path, it is
  testable natively in seconds, it gives native ECL an image as well
  (5.3 s -> ~1.8 s), and the artifact is host-independent (ACL2's own
  serializer format, so it works for any ECL and can be inspected).
* **E1 is the only route to seconds**, and the probe plus the `cl_boot`
  result show exactly what it needs -- but it is wasm-only, it leans on
  Emscripten and bdwgc internals, and it buys a further 8-10x in per-process
  startup over an 18-20 s figure that is already workable at `-j 16`.
  Recommend keeping it as a later optimisation (the two layers compose).

This is also the answer to "does ECL just need an image": for a *general*
ECL image the answer is no (design, not maintenance), so the general solution
that is actually reachable is the ACL2-level one (E2).

### Revised for the browser target (2026-11-05)

The goal is to run ACL2, and include certified books on demand, in a web
browser.  That settles the E1/E2 order, because a snapshot is not something
one can ship to a browser.  Delivery sizes measured today:

| artifact | raw | gzipped |
| --- | --- | --- |
| ACL2 world image (`world.ser`) | 21.7 MB | 9.6 MB |
| compiled ACL2 sources (`*.fasc` in the repo root) | 21 MB | -- |
| `ecl.wasm` | 5.2 MB | -- |
| wasm memory snapshot | at least the 323 MB native RSS of a live ACL2; ~720 MB resident in wasm | ~2.3x at best |

So an E2 browser bundle is ~48 MB raw (split into world image, `.fasc`, wasm;
~14 MB compressed and cacheable), while an E1 snapshot is hundreds of MB.
E2 also takes `initialize-acl2` -- and therefore the `.lisp` sources -- out of
the runtime path, which is what currently forces `-sSTACK_SIZE=1.5GB` and
`-sINITIAL_MEMORY=2GB`.  Those can shrink to whatever proofs need, which
matters because browsers and mobile devices do not happily reserve 2 GB of
linear memory.  Measure how deep `ser-decode-from-stream` recurses first: it
walks the 138k-triple list recursively.

E1 stays on the shelf for a server-side or long-lived deployment, or for a
browser revisit if the snapshot can be made small (heap-only dump plus
compression).

The browser also needs work that is independent of either startup route:

* Filesystem: `-sNODERAWFS=1` must become MEMFS with a preloaded bundle, or a
  fetch-backed `FS` layer, since a browser has no `fs` module.
* Standard input: the ACL2 loop must read from a stream fed by the page
  (`Module.stdin`/a custom TTY device), not from fd 0 of a terminal.
* Books on demand: `include-book` needs the `.cert` and `.fasc` for the book
  available at include time, so either preload them or add an asynchronous
  fetch hook (ECL opens files synchronously, so this needs care).

The interpreter levers (`--liftoff-only`, wasm64 for 62-bit fixnums) and a
native wasm backend remain orthogonal multipliers; none of them removes the
boot-strap, which is the 97% item.

## Next steps

1. **Fix wasm book certification.** *Done (2026-11-05.)* It was a malformed
   COND clause in `acl2-compile-file`; see "Certifying books in wasm" above.
   Four dependency-free books certify under `cert.pl`.  A native
   bytecodes-only tree makes further work on this ~9x cheaper (42 s vs ~375 s
   per run), and `make -k -j 16 basic` still passes natively (1,486
   certificates; two books hit the known `acl2-status.txt` startup race on the
   first pass and were certified by a 56 s re-run).
2. **Split init properly, on native ECL.** *Done.* The tool is
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
3. **Find out why passes 1 and 2 cost 80-100x their native time.** *Answered
   (2026-11-05): two interpreter factors, not a wasm-specific pathology.*
   Native bytecodes-only `initialize-acl2` is 40.0 s (native C 5.8 s, wasm
   352 s); `defun-fn` is 16.6 s / 6,699 calls natively in bytecode (native C
   1.313 s, wasm 129.0 s), and `chk-acceptable-defuns1` is 9.68 s / 7,273
   calls (wasm 72.4 s).  Thus native C to native bytecode is ~12.6x and wasm
   on top of bytecode is ~7.8x; 12.6 x 7.8 = 98x.  Real book proofs show the
   same 6-8x wasm-on-bytecode band, with nothing growing with book size, so
   bignum arithmetic and GC are not the explanation.  The remaining levers
   are a native backend for wasm and the interpreter improvements below.
4. **Ahead-of-time compilation of the `*1*` functions on native ECL.**
   *Done for ECL.* `*acl2-*1*-aot-file*` in `interface-raw.lisp`
   loads a precompiled file of the counterparts instead of generating and
   compiling them; `make exec-aot` builds it, and the launcher refuses it when
   any source is newer or the host Lisp differs. Startup goes from
   6.4-6.8 s to 5.0-5.5 s. It does not speed up rewriting, because `rewrite`,
   `type-set` and `ev-fncall` were already native; it speeds up `ev-fncall`
   paths. The same design would let wasm ship wasm code produced by ECL's
   cross compilation.
5. **Remove the repeated `initialize-acl2` on wasm**, which is ~352 s of
   every ~361 s start.  The options and expected payoffs are in "Options for
   cutting the ~361 s startup"; the reasons for preferring a memory snapshot
   over a world image, and the concrete design for both, are in "Avoiding the
   boot-strap: research and the next experiment" above.  **Next action: E1,**
   which is now known to be mechanically possible under Node without a WASI
   port.  Source AOT is already done; AOT of the `*1*` counterparts would
   save only ~15 s.  For native ECL, image save is likewise the only way to
   remove the remaining ~5.4 s (serialization, an ECL image facility, or a
   memory snapshot), and E2 would give that too.
6. **Certify books under wasm at scale** (`cert.pl`).  Works for a handful of
   dependency-free books.  At ~375 s per book, `make -k -j 16 basic`
   (1,486 books) would take roughly 10 hours.  Cut the startup (item 5) or
   amortize it over books in a batch driver before attempting this.
7. Wasmtime/WASI: blocked on ECL (see above).
8. Upstream: the two ECL patches, the ACL2 `:emscripten` branches, and the
   boot-strap skip of the irrelevant-formals check (which helps every host)
   are small and self-contained; the `-O0` override in ECL's configure is
   worth revisiting upstream.
