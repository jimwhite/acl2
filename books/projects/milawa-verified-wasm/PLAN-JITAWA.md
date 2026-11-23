# PLAN: a verified Lisp runtime for Milawa, in Jitawa's shape

This is the project plan the PoC pointed at, revised after a close review of
Jitawa's papers and HOL sources (`jitawa-docs/`,
`/home/vscode/HOL/examples/theorem-prover/`).  See
[`JITAWA-REVIEW.md`](JITAWA-REVIEW.md) for the review that drives this plan.

The project has two stages, in Jitawa's order:

1. **`lisp-runtime`** -- a verified Lisp read-eval-print loop: a small Lisp
   specification, a compiler to bytecode, a generated machine/WASM
   implementation, a parser, a printer, and a top Hoare-style theorem.
2. **`milawa-prover`** -- formalize Milawa's logic, prove it sound, prove the
   kernel source faithful to it, and compose the two at
   `MILAWA_CORE_TEXT ++ input`.

The existing `wasm3/chain*`, `const*`, and `engine*` books, and the newer
`refinement/ops-*`/`wasm/milawa-ops.wat` books, stay certified as an archive
and regression suite; they are not the route to the theorem.

## 0. The goal (revised after the Jitawa review)

The deliverable is a **verified Lisp runtime followed by the Milawa prover**,
not a per-program trace and not a clocked machine simulation.  Concretely:

- the Lisp specification is small and relational: a `term` syntax, big-step
  `R_ev`/`R_ap`/`R_exec` semantics with an `ok` flag, the parser and printer,
  and explicit input/output streams;
- the compiler and bytecode semantics are related by one theorem: if the
  source evaluation relation returns, the bytecode relation reaches a related
  state (`BC_ev_thm`, with a `BC_REFINES` invariant);
- the generated machine/WASM code is related to bytecode by a relational
  simulation (`W3T::STEP^*` or an equivalent Hoare triple), not by exact step
  counts;
- the top runtime theorem is partial correctness with a termination premise
  and an error disjunct, as in Jitawa's `jitawa_correctness_thm`;
- the Milawa composition is instantiated at the kernel text and the input, so
  a printed theorem is semantically true.

"Correct by construction" is used in Jitawa's sense: **the compiler need not be
trusted**.  It is an ACL2 function; the correctness theorem is the guarantee,
and the artifact is produced by evaluating that function.  A wrong compiler
produces code that fails the theorem; it does not produce code that escapes it.

**Step counts are not part of the goal.**  Jitawa's `BC_ev_thm` uses
`iSTEP^*` (a reflexive-transitive closure), and `jitawa_correctness_thm` is a
Hoare triple with a `terminates` premise and `error \/ R_exec` postcondition.
Exact clocks are a performance/regression concern, not a correctness
requirement.  Our earlier exact-clock K1 slice is therefore demoted to a
regression; the active K/L1 shape is relational.

This rules out the earlier shape in which the WASM module was a hand-written
WAT file and the proofs were about that file's instruction sequence.  The
hand-written module, the per-opcode `ops-*` books, the host loop that calls its
`STEP`, and the exact-clock `k1-arith` top-level attempt are an experiment.
They are archived, not extended, and no part of the final theorem depends on
them.

## 0.1 The two top theorems to copy

From Jitawa (see `JITAWA-REVIEW.md` for the file/theorem names):

- **Runtime**: if the input is one for which the specification terminates,
  the machine code either reports an error or reaches a final state described
  by `R_exec`.  The parser and printer are inside the specification; the
  runtime may aborts on resource limits.
- **Milawa**: if the kernel source is `core.lisp`, the top theorem is
  instantiated at `input = MILAWA_CORE_TEXT ++ rest`, and every printed
  `THEOREM` line is true in the formalized logic.  The kernel is related to the
  logic through the deep-to-shallow certificate (`M_ev ==> MR_ev ==> R_ev`).

## 0.2 Why step counts are not important

They are not part of either Jitawa theorem.  `BC_ev_thm` uses the closure
`iSTEP^*`; `jitawa_correctness_thm` is a Hoare triple with a `terminates`
premise and `error \/ R_exec` postcondition.  Jitawa reports speed separately
and never makes correctness depend on a clock.

Our exact-clock K1 attempt was therefore a proof-shape mistake, not a semantic
requirement.  A theorem of the form
`machine-run (clock (gen x)) initial = value-state` is stronger than needed and
forces an additivity/clock-arithmetic induction that Jitawa avoids entirely.
The active plan uses relations:

- source: `R_ev` returning implies a related bytecode state;
- bytecode: `BC_ev` reaching a state implies a related machine configuration
  under `STEP^*`;
- top: `{init * terminates} code {error \/ R_exec result}`.

If we later want clocks, they belong to a separate timing/regression layer and
must not appear in the soundness theorem.

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

## 3. The architecture (Jitawa's layers, with ACL2 and WASM)

The Lisp runtime, which is the first deliverable:

```
Lisp source text (core.lisp + input)
        |
        |  verified parser: next_sexp / sexp2term
        v
term / sexp
        |
        |  relational spec: R_ev / R_ap / R_exec  (ok flag, io)
        v
source evaluation relation
        |
        |  compiler (untrusted ACL2 function)
        v
bytecode (bc_inst_type) + BC_ev relation
        |
        |  BC_ev_thm: R_ev returning ==> BC_ev reaches a related state
        v
generated machine/W3T code (no hand-written module)
        |
        |  STEP^* / Hoare triple (relational, no clock)
        v
top runtime theorem:
  {init * terminates} code {error \/ R_exec result}
```

Then the Milawa prover, which is the second deliverable:

```
core.lisp text --> MILAWA-CORE-TEXT (logic constant)
      |
      |  M_ev / MR_ev / R_ev   (deep-to-shallow certificate)
      v
kernel invariant --> proofp faithful --> milawa_main_soundness
      |
      |  compose with the runtime theorem at MILAWA_CORE_TEXT ++ input
      v
milawa_soundness_thm: every printed THEOREM line is semantically true
```

### Design principles

1. **Spec first, and relational.**  The reference semantics is small and
   relational; the compiler and generated code are judged against it.  The
   specification owns parsing, evaluation, printing, and the `ok` flag.
2. **One theorem per layer, parametric in the program/state.**  Compiler
   correctness is one theorem (`BC_ev_thm`); machine correctness is one
   relational simulation; the top is a composition.  No proof is per program
   and no proof is per opcode path.
3. **The compiler is untrusted.**  Its output is related to the source by the
   correctness theorem; a wrong compiler fails the theorem, not the users.
4. **The artifact is generated, not hand-written.**  The compiler emits the
   machine/WASM code and the proof is about the emitted code.  There is no
   hand-written WAT, no per-opcode hand proof, and no per-program trace.
5. **Partial correctness with an error disjunct.**  The top theorem assumes
   termination of the specification and concludes `error \/ R_exec result`, as
   Jitawa does.  Resource exhaustion and runtime errors are allowed; they are
   not false acceptance.
6. **No exact clocks at the top.**  Correctness is stated with `STEP^*` and
   relations, not step counts.  Clocks belong to a separate timing/regression
   layer; they are never a premise of the soundness theorem.
7. **The parser and printer are in the runtime.**  They are part of the
   specification and the top theorem, not an untrusted shim.  Input is read
   incrementally and output is printed eagerly.



## 4. Milestones

### Active track: L (lisp-runtime) then M (milawa-prover)

The old K/J bullets below are retained as history.  They are not the active
plan.  The active plan follows Jitawa's two directories.

#### L -- the verified Lisp runtime

- **L0 -- the specification (`lisp_semantics` analogue).**  Define the core
  Lisp `term` syntax, `sexp2term`, the big-step `R_ev`/`R_evl`/`R_ap`
  relations with an `ok` flag, the read-eval-print `R_exec` relation, and the
  parser/printer specification.  Determinism (`R_ev`/`R_ap` functional) is a
  separate theorem.  The existing `milawa-lisp` evaluator is a reference, not
  the final spec shape.
- **L1 -- the compiler and bytecode (`lisp_compiler` analogue).**  Define
  bytecode syntax and the relational `BC_ev` semantics (stack, return stack,
  function table, constants, I/O, `ok`).  Define the untrusted compiler.
  Prove one theorem `BC_ev_thm`: if `R_ev` returns, `BC_ev` reaches a state
  related by `BC_REFINES`.  No clocks.
- **L2 -- the machine/WASM layer.**  Generate the bytecode/W3T instruction
  stream from the compiler; define the heap/stack invariant; prove a
  relational `STEP^*` or Hoare-style simulation from the generated code to
  `BC_ev` (the `zBYTECODE_EVAL_THM` analogue).  The artifact is compiler
  output; no hand-written WAT.  Emit a small instruction subset and prove the
  per-instruction snippets once.
- **L3 -- the top runtime theorem.**  Compose init code, parser, eval/compile,
  print and the main loop into the `READ_EVAL_PRINT_LOOP_THM` /
  `jitawa_correctness_thm` analogue:
  `{init * terminates} code {error \/ R_exec result}`.  Parser/printer are
  included; resource limits may abort.
- **L4 -- the artifact and regression.**  Emit the binary/module from the
  proved generator (verified encoder or checked decoding); run it in a
  conforming engine; keep the corpus as a regression suite.  Exact clocks, if
  wanted, live here for timing only.

**Acceptance for L:** the top runtime theorem for the generated code,
including parsing and printing, with no hand-written module and no exact
clock in the correctness statement.

#### M -- the Milawa prover

- **M0 -- logic and soundness.**  Reuse the sibling `books/projects/milawa`
  formalization/soundness proof (or its ACL2 port).  Formalize the logic,
  `context_ok`, the inference rules, and the soundness theorem; the kernel is
  not reproved from scratch.
- **M1 -- kernel source and deep-to-shallow.**  Parse the actual `core.lisp`
  text through the verified parser; build the initial state; prove
  `M_ev ==> MR_ev ==> R_ev` (the `milawa_execScript` analogue).  Use a
  shallow ACL2 embedding of the kernel with a certificate theorem, or a
  proof-producing translation; the kernel source is not hand-transcribed
  without a theorem.
- **M2 -- the kernel invariant and checker.**  Prove the kernel invariant
  (logical context, theorem list, arity table, current checker, runtime
  function table) and `proofp` faithful to the inference rules
  (`milawa_proofpScript` analogue).
- **M3 -- the top soundness theorem.**  Compose M2 with the L3 runtime
  theorem at `input = MILAWA_CORE_TEXT ++ rest`:
  `milawa_soundness_thm`; every printed `THEOREM` line is semantically true.

**Acceptance for M:** the Jitawa sentence with ACL2 in place of HOL4 and WASM
in place of x86-64.

#### Old K-track (history, not active)

- **K0 -- source/IR interface.**  Superseded by L0/L1.
- **K1 (partial, exact clocks) -- generated arithmetic code.**
  `refinement/k1-arith.lisp` proves the engine step lemmas and closed runs.
  It is kept as a regression for the generated instruction layer; the
  exact-clock run theorem is not the L1 shape and is not extended.
- **K2/K3/K4/K5** -- superseded by L2/L3/M0-M3.

**Acceptance at the end:** the top-level theorem says that acceptance by the
generated runtime implies truth, and the runtime is the compiler's output.  No
hand-written WASM is on the proof path.

### Status (2026-11-23, history)

> **Archive notice.**  The J0-J4/K-track status below is historical.  It
> includes exact-clock and hand-written-module experiments that are not the
> active plan.  The active plan is the L-track followed by the M-track above.
> Do not extend the old J/K work except as regression.

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
| `milawa-lisp/values`, `eval`, `programs`, `metatheory`, `reachability` | **keep**; reference evaluator and exact-step relation, but the final L0 spec is the relational `R_ev`/`R_exec` shape |
| `refinement/spec.lisp`, `compile.lisp`, `machine.lisp`, `top-run.lisp` | **keep as reference**; the tiny AST/IR is useful for L1, but L0/L1 must be extended to the full Lisp terms and a relational `BC_ev` |
| `refinement/milawa2-data`, `milawa-check`, `milawa-events`, `milawa-run` | **keep as reference**; the front end and model run show the kernel works, but the final M1 needs a verified parser and a deep-to-shallow certificate |
| `refinement/k1-arith.lisp` | **regression only**; the engine step lemmas and closed generated runs are useful, but the exact-clock top theorem is not the L shape |
| `wasm-acl2` (`W3T`, engine) | **keep**; the ACL2 WASM 3.0 target semantics |
| `wasm3/decode`, `module`, `state`, `memory`, `numerics` | **keep** as W3T/artifact infrastructure and decoding regression |
| `wasm3/poc.lisp`, `POC.md`, `examples/*.mvm` | **keep** as front-door regression; not the proof |
| `wasm/milawa-verified.wat`/`.wasm`, `wasm/milawa-ops.wat`/`.wasm` | **archive**; hand-written modules, not the artifact |
| `refinement/ops-*`, `refinement/top-host.lisp`, the host/W3T parts of `refinement/poc.lisp` | **archive**; the hand-written dispatcher path, not extended |
| `machine/mvm.lisp` | **archive**; the model of the hand-written module (useful history, not the target) |
| `wasm3/chain*`, `links`, `frozen`, `running`, `dispatch*`, `load`, `fetch`, `halt`, `abort`, `oob`, `const*`, `engine*`, `const-join`, `const-steps`, `const-front` | **archive**; still certified, not extended |
| The 57-book `make check` | **keep green** while the new tree is built separately |

The archive is not wasted: it is the concrete evidence for the W3T
instruction library, the generated-instruction step lemmas, and the traps
recorded in `AGENTS.md`.  It is simply not the proof the project will ship.

## 6. Risks and mitigations

- **The compiler and bytecode semantics are the long pole.**  We need a
  relational `BC_ev`, a compiler theorem, and a generated-code simulation
  against W3T.  ACL2 has no ready-made WASM backend.  Mitigation: copy
  Jitawa's layering; prove one theorem per layer, relational and parametric;
  start with the L0/L1 subset and extend one source construct at a time.
  The compiler need not be trusted: `BC_ev_thm` is the guarantee.
- **The parser, printer, and heap are in scope.**  Jitawa's top theorem
  includes parsing, printing, function definitions, I/O and resource limits,
  and its runtime has a verified heap/GC.  Mitigation: make them part of L0
  and L3 from the start; do not treat them as an untrusted shim.  An abort on
  resource exhaustion is allowed by the error disjunct.
- **The deep-to-shallow translation.**  Jitawa uses proof-producing
  deep-to-shallow extraction.  ACL2 has no equivalent tool.  Mitigation:
  write shallow ACL2 functions for the kernel and prove the certificate
  theorem relating them to the deep `M_ev`/`MR_ev`/`R_ev` semantics, or
  implement the small translation for the core language.  Do not hand-wave
  the kernel transcription.
- **The Milawa composition is large.**  Mitigation: reuse the sibling
  Milawa checker/soundness proof and Jitawa's `milawa_exec` pattern; the
  runtime side only has to instantiate the top theorem at the core text.
- **The runtime loop.**  The host that reads input and drives the generated
  code is in the trusted boundary.  Mitigation: include the loop in the
  specification and generate/prove it as part of the runtime, as Jitawa's
  `exec` loop does; do not hand-write a dispatcher.
- **Exact clocks are a trap.**  They are not needed for correctness and are
  expensive to prove.  Mitigation: keep the correctness statement relational
  (`STEP^*`, `BC_ev`, `R_exec`); put clocks in a separate timing layer.

## 7. Goal statement

> **Goal (Jitawa-shaped):** A verified Lisp runtime, followed by the Milawa
> prover.  The runtime is a small relational Lisp specification (`R_ev` /
> `R_ap` / `R_exec`, parser and printer), an untrusted compiler with one
> relational correctness theorem (`BC_ev_thm`), a generated machine/WASM
> implementation proved by `STEP^*` / a Hoare-style simulation, and a top
> partial-correctness theorem `{init * terminates} code {error \/ R_exec}`.
> The prover formalizes Milawa's logic, proves it sound, proves the kernel
> source faithful through a deep-to-shallow certificate, and composes at
> `MILAWA_CORE_TEXT ++ input`.  The end is the Jitawa sentence with ACL2 in
> place of HOL4 and WASM in place of x86-64.  No hand-written WAT and no
> exact clock is on the proof path.

## 8. Immediate next actions

1. **Stop** extending `const-*`, `chain-*`, `engine*`, `ops-*`, `top-host`,
   the exact-clock `k1-arith` top theorem, and the hand-written
   `milawa-verified.wat`/`milawa-ops.wat`.  Leave them certified as archive.
2. **L0**: write the relational Lisp spec (`term`, `sexp2term`,
   `R_ev`/`R_ap`/`R_exec`, parser/printer) in ACL2; use the existing
   `milawa-lisp` as a reference, not as the final shape.
3. **L1**: write the relational bytecode `BC_ev` and the compiler; prove
   `BC_ev_thm` with `BC_REFINES`; no clocks.
4. **L2**: generate machine/W3T code from the compiler; prove the
   relational `STEP^*`/Hoare simulation and the heap invariant; no
   hand-written module.
5. **L3**: compose parser, evaluator, compiler, machine and printer into the
   `READ_EVAL_PRINT_LOOP_THM` analogue.
6. **M0-M3**: reuse the Milawa formalization; parse `core.lisp`; prove
   `M_ev ==> MR_ev ==> R_ev`; prove the kernel invariant and the top
   soundness theorem at `MILAWA_CORE_TEXT ++ input`.

The first reviewable deliverable is L0+L1: the relational Lisp spec and the
compiler theorem, with no exact clocks and no hand-written machine module.
