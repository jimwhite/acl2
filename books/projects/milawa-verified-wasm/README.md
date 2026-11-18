# milawa-verified-wasm

A verified Lisp runtime for Milawa, verified in ACL2, targeting WebAssembly.

This is the implementation of the plan in
[`../milawa/VERIFIED-WASM-LISP.md`](../milawa/VERIFIED-WASM-LISP.md).  It adds
new books; it does not change the existing Milawa tree or the existing
ECL-based WebAssembly checker in [`../milawa/wasm/`](../milawa/wasm/).

The goal is the sentence Milawa's `README` uses for Jitawa, with ACL2 in place of
HOL4 and WebAssembly in place of x86-64:

> if you run the simplified Milawa kernel on this runtime inside any conforming
> WebAssembly engine, it can only accept theorems of formulas that are
> semantically true.

## Status

Seven books, all certifying; no `skip-proofs`, no `defaxiom`.  A clean build
takes about ten seconds plus ten *minutes* for one event: the `MILAWA-RUNS`
elimination principle (see below).  That is deliberate.  Correctness first —
Milawa's own ECL/WebAssembly checker run takes two days — and the proof
engineering to make that event fast is tracked as a next step.

| Piece | State |
|---|---|
| Value domain, twelve primitives, `2^30` bounded arithmetic | **proved** (`milawa-lisp/values.lisp`) |
| `MILAWA-STEP` machine and `MILAWA-RUN` loop, total, `:ok` / `:abort` | **proved** (`milawa-lisp/eval.lisp`) |
| Kernel functions as data, in core syntax | **done** (`milawa-lisp/programs.lisp`) |
| Evaluation checks (rank, lookup, ord<, overflow, fuel exhaustion) | **proved** (`milawa-lisp/demo.lisp`) |
| **Fuel monotonicity** — a longer budget never changes a successful result | **proved** (`milawa-lisp/metatheory.lisp`) |
| Abort/acceptance disjointness, zero-fuel aborts, `-` closed under values | **proved** (`milawa-lisp/metatheory.lisp`) |
| `MILAWA-RUNS`: relational presentation of the machine (`definductive`), the per-rule step-count facts, and a worked derivation | **proved** (`milawa-lisp/reachability.lisp`) |
| Elimination principle for `MILAWA-RUNS`, via `definductive`'s `-ALT` rule and functional instantiation | **proved** (`milawa-lisp/reachability.lisp`); one event costs ~600 s |
| `milawa-runs-positive` and `milawa-runs-shape` (corollaries of elimination) | **not yet** — statements recorded; proving them through `:use` currently exceeds 30 min |
| `MILAWA-RUNS` agrees with `MILAWA-RUN` | **not yet**; follows from the corollaries |
| `MVM` step machine port, WASM module, L1/L2 refinement | **not started** |
| Whole kernel (`milawa-init` from `milawa2.lsp`) | **not started** |

## Why this shape

Three decisions carry the design; the long version is in the design document.

**The target is `milawa2.lsp`, not `milawa.lsp`.**  The simplified kernel is a
first-order Lisp with twelve primitives, integers bounded to `[0, 2^30)` with
`+` aborting on overflow instead of using bignums, and the whole kernel
expressed as data.  It was written to be a verified-runtime target.

**Verify an interpreter, not a compiler.**  `core.admit-defun` in `milawa2.lsp`
only records `(name formals body)` in a function table; nothing in the checker
ever calls a function installed by a `DEFINE` event.  So the runtime needs no
JIT, no runtime `compile`, and no verified compiler.  Proof work is then
proportional to the size of the *runtime*, not of the kernel.

**The source language is ACL2's internal term language.**  Core Milawa-Lisp
terms are `(quote x)`, `(if a b c)`, variables, function calls, and lambda
applications — exactly what `translate` produces.  That is why a Milawa-Lisp
program can be the ACL2 source text itself, and why the correspondence between
a translated function and the evaluator should be provable one `defun` at a
time.

**The runtime is a step machine, not a recursive interpreter.**  `MILAWA-STEP`
is a non-recursive function from one configuration to the next (or to a
result); `MILAWA-RUN` is a fuel-counted loop with a single tail call.  Two
things fall out.  Fuel monotonicity is provable, because the step has no fuel
argument.  And the machine the WASM module must implement is already written
down, so L1 compares the module with `MILAWA-STEP` rather than with a
tree-walking evaluator.

`MILAWA-EVAL` returns `(:MILAWA-OK . value)` or `(:MILAWA-ABORT . reason)`.
Every place where the Common Lisp kernel would signal, quit, or overflow is an
abort.  Because abort is a constructor rather than a side condition, the
soundness statement needs no partiality: "the runtime failed" is an ordinary
value, and an abort is provably not an acceptance.

## Layout

```
milawa-lisp/
  values.lisp        value domain, primitives, tagged results
  eval.lisp          MILAWA-STEP, MILAWA-RUN, MILAWA-EVAL, MILAWA-CALL
  programs.lisp      kernel functions as data (*MILAWA-DEMO-PROGRAM*)
  demo.lisp          executable checks on that program
  metatheory.lisp    fuel monotonicity, abort/acceptance facts
  reachability.lisp  inference rules for reaching a result (definductive)
  top.lisp           includes the above
  Makefile
```

Planned: `machine/` (the `MVM` port of the step machine), `wasm/` (L1 per-step
refinement against the WASM 3.0 semantics from
[`wasm-acl2`](https://github.com/raymyers/wasm-acl2), and the L2 run-level
instantiation), `kernel/` (per-`defun` correspondence to `ACL2/logic/`), and
`harness/` (WAT sources, the build, the JS shim, differential tests).

## Building

```sh
cd books/projects/milawa-verified-wasm/milawa-lisp
make ACL2=/path/to/saved_acl2
```

or, for a single book,

```sh
$ACL2_SYSTEM_BOOKS/build/cert.pl --acl2 $ACL2 values
```

Use the same ACL2 that certifies the rest of the community books.  No external
books are needed yet beyond `std/util/definductive`.  When the WASM books
arrive, `wasm-acl2` is pinned rather than vendored, and this directory must stay
out of the default community-books scan (or be listed in `EXCLUDED_PREFIXES`),
because a missing dependency is a build failure for everyone.

## Adding a program

Programs are lists of `(name formals body)` triples whose bodies are in core
syntax.  Two rules:

1. Constants are written `(quote n)`, not `n`.  Core Milawa-Lisp is ACL2's
   internal term language, so there are no unquoted literals.
2. `let`, `let*`, `cond`, `and` and `or` are surface syntax.  Expanding them is
   the job of the untrusted front end, so the verified evaluator only ever sees
   `if`, `quote`, variables, calls, and lambdas.

Then evaluate with

```lisp
(milawa-call 'rank (list x) *milawa-demo-program* fuel)
```

and check the result in `demo.lisp` with `assert-event`, or state a theorem
about it in `metatheory.lisp`.

## What we learned

These are the findings that cost the most time, recorded so they are not
rediscovered.  Each is a property of ACL2 or of `definductive`, not of Milawa.

**A `mutual-recursion` clique gets no induction machine.**  Writing the
evaluator as `eval` / `eval-args` / `eval-application` is the natural shape and
is a dead end for metatheory: `:props` shows no `INDUCTION-MACHINE`, and
`:induct` reports "No induction schemes are suggested".  The single
tail-recursive loop is not just tidier, it is what makes the metatheory
reachable.

**Two different fuels need a matched induction scheme.**  For monotonicity,
`:induct (milawa-run ... n)` is not enough: the induction hypothesis is then
about the original `m`.  The fix is an induction-hint function,
`milawa-run-induct`, that descends `(1- n)` and `(1- m)` together.

**Keep the step symbolic.**  `milawa-step` has twenty branches.  Expanding it
during a symbolic proof turned a single subgoal into ~150, none nearer to done.
Disabling `milawa-step`, `milawa-apply-*` and (in the relational book)
`milawa-conf-step` is what made every hard proof go through.

**A fuel-decreasing theorem must not be a rewrite rule.**  Both
`milawa-run-monotone` and the `milawa-runs` elimination principle rewrite a term
into one with a smaller measure, or into one that contains the original as a
conjunct.  As rewrite rules they loop: ACL2 either reports a call-depth error or
grinds for minutes.  `:rule-classes nil` plus `:use` is the fix, every time.

**`definductive` gives you the elimination principle for free — use it.**
Unfolding a `definductive` predicate is hopeless (it is stored as "a minimal
valid proof tree exists", so unfolding drags in the minimality machinery).
`MILAWA-RUNS-ALT-WHEN-MILAWA-RUNS` is the least-fixpoint principle: instantiate
`ALT` with the property you want and discharge its two constraints by functional
instantiation.  Two details: the property must *include the relation itself*
(otherwise the step rule's premise is unrecoverable), and an introduction rule
whose continuation appears only in hypotheses has a free variable, so it cannot
backchain — instantiate it with `:use`.

**Measure before guessing.**  Two certification timeouts in a row were resolved
by running the book's forms directly and reading the `Time:` lines, which named
the single 598-second event.  `(ld "book.lisp")` after including its
dependencies is the cheapest way to get per-event timings.

**Guard the demo with executable checks.**  The refactor from a recursive
evaluator to a step machine introduced a real bug — a primitive's value was
returned as the machine's result instead of being handed to the waiting frames,
so any application of a primitive inside a larger expression returned nil.  The
`assert-event` checks in `demo.lisp` caught it immediately; the proofs did not.

## Trust

| Trusted | Why |
|---|---|
| ACL2 and its host Lisp | already trusted by Milawa's own stage-1 proof |
| SpecTec and the SpecTec→ACL2 translator (`wasm-acl2`) | generated semantics; no theorem connects the output to the source |
| the WASM engine that runs the artifact | the role the CPU plays in Jitawa |
| the front end and the I/O shim | untrusted by design: a bug there can cause a rejection, never a false acceptance, provided the acceptance predicate is proved about the parsed value |

Not trusted: the evaluator, the primitives, the allocator, the compiled runtime,
and — once `kernel/` exists — the correspondence between the kernel program and
`logic.proofp`.

## Next steps, in order

1. **Add the elimination corollaries.**  `milawa-runs-positive` (every
derivation has `N > 0`) and `milawa-runs-shape` (one finishing step, or at least
two steps with a derivation of the continuation) follow from the elimination
principle alone and are the form the refinement books consume.  Their
statements are commented at the end of `reachability.lisp`; proving them through
`:use` currently pushes a build past thirty minutes, so this wants either a
cheaper elimination proof or a direct proof from `MILAWA-RUNS-GOODP`.
2. **Make the elimination proof cheap.**  The event costs ~600 s because ACL2
specialises `N` to 1 (via the HALT closure lemma) before re-deriving the
relation conjunct, after which `(+ 1 N)` no longer matches `MILAWA-RUNS-STEP`.
Explicit `:use` instantiations of the two intro rules for the shapes ACL2
actually reaches should collapse it.  Speed is a *later* concern; this is listed
second only because it unblocks item 1.
2. **Prove `MILAWA-RUNS` agrees with `MILAWA-RUN`.**  Soundness and
   completeness, with the fuel-exhaustion case excluded (stopping for lack of
   fuel is not a run; it is the runtime declining to answer).  The matched
   induction trick from `metatheory.lisp` applies here too.
3. **Port the loop to WASM.**  L1: one dispatch iteration of the module is one
   `MILAWA-STEP`.  L2: instantiate the run-level theorem from `wasm-acl2`'s
   `engine/`.  This needs `wasm-acl2` pinned, and it is where `definductive`
   pays off again, since `W3T::STEP` is relational.
4. **`kernel/`.**  One lemma per `defun` of `milawa-init`, generated with
   `make-event` from the ACL2 bodies.
5. **The phase-0 experiments from the design document**, which are still open:
   instrument `+` for its maximum value (does anything exceed `2^30`?) and
   `ftbl` (does the checker ever call a function installed by a `DEFINE`
   event?).  The second one underwrites the whole "no JIT" argument.
