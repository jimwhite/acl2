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

- Refactor the artifact into **per-opcode exported functions** plus a
  **tiny dispatcher**; keep the single exported `STEP` for deployment.  The
  module is generated from a table (a checked generator, not a hand-written
  instruction sequence).
- For each opcode, prove **one symbolic theorem**:
  the artifact's opcode function implements the VM's opcode step for all
  well-formed states and operands (including the abort cases).
- Prove the dispatcher once: the exported `STEP` selects the right opcode
  function and returns the same state as `bc-step`.
- Retire the per-path chain: no `chain*`, `const*`, or `engine*` book is
  extended for this.

**Acceptance:** `STEP`-correct for the subset, with one theorem per opcode
plus one dispatcher theorem; no exact 67-step trace in the statement or
proof.  The existing `abs.lisp` concrete checks remain as a regression
suite.

### J3 -- Run level and the front door (`refinement/top/`)

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
