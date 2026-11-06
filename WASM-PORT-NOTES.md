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
8. Upstream: the two ECL patches, the ACL2 `:emscripten` branches, and the
   boot-strap skip of the irrelevant-formals check (which helps every host)
   are small and self-contained; the `-O0` override in ECL's configure is
   worth revisiting upstream.
