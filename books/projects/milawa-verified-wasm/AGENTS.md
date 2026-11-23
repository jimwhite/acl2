# Agent notes: milawa-verified-wasm

A verified Lisp runtime for Milawa, in ACL2, targeting WebAssembly.  The plan is
`../milawa/VERIFIED-WASM-LISP.md`; this file is the short operational memory for
anyone (human or agent) working here.

## Direction (2026-11-23)

Read `PLAN-JITAWA.md` before starting work.  New proofs follow its J0--J5
milestones in a `refinement/` tree: spec -> compiler correctness -> bytecode
VM -> one symbolic theorem per WASM opcode -> run-level -> Milawa soundness.
The `wasm3/chain*`, `wasm3/const*` and `wasm3/engine*` books are the archive of
the earlier per-path experiment: keep them certified, do not extend them as
the proof path.  The PoC and the `abs.lisp`/memory/numerics books are kept as
the regression suite.

**Refinement tree (J0/J1 compiler + J2a machine done, 2026-11-23).**
`refinement/spec.lisp` has `variable-p`/`term-p`/`r-ev`;
`refinement/compile.lisp` has `compile-term`, `bc-eval`, and
`compile-correct` for the arithmetic/control subset (all twelve primitives +
`if`), with the PoC expressions as corollaries.  `refinement/bridge.lisp`
checks `r-ev` against `MILAWA-RUN` on those forms.  `refinement/machine.lisp`
is J2a: the flat stack/pc lowering and `machine-step`/`machine-run`, one step
theorem per opcode, the dispatcher coverage, and the closed
`(+ 1 2)`/`if`/`cons` passes.  A CEK-style run proof was prototyped and is a
slog (600 s, diverging); the general run-level theorem is J3, and the
per-opcode WASM artifact is J2b.  The general `r-ev = MILAWA-RUN` bridge is
the open J1b piece.  Build with `make refinement ACL2=...`; separate from
`make check`.

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
make engine ACL2=...                           # certify the wasm-acl2 engine books (once per pin)
make -C wasm3 ACL2=...                         # the wasm3 books only (needs the pinned wasm-acl2 submodule)
make experiment FILE=/tmp/try.lsp BOOK=chain    # scratch ACL2 with dir/timeout/log fixed
make walk                                       # what the semantics does next, from the post-call config
make lint                                       # parens the way ACL2 reads them
```

The wasm3 books depend on the pinned `wasm-acl2` submodule at `wasm-acl2/`
(commit `1ce59e0`, the `engine-plan2` branch; remote
`https://github.com/raymyers/wasm-acl2.git`); its 26 generated semantics books
and the engine books `wasm3/engine.lisp` includes must be certified first.
`make engine` certifies the engine books in the submodule; `make books` says so
rather than failing obscurely.  The submodule lives inside this project so the
project's `cert_pl_exclude` keeps it out of a community certification run.

**The package is `MILAWA-WASM`.**  Every book starts
`(in-package "MILAWA-WASM")`.  The `defpkg` is in `package.lsp` at the project
root -- not in a book, because a `defpkg` is not an embedded event form -- and
each directory's `cert.acl2` loads it before certification.  The harness prepends
the same two forms (`(ld "../package.lsp")`, `(in-package "MILAWA-WASM")`) to
every scratch script, so new scratch files can use the project's names
unqualified.  A session that includes a book by hand must load `package.lsp`
first.  Names from included system books that ACL2 does not export are imported
in `package.lsp` (`expt2`, `logapp`, `loghead`, `logtail`) or written with
`acl2::` (`acl2::rem-bounds`, `acl2::loghead-identity`); after changing
`package.lsp`, every certificate must be rebuilt.

## Automation

- `wasm3/literals.lisp` — write a position as `(func-body-lit i)`,
  `(func-tail-lit i n)` or `(func-instr-lit i n)` (or a `def-func-*`
  constant) and let the event carry the module's literal.  The value is
  computed from `milawa-func-body` at expansion time, so a module change
  propagates at the next certification, and a malformed instruction list is
  an expansion error rather than a false lemma.  Use it instead of copying
  instruction lists by hand.  A `defconst` of the accessor's value is also
  spliced as a literal (measured: `step_pure` on `*literals-tail-6-3*`
  proves by evaluation in 4 steps).
- `wasm3/subst.lisp` — `defsubst-chain` applies a checked pseudo-term
  substitution to a theorem's stored statement.  Use it for the return
  chains instead of exact-text substitution: a pattern that does not occur
  is an error naming the pair and its count.
- `wasm3/engine-flat.lisp` — the flat/context engine lemmas, with the
  engine's rule set LOCAL and the lemmas `:rule-classes nil`, so a later
  book's default theory is unchanged.  `wasm3/engine.lisp` holds only the
  admin-term lift, whose statement needs the WE functions.
- `wasm3/generic-position.lisp` — `engine-flat-body-6-step` states a flat
  position through `engine-ctxt-from-instr-step` plus the instruction's own
  step.  `chain.lisp`'s two flat laws are now instances of
  `engine-flat-body-step`; this is the template for replacing a search
  expansion: two `:use` facts instead of `step/r-ctxt-instrs` + `search21`
  at the literal body.
- `wasm3/chain-flat-own.lisp` — the body-6 `step` over the project's
  `milawa-state-pair-p` with a non-nil `inner`, from
  `we::step-of-flat-block` + `rebuild-when-state-shape-p`.  The engine rules
  are local; the `:use` must instantiate `we::z`.
- `wasm3/chain-label-generic.lisp` — `chain-state-pair`, `chain-label-step`
  and `chain-frame-step` via `engine-admin-term-in-block`, engine rules local.
- `wasm3/chain-body.lisp` — `step-body-6-first`, from `chain-frame-step` +
  `chain-label-step`; `links`/`frozen` include it.  `chain.lisp` is now only
  the flat laws and the generic label (its old label/frame proofs are gone).
- `wasm3/const-callee.lisp` now carries the engine rungs inline, with the
  engine's rules LOCAL: `clr1-ctxt-engine` (the read1 `ctxt-d` rung through
  `engine-ctxt-from-instr-step` + `tail-iframe3`, 2,098 steps), the seven
  `label0-rest` rungs (the same engine lemma with the position's
  `tail-cl-<p>-label0` as the isolated step), the six larger `label0` rungs
  (`engine-admin-term-in-block`, `k = :l`, with `tail-cl-<p>-step-d` as the
  inner), and all seven `frame` rungs (`k = :f`, with `tail-cl-<p>-label1` as
  the inner).  `label1` still uses `label-lift-general` and its trap/size
  premises.  The costs: label0-rest 120k-1.63M -> 2.2k-14.1k; label0
  10.8k-102.4k -> 4.7k-6.3k; frame 8.4k-80.9k -> 4.4k-7.6k.  The hint must
  disable `w3t::step` (it unfolds the store), `sof-gset-is-frozen-store` (it
  rewrites the state spelling), `milawa-callee-frame`, and
  `milawa-func-body`; `:use` the isolated step fact, and add
  `we::not-exit-body-p-of-vals-admin-term-rest` for the admin lift's
  `exit-body-p` hypothesis.
- `wasm3/engine-flat.lisp` exports three context rungs:
  `engine-ctxt-from-values-instr-step` (a value prefix before one
  instruction; `milawa-values-p` + the local `milawa-values-p-is-we` bridge),
  `engine-ctxt-two-values-instr-step` (two values then one instruction), and
  `engine-ctxt-pair-instr-step` (a value then a two-instruction redex, with a
  local `flat-search2` + two-instruction `%size` layer).  The first cut
  `dconst-call0-expand-ctxt` from **3,230,608 to 29,337**; the second cut
  `dconst-call0-entry-ctxt` from **39,463,918 to 266,356** (the const and
  `ref.func_addr` are both values; the `call_ref` is the instruction).  The
  pair lemma is not needed for the call0 entry but covers the case where the
  second element is not a value; its bridge required the take-form
  `%size-of-operands-and-two-instr`, the append-form linear corollaries, and
  `:do-not-induct` (the symbolic search otherwise loops).  `const.lisp`
  453.8M -> **414.6M**.  The `link-*` chain (30 facts, up to 24M) is
  prototyped on `link-24`: `engine-admin-term-in-block` (`k = :f`) with
  `lbl-dconst-push-s2-lit` as the inner and **`zo2` enabled** so the engine's
  `(list :%;% (sof zo2) (fof zo2))` inner state unfolds to the label fact's
  `(zo2 ...)` spelling; 24,361,332 -> **69,573** steps.  The state-function
  alignment is per link: the `iz6`-state links and the rest of the `zo*`
  group still fail (first at `link-23`), needing the output-state and
  `state-shape-p` alignments.
- `wasm3/const-fetch.lisp` has the same ten-position shape and now runs all
  ten `label0-rest` rungs through `engine-ctxt-from-instr-step`
  (1.0M-6.3M -> 1.2k-18k steps; book 32.2M -> 16.8M).  Four frames (blk, elb,
  if, ld2) are engine instances marked `:rule-classes nil` (as rewrite rules
  they rewrote each other's goals).  The six large frames (nested states) and
  the ten `label0` steps (value-headed bodies) remain on the old proofs.
- `wasm3/const-join.lisp` joins the front to the tail: the front's 34 steps
  (`front-advance-19` + `front2-advance-15`), `tail-frame1` (the lone call
  split), and `tail-entry-zl-frame` (the call entry) compose into a 36-step
  advance.  The front's endpoint and the tail's `gset` entry are the
  same state once `gset`/`iz6` are enabled and `(caddr (nth 12 *ft2*))` is
  rewritten to the literal 13-instruction body.  Naming each endpoint (and the
  tail step's result) as a defun, keeping every spelling function disabled in
  the composition, is the template for the remaining tail links: each one
  consumes the state the previous one leaves.
- `wasm3/const-steps.lisp` re-states the callee's first five positions at one
  generic run-level state, `const-tail-callee-state` (outer frame 6, label 1,
  label 0, frame 3 around a body), with the body progressing
  `(milawa-func-body 3)` -> `dbody0` -> `dbody1` -> `dbody2` -> `dbody3` ->
  `dbody4`.  The first four are `TAIL-CL-READ1/SUB/READ2/MUL-FRAME`
  instantiated there; the ltu is the exception: its frame fact's body is
  stated with the literal `(CONS (CONST ...) ...)`/`(LIST (CONST (RELOP ...)))`
  spelling, so it gets a literal-spelling state and body macros.  Unfolding
  `dbody3`/`dbody4` there made the `:use` instance miss and the prover
  re-derive the frame step (still running past 10 minutes); the literal
  spelling proves in 5.4M steps/21 s.  The five cost 402 s together, so they
  live in their own book rather than in the cheap `const-join`.
- `wasm3/const-front.lisp` adds those five steps to the run-level advance
  (`const-front-37..41`): each is one `steps-fuel-succ-of-a-step` at the state
  the previous advance leaves, so the composition is cheap (162 s) even though
  the step facts are not.  The CONST path is at 41 of 67 steps.
- `gen_chain.py` and `walk.py` read the body through ACL2's
  `milawa-func-body`; there is no Lisp parser in the harness any more.
  `chain.lisp`'s `*body-6*` is `(milawa-func-body 6)`.
- `make generated-check` — the generated books (`bytes.lisp`, `chain.lisp`,
  `machine/examples.lisp`) must still match their sources.  `module-check`
  covers `module.lisp`/`state.lisp`.
- `AUTOMATION-RESEARCH.md` — the measurements, the engine-reuse finding and
  the roadmap.  Read it before starting the next fact family.

## House rules

- No `skip-proofs`, no `defaxiom`; `make check` fails on either.
- `wasm3/bytes.lisp`, `module.lisp`, `state.lisp` and `chain.lisp` are
  **generated**, as is `machine/examples.lisp`.  Regenerate with `wasm/build.sh`
  + `make -C wasm3 bytes module`, `harness/gen_chain.py`, or
  `harness/examples.py --gen-lisp`; never hand-edit.
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
- **An instruction list is not a list of instruction lists.**  `dadmin` (like
  `milawa-callee-admin`) returns a one-element list of instructions, so the full
  body at label 6 is `(append (dadmin b) rest6)`, not `(cons (dadmin b) rest6)`.
  The malformed body still steps (its first element is a list; the search
  fails), so it surfaces as false measure inequalities, not as an error.
- **Hand-written literal instructions must spell the keyword exactly.**  The
  semantics' testop instruction is `(:TESTOP (:I32) (:EQZ))`; a scratch file
  wrote `:TESTTOP` and every `:use` fact silently failed to match (the printed
  goals looked identical at a glance).  Prefer `(list :testop (list :i32)
  (list :eqz))` or copy the keyword from a walk output.
- **A rule guard's size disjunct does not compose propositionally.**  Carrying
  a context rule's first `%size` disjunct as a hypothesis (and proving it
  standalone: the label-0 body size is 5.8k steps) works for the callee-level
  label facts, but at the halt level the same fact still stalls: the instance's
  guard normalizes the disjunct to `(< (+ 4753 V) (+ 4758 V))` while the
  context's linear pot is polluted by the store term's `sp` rational normal
  forms, and the clausifier never sees the two as the same literal.  The next
  attack should state the guard's whole size condition (both disjuncts, at the
  exact post-normalization spelling) as the fact's hypothesis, or split the
  label step itself into the `ctxt-instrs` result plus a separate step-bridge
  fact (the `dstep-phases-gen` route) so the label rule's guard is never asked
  to compute sizes at all.
- **A chain instantiates by exact-text substitution.**  The pop's return
  lifts were generated from the load's certified chain by replacing the
  literal term strings (the frame with its load body -> the return's frame with
  the popped value, the stepped frame -> the dissolved one).  The substitution
  must match the ACL2 printer's exact rendering: the record is
  `(quote (:%REC ...))`, never `'(:%REC ...)`, and an instruction inside a cons
  is `(quote (:load ...))` -- a missed quote makes the replace a silent no-op.
  Rename the inner-fact references first (`p2hload-ctxt` -> the stage's
  ctxt fact), then the fact-name prefixes.
- **A disjunctive hypothesis is weak in clausification, and its TERMS are
  rewritten.**  Carrying a context rule's size condition as an `or` hypothesis
  splits into the clauses `(or (not A) ...)` and `(or (not B) ...)`, so the
  proof gets `not A` in one branch, not `A` — carry the needed disjunct ALONE.
  And even the `(unsigned-byte-p 32 V)`/`(mvm-word-to-bytes W)` hypotheses are
  rewritten in place: `unsigned-byte-p` expands to the `expt` bound,
  `mvm-word-to-bytes` to the `floor`/`loghead`/`logtail` encoding, and those
  normal forms then pollute the linear pot.  Keep `unsigned-byte-p`,
  `mvm-word-to-bytes`, `acl2-count` and the store accessors disabled when a
  fact's hypotheses contain them and the goal also mentions them.
- **A context rule's guard is cheapest discharged by the dispatcher's phase
  facts, not by unfolding the dispatcher.**  For the halt-level label step the
  route that works is: prove `step_pure` and `step_read/split` nil for the
  label's code, `step/r-ctxt-instrs` nil for the label config (its search's
  slice IS the config, so the size disjuncts tie and reject), and the label
  predicate's value from the inner step; then instantiate the definition of
  `step` with those four equalities plus the inner step and the label rule's
  size.  8 facts, 2.94M steps.  The attempts that let the dispatcher unfold
  looped on the phase computations (`%tag-lo`/`floor`/`mod`/`acl2-count`).
  The residual: the label's context lift's search still meets the symbolic
  body in its size arithmetic; a generic variable-body label fact (so the two
  size terms share the body and cancel) is the next move.
- **The search's nil fact must be stated at the EVALUATED body.**  The pure
  return-label rule searches the label's body, and the search is not ground once
  the body carries a symbolic value (`(car ($binop_ ... sub sp 4))`).  A fact
  about the folded body never matches the goal's frame record; state it at the
  evaluated body (the quoted `(:%REC ...)` frame record and the literal
  instruction list) and hand in `(:definition step_pure/search141)` instances at
  `k` and `k+1` (the `k+1` instance is the guard-false NIL).  The `if0`/`block`
  chains need no such fact only because their bodies are fully literal.
- **`(fof ($with_global pair i v))` is the pair's fof, i.e. the literal callee
  record.**  State the frame's `fp` field as the quoted record rather than
  `(fof z)`: the symbolic spelling unfolds to `($frame ($with_global ...))`,
  which makes the label rule's `%size` comparison arithmetic over a symbolic
  call and it never closes.  With the record, the size lemmas (`%size-is-
  acl2-count`, `acl2-count-of-frame-gt-body`, `acl2-count-of-label-gt-body`)
  discharge the guards and the frame/label lifts prove in seconds.
- **The tail after a consumed instruction changes.**  After the testop the
  body appends to `(cddr (nthcdr 4 *body-6*))`; after the ifelse to
  `(cdddr ...)`; `rest6` itself starts *at* the testop.  Stating a result with
  the wrong tail makes the equality false, ACL2 reduces it to NIL, and the
  leftover goal looks like the negation of a hypothesis -- a wrong conclusion,
  not a prover anomaly.
- **An indexed image decomposition needs a lexicographic induction.**  For
  `(take 4 (nthcdr (* 4 i) (image ws)))`, induct on `(i, ws)` together and state
  the succ step at the index `(* 4 i)`; the absolute-index rewrite
  `4i = 4 + 4(i-1)` as a rewrite rule either fails to match or folds back (call
  depth).  `image-word-at` in `memory.lisp` is the worked example.
- **A body ending in a symbolic tail has the same acl2-count as its slice.**
  `acl2-count` of a symbol is 0, so a body written as a cons chain ending in a
  defconst symbol can tie the size test at the last position; the search then
  fails and the step falls through.  Cons one concrete instruction *after* the
  one being stepped, and let the defconst be the tail after that.
- **`acl2-count` charges an integer its absolute value** in this ACL2
  (`(acl2-count 5)` is 5).  Symbolic values in an instruction list therefore
  enter every `%SIZE` guard, and the guard becomes arithmetic in `pc`/`clen`.
  Keep each intermediate value opaque and give it a conditional
  `:type-prescription` (`integerp-dsub`, `integerp-dmul`, `integerp-dltu`,
  `integerp-testop-eqz`); then acl2-count sees `(integer-abs term)` on both
  sides and the comparisons cancel.
- **ACL2's `TAKE` pads**, and `acl2-count` of a symbol is its name length, so
  the tempting `(equal (acl2-count x) 0) = (not (consp x))` is false.
- **FLOOR and MOD have a rational normal form.**  Unfolding them turns the same
  identity into `numerator`/`denominator` spellings, and the arithmetic stops
  closing (`le-int-of-le-bytes` at symbolic `k` failed this way).  Keep them
  abstract and use `ihs/quotient-remainder-lemmas`' `mod-x-i*j-of-positives` and
  `floor-floor-integer`; `numerics.lisp` is the worked example.
- **A recursive function whose body calls FLOOR or MOD does not unfold by its
  definition rule in a theory where they are disabled** (measured on
  `%LE-BYTES`: the same goal proves with `(enable %le-bytes)` and stalls with
  the definition enabled but floor/mod disabled).  Give the concrete
  unfoldings explicitly with `:expand`; that does unfold.
- **A rule whose LHS contains `ICFG` never matches.**  The `icfg` call is
  unfolded before the rewrite rule is tried, so the goal term is
  `(LIST :%;% ...)` by then.  State standalone lift facts (`...-slice-gen`,
  `ctxt-...-fails`) in constructor form; the `:use`-based lifts work with
  `icfg` only because both sides of the `:use` formula are normalized together.
  Measured on the add's context lift: 8.9M steps and a waterfall failure in
  `icfg` form, 349k steps and Q.E.D. in constructor form.
- **A spelled-out pair blocks its facts.**  The frame rule builds its inner pair
  as `(%;% ($sof ...) ($fof ...))`; a fact stated at `(dcallee-pair ...)` cannot
  match once the pair's arguments unfold.  Prove a bridge rewriting the spelled
  pair to the helper and DISABLE `dcallee-pair` and the accessors, leaving
  `step` enabled: the bridge then fires before the pair unfolds, the label fact
  matches the whole step, and the step is 218 prover steps (418k and a stall on
  `step/r-ctxt-instrs` without the disable).  `pair-spelled-is-dcallee` is the
  worked example in `abort.lisp`.
- **A parameterized label wrapper must take a CONCRETE body.**  With the
  label's instruction list a variable, `step_pure`'s matchers and
  `search127` run on it and the proof diverges past 300 s.  State the label
  lift at the concrete body (or provide the pure failure as a fact at that
  body); the frame wrapper's variable form worked because the frame rule's
  guards are on the instruction lists, not the body's interior.
- **A frame rule's wrapper is provable once, parameterized.**  Hand it the inner
  step at the SAME variable pair the rule builds, plus the size guard, and
  instantiate it per position: `dstep-frame-abort-param` (40k steps) is the
  worked example; the first attempt with raw variables diverged because the
  pure-rule searches ran on symbolic instruction lists.
- **A call never reduces by plain evaluation.**  The step dispatcher reaches
  `step/r-ctxt-instrs` and stalls on the read rule's symbolic guard.  Use
  running.lisp's `no-ctxt-instrs-on-call-3` template: state the context rule's
  failure on the `(ref.func_addr + call_ref)` pair with an `:expand` of the
  context rule and a `:free` expansion of `search21`, then the entry is the
  step with that fact `:used` and `step` `:expanded`.  The call must be at the
  CALLEE pair -- the type lookup goes through the frame's module.
- **Inside a wasm label the inner step is a context step.**  With `step`
  enabled the label rule's body unfolds the inner step to
  `step/r-ctxt-instrs`, so the label lift must hand it the CONTEXT fact
  (`dctxt-call2`), not the step fact; with `step` disabled the outer step
  cannot unfold to the label rule at all.
- **A slice whose only rule is late in the dispatcher needs a context-failure
  fact.**  `step` tries `step/r-ctxt-instrs` before `step/r-local.set`; the
  search refuses a slice that consumes the whole instruction list (its splice
  guard needs a val or an instruction after the slice), and proving that
  refusal (`ctxt-local-set-slice-fails`) is what lets the slice reach the late
  rule.
- **State label/frame lifts over a generic store-and-frame pair `Z`.**  Written
  out as `(iz6 ...)`, the pair is normalized to a `LIST*` form by the label
  rule's own measure test and the inner step stops matching the lift's LHS.
  The generic local.set context lift is 37k prover steps; the spelled-out one
  is 1.17M.

## Current state (2026-11-20)

53 books, all certified.  The frozen path (`status ≠ 1`) is done end to end for
symbolic state in `wasm3/frozen.lisp`: nine steps, the exact clock, the
readback; `frozen-step-check` is `abs.lisp`'s `milawa-step-check` clause for
clause.  `wasm3/running.lisp` proves the seven-step shared head of the running
paths (the status test's else branch, the empty block/label, the call split, and
the call into `$in_code`'s frame), plus the first instruction of `$in_code`'s
body and the range facts the dispatcher needs (i32 binops are `rem`s;
`relop-ltu-value`).  `wasm3/dispatch.lisp` executes the rest of `$in_code`'s
body end to end at symbolic `pc`/`clen` — the sub, the read of global 2, the
mul, the comparison (the last instruction: a pure body step), and the two value
dissolves — and returns the result into function 6's continuation, and it
proves, under the in-code hypothesis (the comparison is 1), the opcode test,
the second ifelse, the empty-block/empty-label chains, and the opcode fetch's
first instruction (`global.get 1`).  78 measured events, 213.9M prover steps,
210 s.  `wasm3/numerics.lisp` proves the spec's four-byte encode/decode round
trip against the image (25k steps); `wasm3/load.lisp` then executes the opcode
`i32.load` (the read rule, with the in-bounds hypothesis) and `local.set 0`
(the first write, carrying the frame update through generic-pair lifts), 15
events and 8.49M steps.  The in-code hypothesis is what makes the testop's value
the concrete 0 and the lists concrete; at a symbolic value the search's measure
guards do not close.  The dispatch's five tests and the first two branch starts are now proved (see
README/SUMMARY): the shared fetch through the opcode test, the CONST test,
the ADD/SUB/LT OR-chain, the IFZ and JMP tests (`fetch.lisp`,
`dispatch-tests.lisp`), the HALT branch's first call (`halt.lisp`), and the
unknown-opcode abort through its closed frame lift and its callee's body
-- the status write and the frame descent into function 4 (`abort.lisp`,
40 events, 54.7M steps).  The abort's step back out -- the caller's label lift
over the callee frame, then the implicit label-vals/frame-vals returns -- is
the open piece; the bridge-vs-spelling tension there is recorded in the traps.
The callee frame descent is restated at the helper pair (499k) so the way out
does not need the forward bridge; the pair shape/components are stated as
facts (dcallee-pair-shape, 232k) because the opaque pair computes nothing; and
the caller's label lift over the callee frame is proved (28.6M).  The same label lift is proved at the SPELLED pair (36k) by handing in the STEP
DEFINITION INSTANCE as a :use (the :expand does not fire once the config's
arguments are rewritten) with the store's shape as a fact (with-global-shape).
The outer frame lift is CLOSED (the parameterized wrapper with the inner
result's pair shape, 52k; applied at the concrete store/frame, 8.9M), and the
implicit value-returns are proved (label-vals 125, frame-vals 912, the
callee-frame-around-a-value wrapper 19.6k).  This is CLOSED: dret-label-vals-in-frame / dret-frame-vals-in-label /
dret-label-vals-in-top / dret-frame-vals-in-top (10.4M/1.07M/19.6k/43) peel
the nesting with the state frame, the outer frame's locals and the inner
frame's locals independent; their instantiations at the abort store are
direct rewrites (2.7k/2.2k/1.7k/1.3k), and the path ends at the stuck host
config.  The halt branch's $depth call entry is now closed through the label-1 and frame-6 lifts (halt.lisp, 29 events, 12.9M steps), and the shape facts live there; abort stays at 38 events/42.4M.  The $depth call is now closed end to end: its (global.get 0) read, its div
step (whose value-range fact needed arithmetic/mod-gcd's division facts and
the :nonlinearp hint), and both implicit-return dissolves (label-vals and
frame-vals), each lifted through the halt-body context, label 0, label 1 and
frame 6.  halt.lisp is at 73 events, 54.6M steps.  Three lessons from the
return chains: (1) a hint helper that passes an empty :in-theory makes the
theory NIL and silently disables every rule -- the div's s141-nil fact
"failed" for exactly this; (2) the chain hypothesis should be the val-p
alone, not (and (un-p ...) (val-p ...)) -- the conjunction's clausification
loses the tautology with the instance's equality; (3) the label-vals result's
instruction list is the label's body, not a list containing it.

THE EQZ TESTOP IS CLOSED (by composing the dispatcher's phases: step_pure nil, step_read/split nil, and the context step as separate facts through the step/r-pure/r-read definition instances; dstep-phases-gen makes that a 2k-step generic bridge).  THE IFELSE IS CLOSED: proved at the literal-0 body and bridged to the actual body (TEQ = 0) in 10k steps; the empty block and label then dissolve, each through the full frame-6 stack.  A KEY GENERATION LESSON: 'emit' wraps step facts in (list ...); do not pass it an already-wrapped (list config) -- the double wrapping made the wrapper's conclusion miss the goal and cost hours.  Also: a frame's instruction list being bigger than its body (acl2-count-of-frame-gt-body) and %size-is-acl2-count discharge the frame rule's size premises generically; and a rewrite rule with a hypothesis over a free variable must be instantiated with that variable bound.  Its search has a value
prefix (prefix7 = 1), and every attempt ends with the ctxt-instrs definition
instance showing (search21 0 0 0 BODY 0 ...) even when a dteq-prefix7 fact
(prefix7 = 1) is available and prefix7 is disabled; the k = 1 branch's step
failure is fail-lone-testop and the k = 0 slice step is dteq-slice (both
proven).  match13-one-const is proven for the prefix check.  The next thing
to inspect is why the instance's %T9 becomes 0: possibly the definition
instance is being created through a different path than :use (the expected
one is (:instance (:definition w3t::step/r-ctxt-instrs) (%a0 HC))).  After
that: the ifelse (with the depth-nonzero condition), $pop, the writes, and
function 6's return.

Earlier notes, kept because the read chain is the template:
(halt.lisp, 2.2M steps for its 10-fact chain: dgread-slice/-ctxt/-step/
-label, dhread-frame at the OUTER pair, dhread-ctxt/-label/-labelctxt/
-label6/-outer).  The div step that follows is BLOCKED, and the reason is
precise: the halt block's label body ends in (:RETURN), so the pure
dispatcher tries Step_pure/return-label, whose step_pure/search141 walks
the body and needs val-p of the (:CONST (:I32) ($truncz (* 1/4 sp)))
inside the callee frame; that reduces to the truncate/numerator-denominator
arithmetic and stalls.  The fix is a value-range fact for the div value
(divval-is-a-value: un-p ($truncz (* 1/4 a)) 32 from un-p a 32); the
arithmetic alone proves standalone with :nonlinearp t and
acl2::rational-implies2 (divval-bound, 301 steps), but the full un-p
statement splits into a denominator-not-1 branch needing
nonnegative-integer-quotient bounds.  Prove that bound (or a
nonnegative-integer-quotient <= rational lemma) and then the div chain
(dhdiv-* mirrors dhread-* with the value in the normal form
($truncz (* 1/4 sp))).  Cost note: the
second body position's INNER two-shot done as one lemma measured ~281M prover
steps; split into flat ctxt-instrs (16.5M), bridge (74k), label (1.85M) and
frame (2.0M) -- ~20M, 14x cheaper.  Split the lifts this way.  For a
step under more than two admin levels, prove it in single shots of two levels
each -- composing one-level facts by `:use` does not close at depth (143M-step
failure; the two-shot succeeds in 3.5M + 30M).

**Classify a body position's shape before attacking it.**  An instruction that
is the LAST element of its body -- the relop at the end of `$in_code`,
`((const s) (const m) (relop))` -- is stepped by the PURE rule on the body, not
by `step/r-ctxt-instrs`: the search's k = 0 branch refuses an instruction list
with nothing after the instruction, so a flat ctxt-instrs lemma there is FALSE.
Its lift starts from the pure body step.  Positions with a suffix after the
instruction (the read, the sub, the mul) do go through the search and use the
flat+bridge+label+frame recipe.  Val-p of an intermediate value needs
`un-p-32-is-unsigned-byte-p` plus `subval-/mulval-/ltuval-is-a-value` with
`$BINOP_`/`$RELOP_` disabled.

Caution worth keeping: NTH/NTHCDR shift facts must be `:rule-classes nil`.  As
rewrite rules ACL2's arithmetic matcher binds `a = 0` and applies them to their
own right-hand sides (measured with `:brr`).  For the readback, state the index
against the append form instead: `(nth (+ i (len pre)) (append pre b)) =
(nth i b)`.  And a context-chain fact at a symbolic `status` must be
specialized (`(instance ... (status 1))`) before a bare `:use` will bind it.
