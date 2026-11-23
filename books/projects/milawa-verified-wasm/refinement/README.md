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
frame-around-label-around-value step for `*ir-store*`/`*ir-frame*`.  The
three-step op_const body composition and the `$invoke` call entry are still
open; these are J2b-2 steps, not an opcode theorem.

**J2b-2 (blocked): the W3T link.**  A symbolic W3T proof that
`$invoke` on an exported function returns the model's i32 did not close:
`op_const` through `steps/%fuel` timed out at 180 s, and the call-entry
lemma alone at 300 s.  The cost is the generated `$invoke`/`val-ok`/call
machinery with symbolic arguments, the same per-call cost the old chain
books pay.  The module and model are checked in; the W3T layer needs the
old call/entry/return lemmas ported to this store, or the verified
translation route (J5).  This is not the W3T theorem the plan's J2
acceptance asks for.

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
  (`milawa-ops.wat`, `ops-state.lisp`, `ops.lisp`); the symbolic W3T theorem
  that a call to an exported function returns the model's value is blocked
  on the generated `$invoke`/`val-ok`/call cost (see the J2b-1 section).
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
