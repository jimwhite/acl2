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

Thirty-three books, all certifying; no `skip-proofs`, no `defaxiom`.  A clean
build takes a couple of minutes; `make check` at the top of this directory runs
every book, the example corpus, and the two policy checks, and refuses to pass if
any book in the tree has been skipped.

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
| Memory correspondence: word image round trip, region round trip (decoding a word list's image gives it back), stack and code images, lengths, disjointness, and **the i-th word of an image** (`(take 4 (nthcdr (* 4 i) image)) = the word's bytes`) | **proved** (`wasm3/memory.lisp`) |
| The numeric bridge between the spec's little-endian bytes and the image: `(mvm-word-to-bytes w) = ($le-bytes 4 w)`, `($le-int ($le-bytes 4 w)) = w mod 2^32`, and **both directions of `$nbytes_`/`$inv_nbytes_` at i32** — the load rule's guard and its value | **proved** (`wasm3/numerics.lisp`, 12 measured events, 25k prover steps) |
| The abstraction `MVM` state → spec configuration, and the clock for every path (47–101 spec steps, opcode-determined) | **proved** (`wasm3/abs.lisp`, 16 theorems by evaluation) |
| The instruction library the chain is assembled from: seven layers, `step_pure` and `step_read` lemmas, the context rules, calls, returns | **proved** (`wasm3/instructions.lisp` … `wasm3/returns.lisp`) |
| The body of function 6 as a literal, with its first instruction stepped — the bottom of the chain, generated | **proved** (`wasm3/chain.lisp`) |
| A whole `step` of a one-instruction configuration, and the head rule in three forms — the general one taking the instruction's own step as a hypothesis | **proved** (`wasm3/head.lisp`) |
| The search's failure facts: an instruction without its operands is not stepped | **proved** (`wasm3/search.lisp`) |
| The chain: two instructions of the exported function's body, level by level, and the two links **composed** | **proved** (`wasm3/chain.lisp`, `wasm3/links.lisp`) |
| **The frozen path** (`status ≠ 1`): all nine steps end to end — the call, the branch, the block, the read inside the block's label, the two returns — the **exact clock**, and the **readback** to `MVM-STEP`: `milawa-step-check`'s conclusion for a symbolic state | **proved** (`wasm3/frozen.lisp`) |
| **The running branch's shared head** (`status = 1`): the seven steps every running path starts with — the status test's else branch, the empty block and its label, the call split, and the call into `$in_code`'s frame — with `$in_code`'s body at the head, and the first instruction of that body stepped | **proved** (`wasm3/running.lisp`) |
| **The callee's tail and the in-code dispatch**: `$in_code`'s body end to end — the sub, the read of the code length, the mul, the comparison (the last instruction, stepped by the pure rule), and the two value dissolves — then, under the in-code hypothesis (the comparison is 1, so the testop's value is the concrete 0), the opcode test, the second ifelse, and the empty block/label dissolve, and the first instruction of the opcode fetch (`global.get 1`) | **proved** (`wasm3/dispatch.lisp`, 78 measured events, 214M prover steps) |
| **The opcode fetch and the first frame write**: the `i32.load` of the opcode — a read whose guard is the numeric round trip, with the in-bounds hypothesis that rules out the TRAP branch — then `local.set 0`, the first write, storing the opcode in the callee frame's local 0; both lifted to function 6's frame at symbolic `pc`/`clen`/`bytes`/opcode | **proved** (`wasm3/load.lisp`, 15 measured events, 8.49M prover steps) |
| **The next fetch instructions and the first two dispatch tests**: the second `global.get 1` (pc, through the updated frame); the add `pc + 4`; the `global.set 1` write of pc; `local.get 0`; the opcode test `(relop eq)` against zero and its ifelse in both cases; the block step; then the CONST test (`local.get 0`, `(const 1)`, `relop eq`) and its ifelse and block/label positions; generic ifelse fail/slice facts for every test; and the halt branch's first call split (`(:CALL 2)` = `(:REF.FUNC_ADDR 2)` + the call_ref type, at the callee pair) | **proved** (`wasm3/fetch.lisp`, 111 measured events, 211.1M prover steps) |
| **The last three dispatch tests**: the ADD/SUB/LT test's whole OR-chain (`eq 2`, `eq 3`, `or`, `eq 4`, `or`) and its ifelse (opcode 2/3/4 vs the rest); the IFZ test (`const 5`) and the JMP test (`const 6`), each through its local.get, equality, ifelse (both cases) and block/label positions; the false path now reaches `(call 4)`, the unknown-opcode abort | **proved** (`wasm3/dispatch-tests.lisp`, 114 measured events, 559.6M prover steps) |
| **The halt branch through the `$pop` call and its callee's second read**: the first call and its label-1/frame-6 lifts, the eqz testop, the abort ifelse's else branch, the empty block/label dissolve, the `$pop` call's split and entry, the callee's first read, `sub`, `global.set 0` write and second read; the instruction-list tails are correct, the pure return-label search's nil fact is stated at the evaluated label body, and the write's reconstructed store is stated at `(:%;% ($sof z) ($fof z))` with the literal callee record (the size conditions compute only then) | **proved** (`wasm3/halt.lisp`, 349 measured events, 217.2M prover steps); the halt body is proved end to end from the block's label body: the `$depth` call, the eqz test and ifelse (both branches), the `$pop` call and its callee, the result write `global.set 4 := W`, the status write `global.set 3 := 0`, and function 6's explicit `(:RETURN)` through label 0/label 1/frame 6 |
| **The unknown-opcode abort**: `(:CALL 4)` splits to `(:REF.FUNC_ADDR 4)` + the call_ref type; the call entry pushes `$abort`'s frame (body `((const 2) (global.set 3) (const 2))`, status := 2, implicit return); both are lifted through the caller's admin label, and the entry's **frame lift is closed** — the frame rule's parameterized wrapper instantiated at the updated store, with the inner label step discharged by a pair bridge (spelled `$sof`/`$fof` pair → the helper) and the label fact; and the callee's body is executed through the status write (`global.set 3` := 2, via the lone-failure/context-failure/slice recipe) and the callee frame descent (also restated at the helper pair, so the way out does not need the forward bridge); the step back out begins: the pair shape/component facts, the caller's label lift over the callee frame (helper pair, 28.6M), and the same lift at the SPELLED pair (so the frame rule's inner step matches it with no bridge; 36k, with the store's shape a fact and the step definition instance handed in — `:expand` does not fire once the config's arguments are rewritten); the **outer frame lift** over that label is closed (the outer frame wrapper instantiated at the updated store and the caller's frame; 8.9M steps), and the implicit value-returns — the pure `label-vals`/`frame-vals` steps and the callee-frame-around-a-value wrapper — are proved; the remaining way-out steps compose those through the caller's label and frame 6 | **closed**: the abort's implicit return is four pure steps (label-vals, frame-vals, label-vals, frame-vals) proved once generically (`dret-*`, 10.4M/1.07M/19.6k/43) and instantiated at the abort's store (2.7k/2.2k/1.7k/1.3k) | **done** (`wasm3/abort.lisp`, 40 measured events, 54.7M prover steps) |
| **The out-of-code entry and the abort callee**: the in-code comparison's zero case — the testop tier (the value 0, its slice, the ifelse on 0 with its else branch) and the ifelse tier's slice/lifts through the empty block and label, the `(:CALL 4)` abort split at the body level and its entry, `$abort`'s frame lift, the callee's body end to end (status := 2 through the lone/slice/ctxt/write recipe and the frame descent), and the unknown-opcode fallthrough's label/frame value-returns (`frame-label-vals`, the callee-frame-around-a-value wrapper) | **proved** (`wasm3/oob.lisp`, 46 events, 9.18M prover steps) |
| **The CONST tail (opcode 1)**: the testop/ifelse true branch of the CONST test — the `$in_code` call's lone split and entry, `$in_code`'s seven body positions (read/sub/read/mul/ltu and the two value dissolves), the testop/ifelse/empty-block/label tiers (the search's result spliced as `(const 0) :: (cdr of the tail)`), the `(global.get 1)` read of pc, the `(i32.load)` of the instruction word under the memory hypotheses, the `local.set 1` write (index 1 — the first write whose `update-nth` needs the opaque-`$with_local` treatment), the pc increment `(global.get 1)(const 4)(add)(global.set 1)` with the store global 6 write, and the `(local.get 1)` read-back of the word; then the `(call 0)` hand-off — the call's expansion and 3-element entry slice (the argument W), the dispatcher's ctxt refusals that make the search terminate, and the whole-config lifts at the tail's continuation; and function 0 `$push`: its seven instructions end to end through the seven-layer chain per position (slice, body ctxt, body step, label, arity-0 frame wrapper, continuation lift, step) at the explicit z spellings the frame rule builds — positions 0-4 (the two global reads, the local read, the memory store with its generic in-z slice and its lone/one-value refusals, and the add) — plus the arity-0 frame wrapper, the generic ctxt lift, the respell bridge and the value facts; position 5 (the `global.set 0` write of `sp + 4`) is also closed — its two-element slice does not fire the ctxt rule (the search's measure ties), so its step is the `global.set` rule itself and the ctxt is nil; the val-p of `(dadd sp)` and the opaque `$with_global` make the tier cheap; the void-return dissolves (the label-vals inside the frame and the frame-vals) are the remaining pieces of the callee, and the module's function 0 is confirmed as the stack-push (`sp` in global 0) | **proved** (`wasm3/const.lisp`, 132 facts; the callee through its last instruction) |
| L1 — one call to `STEP` equals `MVM-STEP` **for symbolic state** | **in progress** — one of the sixteen paths (the frozen one: the halted and aborted states) is proved from entry configuration to observations; the other fifteen are open |
| L2 — `MVM` run level = `W3T::STEPS` | **not started** |
| L3 — `MVM` refines `MILAWA-EVAL` | **not started** |
| WASM 3.0 semantics available locally (`wasm-acl2` `7f96c89`, 26 books certified, IL reproducible from SpecTec) | **done** |
| Whole kernel (`milawa-init` from `milawa2.lsp`) | **not started** |

## Building

One command, from this directory:

```
$ make check ACL2=/path/to/saved_acl2
--- lint (parentheses the way ACL2 reads them)
lint: 39 file(s) balance the way ACL2 reads them
--- milawa-lisp / machine / wasm3          (books, in dependency order)
--- artifact vs pinned module              (module.lisp, state.lisp: up to date)
--- example corpus (artifact)              (10 example(s) agree with the artifact)
--- litmus: no skip-proofs, no defaxiom    (none in 39 book(s))
--- every book has a certificate           (39 books, all certified)

===== summary =====
books certified:  33
corpus examples:  10
```

`make help` lists the rest (`books`, `examples`, `module-check`, `no-skips`,
`lint`, `experiment`, `walk`, `complete`, `clean`).  A full clean rebuild takes
a few minutes; the dispatch book alone is about three and a half.

**The books are in their own package.**  Every book in `milawa-lisp/`,
`machine/` and `wasm3/` is in `MILAWA-WASM`, so the functions and theorems this
project defines cannot collide with another book's.  The package is defined in
`package.lsp` -- a `defpkg` is not an embedded event form, so it cannot live in
a book -- and each directory's `cert.acl2` loads it before certification.  To
include a book by hand in a session, load the package first:

```lisp
(ld "package.lsp")
(include-book "wasm3/frozen")
```

`make experiment` and `make walk` do this for you.  The name is
project-specific rather than `MILAWA` because the sibling Milawa ACL2 tree
(`../milawa/ACL2/package.lsp`) already defines a `MILAWA` package with a
different import list.  A system-book name that ACL2 does not export must be
imported explicitly (`expt2`, `logapp`, `loghead`, `logtail` from the `ihs`
books) or used with its package prefix (`acl2::rem-bounds`,
`acl2::loghead-identity`).

**`make walk`** asks the semantics what the next steps actually are:

```
$ make walk
STEP 0: ok=T len-instrs=1 head=:FRAME_%{%}% zdiff=NIL
STEP 1: ok=T len-instrs=1 head=:FRAME_%{%}% zdiff=NIL
...
STEP 8: ok=T len-instrs=1 head=:CONST zdiff=NIL
STEP 9: ok=NIL len-instrs=0 head=NIL zdiff=T
```

`step` is a logic function, so on a concrete configuration ACL2 will simply
compute it -- which makes the shape of the next step a fact to read off rather than
guess.  `--full` prints each instruction list, `VALUE=1` runs a different branch.
This is the tool that unblocked the opcode chain: several attempts failed with a
hand-written configuration in a hint and no way to know it was wrong.

Two of those targets exist because of mistakes made while building this:

**`make lint`** counts parentheses the way ACL2's reader does — skipping `;`
comments, `#| ... |#` blocks, `"..."` strings and `|...|` escaped symbols — and
says so when a file is balanced for ACL2 but not for a naive reader.  That second
half earns its keep: an editor claimed `wasm3/chain.lisp` was unbalanced, and the
file was perfect.  A generated file whose literals hold thousands of parentheses
is exactly the case a reader without comment context gets wrong.  The lint run
found the one real instance of this in the tree — a comment writing an interval as
`[0, 2^30)`, whose bare `)` makes a comment-blind reader see one parenthesis too
many — and it now reports zero.

**`make experiment FILE=/tmp/try.lsp BOOK=chain`** runs a scratch ACL2 script with
the working directory, timeout, log path and summary all fixed:

```
acl2: dir=wasm3 book=chain elapsed=4s timeout=900s
acl2: Q.E.D.=1 errors=0 raw-errors=0 prover-steps=5
acl2: log=/tmp/acl2-wasm3-smoke.log
```

`include-book` resolves against the working directory, so getting the `cd` wrong
silently loads nothing and the error you then chase is in the wrong place; and a
diverging proof with no timeout sits there.  Both happened repeatedly while
building the chain, which is why this is a script and not a habit.

The `complete` target is worth its own line: it checks that every `.lisp` in a book
directory has a `.cert` beside it, and it exists because it caught a real bug —
`wasm3/Makefile`'s `BOOKS` line had silently lost the three newest books to a bad
string replacement, so a fresh checkout certified 23 of 26 and nothing complained. A
count of certificates cannot tell "all of them" from "the ones we remembered to
list".

`node` is needed only for the corpus, which runs the real `.wasm`; the books do not
need it.  The `wasm3/` books need the pinned `wasm-acl2` tree's 26 generated books
certified first, and `make books` says so rather than failing obscurely.

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

**`:expand` cannot unfold a member of a mutual recursion; a `:definition`
instance can.**  The certified semantics' `step`, `step/r-ctxt-instrs`,
`step/r-ctxt-label` and `step/r-ctxt-frame` are one clique, so `:expand
((w3t::step cfg))` unfolds `step` and stops dead at `(step/r-ctxt-frame cfg)`.
Adding `:expand` for that symbol, or enabling its definition rule, changes
*nothing* -- 23,319 prover steps in every variant, byte for byte.  What works is
to instantiate the axiom by hand:

```lisp
:use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 cfg)))
```

**A rewrite rule whose left-hand side contains `(cons x y)` cannot match a quoted
constant.**  This is a real tension, not a bug: the semantics' search only
computes when the instruction list is a *literal*, and the rewriter treats
`(quote ...)` as an atom rather than decomposing it into cons structure.  So a
general rule about `(cons instr rest)` and a literal body are incompatible, and
what works is an *instance* stated at each position.

**The semantics' search refuses a lone instruction.**  `step/search21` requires a
value before the instruction or an instruction after it.  A lemma without
`(consp rest)` is therefore *false*, not merely hard -- one attempt spent 401,630
prover steps chasing it.

**When the intermediate configurations of a proof keep coming out wrong, compute
them.**  `step` is a logic function, so on a *concrete* configuration ACL2 will
evaluate it and print the result: that is the specification of the lemma, not a
guess.  `python3 harness/gen_chain.py --probe` does exactly this, and it settled in
one run what several rounds of hand-written `:definition` instances had not.

**`acl2-count` of a symbol is the length of its name**, so the tempting
`(equal (equal (acl2-count x) 0) (not (consp x)))` is false.  The one-directional
form `(implies (consp x) (< 0 (acl2-count x)))` as a `:linear` rule is what
discharges the measure obligations, in 381 steps.
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

**The block is a READ rule, not a context rule.**  The block step looked like
the one that would need a general context-descent lemma, because the
semantics has no `step/r-ctxt-block`.  It does not: `step_read/split/r-block`
rewrites `(:BLOCK bt instrs)` into `(:LABEL_ n NIL instrs)` (with `n` the number
of result types in the blocktype), and it is reached through `step/r-read` --
the ordinary instruction search.  So a block is a *flat* position like any
other: the per-position recipe applies, and a lone block proves by evaluation
(516 prover steps).  The label the rule produces is the extra
level the following steps have to descend through, which is a shape fact, not a
new lemma.

**A call leaves the CALLEE's frame.**  The walk's configuration and the links'
configuration both use the pinned frame `(CADDR Z)` as the frame under the
label.  The call actually leaves `(milawa-callee-frame 6)`, whose four
zero-initialised locals make it a different term -- and the body reads globals
through its frame's module, so "the frames differ" is not a detail that cancels.
The chain that composes with the call has to be stated at the callee's store:
`wasm3/frozen.lisp` does.  (The modules are equal, which is why the same
`global.get` lemmas go through.)

**A free variable in a lemma's LHS is fatal to composition.**  The inner-label
steps carry `status` in their *result* but not in their *input* -- the input is
a label around a `global.get`, and the status only appears once the read has
happened.  As rewrite rules those lemmas have a free `status`, and their
conclusions cannot be matched.  Binding it explicitly in the `:use` instance,
`(status status)`, is the whole fix; without it the same goal grinds for
minutes.

**`steps/%fuel` does not unroll on a constant fuel alone.**  With an opaque
configuration under it, ACL2 will neither evaluate it nor apply its definition
rule.  The step-count composition is therefore one `:rule-classes nil` successor
lemma per step plus a definition instance, used through `:use`; as a rewrite
rule the fuel-decreasing successor would loop, which is the same lesson as
`milawa-run-monotone`.

**Composing one-level context lemmas stops working at depth.**  The steps
inside `$in_code`'s body (`wasm3/running.lisp`) descend through frame 6, label
6, frame 3 and label 3.  Nine one-level facts, each taking the next as a
hypothesis, do not close by `:use` at that depth (ACL2 re-derives the guards;
the direct attempt was 143M steps).  What works is two single-shot lemmas: one
with every definition instance from label 3 up to frame 3, and one from frame 3
up to frame 6 taking the first as a fact.  3.5M and 30M steps.  The general
lesson matches the memory-correspondence one: when a proof will not close,
change the decomposition rather than the hint.

**An instruction list is not a list of instruction lists.**  The body at label
6 is frame 3 around label 3 around the callee's body, followed by the rest of
function 6.  Writing that as `(cons (dadmin b) rest6)` puts the *one-element
list* `(dadmin b)` where the frame instruction belongs; `dadmin` already
returns a list and the first element is `(car (dadmin b))`.  The malformed body
still steps -- its first element is a list, not an instruction, and the search
just fails -- so it does not show up as an evaluation error: it shows up as
every measure check comparing the wrong two lists, with false linear
inequalities like `(<= (+ 22581 pc) (+ 17854 pc))` as the final goal.  Days
went into that inequality.  `wasm3/running.lisp`'s `ibody` has the right shape;
`dfull` in `wasm3/dispatch.lisp` is the same `(append (dadmin b) rest6)`.

**`acl2-count` counts an integer by its absolute value.**  In this ACL2
(`axioms.lisp`), `(acl2-count 5)` is 5, not 0.  A configuration's instruction
list therefore carries the *values* of its 32-bit constants into every context
rule's `%SIZE` guard, and a symbolic `pc` or `clen` inside a body turns the
guard into arithmetic in `pc`: `$BINOP_` gets evaluated, `numerator` and
`denominator` appear, and a goal like `(<= 2^32 pc)` is left over.  The fix is
to keep each intermediate value as an opaque function term and give it a
conditional `:type-prescription` (`integerp-dsub`, `integerp-dmul`,
`integerp-dltu`, `integerp-testop-eqz`), so `acl2-count` charges it as
`(integer-abs term)` on both sides of every comparison.  With that, the whole
callee tail certifies in 207M prover steps; without it, the same lemmas do not
close.  Measured per event: the sub's context rule 14.8M, the mul's 70.5M (the
most expensive), the outer label-6 lifts 12-20M each, the two dissolve outs
18.5M and 17.1M.

**A body position's shape decides its recipe.**  The sub, the read and the mul
have an instruction after them, so the search steps them and the lift is
flat/ctxt, label, frame, label 6, frame 6.  The comparison is the *last*
instruction of function 3's body: the search's k = 0 branch refuses an
instruction list with nothing after it, so the body is stepped by the pure
`r-relop` rule and the lift starts from that.  After the comparison the label's
body is a value list and dissolves (`r-label-vals`), then the frame does
(`r-frame-vals`).  Classify the position before choosing the lemmas.

**A rewrite rule can be applied to its own right-hand side.**  The readback
needs to shift an index onto a list -- `(nth (+ k a) b) = (nth k (nthcdr a b))`
and `(nthcdr (+ 4 a) l) = (nthcdr 4 (nthcdr a l))` -- and as rewrite rules they
do not terminate.  `:brr` showed the mechanism: ACL2's arithmetic matcher binds
`a = 0` and applies the rule to the constant `4` on its own right-hand side, so
`(nthcdr 4 X)` becomes `(nthcdr 4 (nthcdr 0 X))` and grows (an eight-line repro
confirmed it).  Keep such facts `:rule-classes nil` and use them through `:use`,
and where an index must meet a list, change the statement to the append form:
`(nth (+ i (len pre)) (append pre b)) = (nth i b)` proved through `nthcdr`, which
is what let the stack-words readback close.

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

1. **L1 for the other fifteen paths.**  The frozen path is one of sixteen and
   is proved end to end for symbolic state; the running branch's shared head and
   the callee's tail (`$in_code`'s body and its two dissolves) and, in the
   in-code case, the opcode test, the second ifelse, and the empty block/label
   dissolve are proved, so every in-code running path now starts at the opcode
   fetch in function 6's body.  What remains on the shared route is the
   out-of-code case (the comparison is 0, so the ifelse aborts through
   `$abort`) and then the opcode fetch and the fourteen per-opcode tails, whose
   clocks are already measured in `abs.lisp`.  The
   branch paths enter a block and then a call, so their links are the frozen
   path's plus `calls.lisp`'s.
2. **L2**: the run level.  Each machine step is a fresh `$INVOKE`, so the run
   theorem is a re-entry composition rather than one long `STEPS/%FUEL`.
3. **L3**: `MVM` running compiled code refines `MILAWA-EVAL`, with the compiler
   untrusted.
4. **The phase-0 experiments from the design document**, which are still open:
   instrument `+` for its maximum value (does anything exceed `2^30`?) and
   `ftbl` (does the checker ever call a function installed by a `DEFINE`
   event?).  The second one underwrites the whole "no JIT" argument.
