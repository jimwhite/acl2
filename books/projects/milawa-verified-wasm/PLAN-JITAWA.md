# PLAN: a Jitawa-shaped runtime, not a per-instruction trace

This is the project plan the PoC pointed at.  It puts the earlier
per-instruction chain aside and rebuilds the verified runtime in the shape
Jitawa actually has: a small specification, an untrusted compiler checked by
one correctness theorem, a bytecode machine checked once per opcode, and a
run-level theorem that composes them.  The existing `wasm3/chain*`,
`const*`, and `engine*` books stay certified as an archive and regression
suite; they are no longer the route to the theorem.

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
        MILAWA-Lisp term / kernel
                  |
                  |  compile        (untrusted ACL2 function)
                  v
        bytecode  (the VM's instruction stream)
                  |
                  |  BC_ev_thm      (one theorem, all terms)
                  v
        VM semantics  (MILAWA-RUN / MILAWA-RUNS today)
                  |
                  |  opcode-correct (one theorem per opcode)
                  v
        WASM artifact (per-opcode functions + tiny dispatcher)
                  |
                  |  run-level simulation
                  v
        W3T::STEP / W3T::STEPS  (the certified WASM 3.0 semantics)
```

On top of that, the Milawa side is:

```
core.lisp text --> MILAWA-CORE-TEXT (logic constant)
      |
      | milawa-init evaluated in the spec
      v
initial function table --> checker soundness theorem
      |
      +--> runtime theorem (compile + machine + run)
                 |
                 v
      milawa_soundness: accepted theorems are semantically true
```

### Design principles

1. **Spec first.**  The reference semantics is small and total; the
   compiler and VM are judged against it.
2. **One theorem per layer.**  Compiler correctness is parametric in the
   term; machine correctness is parametric in the VM state/opcode; run-level
   correctness is an induction on the number of steps.
3. **The compiler is untrusted.**  Its output is checked by
   `compile-correct`; a wrong compiler fails the theorem, not the users.
4. **The artifact is a library, not a trace.**  The WASM module exports a
   small `STEP`; internally it is a per-opcode function plus a dispatcher.
   Each opcode is proved once, and the dispatcher is a small case split.
   There is no 67-step path proof.
5. **Determinism supplies the answer.**  The top-level theorem is
   existential/conditional (the spec's result exists); concrete evaluation
   gives the value, as in the PoC.
6. **The front door is a corollary.**  `poc` is a closed instance of the
   general theorem, not a separate proof style.

## 4. Milestones

### Status (2026-11-23)

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
- **J2b-1 module/table/model: done.**  `wasm/milawa-ops.wat` +
  `milawa-ops.wasm` is the per-opcode integer/arithmetic/if library;
  `refinement/ops-state.lisp` pins it; `refinement/ops.lisp` has the checked
  table, the i32 model, per-opcode dispatcher theorems, and value-level
  agreement with `machine-step`.  0.5 s.
- **J2b-2 W3T link: done (per opcode and dispatcher).**  The dispatcher
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
- **J2b-2 W3T link history (op_const/op_add):**
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
- **Next.**  J2b: the per-opcode WASM artifact against the J2a machine, then
  J3.


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

**J2b (next).**

- Refactor the artifact into **per-opcode exported functions** plus a
  **tiny dispatcher**; keep the single exported `STEP` for deployment.  The
  module is generated from a table (a checked generator, not a hand-written
  instruction sequence).
- For each opcode, prove **one symbolic theorem**: the artifact's opcode
  function implements the J2a opcode step for all well-formed states and
  operands (including the abort cases).
- Prove the dispatcher once: the exported `STEP` selects the right opcode
  function and returns the same state as `machine-step`.
- Retire the per-path chain: no `chain*`, `const*`, or `engine*` book is
  extended for this.

**Acceptance (J2b):** `STEP`-correct for the subset, with one theorem per
opcode plus one dispatcher theorem.  This is met: functions 0-6 have
`ir-op-*-call-result`, the dispatcher has `ir-op-step-call-result0..7`, and
the exported theorem is `ir-op-step-call-result` (all opcodes, symbolic
operands).  The dispatcher theorem uses the per-branch step clocks
(9/14/21/26/31/37/39/44) because a dispatcher branch is a straight-line
WASM block; there is no monolithic concrete-program trace, and the operands
remain symbolic.  The existing `abs.lisp` concrete checks remain as a
regression suite.

### J3 -- Run level and the front door (`refinement/top/`)

**Status (2026-11-23): the host loop and the front door are done.**  The
bytecode VM run is `machine-run` (J2a).  `refinement/top-host.lisp` models the
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
induction over that lowering is the next book.

- Prove the host loop: `n` calls to the exported `STEP`, at the
  opcode-determined clocks, equal `bc-run` for `n` steps
  (`MVM-RUN`/`W3T::STEPS` relation).  This is an induction, not a path
  proof.
- Compose J1 and J2/J3: a program's `bc-run` refines `MILAWA-RUN`, and the
  WASM loop refines `bc-run`.
- Re-prove the PoC as a corollary of the general stack
  (`(+ 1 2)`, plus a `cons` example and a small `if` loop).
- `make poc` prints the closed instance from the new stack.

**Acceptance:** a closed `W3T` theorem for the PoC and at least one
`cons`/`if` program, all derived from the general theorems; no program-
specific WASM step chains.

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
theorem.  Parsing the ACL2 `core.lisp` text into a logic constant, proving
the interpreter implements the logic (the MILAWA-RUN/MR_ev layer), and
refining the evaluator to `milawa-verified.wasm` remain.

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

### J5 -- The endgame (optional)

- Performance (the VM is an interpreter; no JIT required).
- A verified compiler from the core Lisp subset to WASM, replacing the
  per-opcode library if it becomes worth the proof cost.

## 5. What to keep, what to retire

| Asset | Decision |
|---|---|
| `milawa-lisp/values`, `eval`, `programs`, `metatheory`, `reachability` | **keep**; the reference interpreter and exact-step relation |
| `machine/mvm.lisp` | **keep** as the starting bytecode VM; extend it for the compiler |
| `wasm/milawa-verified.wat`/`.wasm` | **refactor** to per-opcode functions + dispatcher; keep the single `STEP` export |
| `wasm3/decode`, `module`, `state`, `memory`, `numerics`, `abs`, `l1` | **keep**; artifact acceptance and the W3T abstraction |
| `wasm3/poc.lisp`, `POC.md`, `examples/add.mvm` | **keep**; the front-door regression and the shape of the result |
| `wasm3/chain*`, `links`, `frozen`, `running`, `dispatch*`, `load`, `fetch`, `halt`, `abort`, `oob`, `const*`, `engine*`, `const-join`, `const-steps`, `const-front` | **archive**: still certified, not extended; the per-path experiment |
| The 57-book `make check` | **keep green** while the new tree is built separately |

The archive is not wasted: it is the concrete evidence for `abs.lisp`, the
clock table, the instruction library, and the traps recorded in
`AGENTS.md`.  It is simply not the proof the project will ship.

## 6. Risks and mitigations

- **No proof-producing WASM synthesis.**  Jitawa's machine code is
  synthesized from HOL.  ACL2 has no equivalent WASM backend.  Mitigation:
  the per-opcode WASM library plus a tiny dispatcher gives the same
  *modularity* (one theorem per opcode) without a verified code generator;
  the module is generated from a checked table.
- **The compiler is the new long pole.**  Compiler correctness for the
  full Lisp subset is real work.  Mitigation: start with the
  arithmetic/control subset (J1), then `cons`/`car`/`cdr`, then calls;
  each extension is an induction over terms, not a new machine proof.
- **The VM must grow.**  The current MVM has seven arithmetic/control
  opcodes; the full kernel needs cons cells, a heap, and a function table.
  Mitigation: J1 defines the bytecode VM for the subset first; the heap is
  a data-structure refinement (Jitawa's `BC` state already carries the
  function table and output), not a new machine.
- **The Milawa composition is large.**  Mitigation: reuse the sibling
  Milawa checker/soundness proof and Jitawa's `milawa_exec` pattern; the
  runtime side only has to instantiate the general theorem at the core
  text.
- **Host dispatch vs machine code.**  If the host selects opcodes, the host
  is trusted.  Mitigation: keep the dispatcher inside the WASM module and
  prove it once; the host only calls the exported `STEP`.

## 7. Goal statement

> **Goal (Jitawa-shaped):** Rebuild the verified runtime as a refinement
> stack -- a small reference Lisp semantics, an untrusted compiler with one
> compiler-correctness theorem, a per-opcode WASM machine with one
> symbolic theorem per opcode and a tiny dispatcher, a run-level simulation,
> and the Milawa core/soundness composition.  Every layer is parametric in
> the program; no per-path WASM instruction chain is part of the proof.
> The first slice is the arithmetic/control subset with a closed PoC
> corollary; the end is the Jitawa sentence for `milawa-verified.wasm`.

## 8. Immediate next actions

1. **Stop** extending `const-*`, `chain-*`, and `engine*` as the proof path.
   Leave them certified.
2. Write the J0 term/parser layer and the J1 bytecode VM/compiler skeleton
   in `refinement/spec/` and `refinement/compiler/`.
3. Prove `compile-correct` for the arithmetic/control subset (the first
   real Jitawa-shaped theorem).
4. Refactor the artifact to per-opcode functions + dispatcher (J2), and
   prove the opcode theorems and the dispatcher.
5. Re-derive the PoC as a corollary (J3), then start `cons`/`car`/`cdr`
   and the function table (J1 extension).
6. Only then take up the Milawa core/soundness composition (J4).

The first reviewable deliverable is `compile-correct` for the
arithmetic/control subset plus the per-opcode `STEP` theorem; the PoC
becomes an instance, not a separate proof.
