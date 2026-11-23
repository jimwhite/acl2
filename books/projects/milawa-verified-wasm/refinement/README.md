# refinement/ -- the Jitawa-shaped tree

> **Direction (2026-11-23, after the Jitawa review).** The goal has two
> stages: a verified Lisp runtime (relational spec, `BC_ev`/`BC_ev_thm`,
> generated machine/W3T code, parser/printer, top Hoare-style theorem), then
> the Milawa prover.  Correctness is relational/partial, not clocked.  The
> hand-written `wasm/milawa-ops.wat`, the `ops-*` books, the host loop in
> `top-host.lisp`, and the exact-clock `k1-arith` top theorem are archive and
> regression, not the proof path.  See [`../JITAWA-REVIEW.md`](../JITAWA-REVIEW.md)
> and the L/M track in [`../PLAN-JITAWA.md`](../PLAN-JITAWA.md).

This is the new proof tree from [`../PLAN-JITAWA.md`](../PLAN-JITAWA.md).  It
is certified separately from the `wasm3/` archive:

```
make -C refinement ACL2=/workspaces/acl2/saved_acl2
# or, from the project root:
make refinement ACL2=/workspaces/acl2/saved_acl2
```

## J0/J1 (done for the compiler level)

`spec.lisp`:
- `variable-p`, `term-p` -- core terms: `QUOTE`, variables, `IF`, and the
  twelve primitives at their arities.
- `r-ev` -- the reference evaluator, returning the runtime's
  `MILAWA-OK`/`MILAWA-ABORT` tagged results.

`compile.lisp`:
- `compile-term` -- the untrusted compiler to the structured bytecode IR
  (`:const`, `:load`, `:prim`, `:if`).
- `bc-eval` -- the IR semantics.
- **`compile-correct`** -- for every `term-p` term and every environment,
  `bc-eval (compile-term term) = r-ev term`.  This is the `BC_ev_thm`
  analogue: one parametric theorem for the whole subset, not a proof per
  program.
- Corollaries: `(+ 1 2)`, `(if (< 1 2) 10 20)`, and `(cons 1 2)`.

`bridge.lisp`:
- `r-ev-add-agrees-with-milawa-run`, `r-ev-if-...`, `r-ev-cons-...`,
  `r-ev-variable-...`, `r-ev-quote-...` -- the PoC and representative forms
  agree with the runtime's `MILAWA-RUN`, by evaluation.  These are checks,
  not the general bridge.

Measured: 3 books, ~3 s, 2.1M prover steps.

## J2a: the flat machine (done)

`machine.lisp` lowers the IR to a flat stack/pc instruction list
(`:const`, `:load`, `:prim`, `:ifz`, `:jmp`, `:label`, `:halt`) and gives it
a step machine:

- `lower-term` / `lower-program` -- the lowering, with absolute labels;
- `machine-step` / `machine-run` -- the step and the fuelled run;
- one theorem per opcode: `machine-step-const`, `-load`, `-label`, `-halt`,
  `-jmp`, `-ifz-true`, `-ifz-false`, `-prim-1`, `-prim-2`;
- `machine-step-dispatches` -- every well-formed instruction is handled, no
  `:bad-instruction` fall-through;
- closed instances `j2-add`, `j2-if`, `j2-cons` -- the J1 terms go through
  `compile-term` -> `lower-program` -> `machine-run` to the right answers.

Measured: 4 books, ~3.5 s.  The general run-level theorem is still useful,
but it must target generated W3T code (K1); the hand-written per-opcode
artifact (J2b below) is archived.

## J2b-1: the per-opcode module and table (archive/off-goal)

`../wasm/milawa-ops.wat` (assembled to `milawa-ops.wasm`) is the
integer/arithmetic/if opcode library: `op_const`, `op_add`, `op_sub`,
`op_lt`, `op_ifz`, `op_jmp`, `op_label`, and a pure `step` dispatcher.
`ops-state.lisp` pins its decoded module/store/frame; `ops.lisp` has the
checked opcode table and index, the i32 model of each function, one
dispatcher theorem per opcode, and value-level agreement with J2a's
`machine-step` for const/add/sub/lt (with the subset's bounds).

Measured: `ops-state` 0.25 s, `ops` 0.24 s.

`ops-w3t.lisp` (with `wasm3/context`'s generic no-ctxt facts) proves the
frame/label `local.get`, the label/frame value returns, and the
frame-around-label-around-value step for `*ir-store*`/`*ir-frame*`, and the
three-step `ir-op-const-body` composition (taking `CAR` after each `STEP`).
The `$invoke` call entry is still open; this is a J2b-2 step, not yet the
opcode theorem.

**J2b-2 (archive/off-goal): the W3T link.**  The `op_const` chain is complete:
`ir-op-const-body` (the three local steps), the value-prefixed
`no-ctxt-instrs-on-op-const-call` (with the two stuck-suffix `STEP` facts),
`ir-op-const-call-entry` (one `STEP` from `$INVOKE` into the callee frame),
and `ir-op-const-call-result` (four `STEP`s from `$INVOKE` to the value).
The call's outer frame is the **empty call frame**, so the body lemmas are
generalized over the outer frame.  For `op_add` (function 1), the entry
configuration, the value-prefixed no-ctxt chain (including the one-constant
suffix), and the one-step call entry are proved.  The redex steps
`add-inner0/1/bin` (and explicit state-pair forms) are proved.  `ops-add.lisp`
proves the `op_add` body at the body config: the first step via the engine's
`step-of-flat-block`, the value-prefix step via
`engine-ctxt-from-values-instr-step`, and `add-body-inner3` composes the three
inner steps.  `ops-add-label.lisp` proves the conditional label/frame lifts
and instantiates them at the explicit inner terms, giving
`ir-op-add-body` (five steps from the callee config to the value) and
`ir-op-add-call-result` (six steps from `$invoke`).  The value is
`(loghead 32 (+ v1 v2))`; the theorems carry the side condition
`(unsigned-byte-p 32 (loghead 32 (+ v1 v2)))`.  For `op_sub`,
`ops-sub-body.lisp` proves the `$isub_` bridge
`(rem (- (+ 2^32 i1) i2) 2^32) = (loghead 32 (- i1 i2))` using
`rem-positive-as-mod`, `loghead-32-as-mod`, and the non-local
`acl2::cancel-mod-+-basic`; `ops-sub-label.lisp` proves `ir-op-sub-body` and
`ir-op-sub-call-result`.  For `op_lt` (function 3), `ops-lt-body.lisp`
proves the signed comparison bridge
`$ILT_ 32 (:s) v1 v2 = (if (< v1 v2) 1 0)` (under 31-bit operands, via
`$SIGNED_`/`$BOOL`, plus `unsigned-byte-p 31 => unsigned-byte-p 32`), the
call entry and three body steps; `ops-lt-label.lisp` proves
`ir-op-lt-body` and `ir-op-lt-call-result` with value
`(if (< v1 v2) 1 0)`.  For `op_ifz` (function 4), the artifact now uses
the straight-line `target * (test == 0 ? 1 : 0)` body
(`local.get` / `i32.eqz` / `i32.mul`); `ops-ifz-body.lisp` proves the
`$IEQZ_`/`$IMUL_` bridges, the call entry, and the four body steps, and
`ops-ifz-label.lisp` proves `ir-op-ifz-body` and
`ir-op-ifz-call-result` with value `(if (equal v1 0) v2 0)`.
`ops-jmp.lisp` (function 5) and `ops-label.lisp` (function 6) prove the
entry and three-step body/call results (to `v2` and `v1`).  For the `STEP`
dispatcher (function 7), `ops-return-label.lisp` proves the exit-body
label step (`((const v) (return))` under a label, bare and with a rest),
`ops-dispatch-tail.lisp` factors the comparison/if-chain generators, and
`ops-return-suffix.lisp` proves the generic no-BR-tail facts, the
function-label return with an arbitrary no-BR suffix, the frame return,
and the generic frame/label lift for one body step.  `ops-trace-0.lisp`
proves the six-step op0 body trace from the first comparison through the
branch's `local.get` and the if-label return, `ops-frame-0.lisp` proves
the frame-level lift, the function-label frame lift, the frame return,
and the append/frame config steps, `ops-frame-6.lisp` proves the
six-step frame trace, and `ops-frame-8.lisp` closes the full eight-step
op0 frame trace to the value configuration (with totalized `sel`/`tail-sel`
eliminating the un-p/no-br side conditions).  The dispatcher is now closed
for every opcode.  `ops-tails.lisp` proves the raw true-branch tails for
ops 1, 3, 4, 6, 7, `ops-eqz`/`ops-tail-5` the ifz/mul tail, and
`ops-frame-skips.lisp` the 28 false-comparison skips at the frame level;
`ops-frame-traces.lisp` composes each opcode's trace from the first
comparison to its value.  `ops-step-call.lisp` proves the four-value
`STEP/PREFIX7` and the no-context facts for every prefix of the dispatcher
call, `ops-step-entry.lisp` the one-step `$INVOKE` entry into function 7 for
each opcode, `ops-step-results.lisp` the composed
`ir-op-step-call-result0..7`, and `ops-step-theorem.lisp` the exported
`ir-op-step-call-result`: for every opcode 0-7 and well-formed operands,
`$INVOKE *ir-store* 7` reaches the opcode's value (9/14/21/26/31/37/39/44
steps; the signed compare carries its 31-bit bounds).  The model-level
`ir-step-table` and `machine-step-dispatches` are proved.  This meets the
plan's J2 acceptance (one theorem per opcode plus a dispatcher theorem);
the step clocks are the per-branch WASM block structure, not a concrete
program trace.

## J3: the run level and the front door (archive/off-goal)

`top-host.lisp` models the host loop that keeps pc/stack and calls the
verified STEP for the arithmetic primitives (`+`, `-`, `<`): `host-prim-2`
checks the artifact's 30-bit range and uses `ir-step`, `host-step` is
`machine-step` for everything else, and `host-run` iterates.
**`host-run-refines-machine-run`** proves, by induction on fuel, that the
host loop equals the VM run unless the artifact's range is exceeded (where
WASM i32 wrap/signed LT differ from the Milawa primitives).

`poc.lisp` is the front door: closed host/machine runs for `(+ 1 2)`, the
`if` example and `(cons 1 2)` derived from that theorem and the J2a closed
passes, plus closed W3T dispatcher theorems for add, lt and ifz derived from
`ir-op-step-call-result`.  `make poc` prints the spec/machine/host answers
and the dispatcher value.

`top-run.lisp` is the verified-lowering groundwork for the remaining
general run theorem (J1b): an untrusted lowering whose labels are the
absolute pcs of their label instructions, its instruction count, the
position invariant `positional-from`, and `label-pc` resolution on that
code.  The run-level induction (`machine-run` of the lowered code equals
`bc-eval`, and hence `r-ev` by `compile-correct`) is the next book.

## Running the Milawa demo on the model

`milawa2-data.lisp` holds the simplified kernel's `DEFINE` forms as data and
`milawa-events.lisp` the `milawa-on-jitawa` `100.events` demo (ACL2's reader
handles the `#n=` sharing).  `milawa-check.lisp` is the untrusted front end
from surface Lisp to core syntax: it expands `COND`/`AND`/`OR`/`LET`/`LET*`/
`LIST`, closes `LET` over its free variables (the evaluator's lambdas are not
closures), specializes `CL-USER::FUNCALL` to `LOGIC.PROOFP`, and supplies the
runtime system functions (`FIRST`..`FIFTH`, `ENDP`, `NULL`, `DEFINE`, `ERROR`,
`PRINT`).  A validator checks that no surface macro or unknown function head
remains and that the translated bodies are closed.

`milawa-run.lisp` starts the kernel from the initial state (translated
function table, initial axioms and arity table, checker `LOGIC.PROOFP`) and
runs all 100 events: `(:MILAWA-OK . SUCCESS)` in ~100 s, certified.
`make milawa-check` reproduces it.  This is the Jitawa demo on the verified
*evaluator model*: a checked run, not yet the WASM artifact.

## Corrected active path (2026-11-23, after the Jitawa review)

The per-opcode W3T link, host loop and exact-clock K1 top theorem above are
archived.  Jitawa's correctness theorems are relational and partial: `BC_ev_thm`
uses `iSTEP^*`, and `jitawa_correctness_thm` is a Hoare triple with a
`terminates` premise and `error \/ R_exec` postcondition.  Exact clocks are
not part of correctness.  See [`../JITAWA-REVIEW.md`](../JITAWA-REVIEW.md).

The active track is:

- **L0 (s-expression layer) -- done.**  `l0-parse.lisp` is the surface-to-core
  front end (`LET`/`LET*`/`COND`/`AND`/`OR`/`LIST`/lambda, closure conversion,
  `DEFUN`, `FUNCALL`).  `l0-spec.lisp` has the core term predicate, the
  big-step evaluator `l0-ev`/`l0-evl`/`l0-ap` (primitives, lambdas, function
  table, `DEFINE`/`L0-DEFUN`/`PRINT`/`ERROR`/`FUNCALL`), the `l0-exec` read-
  eval-print loop, `l0-run-source`, and the string printer
  `l0-print-value`/`l0-print-values`.  No clocks are exposed; fuel only bounds
  recursion.  The ASCII/character reader and stream are the remaining L0b
  layer.
- **L1** -- relational bytecode `BC_ev` and the compiler theorem
  `BC_ev_thm`, with `BC_REFINES`; no clocks.
- **L2** -- generated machine/W3T code and a relational `STEP^*`/Hoare
  simulation; no hand-written module.
- **L3** -- top runtime theorem `{init * terminates} code {error \/ R_exec}`.
- **M0-M3** -- Milawa logic, kernel deep-to-shallow, invariant, and top
  soundness composition.

## What is deliberately not here yet

- **L0b: the character reader.**  L0 starts from a list of s-expressions
  (`l0-run-source`); the verified ASCII reader/stream and its inverse to the
  printer are the next L0 layer.
- **L1.**  There is no `BC_ev`/`BC_ev_thm` yet; this is the next book.
- **The general `R-EV = MILAWA-RUN` bridge.**  `bridge.lisp` checks the PoC
  and representative forms; the theorem for all terms is part of L0/L1.
- **Calls/lambdas/heap.**  L0 has the evaluator and function table; the
  bytecode/compiler and heap are L1/L2, and the full kernel is M0-M3.

## Why this shape

The earlier `wasm3/const-*` chain proved one fixed WASM dispatch trace for
one opcode path.  This tree proves the compiler once, for all terms.  The
correction is that the next layer is *generated* code, not a hand-written
per-opcode module: the compiler emits the module, and the proof is about the
emitted module.  The Jitawa review adds the second correction: state the
correctness theorem relationally (not with exact clocks), and put the parser,
printer, heap and Milawa kernel inside the compositional stack.
