# Agent notes: milawa-verified-wasm

A verified Lisp runtime for Milawa, in ACL2, targeting WebAssembly.  The plan is
`../milawa/VERIFIED-WASM-LISP.md`; this file is the short operational memory for
anyone (human or agent) working here.

## Where the truth lives

- **`README.md`** — authoritative status, one row per piece, build commands, and
  the "What we learned" list.  Update it when a row changes.
- **`SUMMARY.md`** — the long-form memory: every finding, with the measurements
  that established it.  New findings go here with their prover-step counts.
- **`../milawa/VERIFIED-WASM-LISP.md` §0.1** — phase-level progress; it defers to
  the two files above for detail.

## Building

```
make check ACL2=/workspaces/acl2/saved_acl2    # lint, books, module pin, corpus, no-skips, completeness
make -C wasm3 ACL2=...                         # the wasm3 books only (needs the pinned .wasm-acl2)
make experiment FILE=/tmp/try.lsp BOOK=chain    # scratch ACL2 with dir/timeout/log fixed
make walk                                       # what the semantics does next, from the post-call config
make lint                                       # parens the way ACL2 reads them
```

The wasm3 books depend on the pinned `wasm-acl2` clone at
`/workspaces/acl2/.wasm-acl2` (commit `7f96c89`); its 26 generated books must be
certified first.  `make books` says so rather than failing obscurely.

## House rules

- No `skip-proofs`, no `defaxiom`; `make check` fails on either.
- `wasm3/bytes.lisp`, `module.lisp`, `state.lisp` and `chain.lisp` are
  **generated**.  Regenerate with `wasm/build.sh` + `make -C wasm3 bytes module`
  or `harness/gen_chain.py`; never hand-edit.
- Measured prover-step counts in comments are part of the record.  Take them from
  the book's `.cert.out`, and correct a stale number rather than leaving it.

## Traps found the hard way (details in SUMMARY.md)

- **The search only computes on literals.**  A rewrite rule whose LHS contains
  `(cons x y)` cannot match a quoted constant, so a general rule about an
  instruction list and a literal body are incompatible.  State the instance at
  the exact per-position shape.
- **`:expand` cannot unfold a member of a mutual recursion** (`step`,
  `step/r-ctxt-instrs`, `step/r-ctxt-label`, `step/r-ctxt-frame`).  Use an
  explicit `(:instance (:definition sym) (arg ...))`.
- **A `defconst` cannot go in a `disable` list** (theory error: it is not a
  rule); helper `defun`s can, and disabling them is how a composed chain keeps
  its terms syntactically stable.
- **A free variable in a lemma's LHS does not compose.**  The inner-label steps
  carry `status` only in their result; as rewrite rules they cannot match.
  Bind it explicitly in the `:use` instance: `(status status)`.
- **A call leaves the callee's frame** (`(milawa-callee-frame 6)`), not the
  pinned `(caddr z)` the walk uses; the body reads globals through its own
  frame's module.
- **The block is a READ rule** (`step_read/split/r-block`), not a context rule;
  no general context-descent lemma is needed.
- **`steps/%fuel` does not unroll on a constant fuel over an opaque config.**
  Compose the clock with a `:rule-classes nil` successor lemma per step plus a
  definition instance; as a rewrite rule the fuel-decreasing successor loops.
- **A frame record field is a dotted pair.**  `(:MODULE :%REC ...)` stores the
  module as the CDR; writing `(:MODULE (:%REC ...))` stores a one-element list
  and every lookup answers NIL.  Same for `%GET-FIELD` arguments.
- **ACL2's `TAKE` pads**, and `acl2-count` of a symbol is its name length, so
  the tempting `(equal (acl2-count x) 0) = (not (consp x))` is false.

## Current state (2026-11-19)

32 books, all certified.  The frozen path (`status ≠ 1`) is done end to end for
symbolic state in `wasm3/frozen.lisp`: nine steps, the exact clock, the
readback; `frozen-step-check` is `abs.lisp`'s `milawa-step-check` clause for
clause.  `wasm3/running.lisp` proves the seven-step shared head of the running
paths (the status test's else branch, the empty block/label, the call split, and
the call into `$in_code`'s frame), plus the first instruction of `$in_code`'s
body and the range facts the dispatcher needs (i32 binops are `rem`s;
`relop-ltu-value`).  The dispatcher's search failure facts for `:SUB`, `:MUL` and unsigned `:LT` are
proved.  Next: the rest of `$in_code`'s body and its two value dissolves, the
opcode test, then the per-opcode tails; then L2 and L3.  Cost note: the second body position's INNER two-shot done as one lemma
measured ~281M prover steps; split into flat ctxt-instrs (16.5M), bridge
(74k), label (1.85M) and frame (2.0M) -- ~20M, 14x cheaper.  Split the lifts
this way before adding positions.  For a
step under more than two admin levels, prove it in single shots of two levels
each -- composing one-level facts by `:use` does not close at depth (143M-step
failure; the two-shot succeeds in 3.5M + 30M).

**Classify a body position's shape before attacking it.**  An instruction that
is the LAST element of its body -- the relop at the end of `$in_code`,
`((const s) (const m) (relop))` -- is stepped by the PURE rule on the body, not
by `step/r-ctxt-instrs`: the search's k = 0 branch refuses an instruction list
with nothing after the instruction, so a flat ctxt-instrs lemma there is FALSE.
Its lift from the pure body step costs 74.7M with `step` enabled and does not
close with `step` disabled.  Positions with a suffix after the instruction (the
read, the sub, the mul) do go through the search and use the ~20M
flat+bridge+label+frame recipe.  Val-p of an intermediate value needs
`un-p-32-is-unsigned-byte-p` plus `subval-/mulval-/ltuval-is-a-value` with
`$BINOP_`/`$RELOP_` disabled.

Caution worth keeping: NTH/NTHCDR shift facts must be `:rule-classes nil`.  As
rewrite rules ACL2's arithmetic matcher binds `a = 0` and applies them to their
own right-hand sides (measured with `:brr`).  For the readback, state the index
against the append form instead: `(nth (+ i (len pre)) (append pre b)) =
(nth i b)`.  And a context-chain fact at a symbolic `status` must be
specialized (`(instance ... (status 1))`) before a bare `:use` will bind it.
