# PLAN: a verified Lisp runtime for Milawa, compiled to WASM

This is the project plan the PoC pointed at.  It rebuilds the verified runtime
in the shape Jitawa actually has, but with the machine code *generated*, not
hand-written: a small Lisp specification, a compiler from the Milawa core Lisp
to WebAssembly checked by one correctness theorem against the ACL2 WASM model,
a generated runtime, and a run-level theorem that composes them with Milawa's
soundness proof.  The existing `wasm3/chain*`, `const*`, and `engine*` books,
and the newer `refinement/ops-*`/`wasm/milawa-ops.wat` books, stay certified
as an archive and regression suite; they are not the route to the theorem.

## 0. The goal (corrected 2026-11-23)

The deliverable is a **Lisp runtime for Milawa that is correct by
construction**.  Concretely:

- the source is the Milawa core Lisp, with the existing `MILAWA-STEP` /
  `MILAWA-RUN` semantics as its reference;
- the object program is emitted by an ACL2 compiler (Lisp -> IR -> WASM), and
  the shipped `.wasm` is the compiler's output;
- one theorem, stated against the ACL2 model of WASM 3.0 (`W3T`), says that the
  generated code refines the Lisp semantics for every program and state; and
- the Milawa composition is instantiated at the kernel text and the events, so
  acceptance by the running artifact implies truth of the accepted formula.

"Correct by construction" is used in Jitawa's sense: **the compiler need not be
trusted**.  It is an ACL2 function, the correctness theorem is the guarantee,
and the artifact is produced by evaluating that function.  A wrong compiler
produces code that fails the theorem; it does not produce code that escapes it.

This rules out the earlier shape in which the WASM module was a hand-written
WAT file and the proofs were about that file's instruction sequence.  The
hand-written module, the per-opcode `ops-*` books, and the host loop that calls
its `STEP` are an experiment.  They are archived, not extended, and no part of
the final theorem depends on them.

## 1. What went wrong

The PoC (`wasm3/poc.lisp`) proved the right *shape*: one Milawa-Lisp
expression, `(+ 1 2)`, from `MILAWA-EVAL` through `MVM-RUN` to four exported
`STEP` calls on the artifact.  It was cheap because the four calls were
ground evaluations.

The continuation then tried to turn that instance into the general theorem
by proving the *same* call for one opcode path at a time: the CONST tail's
67 spec steps, then the callee's positions, each as a concrete composition
of WASM steps.  That is the old design's shape, and it is why the work is
slow:

- Every program/opcode path re-proves the artifact's dispatch loop.
- The proofs are large because the thing being stepped is a *fixed machine
  code sequence*, not a compiler parameter.
- The result is still only one path; the other fifteen paths and every
  future program pay the same cost.

Jitawa never does this.  It has one correctness theorem for the compiler and
one for the REPL/machine, and every program is an instance.

The later per-opcode library was a partial correction, but it kept the
hand-written module.  It replaced a concrete path with one theorem per opcode,
yet the module was still an artifact written by hand and the run level still
assumed a host loop calling its exported `STEP`.  Jitawa's machine code is
*generated* from the verified compiler, and the proof is about the generated
code.  That is the property this plan now requires.

## 2. What Jitawa actually does

The local HOL sources (`examples/theorem-prover/lisp-runtime` and
`examples/theorem-prover/milawa-prover`) show four layers:

1. **Spec** (`lisp_semanticsScript.sml`, 410 lines): a `term` AST,
   `sexp2term`, big-step `R_ev`/`R_evl`/`R_ap` with an `ok` flag, and the
   `R_exec` REPL.  Determinism (`R_ev_T_11`, `R_ap_T_11`) turns "there
   exists a result" into "the result is unique".
2. **Compiler + bytecode VM** (`lisp_correctnessScript.sml`, plus the
   compiler/bytecode books): an untrusted compiler from `term` to bytecode,
   a bytecode semantics `BC_ev`, and **one** symbolic theorem `BC_ev_thm`:
   if `BC_ev` returns, the machine's `iSTEP^*` reaches the corresponding
   state.  `BC_REFINES` is the invariant.  `BC_ONLY_COMPILE_THM` is the
   expression-level instance.
3. **Machine code**: the compiler is not verified; the code is produced by
   proof-producing synthesis/extraction (`lisp_extract`, `lisp_synthesis`).
   `jitawa_correctness_thm` composes the initialisation code and the REPL
   machine code into a Hoare triple.  The postcondition is
   `zERROR_MESSAGE ex \/ (exists result. R_exec ... * output ...)` -- no exact
   step count at the top.
4. **Milawa**: `milawa_coreScript` parses the actual `core.lisp` text into a
   logic constant; `milawa_initScript` evaluates `(milawa-init)` to get the
   function table; `milawa_execScript` proves `M_ev ==> MR_ev ==> R_ev`;
   `milawa_proofpScript` proves the checker; `milawa_soundnessScript`
   composes the runtime triple with `milawa_main_soundness` at
   `input = MILAWA_CORE_TEXT ++ rest`.

The important structural facts:

- **The spec is tiny and the compiler is untrusted.**
- **One correctness theorem per layer**, parametric in the program/state.
- **The machine code is derived**, not hand-proved instruction by
  instruction.
- **The top-level proof is a composition**, not a trace.

## 3. The new architecture

```
        Milawa core Lisp (core.lisp / translated core terms)
                  |
                  |  source semantics: MILAWA-STEP / MILAWA-RUN
                  v
        Lisp program
                  |
                  |  compile        (untrusted ACL2 function)
                  v
        IR  (compile-term / lower-program; J1/J2a)
                  |
                  |  code generation (untrusted ACL2 function)
                  v
        WASM module  (generated code + data layout)
                  |
                  |  compiler-correctness (one theorem, all programs)
                  v
        W3T::STEP / W3T::RUN  (the certified WASM 3.0 semantics)
```

On top of that, the Milawa side is:

```
core.lisp text --> MILAWA-CORE-TEXT (logic constant)
      |
      | milawa-init evaluated in the spec
      v
initial function table --> checker soundness theorem
      |
      +--> runtime theorem (compiler + generated code + W3T)
                 |
                 v
      milawa_soundness: accepted theorems are semantically true
```

### Design principles

1. **Spec first.**  The reference semantics is small and total; the
   compiler and the generated code are judged against it.
2. **One theorem per layer, one lemma per source construct.**  Compiler
   correctness is parametric in the term; code-generation correctness is
   parametric in the IR and the generated W3T state; run-level correctness is
   an induction on the number of steps.  No proof is per program and no proof
   is per opcode path.
3. **The compiler is untrusted.**  Its output is checked by
   `compile-correct` and the code-generation theorem; a wrong compiler fails
   the theorem, not the users.
4. **The artifact is generated, not hand-written.**  The compiler emits the
   WASM module from the IR, and the proof is about the emitted code.  There is
   no hand-written WAT, no per-opcode hand proof, and no per-program trace.
   The module is correct because it is the compiler's output, and the theorem
   applies to every output.
5. **Determinism supplies the answer.**  The top-level theorem is
   existential/conditional (the spec's result exists); concrete evaluation
   gives the value, as in the PoC.
6. **The front door is a corollary.**  `poc` is a closed instance of the
   general theorem, not a separate proof style.

## 4. Milestones

### Corrected milestone track (2026-11-23)

The old J2b/J3 bullets below are retained as history.  They are off the proof
path.  The active track is:

- **K0 -- source semantics and interface.**  Reuse `refinement/spec.lisp`,
  `compile.lisp`, `machine.lisp`, and `milawa-lisp/eval.lisp`.  Define the
  source language as the core Lisp that the Milawa front end already
  produces, and fix the compiler interface: source -> IR -> W3T module
  (generated code plus the data layout).
- **K1 (partial) -- generated code for the arithmetic subset.**
  `refinement/k1-arith.lisp` has the generator (`k1-gen`), the value
  semantics (`k1-value`), and the proved engine step lemmas for `:const` and
  `:binop add`, including the engine's result-goes-to-IS-then-VALS
  behavior.  Closed generated programs `(+ 1 2)` and `(+ 1 (+ 2 3))` are
  proved to run to their values.  The all-terms composition of
  `machine-run` over `k1-gen` is the remaining K1 proof; the module is
  emitted from the generator, no WAT.
- **K2 -- the Lisp data model.**  Add conses, symbols, environments, and the
  heap to the IR and the generator; prove the simulation for every source
  construct.
- **K3 -- the runtime.**  Add the function table, calls,
  closures/lambdas, and the reader/REPL loop.  The compiled kernel and
  `100.events` run on the generated module.
- **K4 -- Milawa composition.**  Parse the core text, initialize the kernel,
  prove `M_ev => MR_ev => R_ev`, and compose with the Milawa soundness
  theorem at `MILAWA_CORE_TEXT ++ events`.
- **K5 -- serialization and artifact.**  Emit the binary (or generated WAT)
  from the proved module with a verified encoder or a checked decoding step;
  run the generated artifact in a conforming engine and keep the corpus as a
  regression suite.

**Acceptance at the end:** the top-level theorem says that acceptance by the
generated runtime implies truth, and the runtime is the compiler's output.  No
hand-written WASM is on the proof path.

### Status (2026-11-23)

> **Archive notice.**  The J2b/J3 per-opcode and host-loop results below are
> historical.  They prove facts about a hand-written WAT module, which the
> corrected goal (section 0) does not use.  Do not extend them.  The K-track
> above is the active plan.

- **J0 (subset): done.**  `refinement/spec.lisp` has `variable-p`,
  `term-p`, and `r-ev` for `QUOTE`, variables, `IF`, and the twelve
  primitives at their arities.
- **J1 compiler: done.**  `refinement/compile.lisp` has `compile-term`,
  `bc-eval`, and **`compile-correct`**: for every term of the subset and
  every environment, `bc-eval (compile-term term) = r-ev term`.  The IR is
  a structured instruction tree; the PoC expressions are corollaries.
  2.5 s, 2.1M prover steps.
- **Bridge checks: done.**  `refinement/bridge.lisp` checks that `r-ev` and
  `MILAWA-RUN` agree on the PoC and representative forms by evaluation.
- **J2a machine: done.**  `refinement/machine.lisp` lowers the IR to a flat
  stack/pc program, gives it `machine-step`/`machine-run`, proves one step
  theorem per opcode, the dispatcher coverage, and the closed `(+ 1 2)`,
  `if`, `cons` passes.  0.4 s.  The general run-level theorem is J3.
- **J2b-1 module/table/model: archived (off-goal).**  `wasm/milawa-ops.wat` +
  `milawa-ops.wasm` is the per-opcode integer/arithmetic/if library;
  `refinement/ops-state.lisp` pins it; `refinement/ops.lisp` has the checked
  table, the i32 model, per-opcode dispatcher theorems, and value-level
  agreement with `machine-step`.  0.5 s.
- **J2b-2 W3T link: archived (off-goal).**  The dispatcher
  chain is now closed too.  `refinement/ops-trace-*.lisp`,
  `ops-frame-*.lisp` and `ops-tails*.lisp` prove the false-comparison skips,
  the true-comparison prefix, the branch body (including value-prefixed
  `local.get` steps and the ifz/eqz cost), and the label/frame returns;
  `ops-frame-traces.lisp` composes them into one symbolic frame trace per
  opcode, from the dispatcher's first comparison to the value
  configuration (`(sel a)`, `loghead` add/sub, the 31-bit signed compare,
  `(if (sel a)=0 (sel b) 0)`, `(sel b)`, `(sel a)`).
  `ops-step-call.lisp` proves the four-value `STEP/PREFIX7` and the
  no-context facts for every prefix of the dispatcher call,
  `ops-step-entry.lisp` proves the one-step `$INVOKE` entry into function 7's
  callee frame for each opcode, `ops-step-results.lisp` composes entry and
  trace into <code>ir-op-step-call-result0..7</code>, and
  `ops-step-theorem.lisp` packages them as
  <code>ir-op-step-call-result</code>: for every opcode 0-7 and
  well-formed operands, `$INVOKE *ir-store* 7` reaches the opcode's value
  configuration (9/14/21/26/31/37/39/44 steps; the signed compare carries
  its 31-bit bounds).  The earlier per-opcode chains (functions 0-6) are
  unchanged.  The step counts are the dispatcher's branch structure, not a
  single concrete program trace; the operands stay symbolic.
- **J2b-2 W3T link history (op_const/op_add) (archive):**
  `refinement/ops-w3t.lisp` proves the frame/label `local.get`, the
  label/frame value returns, the frame-around-label-around-value step, the
  three-step `ir-op-const-body`, the value-prefixed
  `no-ctxt-instrs-on-op-const-call` (with the two stuck-suffix `STEP` facts),
  the one-step `ir-op-const-call-entry`, and the four-step
  `ir-op-const-call-result` from `$INVOKE` to the value.  The outer frame is
  the **empty call frame** (`:locals` / empty `:module`), not `*ir-frame*`;
  the body lemmas are generalized over the outer frame.  For `op_add`
  (function 1), `ir-op-add-invoke`, `prefix7-op-add-call`, the value-prefixed
  `no-ctxt-instrs-on-op-add-call` chain (including the one-const suffix),
  and `ir-op-add-call-entry` are proved.  The `op_add` body (two `local.get`s
  and `binop` through the frame) is the next blocker: the body has a
  multi-instruction label body, so it needs the label-lift/context lemmas,
  not the single-`local.get` value dissolve that made `op_const` easy.  The
  redex steps (`add-inner0/1/bin` and their explicit-state-pair forms) are
  proved.  In `refinement/ops-add.lisp`, the first (`vals nil`) body step uses
  the engine's `step-of-flat-block`; the value-prefix step uses
  `engine-ctxt-from-values-instr-step`; and `add-body-inner3` composes the
  three inner body steps to `(:CONST (:I32) (+ v1 v2))`.  In
  `refinement/ops-add-label.lisp`, the conditional label/frame lifts are
  instantiated at the explicit inner terms (using bare extraction lemmas,
  `add-body-step1-specific`, `add-body-step2`, `add-innerbin-explicit`,
  `add-state-pair-z`), and `ir-op-add-body`/`ir-op-add-call-result` are
  proved: five steps from the callee config to the value and six from
  `$invoke`.  The value is `(loghead 32 (+ v1 v2))`; the theorems carry the
  type side condition `(unsigned-byte-p 32 (loghead 32 (+ v1 v2)))` (not yet
  discharged).  For `op_sub`, `refinement/ops-sub-body.lisp` proves the
  `$isub_` bridge `(rem (- (+ 2^32 i1) i2) 2^32) = (loghead 32 (- i1 i2))`
  (via `rem-positive-as-mod`, `loghead-32-as-mod`, and the non-local
  `acl2::cancel-mod-+-basic` from `ihs/quotient-remainder-lemmas`), the sub
  call entry and body steps; `refinement/ops-sub-label.lisp` proves
  `ir-op-sub-body` and `ir-op-sub-call-result` (same conditional pattern,
  side condition `(unsigned-byte-p 32 (loghead 32 (- v1 v2)))`).  For
  `op_lt` (function 3), `refinement/ops-lt-body.lisp` proves the signed
  comparison bridge
  `$ILT_ 32 (:s) v1 v2 = (if (< v1 v2) 1 0)` under 31-bit operands (and
  `unsigned-byte-p 31 => unsigned-byte-p 32`), the call entry, the three
  body steps, and `refinement/ops-lt-label.lisp` proves
  `ir-op-lt-body`/`ir-op-lt-call-result`.  The value is
  `(if (< v1 v2) 1 0)`; the theorems carry the (trivial) 32-bit value
  bound.  For `op_ifz` (function 4), the artifact now implements
  `target * (test == 0 ? 1 : 0)` with a straight-line `local.get` /
  `i32.eqz` / `i32.mul` body, so it shares the add/sub composition
  machinery.  `ops-ifz-body.lisp` proves the `$IEQZ_` and `$IMUL_`
  bridges, the call entry, the four body steps, and
  `ops-ifz-label.lisp` proves `ir-op-ifz-body` and
  `ir-op-ifz-call-result`, value `(if (equal v1 0) v2 0)`.  For
  `op_jmp` (function 5), `ops-jmp.lisp` proves the entry and the
  three-step body/call result to `v2`; for `op_label` (function 6),
  `ops-label.lisp` proves the entry and the three-step body/call result
  to `v1`.  For the `STEP` dispatcher (function 7),
  `refinement/ops-return-label.lisp` proves the exit-body label step
  (`((const v) (return))`, bare and with a rest),
  `refinement/ops-dispatch-tail.lisp` factors the if-chain generators,
  and `refinement/ops-return-suffix.lisp` proves the no-BR-tail searches,
  the function-label return with an arbitrary no-BR suffix, the frame
  return, and the generic frame/label lift for one body step.
  `refinement/ops-trace-0.lisp` proves the six-step op0 body trace,
  `refinement/ops-frame-6.lisp` the six-step op0 frame trace, and
  `refinement/ops-frame-8.lisp` closes the full eight-step op0 frame
  trace to the value configuration, using totalized `sel`/`tail-sel`
  values to make the side conditions unconditional.  The remaining work
  is generalizing the eight-step trace to ops 1-7, the
  `$invoke *ir-store* 7` call result, and the exported `STEP` theorem
  (the model-level `ir-step-table` and `machine-step-dispatches` are
  proved).
- **Design finding.**  A CEK-style flat machine with a fuel/continuation
  run proof is a slog (600 s, still diverging in the primitive case); J2a
  avoids it by proving the per-opcode layer and the closed pass, leaving
  the run-level to J3 (where the exact-count `MILAWA-RUNS` pattern is the
  better target).  The general `r-ev = MILAWA-RUN` bridge remains the open
  J1b piece.
- **Next (corrected 2026-11-23).**  K1: a generated-code theorem for the
  arithmetic/control subset, with the module emitted by the generator.  The
  old J2b/J3 path is archived.


The milestones are ordered so that each one produces a theorem a reviewer
can read, and each one is parametric rather than program-specific.

### J0 -- The reference semantics (`refinement/spec/`)

- Keep `milawa-lisp/values.lisp`, `eval.lisp`, `programs.lisp`,
  `metatheory.lisp`, `reachability.lisp` as the reference interpreter and
  its exact-step relation.  `MILAWA-RUN`/`MILAWA-RUNS` is the spec the
  compiler is judged against.
- Add a small **term syntax** and **parser** for the core subset
  (`quote`, variables, `if`, the twelve primitives, calls).  Jitawa's
  `sexp2term` is the model; we need it to feed `compile`.
- Add determinism/typing facts for the reference: a successful
  `MILAWA-RUN` is unique, and `MILAWA-RUNS` is a function of the exact
  count.  Much of this exists; the missing piece is the term/parser layer.

**Acceptance:** the spec parses a term, evaluates it, and the result is
deterministic; the PoC's `(+ 1 2)` and the demo calls are instances.

### J1 -- Compiler correctness (`refinement/compiler/`)

- Define a bytecode VM for the core subset: state, instruction set,
  `bc-step`, `bc-run`.  Start with the arithmetic/control subset
  (`const`, `add`, `sub`, `lt`, `ifz`, `jmp`, `halt`); then add
  `cons`/`car`/`cdr` and the function table.
- Define the untrusted `compile : term -> bytecode`.
- Prove **one** theorem:
  `bc-run (compile term, env, ftbl)` refines `MILAWA-RUN term` (the
  `BC_ev_thm` analogue), with the `BC_REFINES` invariant (function table,
  environment, output, ok flag).
- Prove the expression-level and program-level corollaries
  (`BC_ONLY_COMPILE_THM` analogue).

**Acceptance:** `compile-correct` is proved for the arithmetic/control
subset; the compiler's output is checked for all terms of the subset, not
one term.  The PoC's program is an instance.

### J2 -- The machine (`refinement/wasm/`)

**J2a (done, `refinement/machine.lisp`).**  The IR is lowered to a flat
stack/pc instruction list (`:const`, `:load`, `:prim`, `:ifz`, `:jmp`,
`:label`, `:halt`) with `lower-term`/`lower-program`; the machine is
`machine-step`/`machine-run`; each opcode has its own step theorem, the
dispatcher coverage is `machine-step-dispatches`, and the closed
`(+ 1 2)`/`if`/`cons` passes certify.  This is the ACL2 machine the WASM
artifact implements.

**J2b (retired 2026-11-23).**  The per-opcode hand-written module and its
`ops-*` proofs are archived.  They are not the artifact and not the proof
path; the corrected plan (section 0) generates the module from the IR (K1).
The old goal was one theorem per opcode plus a dispatcher theorem, and that
was met (`ir-op-step-call-result`); it is retained only as a regression
suite.  No new work goes into `wasm/milawa-ops.wat` or the `ops-*` books.

### J3 -- Run level and the front door (`refinement/top/`)

**Status (2026-11-23): archived/off-goal.**  The host loop and front door
below proved a hand-written dispatcher path; they are retained as history and
regression, not extended.  The active run level is K1/K3: generated code
executing under W3T.  The `machine-run` semantics (J2a) remains the source IR
semantics.  For the record:  `refinement/top-host.lisp` models the
host loop that holds pc/stack and calls the verified STEP for the arithmetic
primitives: `host-prim-2` checks the artifact's 30-bit range and uses the J2
dispatcher model `ir-step` for `+`, `-`, `<`; `host-step` is `machine-step`
elsewhere; `host-run` iterates.  **`host-run-refines-machine-run`** is the
fuel induction: the host loop equals the VM unless the artifact's range is
exceeded (where WASM i32 wrap/signed LT differ from the Milawa 30-bit
primitives).  `refinement/poc.lisp` proves the closed host/machine runs for
`(+ 1 2)`, the `if` example and `(cons 1 2)` as instances of that theorem
plus the J2a closed passes, and closed W3T dispatcher theorems for add, lt
and ifz as instances of `ir-op-step-call-result`.  `make poc` prints the
spec/machine/host answers and the dispatcher value.

The general term-to-machine composition (`machine-run` of a lowered
`compile-term` equals `bc-eval`/`r-ev` for every term, the J1b lowering
theorem) is the remaining run-level piece; it is independent of the host
loop and the front-door instances above.  `refinement/top-run.lisp` has the
verified lowering groundwork for it: an untrusted lowering whose labels are
the absolute pcs of their label instructions, the instruction count, the
position invariant (`positional-from`: a label instruction's value is its
pc), and the `label-pc` resolution theorem for that code.  The run-level
induction over that lowering is still useful for K1, but it now targets the
generated W3T code rather than the hand-written module.

- Prove the host loop: `n` calls to the exported `STEP`, at the
  opcode-determined clocks, equal `bc-run` for `n` steps
  (`MVM-RUN`/`W3T::STEPS` relation).  This is an induction, not a path
  proof.
- Compose J1 and J2/J3: a program's `bc-run` refines `MILAWA-RUN`, and the
  WASM loop refines `bc-run`.
- Re-prove the PoC as a corollary of the general stack
  (`(+ 1 2)`, plus a `cons` example and a small `if` loop).
- `make poc` prints the closed instance from the new stack.

**Old acceptance (retired):** a closed `W3T` theorem for the PoC and at least
one `cons`/`if` program, all derived from the general theorems; no
program-specific WASM step chains.  The replacement acceptance is K1's
generated-code theorem.

### J4 -- Milawa core and soundness (`refinement/milawa/`)

**Status (2026-11-23): the milawa2 kernel runs the demo on the verified
model.**  `refinement/milawa2-data.lisp` holds milawa2.lsp's DEFINE forms as
data; `refinement/milawa-check.lisp` is the untrusted front end from surface
Lisp to core syntax (COND/AND/OR/LET/LET*/LIST expansion; LET is closed over
its free variables because the evaluator's lambdas are not closures;
CL-USER::FUNCALL in CORE.CHECK-PROOF is specialized to the initial checker
LOGIC.PROOFP; FIRST..FIFTH/ENDP/NULL/PRINT/DEFINE are the runtime's system functions;
ERROR is left undefined so a malformed event aborts the run instead of
being masked).  The front end is validated: no untranslated macro or
unknown function head remains, and every translated body's variables are
bound.  `refinement/milawa-events.lisp` is the milawa-on-jitawa
`100.events` demo as data (labels/sharing respected by ACL2's reader).
`refinement/milawa-run.lisp` builds the initial state (translated function
table, initial axioms and arity table, checker LOGIC.PROOFP) in the kernel's
own CORE.STATE and runs all 100 events: `(:MILAWA-OK . SUCCESS)` in ~100 s.
`make milawa-check` reproduces it.

This is the Jitawa demo run on the verified evaluator *model*: the kernel is
interpreted, and this is a checked run (evaluation), not a soundness
theorem.  It is a useful reference for the compiler, not the delivered
runtime.  Parsing the ACL2 `core.lisp` text into a logic constant, proving
the interpreter implements the logic (the MILAWA-RUN/MR_ev layer), compiling
the core Lisp to generated WASM (K1-K3), and composing the soundness theorem
(K4) remain.

- Parse the actual `core.lisp` text into a logic constant (Jitawa
  `MILAWA_CORE_TEXT_THM`).
- Evaluate `milawa-init` in the spec to get the initial function table;
  prove the extracted definitions' side conditions and the `M_ev ==>
  MR_ev ==> R_ev` bridge (`milawa_execScript` analogue).
- Use the sibling `books/projects/milawa/ACL2` checker/soundness proof;
  do not reprove the kernel.  Compose the runtime theorem with
  `milawa_main_soundness`/`logic.proofp`, as `milawa_soundnessScript` does.
- The final statement is the Jitawa sentence with ACL2 in place of HOL4 and
  WASM in place of x86-64.

**Acceptance:** the top-level soundness theorem, with the runtime theorem
instantiated at `MILAWA_CORE_TEXT ++ events`; the checker's acceptance
implies semantic truth.

### J5 -- Generated artifact and endgame

- Emit the binary (or generated WAT) from the proved W3T module.  Either
  prove the encoder/decoder round trip or check the emitted bytes decode to
  the proved module; the assembler is not part of the proof.
- Run the generated artifact in a conforming engine and keep the corpus as a
  regression suite.
- Performance (the generated runtime need not be a JIT; a verified
  compiler is enough).

## 5. What to keep, what to retire

| Asset | Decision |
|---|---|
| `milawa-lisp/values`, `eval`, `programs`, `metatheory`, `reachability` | **keep**; the reference Lisp semantics and exact-step relation |
| `refinement/spec.lisp`, `compile.lisp`, `machine.lisp`, `top-run.lisp` | **keep**; source AST, compiler, IR semantics, and lowering groundwork |
| `refinement/milawa2-data`, `milawa-check`, `milawa-events`, `milawa-run` | **keep**; kernel data, front end, and the model run used as the compiler's reference |
| `wasm-acl2` (`W3T`, engine) | **keep**; the ACL2 WASM 3.0 target semantics |
| `wasm3/decode`, `module`, `state`, `memory`, `numerics` | **keep** as W3T/artifact infrastructure and decoding regression |
| `wasm3/poc.lisp`, `POC.md`, `examples/*.mvm` | **keep** as front-door regression; not the proof |
| `wasm/milawa-verified.wat`/`.wasm`, `wasm/milawa-ops.wat`/`.wasm` | **archive**; hand-written modules, not the artifact |
| `refinement/ops-*`, `refinement/top-host.lisp`, the host/W3T parts of `refinement/poc.lisp` | **archive**; the hand-written dispatcher path, not extended |
| `machine/mvm.lisp` | **archive**; the model of the hand-written module (useful history, not the target) |
| `wasm3/chain*`, `links`, `frozen`, `running`, `dispatch*`, `load`, `fetch`, `halt`, `abort`, `oob`, `const*`, `engine*`, `const-join`, `const-steps`, `const-front` | **archive**; still certified, not extended |
| The 57-book `make check` | **keep green** while the new tree is built separately |

The archive is not wasted: it is the concrete evidence for the W3T
instruction library, the step clocks, and the traps recorded in `AGENTS.md`.
It is simply not the proof the project will ship.

## 6. Risks and mitigations

- **The code generator is the long pole.**  We need a verified compiler
  from the core Lisp/IR to W3T.  ACL2 has no ready-made WASM backend, so the
  generator is our own.  Mitigation: reuse the J1 compiler and J2a machine as
  the source IR; prove one simulation theorem per source construct; generate
  the module from the function; start with the arithmetic/control slice.
  The compiler need not be trusted: the theorem is the guarantee.
- **The source language is larger than the J1 subset.**  The full kernel
  needs `cons`/`car`/`cdr`, symbols, environments, closures, the function
  table, and the heap.  Mitigation: extend the IR and generator one source
  construct at a time; each extension is an induction over terms/IR, not a
  new machine proof.
- **The VM must grow.**  The current MVM has seven arithmetic/control
  opcodes; the full kernel needs cons cells, a heap, and a function table.
  Mitigation: J1 defines the bytecode VM for the subset first; the heap is
  a data-structure refinement (Jitawa's `BC` state already carries the
  function table and output), not a new machine.
- **The Milawa composition is large.**  Mitigation: reuse the sibling
  Milawa checker/soundness proof and Jitawa's `milawa_exec` pattern; the
  runtime side only has to instantiate the general theorem at the core
  text.
- **The runtime loop.**  The host that reads the input and drives the
  generated code is part of the trusted boundary unless it is generated and
  proved.  Mitigation: generate the runtime/REPL loop as part of the module,
  or prove the small host driver; do not hand-write a dispatcher.

## 7. Goal statement

> **Goal (corrected):** A verified Lisp runtime for Milawa that is correct
> by construction.  The source is the Milawa core Lisp with the existing
> `MILAWA-STEP`/`MILAWA-RUN` semantics.  An untrusted ACL2 compiler emits
> WASM from the IR; one correctness theorem, stated against the ACL2 `W3T`
> model, says the generated code refines the Lisp semantics for every
> program and state.  The generated runtime is composed with the Milawa
> soundness theorem so that acceptance implies truth.  The shipped artifact
> is the compiler's output; no hand-written WAT and no per-opcode path is on
> the proof path.  The first slice is the arithmetic/control subset with a
> generated-code PoC; the end is the Jitawa sentence for the generated
> runtime.

## 8. Immediate next actions

1. **Stop** extending `const-*`, `chain-*`, `engine*`, `ops-*`, and the
   hand-written `milawa-verified.wat`/`milawa-ops.wat`.  Leave them
   certified as archive.
2. Fix the compiler interface: source core Lisp -> IR
   (`compile-term`/`lower-program`) -> a generated W3T module, with the
   simulation relation stated once.
3. Prove K1 for the arithmetic/control subset: W3T execution of the
   generated code refines `machine-run`; emit the module from the generator
   and make the PoC an instance.
4. Extend to `cons`/`car`/`cdr`, symbols, environments, and the heap (K2),
   then the function table, calls, and runtime loop (K3).
5. Compile the kernel and run `100.events` on the generated module (K3);
   then compose the Milawa soundness theorem (K4).
6. Emit and check the binary artifact, and keep the corpus as the
   regression suite (K5).

The first reviewable deliverable is K1: the generated-code theorem plus a
PoC whose WASM module is produced by the compiler.  There is no hand-written
module in that deliverable.
