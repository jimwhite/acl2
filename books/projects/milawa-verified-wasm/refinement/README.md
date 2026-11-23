# refinement/ -- the Jitawa-shaped tree

This is the new proof tree from [`../PLAN-JITAWA.md`](../PLAN-JITAWA.md).  It
is certified separately from the `wasm3/` archive:

```
make -C refinement ACL2=/workspaces/acl2/saved_acl2
# or, from the project root:
make refinement ACL2=/workspaces/acl2/saved_acl2
```

## J0/J1a (done)

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

Measured: 2 books, 2.5 s, 2.1M prover steps.

## What is deliberately not here yet

- **J1b -- the flat machine.**  The IR is a tree, the simplest target that
  makes the compiler theorem cheap.  The flat stack/pc machine
  (`bc-step`/`bc-run`), the lowering from the tree IR, and the run-level
  theorem are J1b.  The compiler theorem above is what that lowering
  consumes.
- **The bridge to `MILAWA-RUN`.**  `r-ev` is the Jitawa-style high-level
  spec.  Proving `r-ev = MILAWA-RUN` (at a computed fuel) for the subset is
  part of J1b; it is what ties the new spec to the existing interpreter.
- **The parser/REPL.**  Terms are ACL2 s-expressions here; the surface
  parser and REPL are J0b.
- **Calls/lambdas/heap.**  The subset is primitives + `if`; the function
  table, `cons`-cell heap, and the full kernel are J1c/J4.

## Why this shape

The earlier `wasm3/const-*` chain proved one fixed WASM dispatch trace for
one opcode path.  This tree proves the compiler once, for all terms.  The
next layers (flat machine, per-opcode WASM, run level) are parametric in
the program, as in Jitawa; see the plan for the full milestone list.
