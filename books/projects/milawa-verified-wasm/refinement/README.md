# refinement/ -- the Jitawa-shaped tree

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

Measured: 4 books, ~3.5 s.  The general run-level theorem is J3; the
per-opcode WASM artifact is J2b.

## J2b-1: the per-opcode module and table (done)

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

**J2b-2 (partial): the W3T link.**  The `op_const` chain is complete:
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
`(if (< v1 v2) 1 0)`.  For `op_ifz` (function 4), `ops-ifz-body.lisp`
proves the call entry, the `i32.eqz` value bridge, and the one-step body
lemmas (`local.get`, `testop`, both `ifelse` branches, `block`, and the
branch `local.get`); the frame/label composition and call result remain.
`ops-jmp.lisp` (function 5) and `ops-label.lisp` (function 6) prove the
entry and three-step body/call results (to `v2` and `v1`).  The `op_ifz`
call result and the `STEP` dispatcher remain.  This is not yet the plan's
full J2 acceptance.

## Design finding (2026-11-23)

A CEK-style flat machine with a fuel/continuation run proof was prototyped
first and is a slog (600 s, still diverging in the primitive case).  J2a
sidesteps that by proving the per-opcode step layer, the dispatcher
coverage, and the closed pass; the general run-level theorem is J3, where a
relational exact-count presentation (the `MILAWA-RUNS` pattern) is the
better target.  The machine that actually ships is the WASM artifact in
J2b.  J2b-1 is the module/table/model; J2b-2's W3T link is the open
bottleneck.

## What is deliberately not here yet

- **J2b-2 -- the W3T link.**  The per-opcode module, table and model are in
  (`milawa-ops.wat`, `ops-state.lisp`, `ops.lisp`), and the full `op_const`
  chain is proved from `$INVOKE` to the value; the other opcode bodies and
  the `STEP` dispatcher are the remaining J2b-2 work (see the J2b-1
  section).
- **J3 -- the run-level theorem.**  `machine-run (lower-program ...)` equals
  `bc-eval`/`r-ev` for all terms; the closed instances are the J2a checks,
  the general theorem is J3.
- **The general `R-EV = MILAWA-RUN` bridge.**  `bridge.lisp` checks the PoC
  and representative forms; the theorem for all terms at a computed clock
  is the remaining J1b piece (and also validates the spec against the
  runtime).
- **The parser/REPL.**  Terms are ACL2 s-expressions here; the surface
  parser and REPL are J0b.
- **Calls/lambdas/heap.**  The subset is primitives + `if`; the function
  table, `cons`-cell heap, and the full kernel are J1c/J4.

## Why this shape

The earlier `wasm3/const-*` chain proved one fixed WASM dispatch trace for
one opcode path.  This tree proves the compiler once, for all terms.  The
next layer (per-opcode WASM, J2) is parametric in the program, as in
Jitawa; see the plan for the full milestone list.
