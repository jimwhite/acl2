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

## Design finding (2026-11-23)

A CEK-style flat machine with a fuel/continuation run proof was prototyped
first and is a slog (600 s, still diverging in the primitive case).  J2a
sidesteps that by proving the per-opcode step layer, the dispatcher
coverage, and the closed pass; the general run-level theorem is J3, where a
relational exact-count presentation (the `MILAWA-RUNS` pattern) is the
better target.  The machine that actually ships is the WASM artifact in
J2b.

## What is deliberately not here yet

- **J2b -- the WASM artifact.**  The per-opcode WASM module (exported
  opcode functions plus the dispatcher) and its W3T theorems are the next
  layer; J2a is the ACL2 machine they implement.
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
