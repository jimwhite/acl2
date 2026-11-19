# milawa-verified-wasm — one page for reviewers

**Goal.** The sentence Milawa's `README` uses for Jitawa, with ACL2 for HOL4 and
WebAssembly for x86-64:

> if you run the simplified Milawa kernel on `milawa-verified.wasm` inside any
> conforming WebAssembly engine, it can only accept theorems of formulas that are
> semantically true.

**Shape.** Verify an *interpreter*, not a compiler.  `core.admit-defun` in
`milawa2.lsp` only records `(name formals body)` in a function table, so the
checker never calls a compiled definition; an interpreted function table
suffices, and the proof is O(size of the runtime) rather than O(size of the
kernel).  Three layers, each separately meaningful:

```mermaid
flowchart TB
    S["W3T::STEP (certified WASM 3.0 semantics)"]
    W["milawa-verified.wasm"]
    M["MVM-STEP (ACL2 model of the module)"]
    E["MILAWA-EVAL (Milawa-Lisp semantics)"]
    W -- "L1: one call to STEP = one MVM-STEP" --> M
    M -- "L2: run level = W3T::STEPS" --> S
    M -- "L3: VM refines the interpreter" --> E
```

## What is proved (28 books, no `skip-proofs`, no `defaxiom`)

| Book | Content |
|---|---|
| `milawa-lisp/values.lisp` | value domain, 12 primitives, `2^30`-bounded arithmetic that aborts on overflow |
| `milawa-lisp/eval.lisp` | `MILAWA-STEP` (one step, total) and `MILAWA-RUN` (one tail-recursive fuel loop) |
| `milawa-lisp/programs.lisp` | kernel functions as data, in core syntax |
| `milawa-lisp/demo.lisp` | executable checks: rank, lookup, `ord<`, overflow, fuel exhaustion |
| `milawa-lisp/metatheory.lisp` | fuel monotonicity; abort/acceptance disjointness; zero fuel aborts |
| `milawa-lisp/reachability.lisp` | `MILAWA-RUNS`: exact step count, the two inference rules, positivity, shape, and that it agrees with `MILAWA-RUN` both ways |
| `machine/mvm.lisp` | `MVM-STEP`/`MVM-RUN`: the ACL2 model of the module, 32-bit words, status protocol.  A stopped machine is a fixed point; spending a budget in two instalments is spending it at once; **fuel monotonicity** — once it has stopped, a larger budget changes nothing |
| `machine/examples.lisp` | the example corpus: ten programs, each with the answer the artifact actually gives (recorded in `examples/*.mvm` from Node), proved about the model by evaluation — so the corpus is a test of the artifact and a proof about the model, kept separate on purpose |
| `machine/mvm-tests.lisp` | model vs module on a spread of programs — **tests, not proofs**, and labelled so |
| `wasm3/chain.lisp` | **generated, the bottom of the chain**: the body of function 6 as a literal, and its first instruction stepped — `step/r-ctxt-instrs` of `(:;% z BODY)` giving the value followed by the rest of the body.  A rewrite rule cannot match a literal, so this is an instance, and the generator emits it |
| `wasm3/head.lisp` | **the assembly layer**: a whole `step` of a one-instruction configuration (`step`, `step/r-read`, and the three forms of the head rule, the most general of which takes the instruction's own step as a hypothesis), the abstract store's reconstruction from its two halves, and the one piece of list arithmetic the semantics' search needs |
| `wasm3/memory.lisp` | the L1 memory correspondence: an MVM state's image in the module's memory (32-bit little-endian words, stack below 4096, code above), with the round trip `bytes-to-word (word-to-bytes w) = w` for 32-bit words **and at region level — decoding a word list's image gives the word list back** — image lengths, and the disjointness invariant |
| `wasm3/returns.lisp` | **layer 7**: returning — out of the label, then out of the frame, leaving the callee's result |
| `wasm3/calls.lisp` | **layer 6**: the call rule — the entry configuration steps to a frame-and-label admin around the artifact's own code, with the locals zero-initialised |
| `wasm3/context.lisp` | **layers 4 and 5**: the context rules — a step inside a `:LABEL_` and inside a `:FRAME_` are steps of the body, re-wrapped; the composition law the library rests on |
| `wasm3/frames.lisp` | **layer 3**: `local.get` of all four locals with the frame symbolic — the layer every opcode's operand load goes through |
| `wasm3/reads.lisp` | **layer 2**: `global.get` of all five globals in the abstract store — the first place the store is symbolic in a proof |
| `wasm3/instructions.lisp` | **layer 1 of the instruction library**: ten `STEP_PURE` lemmas with symbolic values — five i32 binops, four comparisons, the zero test — stated at the static value count so the rule chain evaluates; the first place here where a symbolic state is stepped rather than evaluated |
| `wasm3/symbolic.lisp` | the abstraction a *symbolic* proof wants: the same store with the memory bytes a variable, the two lookups proved (field lookup on symbolic leaves, and the memory reading back as given), and the layering the instruction library follows |
| `wasm3/abs.lisp` | the abstraction itself: `MVM` state → entry configuration of a call to the exported `STEP`, through the spec's own `$WITH_MEM`/`$WITH_GLOBAL`, and the inverse observations. **Sixteen theorems, one per path through the module** — every opcode, every abort, both frozen statuses — each giving the exact clock and the fact that what the semantics stopped on reads back as `MVM-STEP` |
| `wasm3/l1.lisp` | the certified semantics executes the artifact: entry configuration is a call to function 6 with no arguments, `STEP` applies and is single-valued, three steps apply, one step enters the frame |
| `wasm3/decode.lisp` | the artifact decodes completely and instantiates with no externs (scripted, since the decoder and the instantiator are `:program` mode); the module is pinned as a logic constant; its shape, export names, and the fact that `STEP` is function 6 are theorems |

## The example corpus

`examples/*.mvm` is the lower-level stand-in for a Milawa events file: ten programs
with the answer each must give.  Each file holds the program as MVM words and an
`expect:` line that is **recorded from the artifact**, never written by hand —
`harness/examples.py --record` runs `wasm/milawa-verified.wasm` in Node and writes
the line.  `machine/examples.lisp` (generated by `--gen-lisp`) then **proves** the
model gives the same answer, by evaluation.

| Example | Program | Answer |
|---|---|---|
| `if-lt-true` | `(if (< 1 2) 10 20)` | halted, 10, 6 steps |
| `if-lt-false` | `(if (< 2 1) 10 20)` | halted, 20, 6 steps |
| `arith` | `(+ 20 (- 3 1))` | halted, 22, 6 steps |
| `sum-1-to-5` | `(+ 1 (+ 2 (+ 3 (+ 4 5))))` | halted, 15, 10 steps |
| `sub-wraps` | `(- 0 1)` | halted, **4294967295**, 4 steps |
| `lt-signed` | `(< -1 0)` | halted, 1, 4 steps |
| `jmp` | JMP over a `CONST` | halted, 7, 3 steps |
| `unknown-opcode` | opcode 7 | aborted, 1 step, PC 1 |
| `const-truncated` | `CONST` with no immediate | aborted, 1 step, PC 1 |
| `halt-empty-stack` | `HALT` with an empty stack | aborted, 1 step, PC 1 |

So a passing corpus means *the artifact does X* (a test, in Node, through a host we
do not trust) **and** *the model does X* (a proof, by evaluation).  The sentence
that ties the two together — that they agree for all inputs — is L1, still open.
Keeping the two claims separate, and both checkable, is the point: when L1 lands,
these same ten files become its regression suite.

Two of them earn their place by disagreeing with the obvious guess: `sub-wraps`
because `(- 0 1)` is `#xFFFFFFFF` and the harness has to report it **unsigned**
(JS exports an `i32`, so it prints `-1` unless asked not to), and `lt-signed`
because `#xFFFFFFFF` is the largest unsigned word yet is *less than* zero under
`i32.lt_s`.

`wasm/milawa-verified.wat` is the module: hand-written, one exported `STEP` per
machine step — the granularity of `MILAWA-STEP` and `W3T::STEP`, so no layer has
to reason about a loop.  It runs in Node today (`node harness/run.js`).

## Trust inventory

| Trusted | Why |
|---|---|
| ACL2 and its host Lisp | already trusted by Milawa's stage-1 proof |
| SpecTec + the SpecTec→ACL2 translator | generated semantics; no theorem connects output to source |
| the WebAssembly engine | the role the CPU plays in Jitawa |
| the front end and the I/O shim | can only cause a rejection, never a false acceptance |
| **one execution of the certified binary decoder, and one of the instantiator**, to turn the `.wasm` into the module and store constants | `W3T::GRAM/BMODULE` and `W3T::$INSTANTIATE` are `:program` mode, so neither step can be a theorem; both are scripted and checked (`harness/gen_module.py --check`).  Everything after them — `$INVOKE`, `STEP`, `STEPS/%FUEL`, `MODULE-P` — is `:logic`, so L1 and L2 are statable |
| WABT (`wat2wasm`) | untrusted by construction: a buggy assembler can produce a module that fails the proof, never one that passes it |

Not trusted: the evaluator, the primitives, the heap, the compiled runtime, and —
once `kernel/` exists — the correspondence between the kernel program and
`logic.proofp`.

## Four findings worth passing on

1. **`definductive` gives an elimination principle you cannot afford.**  It admits
   the predicate over a proof object, so the generated scheme's step case is
   stated in terms of `-PROOF-KIND` and `-PROOF-STEP->C2`, not the rule premises;
   the only route back is the `ALT` rule, whose functional instantiation
   re-proves the source theorem by induction on that proof object.  Measured:
   >16 min, unfinished.  Stating the rules *as a function of the exact step count*
   gave the same theorems in **0.2 s** and the halt/step induction a refinement
   proof actually wants.
2. **A `mutual-recursion` clique gets no induction machine**, so an evaluator
   written as `eval`/`eval-args`/`eval-application` is a dead end for metatheory.
   The single tail-recursive loop is what makes the metatheory reachable.
3. **"Exactly N" ≠ "at most N".**  A relation defined from the fuelled loop says a
   halting machine runs in any larger count; a WASM `STEP` derivation gives an
   exact count, so the count must be spent.  And completeness must exclude fuel
   exhaustion, or the theorem is simply false (ACL2 found it).
4. **Keep the machine step symbolic.**  Expanding `MILAWA-STEP` (20 branches) or
   `MILAWA-CONF-STEP` in a symbolic proof turns one subgoal into ~150; every hard
   proof here depends on disabling it and matching the hypothesis instead.

## The abstraction, and the clock

`mvm-abs` turns an MVM state into the configuration the certified semantics runs:
the artifact's own store, with the stack image written below byte 4096 and the
code image above it, and five globals set — SP (byte offset), PC (byte address),
CODE-LEN, STATUS, RESULT.  Those five and the memory under SP are the module's
whole mutable state, so `milawa-observations` reads a stopped configuration back
as machine state.

With the abstraction fixed, the clock is a fact rather than a parameter.  One
machine step is **47 to 101 spec steps, and the count depends only on the
opcode**:

| Path | Spec steps |
|---|---|
| status already 0 or 2 (frozen) | 9 |
| PC off the end of the code | 26 |
| HALT with an empty stack (abort) | 47 |
| HALT, one or two values | 53 |
| CONST | 67 |
| CONST with the immediate off the end (abort) | 55 |
| ADD / SUB / LT | 96 / 101 / 101 |
| ADD with fewer than two values (abort) | 63 |
| IFZ taken / not taken | 99 / 95 |
| JMP | 78 |
| unknown opcode (abort) | 63 |

That the clock does not depend on the *values* is what makes the symbolic proof's
clock a small case split rather than a search, and it is why `abs.lisp` is the
template for L1 proper rather than a detour.  Two of the numbers are worth
reading twice: an unknown opcode is cheaper than a known one (63 < 96) because it
falls out of the dispatch chain straight into `$abort`, and a truncated `CONST`
is cheaper than a good one (55 < 67) because it aborts before pushing.

Two things about the spec's API that cost time and are now written down in the
book:

- `$WITH_MEM` and `$WITH_GLOBAL` take the store-**and-frame** pair `Z`, not a
  store: `($SOF Z)` is the store and `($FOF Z)` the frame, and the module's index
  vector — the thing mapping a module global to a store slot — lives in the
  *frame*.  A store alone cannot be updated.
- the frame `$INVOKE` builds does not answer `%GET-FIELD :MODULE`, so the
  observers read the store through the pinned frame.  That is sound and is what
  we want: the module is a constant of the artifact and only the store varies.

### What the symbolic version actually hits

Four measured attempts.  The negative results are the useful part: the obstacle
is not where the plan assumed, and one of them dissolved on measurement.

**(a) The whole 9-step frozen-status chain, no hints.**  It does not even start:
the goal comes back *unreduced*, with `STEPS/%FUEL`, `STEP` and `$INVOKE` still in
it.  ACL2 will not unfold a recursive definition on symbolic arguments unless
asked.  A hint problem, not a cost problem — so the earlier "900 s and no output"
run was not measuring the chain either.

**(b) The whole chain with `(enable w3t::step)`.**  Killed at 400 s.  (One step
*with* `step` enabled is the same 0.13 s and the same failure as (c), so enabling
it is not the lever either.)

**(c) One single step, no hints.**  The rewriter *does* expand `$INVOKE`,
`$WITH_GLOBAL`, `%GET-FIELD`/`%PUT-FIELD`, `EXPAND` and the module's own lookups,
so a configuration with concrete shape and symbolic leaves is tractable; it walks
down `STEP`'s rule chain and stops at `STEP/R-CTXT-INSTRS` — the rule that steps
*inside* an instruction sequence.  It fails in 0.13 s and 29k prover steps, cheap
enough to iterate on.

**(d) The context-rule guard, measured.**  I first read (c) as "the `%SIZE`
guard in the context rules needs context lemmas".  That was wrong, and the
measurement is in `wasm3/size.lisp`: the module's WASM code lives in the store's
`:CODE` field, which neither `$WITH_MEM` nor `$WITH_GLOBAL` touches, so **every
instruction list in a configuration is concrete**; only the memory bytes and the
five globals are symbolic.  And the split point the context rules search for is
decidable on a concrete instruction list:

```
(step/prefix7 '((:GLOBAL.GET 3) (:CONST (:I32) 1) ...))    = 0
(step/prefix7 '((:CONST (:I32) 7) (:RETURN)))              = 1
(step/prefix7 '((:CONST (:I32) 7) (:CONST (:I32) 9) ...))  = 2
```

So the `%SIZE` guard — which mentions only the instruction list — evaluates too,
and the strict size lemmas are **not** on the critical path.  They are in
`wasm3/size.lisp` anyway (with the bridge that `%SIZE` is `acl2-count` hidden
behind `mbe` and disabled), because they are cheap and true and would be what an
arbitrary-program statement needs.

So the remaining blocker for a symbolic step is (a)+(b): `STEP` is a chain of
`(let ((r (STEP/R-X c))) (if r r (next)))`, and on a symbolic configuration ACL2
cannot decide any `STEP/R-X`, so the proof splits on each in turn instead of
walking the chain.  The residual goal of the single step says so exactly:

```
Subgoal 2
(IMPLIES (W3T::STEP/R-CTXT-INSTRS <config>) ...)
```

The lever is therefore not to enable `STEP` (measured: no difference) but to
enable **one `STEP/R-X` at a time** and feed its recursive call from the previous
lemma.  Concretely, the recipe for one instruction is:

1. state the successor as an explicit term, so nothing is invented at proof time;
2. `:in-theory (e/d (step/r-<that-rule>) (w3t::step))` — unfold only the rule, so
   the inner `STEP` stays symbolic and becomes the *hypothesis* rather than a thing
   to evaluate;
3. discharge that inner `STEP` with the lemma proved at the previous instruction,
   by `:use`, i.e. compose the chain by hand instead of asking ACL2 to run it.

That is an instruction-lemma library with the recursion factored out, and it is
the same object the engine's E4 builds — arrived at from the other direction.

**(e) The abstraction with an abstract memory.**  `wasm3/symbolic.lisp` restates
the abstraction with the memory bytes a variable instead of the pinned page, and
proves the two facts a symbolic proof needs first: that a field lookup on a store
with symbolic leaves is decidable (`%GET-FIELD` is `assoc-equal` on keys, and the
keys are concrete — the probe that "failed" had written `(list :globals g)` where
the store uses `(:globals . g)`, so it was the probe that was wrong), and that the
memory field reads back as the variable it was given.  With the page abstract, the
failing step leaves **one readable subgoal** instead of a screen of memory:

```
Subgoal 2
(IMPLIES (W3T::STEP/R-CTXT-INSTRS <configuration>) ...)
```

That is the rule which steps *inside* an instruction sequence.  ACL2 asserts it
rather than evaluating it, because evaluating it needs `(STEP <inner config>)`, and
the inner configuration carries the symbolic store, so `STEP/SEARCH21`'s walk down
the instruction list cannot bottom out.

### Layer 4: the context rules

The context rules are where the proof first reasons about *nesting*: a step inside a
`:LABEL_` or `:FRAME_` admin is a step of the whole configuration.  Measured, on the
smallest such statement — "stepping a config whose only element is a `:LABEL_`
wrapping one `local.get` is stepping the body and re-wrapping it":

- ACL2 leaves the goal as `(IMPLIES (W3T::STEP/R-CTXT-INSTRS <config>) ...)` and
  gives up in 215 prover steps;
- `:in-theory (enable w3t::step/r-ctxt-instrs w3t::step/prefix7
  w3t::step/search21)` changes nothing — the *same* 215 steps.

The reason, from `:pe`: these functions carry

```lisp
(declare (xargs :ruler-extenders :all
                :measure (wrt::%om3 (wrt::%size (nth 2 %a0)) (1+ (wrt::%size (list %a0))) 0)))
```

`:ruler-extenders :all` plus a `%SIZE`-based measure means the rewriter will not
open the definition unless the measure provably decreases at each unfolding — so
`enable` is the wrong lever entirely, and no amount of it helps.

The lever is **`:expand`**: force one unfolding of the rule function for the specific
term, let its concrete guards reduce, and expand the level beneath it with a `:free`
pattern.  `wrt::%size` is `acl2-count` behind `mbe` and disabled, which is what
`size.lisp` supplies.

**It works.**  `wasm3/context.lisp` proves two lemmas:

- `no-ctxt-instrs-on-a-lone-label` — the *negative* fact that has to come first: on
  a configuration whose only element is a label, `ctxt-instrs` does not apply.  242
  prover steps, two `:expand` hints.
- `step-in-label-local-get` — the context lemma itself: a step inside a `:LABEL_` is
  a step of the body, re-wrapped.  61,409 prover steps.
- `no-ctxt-instrs-on-a-lone-frame` / `-label-general` — the same negative fact for a
  frame, and generalised in the body, 458 prover steps each, which is what the
  deeper lemmas need.
- `step-in-frame-local-get` — **layer 5**, the nesting a call actually uses:
  `(frame n F (label k nil body))`.  14,310 prover steps.

The frame rule's bookkeeping is not symmetric and is worth having written down: the
inner configuration it steps is `(:;% (:;% S F') instr*)` — the store with the frame
carried by the *admin*, because that is whose locals the body reads — while the
result carries the *outer* frame, `(:;% (:;% S' F) ((:FRAME_ n F'' instr'*)))`.  Store
updates flow outward, frames flow inward; a lemma that swaps them is false rather
than hard, which ACL2 will simply refute.

That second one is the composition law the instruction library rests on: it is what
lets a chain of single-instruction lemmas be lifted out of the nesting.  The other
three context rules have the same shape; `ctxt-frame` is the one a call needs.

### Layer 6: entering a call, proved

`wasm3/calls.lisp` proves both halves:

- `no-ctxt-instrs-on-a-call` — 37,304 prover steps.  With `(:REF.FUNC_ADDR 6)`
  counting as a value (prefix7 = 1), the ctxt-instrs rule still does not apply to a
  call; measured before it was proved (`ctxt-instrs` NIL, `call_ref-func` T).
- `step-call-enters-frame` — 85,194 prover steps.  The entry configuration steps to

  ```
  (:;% Z ((:FRAME_ 1 F ((:LABEL_ 1 nil BODY)))))
  ```

  with `Z` unchanged, `F` the callee's frame with its locals zero-initialised, and
  `BODY` the callee's code taken out of the store's `:CODE` field.  The right-hand
  side is built by `milawa-callee-admin`, which is a *definition* rather than a
  literal because the body is two hundred lines; it was verified against the
  artifact by evaluation before any proof was attempted.

That is the whole entry path: layers 1-3 say what the body's instructions do, 4-5
lift a step out of the label and frame, and 6 puts the frame there in the first
place.

### Layer 7: returning, proved

`wasm3/returns.lisp`.  Both return rules are in `STEP_PURE`, because both
manipulations happen inside the *instruction list* -- the frame and label are
admins that appear in it, so unwrapping them needs no store at all.  Traced on the
shape a call produces:

```
((:FRAME_ 1 F ((:LABEL_ 1 nil ((:CONST 1) (:RETURN))))))   start
((:FRAME_ 1 F ((:CONST 1) (:RETURN))))                     label gone
((:CONST 1))                                               frame and return gone
```

- `step-pure-return-out-of-label` — the label is dropped, body kept whole.
- `step-pure-return-out-of-frame` — frame and `:RETURN` both go, leaving the
  callee's result.  The frame's arity is pinned to 1, which is the module's own
  arity (`step` returns one i32).

Three hypotheses emerged one at a time from ACL2's checkpoints rather than from
reading the rule: the label's type field is a `true-listp`, and the returned value
is `(unsigned-byte-p 32 x)` — which is *exactly* the rule's own guard,
`(and (integerp x) (<= 0 x) (<= x 4294967295))`, and also exactly what an i32
constant is.

### Why the library stays per-instruction

The obvious next move after layers 4-7 is to generalise the context laws: "if the
body steps to `inner`, the label steps to `inner` re-wrapped", with the body a
variable.  Measured: **400 s, killed**.  The reason is the same one that shaped the
whole library: the context rule has to *find* the split point in the instruction
list (`STEP/PREFIX7`, then `STEP/SEARCH21` walking k down), and with a symbolic body
that search cannot bottom out — so the rule cannot be shown to apply.

That is not a setback, it settles a design question.  Since the module's bodies are
**constants of the artifact**, every lemma the chain needs can be stated about a
concrete instruction list with symbolic *values*, which is exactly the shape layers
1-3 use and the shape that works.  A general law would be elegant and is not needed:
the chain is over `(milawa-func-body i)`, and `i` is fixed.

So the opcode theorems are built by specialising, and the work is mechanical: one
lemma per *instruction of the module's body*, at its static stack height, plus the
context wrapper from layers 4-7.  The measured clock per opcode (9 for a frozen
status, up to 101 for SUB) is the number of links in that chain, and it is now
visible: tracing the frozen path gives exactly

```
9: ((:FRAME_ 1 F ((:LABEL_ 1 is0 BODY))))     after the call
8..2: the same shape, stepping inside the label
1: ((:CONST i32 0) (:RETURN))                 inside the frame
0: ((:CONST i32 0))                           the value, frame gone
```

— one call, six steps inside, and two returns.

### How `step` descends, and the trick that unfolds it

Attacking the chain's first link produced the most useful structural result of this
stretch, and corrected a wrong assumption.

**Wrong assumption.** I had assumed `step/r-ctxt-instrs` is NIL on a config whose
instruction list is flat, so that the descent would fall through to the pure and
read rules.  It is not.  Reading the generated semantics
(`4_3-execution_instructions.lisp`) settles it:

```
(defun step/r-ctxt-instrs (a0)
  ... (let* ((%t9 (step/prefix7 %t6)))          ; leading values
        (and (< %t9 (len %t6))
             (step/search21 %t9 0 %t9 %t6 %t9 z a0))))
```

`step/prefix7` counts the leading values, then `step/search21` walks `k` *down*
from that count, and at each `k` it takes one instruction, wraps it in a
context-free config and calls `step` on it.  So `step/r-ctxt-instrs` is the
function that **finds the instruction to step next** and puts the surrounding
values back with `append`:

```
(:;% z' (append (step/iter20 values) (append instrs' rest)))
```

That is the mechanism the whole `step` rests on, and it means an instruction lemma
of the layer-1/layer-2 shape (values before, instruction last) is exactly what
`step/ctxt-instrs` consumes.  The layers built earlier are therefore the right
ingredients -- the chain does not need a separate interface.

**The descent for a frame holding a label.**  With `C0 = (:;% Z ((:FRAME_ 1 F ((:LABEL_ 1 nil BODY))))`,
one step is

```
step C0
  step/r-pure C0            -> nil
  step/r-read C0            -> nil
  step/r-ctxt-instrs C0     -> nil        (frame is not a value; the inner
                                           step on the frame itself recurses)
  step/r-ctxt-label C0      -> nil        (the one element is a frame, not a label)
  step/r-ctxt-handler C0    -> nil
  step/r-ctxt-frame C0      -> fires: steps (:;% (:;% S F) ((:LABEL_ 1 nil BODY))) = C1
    step/r-ctxt-instrs C1   -> nil        (a lone label -- no-ctxt-instrs-on-a-lone-label-general)
    step/r-ctxt-label C1    -> fires: steps (:;% (:;% S F) BODY) = C2
      step/r-ctxt-instrs C2 -> fires: the head instruction is global.get 3,
                               so (step (:;% Z1 ((:GLOBAL.GET 3)))) must give the
                               value, and the result is the value appended to BODY's tail
```

Three nested `step` calls, two inner nil-ness facts (both already proved), and one
per-instruction fact (the value of `global.get 3`, proved in `reads.lisp`).

**The trick: `:expand` cannot unfold a mutual-recursion member, a `:definition`
instance can.**  `step`, `step/r-ctxt-instrs`, `step/r-ctxt-label`,
`step/r-ctxt-frame` are one mutual recursion, so `:expand ((w3t::step C0))`
unfolds `step` and then *stops dead* at `(step/r-ctxt-frame C0)` -- adding
`:expand` for that symbol, or enabling its definition rule, changes nothing at
all (measured: 23,319 prover steps in every variant, byte for byte).  What works
is to instantiate the definition axiom by hand:

```lisp
:hints (("Goal" :use ((:instance (:definition w3t::step/r-ctxt-frame)
                                 (w3t::%a0 C0)))))
```

Measured: 496,961 prover steps with `z` a variable (stalls asking `(CONSP Z)`),
and with the real store `(mvm-abs-z-abstract bytes sp pc clen status result)` the
proof carries all the way to a single remaining obligation:

```lisp
(implies (< 21 (+ 27 (acl2-count f)))   ; the %OM3 measure side condition
         (w3t::step/r-ctxt-instrs <config at C2>))
```

So the chain is now a finite, enumerated list of obligations rather than a black
stall -- which is the first time that has been true.  The next steps are: the
head-instruction lemma for a flat config (`step/r-ctxt-instrs` on
`(:;% z (cons instr rest))`), and the `%size`/`acl2-count` facts that discharge
those `(< 21 (+ 27 (acl2-count f)))` side conditions -- what `size.lisp` began.

## The head rule: the load-bearing lemma of the chain

`wasm3/head.lisp` is new and it holds the lemma the whole chain is built on --
stepping the *first* instruction of a flat configuration:

```lisp
(defthm ctxt-instrs-steps-the-head
  (implies (and (consp rest)
                (true-listp rest)
                (equal (w3t::step (list :|%;%| z (list (list :global.get 3))))
                       (list (list :|%;%| z
                                   (list (list :const (list :i32)
                                               (milawa-global 3 z)))))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cons (list :global.get 3) rest)))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32) (milawa-global 3 z))
                                    rest))))))
```

302,816 prover steps.  `Z` is symbolic, so every position of every body is an
instance of it; the one-instruction step it needs is a *hypothesis*, which is what
makes a symbolic store possible at all (without it the search's inner step cannot
be reduced, because the answer would have to be phrased in the spec's record
structure).

Three things had to be discovered to get there, and each of them was a wrong
belief first:

1. **The search refuses a lone instruction.**  `step/search21` requires
   `(or (not (equal val-star nil)) (not (equal instr-1-star nil)))` -- a value
   before the instruction or an instruction after it.  A statement without
   `(consp rest)` is *false*, not merely hard, which is why the first attempt
   burned 401,630 prover steps chasing it.
2. **`acl2-count` of a cons is positive, and that is the only arithmetic needed.**
   `(defthm acl2-count-positive-when-consp (implies (consp x) (< 0 (acl2-count x)))
   :rule-classes :linear)` -- 381 prover steps, and it closed the measure
   comparison the search makes.
3. **The natural companion of that rule is FALSE.**  `(equal (equal (acl2-count x) 0)
   (not (consp x)))` does not hold in ACL2, because a symbol counts by the length
   of its name.  Stating it wasted a round; the one-directional linear rule is the
   right thing.

Also proved here, and needed to discharge the hypothesis above: `step` and
`step/r-read` on a one-instruction configuration over the abstract store, giving
the parameter `STATUS` back (21,668 and 21,597 steps).

**Where the first link actually stops now.**  Driving the whole thing through
`gen_chain.py` with the frame pinned to `(milawa-callee-frame 6)` and the inner
context pinned to `(list :|%;%| (car (mvm-abs-z-abstract ...)) (milawa-callee-frame 6))`
moved the stall one level *up*: the obligation is now

```lisp
(w3t::step/r-ctxt-instrs (:;% Z ((:FRAME_ 1 F ((:LABEL_ 1 nil BODY))))))
```

with a *concrete* frame `F`, where `Z` is a variable it proves in 19 steps.  The
reason is `%SIZE`: at `k = 0` the search wraps the frame itself and asks whether
`(%SIZE (nth 2 (list :;% z instr-star)))` is less than `(%SIZE (nth 2 a0))`, and
with `instr-star` produced as `(take 1 (nthcdr 0 instrs))` the two are equal in
value but not syntactically equal -- so ACL2 has to do arithmetic on
`acl2-count`s to see that the strict inequality fails.  That is precisely
`acl2-count-of-take` and `acl2-count-of-nthcdr`, which `size.lisp` already has;
what is missing is the obligation being stated in a shape those rules fire on.

So the remaining work for the first link is now three named things, in order:
(1) the `acl2-count`/`%size` step that makes the search's measure comparison go
through, (2) then the link itself, (3) then the same generator extended to the
body's other instructions.  Nothing about it is open-ended any more.

## The chain: the bottom two levels are proved

`wasm3/chain.lisp` (generated) now carries three lemmas, all certified:

| lemma | steps | what it says |
|---|---|---|
| `step-flat-body-6-first` | 145,059 | the body's first instruction steps, store pinned |
| `flat-body-6-general` | 683,415 | the same at an **arbitrary** store, with the instruction's own step as a hypothesis |
| `step-in-label-body-6-first` | 1,217,401 | a step inside a label is a step of its body, re-wrapped |

2,045,875 prover steps, **5.06 seconds** of wall clock.  The step counts are large
and the clock is small; that gap is worth keeping in mind before reading a stall as
slowness.

**The lever that unlocked the label level** is two hint elements together, and
neither works alone:

```lisp
:hints (("Goal"
         :use (step-flat-body-6-first          ; pass the fact, do not hope it fires
               (:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 cfg)))
         :in-theory (disable w3t::step/r-ctxt-instrs)))   ; or ACL2 re-expands the search
```

Without the `disable` the identical goal costs 288,294 steps and stalls: the
rewriter prefers to expand `step/r-ctxt-instrs` and re-run the search rather than
use the lemma it has.  This is the fourth time in this project that the fix was
*withholding* a definition rule rather than adding a fact.

**Why the general flat rule matters.**  Because `z` is a variable in
`(list :|%;%| z *body-6*)`, the literal body still matches *any* store — so the
"a cons-pattern cannot match a quoted constant" problem is avoided by keeping the
store symbolic instead of pinning it.  That is the form the levels above need.

**What is left of the chain: the frame level.**  It is the same shape, and it fails
for a real reason rather than a mysterious one: `step/r-ctxt-frame` rebuilds the
inner store as `(:;% (cadr z) (caddr z))`, and `mvm-abs-z-abstract` is expanded
before `reconstruct-abs-z` can reassemble it, so the inner configuration is not
syntactically the one the label lemma is stated at.  Two ways forward, both
concrete: state the label lemma also at the reconstruction, or state the frame link
with the label result as a hypothesis (the pattern that just worked twice).

The probe (`gen_chain.py --probe`) is what made these levels derivable at all: it
computes `step` on a concrete configuration and prints the answer, so each
right-hand side is read off the semantics instead of guessed.  Three of the four
earlier attempts at this had the wrong configuration in the hint and no way to
know.

## Bodies must be literals, not terms

The next thing tried was the chain's first link, stated compactly:

```lisp
(equal (step (:;% Z ((:LABEL_ 1 nil (milawa-func-body 6)))))
       (:;% Z ((:LABEL_ 1 nil (cons (:CONST i32 status) (cdr (milawa-func-body 6)))))))
```

i.e. "the body's first instruction reads the status global and pushes it", with the
two-hundred-line body hidden behind the accessor.  Measured: **229,292 prover steps
and it still stalls at the same `STEP/R-CTXT-INSTRS` question** — the rule's search
does not bottom out, because the body is now a TERM rather than a list it can walk.
The `no-ctxt-instrs-on-a-lone-label-general` lemma it needs does not match, and even
with the body opaque the search has nothing to work with.

Compare the same statement with the body written out as a literal: layers 1-5 all
proved that way, cheaply.

So the chain's lemmas must carry **literal** bodies.  (And having built the
generator — `harness/gen_chain.py`, which lifts function 6's body out of
`state.lisp` — the first literal-body link *still* stalls at the same
`STEP/R-CTXT-INSTRS` question.  So the literal is necessary and not yet sufficient:
what is missing is a way to tell ACL2 that the rule does not apply, and
`no-ctxt-instrs-on-a-lone-label-general` is not matching the term ACL2 produces.
That is the next thing to fix, and it is narrow: one rewrite rule's LHS.)  That is not a hardship -- it is
a generated artifact, exactly as `state.lisp` and `module.lisp` are: `harness/`
should grow a generator that reads the module's bodies out of the pinned store and
emits one lemma per instruction, at its static stack height, with the literal body
it belongs to.  The `milawa-func-body` accessors stay useful for stating THAT a body
is what we think it is (a drift check), not for hiding it inside a proof.

### The instruction library, cut at the joints

The residual names the first lemma, and the object is smaller than it looks: the
innermost pieces are *instruction lists*, not configurations.

```
step_pure : instr* -> instr* option     arithmetic, tests, consts -- no store
step_read : config -> instr* option     loads, global.get, local.get
```

So for one instruction the chain is

```
STEP_PURE lemma   (symbolic values only, no store)   <- DONE, wasm3/instructions.lisp
  -> STEP_READ lemma   (one store read at a concrete place)  <- DONE, wasm3/reads.lisp
     and the same layer reading the FRAME (locals)           <- DONE, wasm3/frames.lisp
    -> ctxt-label / ctxt-frame lemma   (one level of nesting)
      -> ctxt-instrs lemma             (the split point)
        -> the call rule               (entering and leaving a function)
```

each proved with **only its own rule enabled**, its recursive call discharged by
the lemma beneath it.

The first layer is proved: `wasm3/instructions.lisp` has ten lemmas — the five i32
binops and the four comparisons the module uses, plus the zero test — each about a
configuration with **symbolic values** and the value count at its static length:

```lisp
(defthm step-pure-binop-add
  (equal (step_pure (list (:const i32 c1) (:const i32 c2) (:binop i32 add)))
         (list (list (:const i32 (car ($BINOP_ i32 add c1 c2)))))))
```

3.7 s for the book; 3,788 prover steps for the first lemma.  The right-hand sides
are the spec's own operations, so nothing about 32-bit wrapping or signedness is
assumed — the lemmas conclude whatever the certified semantics concludes.  Two
shape facts worth having written down: `$BINOP_` returns a *list* (it can trap) so
the rule takes `(car ...)`, while `$RELOP_` and `$TESTOP_` return the value
directly; and `div_u` needs the trap not to fire, which is exactly the rule's own
guard.

Layer 2 is proved too: `wasm3/reads.lisp` covers `global.get` of all five globals
in the **abstract store**, so the store is symbolic in the proof — the five globals
arrive as variables and the semantics digs them back out.  12,101 prover steps for
the first one, and the reason it works is the fact `symbolic.lisp` established:
the lookup is `assoc-equal` on keys and the keys are concrete.  `global.get` is the
read that matters most, because the module's dispatch begins `(global.get $status)`
and every address goes through `(global.get $pc)`.

Layer 3 adds the frame: `wasm3/frames.lisp` proves `local.get` of all four locals
($op, $imm, $a, $b) with the frame's locals symbolic.  2,647 prover steps each —
cheap, because no global lookup is involved.  Every one of the module's seven
opcodes loads its operand word through those locals, so this is what makes the
dispatch expressible at all.

Two representation facts, both found by measuring and both of which answer NIL
silently when got wrong:

- **a local is a singleton list holding its value**: `(:LOCALS ((:CONST (:I32) 0)) ...)`.
  That is why the rule's value is `(CAR ($LOCAL Z X))` and why `$LOCAL` itself
  answers a list.  Written unwrapped, every lemma on this layer says NIL and it looks
  like the semantics has no `local.get` rule.
- **the config is `(:;% Z instrs)` with `Z` = `(:;% STORE FRAME)`.**  Passing the
  store where `Z` belongs also answers NIL, silently — the same trap `abs.lisp`
  records for `$WITH_MEM`/`$WITH_GLOBAL`, and it cost a second afternoon.  Then C2 per opcode is a chain of those — ~50 to 100 links,
exactly the clock in the table above, writable because the clock does not depend on
the values.

## Where L1 stands

The certified WASM 3.0 semantics **executes the artifact**, and that is proved, not
tested: `wasm3/l1.lisp` pins the instantiated store and frame as logic constants
and proves, by evaluation on them, that the entry configuration exists, that it is
a call to function 6 with no arguments, that `STEP` applies and is single-valued,
that three steps still apply, and that one step enters the frame pushed for our
function's locals.  Those are the first facts here stated about the certified
semantics running our module rather than about our model of it.

Getting there needed the API written down: `$INSTANTIATE` returns a
*configuration*, not a store (ours is already final, since the module has no
imports, data or start function); the store and frame are `(CADR (CADR C))` and
`(CADDR (CADR C))`; `$INVOKE` builds the entry configuration; `STEP` returns the
*list* of successors.

Two steps remain outside the logic: decode and instantiate are both `:program`
mode, so they are scripted and drift-checked (`harness/gen_module.py --check`)
rather than proved.  Everything after them is statable.

With `abs.lisp` the *statement* of L1 is fixed and checked on every path the
module has: sixteen ground theorems, each giving the exact clock, each showing
one more step is not available, and each showing that the configuration the
semantics stopped on reads back as `MVM-STEP`.  What remains is the same theorem
with the state symbolic — a symbolic execution of the module's twelve function
bodies.  That is the piece the `wasm-acl2` engine goes after as E11, and it is
unfinished there too (its C2 is proved for clock-0 steps only), so this is the
project's hardest open problem, not a formality.

Underneath L1 proper sits the memory correspondence, and the hardest piece of it
is now proved: **decoding the image of a word list gives the word list back**
(`mvm-image-words-of-mvm-word-list-to-bytes`), and the stack case follows
(`mvm-image-of-stack`).  The route there is worth recording, because the obvious
statements do not work:

- the indexed form `(nthcdr (* 4 i) bytes)` is the natural thing to write and is
  unusable — `(* 4 i)` blocks every append lemma, and rewriting it to
  `(+ 4 (* 4 (i-1)))` makes ACL2's `fold-consts-in-+` fold it straight back, to a
  HARD ERROR [Call depth] 1000;
- letting the recogniser `mvm-word-list-p` unfold splits each induction step on
  `(integerp (car ws))`, `(<= 0 ...)` and `(< ... 2^32)`: 259, then 4963 subgoals,
  387 s and 56 GB before giving up;
- letting `mvm-word-to-bytes` unfold brings `loghead`/`logtail` in, and ACL2 then
  splits on the arithmetic: 9.5M prover steps, still open.

What closes it is all three together: a decoder that consumes four bytes a step
(`car`/`cadr`/`caddr`/`cadddr` instead of an index), a **step rule** about the
append form, and the recogniser plus the byte-level definitions **disabled** so
that forward-chaining supplies the recogniser's facts without ever unfolding it.
The induction then finishes in 0.48 s.

## What is next, in order

1. **The chain, one position at a time.**  `gen_chain.py` now has a known-good
   target: for each position of function 6's body, an instance lemma of the shape
   that already proved at 138,429 steps (literal body written out, `:definition`
   instances for `step/r-ctxt-instrs` and `step/search21`), because a rewrite rule
   with `(cons instr rest)` cannot match the quoted literal the search needs.  The
   intermediate configurations must be *read out of failed goals* rather than
   written down in advance -- guessing them has cost several rounds.  Then join
   them with `step-call-enters-frame` (layer 6) and the two return lemmas
   (layer 7) into the 9-step theorem that matches `abs.lisp`'s clock for the
   frozen path.
2. **L1, symbolic**: the sixteen paths of `abs.lisp` generalised to symbolic
   state.  The clock is already known per opcode, and `head.lisp` has removed the
   bottom of the descent (the head instruction) from this problem, so the shape is
   the per-opcode position lemmas plus the frozen-status and off-the-end cases.
3. **L2**: the run level.  Each machine step is a fresh `$INVOKE`, so the run
   theorem is a "re-entry" composition rather than one long `STEPS/%FUEL`; the
   engine's `ENGINE-RESULT-IS-SPEC-RESULT` packaging (`wasm-acl2` `engine/`) is
   the reference, not a drop-in.
4. **L3**: `MVM` running compiled code refines `MILAWA-EVAL`, with the compiler
   untrusted — L3 is what makes that acceptable.
5. Conses, symbols, environments and the heap in the module and the model; then
   the whole `milawa-init` kernel, and one lemma per `defun` against
   `ACL2/logic/`.

## Reproducing

```sh
make -C books/projects/milawa-verified-wasm/milawa-lisp ACL2=$ACL2   # 7 books, seconds
make -C books/projects/milawa-verified-wasm/machine     ACL2=$ACL2   # 3 books, seconds
make -C books/projects/milawa-verified-wasm/wasm3       ACL2=$ACL2   # 7 books, needs the pin
```

The `wasm3/` books depend on `wasm-acl2`, pinned at `7f96c89` and cloned (not
vendored) as `/workspaces/acl2/.wasm-acl2`; they are listed in `cert_pl_exclude`
so a community certification run never has to find it.  The 26 books of the WASM
3.0 semantics are generated from the checked-in IL (`make gen SPEC=3.0`, ~2 min)
and certified (~5 min); `make -C translate check-il SPEC=3.0` re-derives that IL
from the spec sources through Nix and reports it reproducible.

Design and plan: [`../milawa/VERIFIED-WASM-LISP.md`](../milawa/VERIFIED-WASM-LISP.md).
