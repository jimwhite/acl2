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

### Driver: `wasm/run-basic-wasm.sh`

The `basic` suite can nevertheless be certified with the startup as it is; it
is just slow.  `wasm/run-basic-wasm.sh` runs it through the books Makefile,
which is `make -j 16 basic` with `ACL2=<launcher>`:

```sh
CLEAN=1 ./wasm/run-basic-wasm.sh   # first run: start from a clean tree
./wasm/run-basic-wasm.sh           # resume; cert.pl skips finished books
```

The script recompiles the ACL2 sources with the wasm compiler first (~90 s),
then deletes existing book artifacts if `CLEAN=1`, then runs
`make -k -j $JOBS basic ACL2=./wasm/acl2-wasm`.  `JOBS` (default 16), `LOG`
(default `/tmp/wasm-basic.log`) and `TARGETS` (default `basic`) are
environment variables.

The deletion is not bookkeeping: the tree normally holds certificates from
the native build, `cert.pl` treats a book as up to date when its `.cert`
exists, and a native `.fas` cannot be loaded by wasm in any case.  Rebuilding
the native suite afterwards costs about 23 minutes (`make -j 16 basic
ACL2=../saved_acl2`).

Two overheads are paid per run.  The Makefile runs `features.sh` with
`$(ACL2)` on every invocation, so each invocation starts with a full wasm
start-up (~7 minutes) before the first book, and the dependency scan that
follows walks all 1,486 books.  Each book then costs ~6 minutes, ~5.9 of them
boot-strap.

Checked end to end through `make` on `textbook/chap10/fact`: features run
under the wasm ACL2 report `ACL2_COMP_EXT := fasc`, `ACL2_HOST_LISP := ECL`
and "Ignoring USE_QUICKLISP=1 since Quicklisp does not work on ECL", the scan
takes 7 s, and the book gives
`Built .../fact.cert (351.150s)` with a `.fasc` next to it.

Expected cost at `-j 16`: 1,486 books x ~5.9 min / 16 = ~9 hours, i.e.
overnight.  At `-j 8` it is about twice that.  `cert.pl`'s `.cert` files make
the run resumable with the same command minus `CLEAN=1`, which is why the
script does not clean by default.

### First full run (2026-11-05): 1,028 books, and a GC bug

The suite was run for real: `CLEAN=1` at 08:11, 16 jobs, finished 20:12 after
12 hours with make exit status 2 and 1,015 certificates; a resume run
(22:58-23:43) added 13 more.  **No `acl2-status.txt` races occurred.**  The 14
books that failed in the first pass and the 10 that still failed after the
retry fall into three groups:

| symptom | books |
| --- | --- |
| bdwgc `Unexpected mark stack overflow`, `GC_mark_some` -> `GC_push_roots` -> `stacks_scanner` -> `GC_push_all` | `data-structures/{portcullis,no-duplicates,list-defuns,alist-defuns,set-defuns,array1}`, and `arithmetic-5/top` (which includes them) |
| ECL fatal `not a lisp data object [54: Not a directory]` in `cl_class_of`, called from `clos_std_compute_applicable_methods` | `arithmetic-3/bind-free/banner`, `kestrel/strings-light/char`, `kestrel/event-macros/fail-event`, `kestrel/error-checking/ensure-function-is-logic-mode`, `std/system/guard-theorem-no-simplify-dollar-tests` |
| ACL2 returned 0 but no certificate (banner printed, loop exited to the ECL top level, ACL2 re-entered) | `misc/profiling`, `tools/time-dollar-with-gc` |

Both crash modes are one bug, and it is in the wasm ECL's garbage collector,
not in any book:

- `data-structures/portcullis` (a `defpkg`, nothing else) reproduces in **1.3
  seconds**, i.e. while `load-acl2` is still loading the compiled ACL2 files,
  long before the book is touched.
- It is deterministic *for the launcher's working directory*: the same command
  crashes 5 times out of 5 when started from `books/data-structures`, and
  survives when started from `books/`, `books/data-structures/..`, or `/tmp`,
  including a `/tmp` path with the same length.  Adding two `format` calls and
  a `(ext:getcwd)` to the driver makes the crashing directory work, so the
  trigger is a small change in allocation timing, not the directory itself.
- `GC_DONT_GC=1` and `GC_INITIAL_HEAP_SIZE=2000000000` both avoid it;
  `GC_PRINT_STATS=1` flips it to the other symptom (`cl_class_of` on a bogus
  object).  That is the signature of a collector handing out an object that is
  still referenced, i.e. a root that is not being scanned.
- The trigger is the *first* collection during `load-acl2`: **any** explicit
  `GC_INITIAL_HEAP_SIZE` avoids it (100 MB and 2 GB behave the same), which
  moves that collection later.  `wasm/acl2-wasm` therefore exports
  `GC_INITIAL_HEAP_SIZE=${GC_INITIAL_HEAP_SIZE:-500000000}` as a documented
  workaround; with it, the previously 0-for-5 crashing directory started 3
  times out of 3.  Override the variable to experiment.

Consequences to keep in mind:

1. **Retrying does not fix it.**  A directory (or timing) that triggers the
   bug fails again; only the *lucky* starts can be resumed.
2. **Certificates from this build are not yet trustworthy.**  A collector that
   can miss a root can also corrupt a proof in silence, which is exactly the
   failure mode a theorem prover must not have.  The 1,028 certificates are
   evidence that the pipeline works, not a soundness claim; a fix must be
   followed by a clean re-run before this build certifies anything for use.
   The `GC_INITIAL_HEAP_SIZE` default above makes the *known* trigger go away
   but does not make the collector sound.
3. The likeliest culprits are conservative stack scanning under wasm (the
   module's stack is 1.5 GB and lives in linear memory) and the mark stack
   (`GC_INITIAL_MARK_STACK_SIZE_BYTES`); both are worth trying before believing
   the bytecodes compiler is at fault.

### Interactive use, and including certified books across the two builds

Before spending another long run it is worth checking that the two builds can be
*driven* interactively and that `include-book` works on the certificates we
produce.  With 1,000+ wasm-produced certificates in the tree:

```lisp
(thm (equal (append (append x y) z) (append x (append y z))))
(defun triple (x) (* 3 x))
(triple 14)                                  ; 42
(include-book "arithmetic/top" :dir :system)
(include-book "std/lists/top" :dir :system)
(thm (equal (len (append a b)) (+ (len a) (len b))))
(include-book "projects/apply/base" :dir :system)
(thm (equal (apply$ 'binary-+ (list 1 2)) 3))
(hons-acons 'a 1 nil)
```

Under native `./saved_acl2` this whole session takes 17 s and every proof is
Q.E.D., but each `include-book` gives

```
ACL2 Warning [Compiled file]: Unable to load compiled file for book
  .../arithmetic/top.lisp because the compiled file does not exist.
```

The certificates were made by the wasm build, so they name `top.fasc`, while
native ACL2 looks for `top.fas`.  The books are still installed -- ACL2 loads
the certified expansion -- so the result is *correct but interpreted*.  Two
conclusions for the delivery plan:

1. Certificates and compiled book files belong to the build that made them; a
   book bundle has to be certified by the runtime that will load it, or the
   loader must be extended to accept a foreign compiled file (which is exactly
   the "separately compiled library" step).
2. The logical half of `include-book` *is* portable between the native and wasm
   builds, which supports the base-snapshot-plus-bundles architecture: the
   world extension does not depend on which Lisp compiled the book.

Under `./wasm/acl2-wasm` the same script is fully clean: three Q.E.D.s,
`((A . 1))` and `:ALL-INCLUDES-DONE`, with no compiled-file warning, because
the `.fasc` files match the certificates.  It took 12m10s end to end while
sixteen certification jobs were running; the three includes and their proofs
are seconds of that, the rest is the boot-strap.  So the wasm build certifies
books *and* loads them interactively from the same certificates, which is the
behaviour the delivery plan needs before any bundling work.

### Browser, first attempt (2026-11-06): ECL runs, ACL2's boot-strap does not

`wasm/build-ecl-wasm.sh` gained a `WEB=1` mode (MEMFS instead of Node's
filesystem, a modularized factory, `-sFORCE_FILESYSTEM -sENVIRONMENT=web,worker`,
same 1.5 GB stack and 2 GB initial memory as the Node build) writing to
`dist/web`.  `wasm/web/` is the harness: `index.html`, a `worker.js` that
preloads files into MEMFS and feeds a script on ACL2's stdin, and
`acl2-web.lsp`, the browser analogue of `wasm/acl2-wasm.lsp`.
`wasm/web/make-manifest.sh` slices the 25 MB of ACL2 sources plus 21 MB of
`.fasc` (and a book bundle) into gzipped files, 9 MB in total, because the
dev-container port forward truncates a noticeable fraction of larger responses.

What works, in a page: **ECL 26.5.5 boots and evaluates Lisp** -- `(+ 1 2)` is 3
and `(print 42)` prints 42 -- with the payload preloaded in about 11 s.

What does not work yet: ACL2 itself stops during `load-acl2` with

```
RangeError: Maximum call stack size exceeded
  at ecl.wasm.variadic_dispatch2 ... at ecl.wasm.ecl_interpret ...
```

The same module under Node with its *default* JS stack fails identically, and
`wasm/acl2-wasm` sets `node --stack-size=524288`, so the limit is V8's stack
for wasm code, not the module's own `-sSTACK_SIZE`.  Measured thresholds, with
the wasm stack at 1.5 GB and an ample `ulimit -s` in every case: `--stack-size`
default, 8192 KB, 65536 KB, 131072 KB and 262144 KB all end in
`RangeError: Maximum call stack size exceeded` during `load-acl2`; 524288 KB
(the launcher's setting) completes.  The boot-strap therefore wants **more than
256 MB** of native stack: a page's is about 1 MB and a page cannot raise it, so
**the boot-strap cannot be re-run in a browser** and the browser target has to
start from a prepared base (the E1 snapshot or the E2 world image).  The
corollary is worth measuring later: whatever state we ship must keep recursion
shallow enough for the browser's stack, so the replay path needs the same check.

An embedder can still do it -- a shell that runs the isolate on a thread with a
512 MB stack and passes `--js-flags=--stack-size=524288` -- but no stock WebView
can: Chromium gives renderer threads the OS default and WebKit's
`maxPerThreadStackUsage` is under a megabyte, neither reachable from script or
from a WebView host.  The practical desktop shape is therefore the one that
already works: ACL2 in a Node (or similar) process with the raised stack, with
the WebView only drawing the UI -- a Tauri/Electron front end driving
`wasm/acl2-wasm` over a pipe needs no snapshot at all.

**Why the boot-strap wants that much stack.**  Measured on this build: a
bytecode-compiled recursive Lisp function overflows a 1 MB native stack at
depth 500 and is fine at 300, i.e. each Lisp call costs roughly 2.5 KB of
native stack (wasm frames, `-O2`), whether the callee is bytecode or
interpreted.  A 256 MB budget is therefore about 100,000 nested calls.  The
depth is not counted by ECL's own limit: `(ext:set-limit 'ext:frame-stack 50)`
does not stop a 300-deep recursion, so a run with `ext:frame-stack` capped at
20,000 completes the boot-strap just as before.  A backtrace from the overflow
is nothing but `ecl_interpret` / `ecl_apply_from_stack_frame` pairs, so the
nesting is Lisp-call nesting rather than a deeply nested form.

That is what makes "put the stack in dynamic storage" the interesting question:
if Lisp calls kept their frames in the heap (a VM with an explicit frame stack,
or CPS/trampolining) the depth would be bounded by memory, not by the native
stack, and the browser limit would disappear for good.  In ECL that is not a
flag: the interpreter (`ecl_interpret`, `ecl_apply_from_stack_frame`) and the
bytecode VM both use the C stack per call, so it means changing the calling
convention -- a real project, and one that would help every wasm deployment.
Cheaper first: find out *what* nests 100,000 calls during the boot-strap.  The
native build tolerates it only because its frames are ~100 bytes, so a native
run under `gdb` with `ulimit -s 4096` will fault with the recursion cycle on
the stack, which is a much better starting point than guessing.

ECL's own C-stack limit does fire -- `(ext:set-limit 'ext:c-stack 32MB)` is
detected as `ecl_cs_overflow` -- but the handler cannot report it: building the
condition (`cl_make_condition`) itself needs stack and the process aborts, at
32 MB and at 128 MB alike.  The excursion happens at a *fixed point* in pass 1
(around 15,000 lines of boot-strap output, the same place for every stack
size), so it is one deep excursion rather than a per-form leak.

Smaller things learned, each of which cost a cycle: `-sEXPORT_NAME` cannot be
combined with the HTML target ECL's link step emits; a worker must be told
`locateFile` (or `wasmBinary`, which needs `INCOMING_MODULE_JS_API`); a page has
no environment, so `ACL2_SMALL_FIXNUMS`/`ACL2_SNAPSHOT_INFO` must be set from
Lisp with `ext:setenv`; and `(setf (ext:getenv ...))` does not exist in ECL.

### AOT and dynamic loading: what has been verified (2026-11-06)

The wasm build runs the prover as bytecode, which is the 12.6x interpreter
factor in the 98x slowdown.  Compiling Lisp to wasm instead would leave only
the ~7.8x wasm factor, so this is the largest speed lever available.  Three
questions, three answers, all measured:

1. **Can a running Emscripten module load a separately compiled wasm module?**
   Yes.  `wasm/dylink-poc/` does it with these tools: `emcc
   -sSIDE_MODULE=2 -o side.wasm side.c` and `emcc -sMAIN_MODULE=2 -o main.js
   main.c`, then `dlopen("side.wasm", RTLD_NOW)` + `dlsym` + call, and Node
   prints `side_double(21) = 42`.  Functions in the side module must carry
   `EMSCRIPTEN_KEEPALIVE` to be visible to `dlsym`.  For a browser, the async
   `emscripten_dlopen` is present in this Emscripten (it is declared in
   `system/include/emscripten/emscripten.h` and implemented in `libdylink.js`),
   which matches fetching a book module after the fact; a synchronous `dlopen`
   works if the bytes are already in the filesystem, which is what preloading
   into MEMFS gives us.
2. **Does ECL survive being that main module?**  Yes.  `wasm/build-ecl-wasm.sh`
   now takes `EXTRA_WFLAGS` and `TAG`, and `EXTRA_WFLAGS=-sMAIN_MODULE=2
   TAG=dylink` produced `dist/node-raw-dylink` that boots and evaluates Lisp
   (`hello 3`); the module grew from 5,191,190 to 5,195,162 bytes and the
   loader now contains `loadDynamicLibrary` and the dylink sections.  So the
   main-module side of the design costs nothing worth measuring -- but it has
   to be decided before a base snapshot is taken, as the delivery plan says.
3. **Can ECL ask for such a module today?**  No.  The wasm ECL is built
   `--disable-shared`, and its features say so: no `:dlopen`, no `:shared`, no
   `:threads`; the `FFI` package exists but has nothing to load with, and there
   is no `ext:load-shared-object` symbol.

The rest of this section is what filled those three gaps.  It works: a Lisp
file cross-compiled on the host becomes a wasm module that the wasm ECL
`dlopen`s, and the compiled functions run 77-124x faster than the bytecode
compiler's (measurements at the end).

#### The compiler side: `wasm/mk-wasm32-target.lsp`

`compile-file` takes `:target <target-info>`; it dispatches through
`compile-with-target-info`, which binds `c::*config-options*` around the
compilation and sets `*cross-compiling*`.  The target-info is a *Lisp alist*
written by `c::write-target-info` -- `read-target-info` rejects the shell
`wasm32.cross_config` with "CL_FIXNUM_TYPE=INT is not of type LIST", because
that file is only used by `configure` to fill in `ecl/config.h`.

A native ECL writes its own target-info while it builds its Lisp library, and
so, it turns out, does the wasm build: `build/compile.lsp` runs inside the
wasm `ecl_min` under Node, so `$WORK/ecl-node/target-info.lsp` is the genuine
article -- `*target-identifier*` "wasm32-unknown-emscripten", fixnum 30 bits,
`long` 32 bits, `*cc*` = emcc, `*features*` = the wasm features (plus a
`:cross` left over from the build).  There was no need to synthesise one;
`wasm/mk-wasm32-target.lsp` only has to make it produce *loadable modules*
instead of programs, and to drop `:cross`.  Reading it does need `cmp` loaded,
because the machine and host-type structures have to exist.

Two things it sets matter:

- `-fPIC` in `*cc-flags*`.  Without it wasm-ld refuses the module:
  `relocation R_WASM_MEMORY_ADDR_LEB cannot be used against symbol 'VV';
  recompile with -fPIC` (`VV` is the constants vector every compiled Lisp file
  has).  And the failure is quiet: link without the export flag below and you
  get a 336-byte, symbol-less module instead of an error.
- `-Wl,--export=__ecl_init_fas_CODE` in `*ld-shared-flags*`.  `-sSIDE_MODULE=2`
  exports only what is asked for, and `si_load_binary` dlsym's
  `_ecl_library_default_entry()`, i.e. `INIT_PREFIX "CODE"` with `INIT_PREFIX`
  `"__ecl_init_fas_"` for a `:fasl` module (`c/ffi/libraries.d`;
  `compute-init-name` in `cmp/cmpbackend-cxx/cmpc-init-name.lsp` -- the name is
  only randomised for `:object`, which is what `:system-p t` builds).
  `-sEXPORTED_FUNCTIONS=___ecl_init_fas_CODE` works too, with one extra
  underscore, because those names are the JavaScript ones.

With that, one call in the host ECL

    (compile-file "book.lisp" :target "/tmp/wasm32.target")

emits `book.c`, `book.o` and `book.fas` -- the last a 2.9 KB wasm module
exporting `__ecl_init_fas_CODE`.  It takes 0.13 s for a small file.

#### The loader side: `DYLINK=1` in `wasm/build-ecl-wasm.sh`

Three changes, all of them forced by measurements:

- `ENABLE_DLOPEN` and `HAVE_DLFCN_H` in `ecl/config.h`.  `configure` only
  defines them with `--enable-shared`, which a wasm build cannot use, and
  without them `si_load_binary`, `ecl_library_open` and the whole of
  `c/ffi/libraries.d` are compiled out -- `(fboundp 'si::load-binary)` was NIL.
  Defining them by hand after `configure` keeps `--disable-shared` (a static
  `libecl.a` is still right) and gives ECL Emscripten's `dlopen`/`dlsym`.
- `-fPIC` for *the whole runtime*, not just for book modules.  wasm-ld's
  `--export-dynamic` (what `-sMAIN_MODULE=1` asks for) exports every symbol of
  a PIC object and *none* of a non-PIC one.  Measured with one source compiled
  both ways: the `-fPIC` build exports `my_func` and `my_global`, the other
  exports neither.  Without it the main module exported 2,368 functions -- all
  of libc and bdwgc -- and no libecl at all, and loading a module died with
  `undefined symbol 'cl_env_p'`.  (This is why `-sMAIN_MODULE=2` is not
  enough either: it exported 18 functions.)
- `-sERROR_ON_UNDEFINED_SYMBOLS=0` and `-Wl,--allow-multiple-definition`, for
  two ECL build quirks that a static link hides: `libeclgmp.a` references
  `__gmpz_jacobi`, `__gmpn_sub_nc` and `__gmpn_add_nc` without defining them,
  and `ecl-cdb.o` is a member of both `libecl-help.a` and `libecl-cdb.a`.

Result: `dist/node-raw-dylink2` is 6,066,302 bytes of wasm (5,191,190 before),
4,409 exports, and `cl_env_p`, `cl_symbols`, `ecl_aref_unsafe` and `ecl_times`
are among them.

#### Measured: compiled wasm running inside the wasm ECL

Compile `bench.lisp` on the host, `(load "/tmp/bench.fas")` in the wasm ECL,
and time the same functions before and after (Node 24, `node-raw-dylink2`):

| benchmark | bytecode | wasm AOT | speedup |
| --- | --- | --- | --- |
| `fib 25` (naive, fixnum decls) | 0.308 s | 0.004 s | 77x |
| `(dotimes (i 2000000) (setq s (+ s (logand i 7))))` | 2.115 s | 0.017 s | 124x |

Both are larger than the 12.6x that native C beats the bytecode compiler by,
and the loop is much larger: the bytecodes compiler does no type inference, so
`(+ s (logand i 7))` goes through generic arithmetic with bignum checks, while
the C compiler unboxes under `(declare (fixnum ...))`.  Numeric ACL2 code
should land somewhere between the two ratios.  Even the low end removes the
12.6x interpreter factor from the 98x slowdown, leaving the ~7.8x wasm factor,
which is what the rest of this document calls the only large lever left.

#### Books: the expansion file, and what it needs

Nothing in ACL2 has to change.  ACL2 compiles a book's *expansion* file
(`<book>@expansion.lsp`, see `expansion-filename`), loads it, and deletes it
unless `save-expansion-file` is set -- which the environment variable
`ACL2_SAVE_EXPANSION=1` arranges.  `include-book` later loads the compiled file
by name (`load-compiled` -> `(load ...)`), so if that file is a wasm module
instead of a fasl of bytecode, the wasm ECL dlopens it.  The certificate does
not care: `.cert` records the *source* hash (`book-hash` of `expansion-alist`,
`cert-data` and `ev-lst`), not the compiled file.

Three things surfaced while wiring this up, all measured:

1. **The expansion file is not plain text.**  `fact@expansion.lsp` (1,536 B for
   a five-event book) begins with serialized `*HCOMP-FN-ALIST*` /
   `*HCOMP-CONST-ALIST*` / `*HCOMP-MACRO-ALIST*` data as `#Z[...]` / `#Y[...]`,
   ACL2's `serialize` read macros, which live in `*acl2-readtable*`.  Compiling
   it therefore has to happen in a process with the ACL2 sources loaded.  The
   natural one is a *native saved ACL2*: its ECL also has the C compiler.
2. **The two ECLs disagree about the entry point.**  The ECL inside a native
   ACL2 build emits `init_fas_CODE`; the ECL that build-ecl-wasm.sh makes
   emits `__ecl_init_fas_CODE`, and `si_load_binary` dlsym's the latter (see
   `init-function-name` in each `cmpc-init-name.lsp`).  `wasm/aot-acl2.lsp`
   therefore does the compile in two steps -- ECL writes the C, the script
   rewrites the name and runs emcc -- instead of letting `compile-file` link.
   It also explains the "undefined symbol: `__ecl_init_fas_ACL2_FNS`" from the
   repository's own native `.fas` files: those were built by the release ECL.
3. **`.fasc` has a fixed meaning for `load`.**  ECL dispatches on the file type
   through `ext::*load-hooks*` (`c/main.d`), mapping `"fasc"` to
   `si::load-bytecodes` because that is what the bytecodes compiler writes.  A
   module that keeps the `.fasc` name has to be recognised some other way, so
   `wasm/acl2-wasm.lsp` wraps that hook: sniff `\0asm` and send such files to
   `si::load-binary` (the dlopen path), everything else to the bytecodes
   loader.  ACL2's own start-up still loads its `.fasc` files through the
   wrapper, so this is transparent.

(For plain Lisp that does *not* need ACL2's readtable -- the microbenchmarks
below, or the experiment of compiling ACL2's own sources -- `wasm/aot-books.lsp`
does the same job in the host ECL that build-ecl-wasm.sh installs, using
`compile-file :target` directly.)

**Solved: the module has to be built by the same ECL tree as the runtime.**
`wasm/aot-acl2.lsp` ran inside a native `saved_acl2`, and that saved image was
built with the ECL 26.5.5 *release* rather than the patched tree the wasm
runtime comes from.  Two independent things went wrong.  The entry point was
named `init_fas_CODE` instead of `__ecl_init_fas_CODE`, which the script
patched up by rewriting the generated C -- cosmetic but a sign of the real
problem; and the module's calls into libecl used the other build's conventions,
so the wasm ECL got its module initialised and then died with "Wrong number of
arguments passed to function SI:WAITPID", with the compiled code never taking
effect (500 `(fact 500)`: 0.754 s, the same as bytecode).

The fix is to keep ACL2's reader but drop the native ACL2:
`wasm/aot-host.lsp` runs in `$WORK/ecl-host`, the *same source tree* as the wasm
runtime, so `(compile-file f :target …)` emits `__ecl_init_fas_CODE` itself and
links the module with emcc -- no renaming, and the ABI matches by construction.
All it needs from ACL2 is `load-acl2`, not `initialize-acl2`, so the whole
driver reaches the first compile in about a second:

* Two things had to be arranged to load ACL2 in the host ECL at all.  (a) The
  sources here are the wasm ECL's `.fasc` bytecode, while the host ECL asks for
  its own `*compiled-file-extension*` (`fas`), and the `*.fas` in the tree come
  from that other build and cannot be dlopened (`undefined symbol:
  __ecl_init_fas_ACL2_FNS`); so the driver replaces the `"fas"` entry of
  `ext::*load-hooks*` with one that loads the `.fasc` through
  `si::load-bytecodes`.  (b) `load-acl2` needs a 1 GB C stack: at ECL's default
  8 MB it dies in `C-STACK overflow at size 8388608` (`ulimit -s` alone is not
  enough; the driver also does `ext:set-limit 'ext:c-stack`).

`wasm/aot-book.sh books/textbook/chap10/fact` now does the whole job -- write
the target files if needed, load ACL2's sources, compile each
`<book>@expansion.lsp` -- in about 1.1 s per book:

    /workspaces/acl2-ecl/books/textbook/chap10/fact.fasc (4167 bytes, 0.17 s)

and in the dylink wasm ECL the book then loads for real: `include-book` of
`textbook/chap10/fact` takes 0.03 s with no `Compiled file` warning, and 500
`(fact 500)` calls take **0.39 s** against 0.747 s for the bytecode fasl.  That
is only ~1.9x, not the 77x of a standalone microbenchmark, because a bignum
`fact` call is mostly bignum arithmetic, which is native C in both cases; the
bytecode part was the `*1*` wrapper.  A function whose work is done in Lisp code
will show much more.

Two loose ends: `.cert` files do not record which `.fasc` is present, so a book
whose module was built for a different wasm ECL would be silently mismatched
(the entry point check catches only the gross case), and nothing yet
*automatically* AOTs a book after certifying it -- certification happens in the
wasm ECL, which cannot compile to wasm itself.

#### The `*1*` counterparts as a wasm module (works; worth ~5 s of start-up)

ACL2's boot strap ends by regenerating and compiling the executable
counterparts of every `:logic`-mode function (`TMP1.lisp`);
`*acl2-*1*-aot-file*` lets a prebuilt file take that step's place, and
`make exec-aot` produces it for native ECL.  The same file, compiled to wasm,
does the same job here, and has a second effect worth more than the first: from
then on every `*1*` function that `EV-FNCALL` runs is native code.

Three things were needed:

1. `acl2-*1*-aot-file` hard-coded the `"fas"` extension; it now uses
   `*compiled-file-extension*`, and `compile-uncompiled-*1*-defuns` passes the
   extension to `load-compiled` explicitly.  Without the latter the load picks
   a stale native `ACL2-EXEC-AOT.FAS` -- with a type-less name ECL takes the
   first type in `EXT::*LOAD-HOOKS*` whose file exists -- and dies with "need
   to see wasm magic number".
2. `./wasm/aot-book.sh acl2-exec-aot.lisp` builds `acl2-exec-aot.fasc`
   (3.1 MB, 16 s from the 1.5 MB, 1,622-definition source).  It loads in
   0.06 s and the names come out as `COMPILED-FUNCTION`.
3. `wasm/acl2-wasm.lsp` sets `*acl2-*1*-aot-file*` from the staleness check
   unless `ACL2_WASM_NO_EXEC_AOT=1`, which is how the two runs below were
   compared.

Measured start, back to back and identical apart from
`ACL2_WASM_NO_EXEC_AOT=1` (each run reaches the prompt and then proves
`(thm (equal (append x y) (append x y)))`): **331.8 s -> 310.6 s**
(5 m 31.8 s -> 5 m 10.6 s).  Small -- 6% -- because the expensive boot-strap
functions are `:program` mode and have no `*1*` counterpart at all.  The
staleness check compares the *sources* with the compiled file, so any edit to
an ACL2 source invalidates it: rebuild this file last.

#### Native wasm code for ACL2's own sources (works: 310.6 s -> 41.1 s)

`wasm/aot-book.sh` compiles plain Lisp files as well as expansion files, so
ACL2's own sources can be built the same way: 43 modules (`acl2-fns`, the 41 of
`*acl2-files*` that `load-acl2` loads compiled, and `acl2-exec-aot` for the
`*1*` counterparts), about 24 MB in total and about 6 minutes to build.  The
wasm ACL2 then loads them instead of bytecode -- the sniffing load hook in
`wasm/acl2-wasm.lsp` already handles the mixture -- and the boot strap, which is
what the 352 s was spent on, mostly runs compiled code:

| | bytecode | native modules |
| --- | --- | --- |
| start to the prompt | 310.6 s | **41.1 s** |
| `include-book "textbook/chap10/fact"` | 0.03 s | 0.03 s (module, no warning) |
| 500 x `(fact 500)` | 0.747 s | **0.04 s** |

Two bugs had to be found first, and both are worth knowing because they apply to
*any* module built for this runtime.

1. **A side module must be linked with `--spill-pointers`.**  bdwgc is a
   conservative collector: a Lisp object that lives only in a register -- in
   wasm, a local -- is invisible to it, so it gets collected under the running
   program.  ECL's own wasm build passes
   `-sBINARYEN_EXTRA_PASSES='--spill-pointers,--strip-debug'` (src/configure),
   which spills pointers to the shadow stack, but the side modules built by
   `compile-file :target` used only `*side-module-flags*`, which did not have
   it.  The symptom was a wrong *value* rather than a crash, and it depended on
   allocation: a one-line function in a module,

       (defun p-loop-collect (n) (length (loop repeat n collect 1)))

   returned 65 (and 41 841 with a different allocation history) instead of
   100000, while the bytecode build returned 100000, `GC_DONT_GC=1` made it
   correct, and a *bigger* function that had already spilled the list to the
   stack was fine.  That last point is why a deliberately shallow probe (a live
   list held across a forced `si::gc` at 40 frames deep) passed and misled us
   earlier.  It also explains every symptom of item 2 below: ACL2's worlds were
   silently corrupted, hence "X is not of type CONS" with X varying, hence the
   dependence on heap size and on how much a driver printed.
2. **Compile-time constants come from the host, not the target.**
   `initialize-state-globals` in acl2.lisp sets the ACL2 global
   `compiled-file-extension` with `,*compiled-file-extension*`, i.e. the value is
   spliced in at *macroexpansion* time.  A module compiled by the host ECL baked
   in the host's `"fas"`, so the wasm ACL2 looked for `<book>.fas` and fell back
   to the expansion file ("Loading expansion file ... in place of compiled file
   ... fact.fas, because the compiled file is missing").  `wasm/aot-host.lsp`
   now pins `*compiled-file-extension*` to the target's `"fasc"` before
   compiling.  Anything else that a macro evaluates at expansion time from host
   state needs the same care; the target-info binds `cl:*features*` (so
   conditionals are right) but not variables like this one.

A third, smaller one: the wasm runtime has no package-locks module, and
`ext:lock-package` / `ext:unlock-package` are called at the first prompt, so
`wasm/acl2-wasm.lsp` defines them as no-ops -- which is what `acl2.lisp`'s
`#+emscripten` branch already assumes.

The two obstacles that came before those bugs are still true and still worth
knowing:

1. **The reader is per file.**  A book's expansion file *needs*
   `*acl2-readtable*`; an ACL2 *source* file must not be read with it -- the
   driver chokes on the first `#\x`-style character with "When the ACL2 reader
   tries to read #\x, then x must either be a single character or one of
   Space, Tab, ...  However, Null is neither ...".  Bind the readtable only for
   `@expansion` files.
2. **The cross-compiler must be configured like the target.**  `$WORK/ecl-host`
   is configured with defaults, i.e. with threads; the wasm build is not.  A
   threaded ECL's `DEFSTRUCT` expands to `(mp::remcas 'accessor)` and
   `(mp::define-cas-expander ...)` calls (src/lsp/defstruct.lsp,
   `#+threads make-atomic-accessors`), which this runtime cannot make, so the
   first structure compiled by that host kills the load with "The function
   MP:REMCAS is undefined"; threaded and non-threaded builds also produce `.fas`
   files that cannot be loaded into each other (`ecl_process_env`).  So the
   build script now produces a third ECL, `$WORK/ecl-cross` -- the patched tree
   configured `--disable-threads --with-tcp=no` -- and `wasm/aot-book.sh`
   prefers it.

How that was found, in case it happens again: with the modules loading
correctly, the boot strap reached the last stage in about 20 s and then failed
at `(VERIFY-TERMINATION-BOOT-STRAP QUOTE-LISTP)` with "`IF is not of type CONS`"
-- a different symbol each run (`R-E-P`, `GENEQV-LST`, `FC-ROUND`, `9`,
`SIGNATURE-RULES-FORM-1`), i.e. a wrong *value* in world bookkeeping rather than
wrong control flow.  Ruled out along the way: `-O0` versus `-O2`,
`(optimize (safety 3))`, `ext:use-direct-c-call`, and `si::`/fixnum/inline
declarations (there are none in `rewrite.lisp`); a native control
(`compile-acl2` and `initialize-acl2` in `$WORK/ecl-cross`) reported `INIT OK`,
which is what showed the trouble was Emscripten-specific and not ACL2's Lisp or
ECL's Lisp-to-C translation.  Bisecting was cheap because native modules make
the boot strap fast: reverting one file to bytecode and re-running costs
20-90 s, and with master copies in `$WORK/modules` and `$WORK/bytecode` each
step is two `cp`s.  Six runs pointed at `rewrite.lisp`, which was a red herring
-- it was simply the file whose code happened to hold a live pointer in a wasm
local at the wrong moment.  What broke the case open was a differential test:
the same one-line function compiled both ways, where bytecode gave 100000 and
the module gave 65, and `GC_DONT_GC=1` made the module agree.  Lesson: when a
compiled function returns a plausible-but-wrong value, compare it against the
bytecode build on the *smallest* expression that still shows the difference, and
try `GC_DONT_GC` before reading any Lisp.

Bytecode is still needed after modules exist: `wasm/acl2-wasm-compile` copies
its `.fasc` output to `$WORK/bytecode` (`/opt/eclwasm/bytecode`) and
`wasm/aot-book.sh` runs the host ECL with `ACL2_AOT_BYTECODE_DIR` pointing
there, because a native ECL cannot load a module and the `.fasc` files in the
ACL2 directory are modules by then.

### Browser: dynamic linking works; the boot strap is what does not

`wasm/web/dylink.html` loads the `WEB=1 DYLINK=1` build of wasm ECL, writes a
compiled Lisp module into the in-memory filesystem, `(load "/dylink-test.fas")`
and calls its functions -- in the page, in 0.4 s:

    ;;; Loading #P"/dylink-test.fas"
    ; dylink-test module initialised
    ; dylink-double(21) = 42
    ; dylink-fib(20)   = 6765
    ; dylink-vec-sum   = 10

That is the same mechanism a certified book uses (`wasm/aot-book.sh` produces
the module, `load` reaches `si::load-binary`, ECL `dlopen`s it), so the browser
half of "certify a book, AOT it, include it" is proven.  Note the file type:
ECL dispatches on it, and `fas` is the `dlopen` path while `fasc` means
bytecode, hence the module is written as `/dylink-test.fas`.

What is still missing for ACL2 itself is the boot strap, not the loading: a page
cannot raise V8's stack, and the boot strap needs 2-4 MB of it.  That also
settles the snapshot question quantitatively: a full linear-memory
snapshot of the post-boot-strap state is **not shippable** -- that state was
measured at ~720 MB -- so of the two snapshot routes only the ACL2-level one
(serialize the world: 21.7 MB, ~5 MB gzipped) can go to a page, and that is the
`ecl-world-image` branch's replay, which is not yet sound-equivalent.  The
cheapest honest route to ACL2 in a page is therefore the source AOT above: it
removes the boot strap from the page rather than moving it elsewhere.

### The last wall: the boot strap needs more native stack than a page has

Measured on the `node-raw-dylink2` build (all 43 ACL2 files are wasm modules,
so the boot strap is the only thing running) by varying V8's `--stack-size`:

| `--stack-size` | result |
| --- | --- |
| 240 KB | dies during a module's `__ecl_init_fas_CODE`, ~100 nested `cl_stringL` frames |
| 1200 KB | dies in the boot strap |
| 2000 KB | dies in the boot strap |
| 4000 KB | reaches the prompt in 41.1 s |

A page gives V8 about 1 MB and there is no way to raise it (no `--stack-size`
in a browser), so the boot strap currently cannot run in a page.  What the wall
is made of, in the order it was established:

- **`ecl_interpret` is ECL's bytecode/AST interpreter**, not an AST-only path:
  `apply.d:114` sends `bclosure` (interpreted) functions there and `apply.d:117`
  sends bytecode functions there too.  So a stack trace full of
  `ecl_interpret` <-> `ecl_apply_from_stack_frame` pairs means *bytecode Lisp
  functions calling bytecode Lisp functions*, each costing three native frames
  (`ecl_interpret`, `ecl_apply_from_stack_frame`, and the dispatch).  A trace of
  native module code looks quite different: repeated `wasm-function[N]` entries
  with a single `variadic_dispatchK` between them.
- **It is not source being interpreted.**  The obvious theory is that the boot
  strap `ld`s `.lisp` files, whose `DEFUN`s then run through the AST
  interpreter.  It does not: hooking `ext::*load-hooks*` for type `"lisp"` and
  counting shows **zero** source loads, and hooking `"fas"` shows only modules.
- **So the deep recursion is ACL2 code that is compiled at run time**, i.e.
  `(compile ...)` through the bytecodes compiler, which in a page is the only
  compiler there is.  That is why the source AOT and the `*1*` AOT do not move
  this number: they make the *loaded* tree native, and the boot strap still
  compiles some of what it defines.

Instrumentation gotcha worth remembering: ECL compiles calls to `CL:LOAD` and
`CL:EVAL` into direct C calls, so `(setf (symbol-function 'load) ...)` and
`(setf (symbol-function 'eval) ...)` are invisible to compiled callers, and an
experiment that "shows" `EVAL` is never called during the boot strap concludes
nothing.  What does work: the `ext::*load-hooks*` table (looked up
at run time), and `TRACE`, whose depth indentation is the cheapest way to read
recursion depth in a build where no debugger exists.

The ways out, none of them started:

- **Fewer frames per Lisp call for bytecode code**: shrink `ecl_interpret`'s
  frame (it is one switch with a large union of locals) or give it its own
  wasm stack via a coroutine.  This is an ECL-side change but it is the only
  option that helps all bytecode at once.
- **Native code for what the boot strap compiles**: there is no C compiler in a
  page, so this means pre-compiling it, which is the `*1*` AOT idea extended to
  whatever `defun-fn` compiles during `initialize-acl2`.
- **Tail calls**: `-mtail-call` in the side-module and main-module link flags
  turns sibling calls into `return_call`, which is free stack for every
  tail-recursive ACL2 helper (`TAILS-AC` is one: `apply-prim.lisp:184`).  It
  cannot help interpreted or bytecode code, so it depends on the answer above.
- **Move the boot strap out of the page** -- a Wizer-style memory snapshot at
  build time, or the ACL2 world-image replay.  The snapshot is the only one
  that is fast *and* sound (the state is the real thing), and it is only
  feasible if a post-boot-strap linear memory can be made small enough to ship:
  measured at ~720 MB, so not as it stands.

### Publishing the browser harness (GitHub Pages)

`wasm/web/publish-gh-pages.sh <dir>` stages the pages, `worker.js` (rewritten to
point at the `DYLINK=1` build), `lib/ecl-dylink.{js,wasm}`, and the preloaded
files as `files.json` + `files/*.gz` (115 files, 22 MB), plus `.nojekyll`.

This repository already has a `gh-pages` branch -- it is the generated ACL2
documentation site (`f3dd85ffba`, "Generate index.html for each dir") -- and a
repository has only one Pages site, whose root must be `/` or `/docs` on the
chosen branch.  So a subdirectory of the documentation branch cannot be the
site root (the harness was published there first, in `ff3c9452d5`, and that was
reverted in `f49a63e182`).  The harness gets **its own branch**, rooted at the
branch root:

    git worktree add --detach /tmp/ghpages origin/gh-pages
    git -C /tmp/ghpages checkout --orphan gh-pages-wasm
    sh wasm/web/publish-gh-pages.sh /tmp/ghpages
    git -C /tmp/ghpages add -A && git -C /tmp/ghpages commit -m ...
    git -C /tmp/ghpages push origin HEAD:gh-pages-wasm

Then Pages is served from branch `gh-pages-wasm`, folder `/`; serving it also
unpublishes the documentation site, since only one of the two can be the site
for this repository.

The landing page (`wasm/web/index-gh.html`) says plainly what works in a page
(ECL, module loading, `include-book` of an AOT'd book) and what does not (ACL2
does not finish starting, for the stack reason above).

### Options for cutting the ~361 s startup

`compile-acl2` -- the ahead-of-time step the build already performs -- is not
what is missing: it removes a 66 s compile from each start, and loading the
resulting `.fasc` files costs ~10 s.  The 352 s is `initialize-acl2`'s two
`ld` passes plus the `*1*` step, and no amount of source AOT removes that.
The realistic options are:

- **AOT of the `*1*` counterparts** (`make exec-aot`) already exists for
  native ECL, and is now ported (see below).  Measured: it saves 5 s of the
  317 s start, because the prover's *expensive* boot-strap functions are
  `:program`-mode raw functions and so have no `*1*` counterpart at all.
  Worth keeping -- it makes every value-producing function native for the
  proofs that come later -- but it is not a startup lever on its own.
- **AOT of ACL2's own source files.**  This is the lever that *should* work:
  the 352 s is spent running `defun-fn`, `chk-acceptable-defuns1` and friends,
  which come from ACL2's source files and are bytecode.  Attempted, and it
  works as far as loading and running but not yet through the boot strap; see
  "Native wasm code for ACL2's own sources" below.
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
   cutting the ~361 s startup": a wasm memory snapshot (best), serializing
   the world / an ECL image, batching books per process (`certify-book!`
   undoes the book, so startup can be amortized), and the interpreter
   levers.  Source AOT is already done; AOT of the `*1*` counterparts would
   save only ~15 s.  For native ECL, image save is likewise the only way to
   remove the remaining ~5.4 s (serialization, an ECL image facility, or a
   memory snapshot).

   A prototype of the world-image route (serialize the post-boot-strap world
   and replay its properties, which reaches the ACL2 prompt in ~1.8 s
   natively) is on branch `ecl-world-image`, deliberately kept off this
   branch: it is **not yet sound-equivalent**.  `(check-acl2-initialization)`
   passes, but `(include-book "projects/apply/base" :dir :system)` fails a
   `badge-table` guard on the replayed image while `saved_acl2` includes it
   fine, and the replay loses the hons fast-alist registrations.  The
   acceptance gate for that branch is `make devel-check` plus
   `make -k -j 16 basic` with the replay launcher, compared against
   `saved_acl2`; do not use an image before it passes.
6. **Certify books under wasm at scale** (`cert.pl`).  Works for a handful of
   dependency-free books, and the full `basic` suite can now be attempted:
   `wasm/run-basic-wasm.sh` runs `make -k -j 16 basic` with the wasm
   launcher (~10 hours; see "Driver: `wasm/run-basic-wasm.sh`").  At ~375 s
   per book the only way to make this fast is item 5 -- cut the startup, or
   amortize it over books in a batch driver.
7. Wasmtime/WASI: blocked on ECL (see above).
8. **Native wasm code for the prover.** *Working for books (2026-11-06).*
   `wasm/mk-wasm32-target.lsp` + `DYLINK=1` builds turn a Lisp file into a wasm
   module the wasm ECL dlopens; measured 77-124x over the bytecode compiler.
   This removes the 12.6x half of the 98x and leaves the ~7.8x wasm factor, so
   it should be done *with* item 5 rather than instead of it.  Books are done:
   `ACL2_SAVE_EXPANSION=1` certifies with the expansion file kept, and
   `wasm/aot-book.sh <book>` compiles it into `<book>.fasc`, a wasm module that
   `include-book` then loads and runs (see "Books: the expansion file").
   What is still missing:
   - **two phases, not one.** `emcc` only exists on the host, so a book must be
     certified in the wasm ECL (which writes the expansion file) and then
     AOT'd in a separate host pass.  For a browser, either the modules are
     built and shipped ahead of time, or a C compiler is compiled to wasm
     (no JIT in a page: wasm cannot generate wasm without one).
   - **the pipeline needs a driver.** Nothing yet automates "certify 1,486
     books, then AOT them, then ship"; `wasm/aot-book.sh` takes the book names
     one run at a time (it loads ACL2's sources in ~1 s, so batching many books
     per invocation is the natural shape).
   - **staleness.** A `.cert` records the book's source hash, not the compiled
     file, so nothing notices a `<book>.fasc` built for a different wasm ECL.
   - **the `*1*` counterparts are done** (see "The `*1*` counterparts as a
     wasm module"): they load as a module and are worth 5 s of start-up plus
     native code for every `EV-FNCALL` afterwards.
   - **ACL2's own sources are done in Node, not in a page.**  43 modules load
     and run and cut the start from 310.6 s to 41.1 s, but the boot strap needs
     2-4 MB of native stack and a page has ~1 MB; see "The last wall: the boot
     strap needs more native stack than a page has" for what the wall is made
     of and the four ways out.
9. Upstream: the two ECL patches, the ACL2 `:emscripten` branches, and the
   boot-strap skip of the irrelevant-formals check (which helps every host)
   are small and self-contained; the `-O0` override in ECL's configure is
   worth revisiting upstream, as is the `MAIN_MODULE=1` + `ENABLE_DLOPEN`
   combination (ECL has no wasm branch for its loader at all).
