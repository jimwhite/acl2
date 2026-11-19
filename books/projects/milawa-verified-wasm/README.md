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
takes about ten seconds.  Nothing in the tree is expensive any more: the one
event that used to cost ten minutes is gone (see "What we learned" for why).

| Piece | State |
|---|---|
| Value domain, twelve primitives, `2^30` bounded arithmetic | **proved** (`milawa-lisp/values.lisp`) |
| `MILAWA-STEP` machine and `MILAWA-RUN` loop, total, `:ok` / `:abort` | **proved** (`milawa-lisp/eval.lisp`) |
| Kernel functions as data, in core syntax | **done** (`milawa-lisp/programs.lisp`) |
| Evaluation checks (rank, lookup, ord<, overflow, fuel exhaustion) | **proved** (`milawa-lisp/demo.lisp`) |
| **Fuel monotonicity** — a longer budget never changes a successful result | **proved** (`milawa-lisp/metatheory.lisp`) |
| Abort/acceptance disjointness, zero-fuel aborts, `-` closed under values | **proved** (`milawa-lisp/metatheory.lisp`) |
| `MILAWA-RUNS`: exact step-count relation, the two inference rules (`-HALT`, `-STEP`) and their step counts, positivity and shape, a worked derivation | **proved** (`milawa-lisp/reachability.lisp`) |
| Elimination principle for `MILAWA-RUNS` | **proved** — immediate, because the relation is a function of the exact count |
| `MILAWA-RUNS` agrees with `MILAWA-RUN` — soundness and completeness | **proved** (`milawa-lisp/reachability.lisp`) |
| `MVM-STEP` — ACL2 model of the module, 32-bit words, status protocol, fixed points | **proved** (`machine/mvm.lisp`) |
| `milawa-verified.wat` — the module: one step per call, runnable in Node | **done** (milestones: `wasm/`) |
| `MVM` model vs the module, on a spread of programs and every abort case | **tested** (`machine/mvm-tests.lisp`, Node recording) |
| **The example corpus**: ten programs with their answers, each recorded from the artifact and proved about the model | **done** (`examples/`, `machine/examples.lisp`) |
| The artifact decodes in the certified semantics; the module is pinned as a logic constant; `W3T::MODULE-P` of it is proved | **proved** (`wasm3/`) |
| The certified semantics executes the artifact: entry config is a call to function 6, `STEP` applies and is single-valued | **proved** (`wasm3/l1.lisp`) |
| Memory correspondence: word image round trip, region round trip (decoding a word list's image gives it back), stack and code images, lengths, disjointness | **proved** (`wasm3/memory.lisp`) |
| The abstraction `MVM` state → spec configuration, and the clock for every path (47–101 spec steps, opcode-determined) | **proved** (`wasm3/abs.lisp`, 16 theorems by evaluation) |
| L1 — one call to `STEP` equals `MVM-STEP` **for symbolic state** | **in progress** — statement fixed and validated on all 16 paths; the symbolic execution is next |
| L2 — `MVM` run level = `W3T::STEPS` | **not started** |
| L3 — `MVM` refines `MILAWA-EVAL` | **not started** |
| WASM 3.0 semantics available locally (`wasm-acl2` `7f96c89`, 26 books certified, IL reproducible from SpecTec) | **done** |
| Whole kernel (`milawa-init` from `milawa2.lsp`) | **not started** |

## The example corpus

`examples/*.mvm` is the honest lower-level stand-in for a Milawa events file: a
program and the answer it must give, one file each.  Each file's `expect:` line is
**recorded from the artifact** — `python3 harness/examples.py --record` runs
`wasm/milawa-verified.wasm` in Node — and `machine/examples.lisp` then **proves**
the model gives the same answer.  `python3 harness/examples.py --check` is what a
build runs.

```
$ python3 harness/examples.py --check
ok   if-lt-true.mvm: halted result=10 steps=6 pc=10
...
10 example(s) agree with the artifact
```

So a passing corpus is two claims, deliberately kept apart: *the artifact does X*
(a test, through a host we do not trust) and *the model does X* (a proof, by
evaluation).  The claim that joins them — agreement for all inputs — is L1 and is
open; when it lands, these files become its regression suite, and until then they
are the thing to point at when the question is "does any of this run yet".

Two of the ten are there to catch plausible mistakes rather than to show variety:
`sub-wraps` (`(- 0 1)` = `#xFFFFFFFF`, which the harness must report unsigned
because JS exports an `i32`) and `lt-signed` (`#xFFFFFFFF` is the largest unsigned
word but *less than* zero under `i32.lt_s`).

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
  reachability.lisp  exact step-count run relation, its inference rules
  top.lisp           includes the above
  Makefile

machine/             the machine the module implements
  mvm.lisp           MVM-STEP, MVM-RUN, 32-bit words, status protocol
  mvm-tests.lisp     differential checks against the module, recorded in Node
  top.lisp           includes the above
  Makefile

wasm/                the artifact
  milawa-verified.wat  one exported STEP per machine step; hand-written
  build.sh             assembles it with wat2wasm (WABT is untrusted)

harness/
  run.js               the untrusted host loop: node harness/run.js <wasm> <words...>
```

The module and the model are kept in step by hand, and the tests say so; L1 is
what makes that a theorem rather than a promise.

A fourth directory, `wasm3/`, holds the books that depend on the pinned
semantics; they are listed in `cert_pl_exclude`, so a community certification run
never has to find `wasm-acl2`, and are certified by `make -C wasm3`.

Still to come: L1 (one call to `STEP` equals `MVM-STEP`, stated against the
certified WASM 3.0 semantics from
[`wasm-acl2`](https://github.com/raymyers/wasm-acl2)), L2 (the run-level
instantiation), conses/symbols/environments in the module and the model, and
`kernel/` (per-`defun` correspondence to `ACL2/logic/`).

## Building

```sh
cd books/projects/milawa-verified-wasm/milawa-lisp
make ACL2=/path/to/saved_acl2
```

That certifies every book here; the whole tree takes a few seconds.  The WASM
side is a separate, pinned clone, `../../../../.wasm-acl2` (commit `7f96c89`),
and its 3.0 books are generated rather than checked in:

```sh
cd ../../../../.wasm-acl2/translate
make gen SPEC=3.0 ACL2=$ACL2                    # ~2 min, no Nix needed
$ACL2_SYSTEM_BOOKS/build/cert.pl --acl2 $ACL2 -j 4 gen/wasm-3.0/wasm3
make check-il SPEC=3.0 NIX=/nix/var/nix/profiles/default/bin/nix   # Nix; the IL must match SpecTec
```

or, for a single book,

```sh
$ACL2_SYSTEM_BOOKS/build/cert.pl --acl2 $ACL2 values
```

Use the same ACL2 that certifies the rest of the community books.  No external
books are needed at all yet.  When the WASM books arrive, `wasm-acl2` is pinned
rather than vendored, and this directory must stay out of the default
community-books scan (or be listed in `EXCLUDED_PREFIXES`), because a missing
dependency is a build failure for everyone.

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

**`definductive` gives the elimination principle, but you cannot use it.**
This one cost a day.  `std/util/definductive` (Coglio and Jurgensen) takes the
inference rules and generates the predicate, the intro rules and
`MILAWA-RUNS-ALT-WHEN-MILAWA-RUNS`; instantiating `ALT` with the property you
want *is* the elimination principle.  It also admits the predicate over a proof
object, so the generated induction scheme's step case is stated in terms of
`MILAWA-RUNS-PROOF-KIND` and `MILAWA-RUNS-PROOF-STEP->C2`, not in terms of the
rule's premises.  Every route back to the premises was measured and failed:

| Attempt | Result |
|---|---|
| `:induct (milawa-runs c n r ftbl)` | step case splits on `milawa-step`, `apply-step`, `nth`, `assoc-equal`; 147 subgoals, then exponential |
| `(disable milawa-runs)` first | also disables the `:induction` rune; "no schemes are suggested" |
| `:induct (milawa-runs-induct ...)`, the scheme function by name | same proof-object scheme |
| `:by (:functional-instance NAME-ALT-WHEN-NAME ...)` | re-proves the source theorem by induction on the proof object: >16 min and still running |
| deriving the corollaries with `:use` | pushes a build past 30 min |

The fix is to stop paying for the proof object: state the relation as the two
rules *as a function of the exact step count*, so the continuation is `(cdr s)`
rather than an existential, and the induction scheme is the halt/step split you
wanted in the first place.  Thirteen events, 0.2 s total, same theorems.  The
`definductive` version is in the history at commit `4814380c1b`.

**"Exactly N" is not "at most N".**  Defining `MILAWA-RUNS` from
`(milawa-conf-run c ftbl n)` looks equivalent and is not: `MILAWA-RUN` stops the
moment it produces a result, so a halting machine "runs" in every count at least
as large as its step count.  A WASM `STEP` derivation gives an exact count, so
the definition must spend its count.

**Measure before guessing.**  Several certification timeouts in a row were
resolved by running the book's forms directly and reading the `Time:` lines,
which named the single expensive event.  `(ld "book.lisp")` after including its
dependencies is the cheapest way to get per-event timings — and the `Form:` line
that appears before a long grind is not evidence about which event is grinding.

**Guard the demo with executable checks.**  The refactor from a recursive
evaluator to a step machine introduced a real bug — a primitive's value was
returned as the machine's result instead of being handed to the waiting frames,
so any application of a primitive inside a larger expression returned nil.  The
`assert-event` checks in `demo.lisp` caught it immediately; the proofs did not.

**A hypothesis you can measure is better than one you can argue for.**  Three
attempts at L1's symbolic form.  With no hints the goal comes back *unreduced* --
ACL2 will not unfold a recursive definition on symbolic arguments unless asked, so
the first run measured a hint problem and nothing else.  With
`(enable w3t::step)` on the whole 9-step chain: killed at 400 s.  One single step
gets a long way cheaply -- `$INVOKE`, `$WITH_GLOBAL`, `%GET-FIELD`/`%PUT-FIELD`,
`EXPAND` and the module's lookups all reduce -- and stops at `STEP/R-CTXT-INSTRS`,
the rule that steps inside an instruction sequence.  That looks like the "context
lemma" upstream calls E11's hard part, and it is not: the module's WASM code is a
constant of the artifact, so every instruction list in a configuration is
concrete, and the split point the context rules search for is decidable on one
(`step/prefix7` = 0, 1, 2 on the module's own bodies).  The `%SIZE` guard goes with
it.  The real blocker is ACL2 declining to unfold `STEP`'s recursive chain -- a
theory-design problem, not a missing lemma -- which is why the work is an
instruction-lemma library rather than a size-lemma library.

**ACL2's `TAKE` pads.**  `(take 3 '(a b))` is `(A B NIL)` and `(take 1 nil)` is
`(NIL)`: there is no `ENDP` test, so "a prefix is no bigger than the list" is
*false* without a length hypothesis, and a length hypothesis is not obvious until
the padding has bitten you once.

**An index is not a shape.****An index is not a shape.****An index is not a shape.**  The memory correspondence — decode the image of a
word list and get the word list back — looks like a one-liner and resisted about
eighteen attempts across two sessions, because the natural statement indexes
bytes with `(nthcdr (* 4 i) bytes)`.  The `(* 4 i)` is equal to
`(+ 4 (* 4 (i-1)))` but is a *different term*, so every append lemma fails to
match; making the split a rewrite rule hits a HARD ERROR [Call depth] 1000 as
`fold-consts-in-+` folds it back.  Unfolding the 32-bit recogniser instead splits
each induction step on `(integerp (car ws))`, `(<= 0 ...)` and `(< ... 2^32)`:
259 subgoals, then 4963, then 387 s and 56 GB.  Unfolding `mvm-word-to-bytes`
brings `loghead`/`logtail` in and does the same thing arithmetically: 9.5M
prover steps, still open.

What works is to change the *shape of the decoder* to match the shape of the
event: it consumes four bytes a step (`car`, `cadr`, `caddr`, `cadddr`), never an
index; a **step rule** states the per-word round trip about the append form
(`mvm-image-words-of-append-word`); and the recogniser plus the byte-level
definitions are **disabled** during the region induction, with
`:forward-chaining` rules supplying the recogniser's facts.  0.48 s.  The lesson
generalises: when an induction will not close, stop looking for the right hint
and look for the right *statement*.

## Trust

| Trusted | Why |
|---|---|
| ACL2 and its host Lisp | already trusted by Milawa's own stage-1 proof |
| SpecTec and the SpecTec→ACL2 translator (`wasm-acl2`) | generated semantics; no theorem connects the output to the source |
| the WASM engine that runs the artifact | the role the CPU plays in Jitawa |
| one execution of the certified binary decoder, to turn the `.wasm` into the module constant | `W3T::GRAM/BMODULE` is `:program` mode, so this step cannot be a theorem; it is scripted and checked (`harness/gen_module.py --check`) |
| the front end and the I/O shim | untrusted by design: a bug there can cause a rejection, never a false acceptance, provided the acceptance predicate is proved about the parsed value |

Not trusted: the evaluator, the primitives, the allocator, the compiled runtime,
and — once `kernel/` exists — the correspondence between the kernel program and
`logic.proofp`.

## Next steps, in order

1. **Port the loop to WASM.**  L1: one dispatch iteration of the module is one
   `MILAWA-STEP`.  L2: instantiate the run-level theorem from `wasm-acl2`'s
   `engine/`.  This needs `wasm-acl2` pinned.  `milawa-runs-halt` and
   `milawa-runs-step` are already stated in the shape `W3T::STEP` has, which is
   what the refinement cases match against.
2. **`kernel/`.**  One lemma per `defun` of `milawa-init`, generated with
   `make-event` from the ACL2 bodies.
3. **The phase-0 experiments from the design document**, which are still open:
   instrument `+` for its maximum value (does anything exceed `2^30`?) and
   `ftbl` (does the checker ever call a function installed by a `DEFINE`
   event?).  The second one underwrites the whole "no JIT" argument.
