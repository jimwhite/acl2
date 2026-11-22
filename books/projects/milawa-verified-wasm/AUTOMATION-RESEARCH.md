# Automation research: milawa-verified-wasm

Research notes on the proof-engineering cost of this project, the recurring
failure modes, and the automation that would remove them.  This is a report,
not a plan approval: the concrete pilots are listed at the end with success
criteria.

Everything below was read or measured in this checkout.  "Measured here" means
I ran it; "recorded" means it comes from the project's own `SUMMARY.md`,
`README.md`, `.cert.out` files, or git history.

---

## 1. Executive summary

The project is not short of mathematical insight.  It is short of
**event-generation and generic lemmas**.  1,843 theorem events have been
written by hand (or by Python string templates), and about 64% of them are
structurally the same fact at a different position, tail, store spelling or
nesting level.  The recurring failures are almost all *term spelling* failures
that fail silently (a keyword typo, an unwrapped local, a one-element-list
splice, a missing `cdr`), plus *theory* failures (the wrong rule enabled, an
`:expand` that cannot unfold a mutual recursion, a rewrite rule that loops).

Three changes would pay for themselves quickly:

1. **Generate positions, not lemmas.**  A position table plus a `make-event`
   generator can emit the standard family (`spure`, `sread`, `ctxt`, `match`,
   `search`, `label`, `frame`) from a row describing one instruction position.
   This is `gen_compose.py` moved into ACL2, and it can be checked instead of
   copied.  The engine in `wasm-acl2`'s `engine-plan2` branch already does
   exactly this for 200+ WASM rules, with a census that fails the book when a
   lemma is missing.

2. **Reuse the engine's generic step theory.**  The engine proved
   `step/r-ctxt-instrs-becomes-flat-search` and `step-of-flat-block` about the
   *same* `w3t::step` functions this project uses.  That is the generic context
   law this project recorded as a 400-second dead end (`SUMMARY.md:370`).  The
   engine's version is 469 prover steps and **no later proof opens the search**.
   Reusing it turns a per-position 20-fact family into an instance of one
   generic theorem.  This is the largest architectural lever in the report.

3. **Make the failure modes impossible, not just documented.**  A
   `make-event` well-formedness checker that rejects non-literal instruction
   lists, unknown instruction keywords, free variables in an LHS, an `icfg`
   head, an unwrapped local, and a pair with the wrong nesting would have
   caught `:TESTTOP`, the `(cons (dadmin b) rest6)` body, the extra `cdr`, the
   extra `(global.get 1)`, and the `:%` comment truncation before any proof
   ran.

The ACL2 MCP is useful, but as a **REPL and probe tool**, not as a proof
engine.  Measured here: loading the package, including `wasm3/chain`, and
walking the semantics ten steps took one MCP call with no temporary files; it
replaces `walk.py` + `acl2.sh` for short probes.  Long proofs still belong in
`make experiment` because the MCP caps a command at 300 seconds.

---

## 2. The cost picture

### 2.1 Code size and repetition

`wasm3/` has 21,000 lines of Lisp and 1,843 `defthm` events:

| Book | defthms | Note |
|---|---:|---|
| `const.lisp` | 523 | the CONST tail; 879.0 s to certify at 478 facts |
| `halt.lisp` | 349 | 244.5 s, 217.2M prover steps |
| `const-callee.lisp` | 141 | **140 are `tail-cl-*`: 7 positions × 20 facts** |
| `const-fetch.lisp` | 114 | **112 are `tail-*`: ~10–11 facts per step** |
| `dispatch-tests.lisp` | 114 | 561.4 s, 559.6M prover steps |
| `fetch.lisp` | 111 | 17 instruction cases × 4 nesting levels = 68 facts |
| `dispatch.lisp` | 78 | 210.0 s, 213.9M steps |
| `frozen.lisp` | 59 | |
| `running.lisp` | 52 | |
| `const-tail.lisp` | 52 | |
| `oob.lisp` | 46 | |
| `abort.lisp` | 38 | |
| `const-branch.lisp` | 30 | |
| all others (17 books) | 119 | |

The repeated families are visible in the names alone: `tail-*` (322),
`dstep-*` (74), `dctxt-*` (65), `dlabel6-*` (65), `douter-*` (63),
`sread-*`/`spure-*` (46 each), `dconst-*` (63), `dret-*` (45), `link-*` (30),
`lbl-*` (30), `p2ret-*` (20), `p2hload-*` (18), `dgw3-*` (20),
`const-front-*` (20), `taglo-*`/`rsearch-*` (17 each).  A conservative sum is
~1,179 events (64%) that are one shape instantiated at different literals.

The hints repeat too: 1,083 explicit `(:instance (:definition ...))` hints,
and 1,280 `disable` forms in the wasm3 books.  The top disable lists are
copy-pasted verbatim dozens of times, e.g. 65 copies of

```lisp
:in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz
                    w3t::$binop_ w3t::$nbytes_ w3t::$with_mem
                    w3t::$with_global w3t::$with_local frozen-store iz6
                    milawa-func-body dconst zlset1)
```

### 2.2 Process cost

Git history for this project (branch `jitawasm-z`) has **192 commits in 3.6
days** (2026-11-18 through 2026-11-21), about 53/day.  126 touch a `.lisp`
book and average **14.6 defthms per book commit**.  130 (68%) also touch
`SUMMARY.md`, 77 touch `README.md`, and 30 touch a Makefile.  The workflow is
fact-group by fact-group: `const.lisp` grew through 14 → 23 → 36 → 40 → 60 →
131 → 156 → 226 → 287 → 307 → 385 → 427 → 478 facts, each step a commit and a
re-certification.

The certification cost is real: `dispatch-tests` 561 s and 559.6M prover
steps, `const` 879 s, `halt` 244 s, `dispatch` 210 s, `fetch` 175 s.  This is
proof cost, not authoring cost; automation will not make these numbers small.
It will make each *new* position cheaper to write and much harder to get
silently wrong.

### 2.3 Where the time actually went

The project's own `AGENTS.md` ("Traps found the hard way", 31 bullets) and
`README.md` ("What we learned", 25 lessons) classify the failures:

| Class | Evidence | Examples |
|---|---|---|
| **Term spelling / shape** | 26 "spelling", 16 "wrong", 16 "trap" in `SUMMARY.md` | literal vs. accessor body; `cons` vs. `append`; `:%` vs. `:|%;%|`; unwrapped locals; a framed field as a dotted pair; one-element vs. list-of-instructions |
| **ACL2 hint/theory control** | 15 "stall", 6 "loop", 3 "blocker" | `:expand` cannot unfold a mutual recursion; a free variable in an LHS does not compose; a rewrite rule applies to its own RHS; guards rebuilt by the clausifier |
| **Generator/edit mistakes** | 12 documented incidents | lost `BOOKS` line; one-element splice; wrong `nthcdr` slice; extra `cdr`; extra `(global.get 1)`; silent exact-text substitution; `:TESTTOP` |
| **Build/tooling** | 6 incidents + 30 Makefile commits | wrong `cd` silently loads nothing; a truncated log reads `Q.E.D.=61`; an editor's parenthesis count is wrong for a generated file |
| **Cost explosions** | ~19 measured | 400 s kills; 56 GB; 401k → 143M wasted prover steps |

The important structural fact: **almost every spelling mistake is silent**.
ACL2 reduces a false equality to `NIL` and leaves the negation of a
hypothesis as the goal.  The docs repeatedly say the result "looks like a
prover anomaly" or "looks like progress".  This is exactly the class a
generator with a checker removes.

---

## 3. What is already automated, and where the gaps are

The Python harness is 1,384 lines across seven scripts:

| Script | What it does | Verdict |
|---|---|---|
| `gen_chain.py` (373) | parses `state.lisp` for function 6's body, emits the static `chain.lisp` lemmas | **Replace the parser and the static book.**  `chain.lisp` already includes `head` → `returns` → `calls` → `context`, so `(milawa-func-body 6)` and `(milawa-func-code 6)` are available.  I measured `(milawa-func-body 6)` returns 43 instructions; a `defconst` of it gives the same literal value at definition time. |
| `gen_compose.py` (337) | holds the position table and tail slices; prints defthms that are pasted into `const.lisp` | **Replace with `make-event`.**  This is the clearest case in the tree: a position table, `nthcdr` slices, and a fixed hint skeleton are all ACL2-side computation.  Today nothing checks the script against the book. |
| `walk.py` (114) | builds a 10-`defconst` script and runs ACL2 | **Replace with an ACL2 program-mode loop.**  Measured here: one MCP `evaluate` did the whole walk with no temp file. |
| `examples.py` (201) | `--record`/`--check` runs the `.wasm` under Node; `--gen-lisp` writes `machine/examples.lisp` | Keep `--record`/`--check` (Node is the untrusted host); move `--gen-lisp` to `make-event` over a Lisp corpus, or at least add a freshness check. |
| `gen_module.py` (117) | runs ACL2's decoder and regex-parses its printed output | **Move the event into ACL2** (`make-event` + program-mode byte reader), keeping a thin external wrapper only for cert dependency tracking.  It also hardcodes `/workspaces/acl2/saved_acl2` instead of honoring `$ACL2`. |
| `gen_bytes.py` (36) | writes `bytes.lisp` from the `.wasm` | Same as `gen_module`: `make-event` can read bytes, but `cert.pl` cannot see the `.wasm` as a dependency; keep a check. |
| `lint_lisp.py` (206) | ACL2-aware paren balance + formatting | Keep the formatting half; the balance half is largely enforced by certification.  Consolidate the three partial readers (ACL2's, `lint_lisp.scan`, `gen_chain.form_at`). |

**Drift gaps found today:**

| Generated file | Generator | Drift check | In `make check`? |
|---|---|---|---|
| `wasm3/module.lisp`, `state.lisp` | `gen_module.py` | `--check` (byte compare) | yes |
| `wasm3/bytes.lisp` | `gen_bytes.py` | none | no |
| `wasm3/chain.lisp` | `gen_chain.py` | `--check` | **no** |
| `machine/examples.lisp` | `examples.py --gen-lisp` | none | no |
| `const.lisp` lift block | `gen_compose.py` | **none (prints only)** | no |

`gen_compose.py` is the most dangerous: its output is already in `const.lisp`,
but nothing compares them, and its constants duplicate data in the book
(`STORE`, `TAIL13`, `TAIL13_XS`, `MOD0_LIT`, `SADMIN_APPEND`).  A rename in the
book is not caught.

---

## 4. The automation opportunities, ranked

### 4.1 A `def-lift` event generator (highest authoring payoff)

A single `make-event` function that takes a position descriptor:

```lisp
(def-lift callee-read1
  :func 3 :at 1
  :z    z                       ; the store/frame pair, symbolic
  :hyps ((unsigned-byte-p 32 pc) ...)
  :enable (layer-2) :disable (layer-2-off)
  :tail rest6)
```

At event-construction time it computes the literal body and tail from
`(milawa-func-body func)` with `nthcdr`, builds the exact literals, and emits
the family:

```
spure-<name>-body, sread-<name>-body, ctxt-<name>-body,
match-<name>-body, search-<name>-body,
spure-<name>-label, sread-<name>-label, size-<name>,
label0-<name>, label0-rest-<name>, label1-<name>, frame-<name>
```

with the standard hint skeleton and a final census.  This reproduces
`const-callee.lisp`'s 140 facts from a 7-row table.  The engine's
`engine/rules/shape.lisp:236–350` and `engine/fast/frame.lisp:65–150` are the
model:

- a program-mode function builds the event;
- each `defthm` is wrapped in `(:or ... (value-triple (cw "FAILED ...")))`;
- the book ends with a function that collects the rules with **no** theorem
  and fails certification if the set differs from the recorded set;
- each proof has a step limit and prints one line per lemma.

Success criterion: re-emit one existing family (`const-callee`'s seven
positions) from a table, all 140 certify, and the generated text differs from
the checked-in book only in whitespace/name order.  If exact re-emission is
too hard, accept "all certify" and keep the table as the source of truth.

### 4.2 Reuse the engine's generic step theory (highest architectural payoff)

The `wasm-acl2` `engine-plan2` branch (commit `1ce59e0`) contains a verified
engine for the *same* generated semantics.  Its `engine/rules/` books are
about `w3t::step`, `w3t::step_pure`, `w3t::step_read/split`,
`w3t::step/r-ctxt-instrs` and `w3t::step/search21`.  Measured here: I checked
the branch out into a worktree, symlinked the existing generated 3.0 books,
and certified `engine/rules/context` in **5.2 s** (its dependency `flat` 7.7 s,
`shape` 6.0 s, `dispatch` 9.6 s, `arity` 5.8 s; `terminal` 107.7 s the first
time because it pulled the generated books).  Then I included it in a live
ACL2 session and confirmed `step-of-flat-block` is present with the expected
statement.

The key theorems:

```lisp
;; engine/rules/flat.lisp
(defthm step/r-ctxt-instrs-becomes-flat-search
  (implies (and (vals-p x) (not (w3t::val-p i)) (true-listp r))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (append x (cons i r))))
                  (flat-search (len x) x i r z))))
;; 469 prover steps; the %SIZE test is discharged once inside.

;; engine/rules/flat.lisp
(defthm step-of-flat-block ...)            ; 31,917 steps, operands + instr + rest

;; engine/rules/context.lisp
(defthm step-of-admin-term ...)            ; one label/handler/frame term
(defthm step-of-admin-term-in-block ...)   ; the same with values before and rest after
```

Why this matters: `SUMMARY.md:370` records that a *general* context law timed
out at 400 s, and `SUMMARY.md:400` shows the descent is three nested `step`
calls.  The project therefore proves a bespoke lift per position and per
nesting level.  The engine's `flat-search` bridge makes the search a small,
openable function, and its `step-of-flat-block` / `step-of-admin-term-in-block`
are the generic descent the project keeps rebuilding.  The engine's V2 note
says it outright: after the bridge, "**no later proof opens the search**."

This is not a small refactor.  The engine's terms use `operands` (`revappend
(take j vals) nil`) where the project's configurations use `append`/`take`, and
its lemmas are stated in package `WE` with a few helper functions.  A pilot
needs reconciliation lemmas between the two spellings.  But the payoff is
large: replace hundreds of `spure`/`sread`/`match`/`search`/`ctxt` facts and
most of the seven-rung recipe with instances of a handful of generic theorems.

Success criterion for the pilot: take one existing position (suggest
`frozen.lisp`'s global.get read or `const-callee`'s `read1`), prove it from
`step-of-flat-block` + `step-of-admin-term-in-block` + shape facts, and record
the prover-step count and wall time against the current chain.

### 4.3 A `defsubst-chain` generator (removes the fragile substitution work)

The return chains (`dret-*`, `p2ret-*`, `p2hload-*`) were produced by exact-text
substitution in `/tmp/gen/*.py`, and `AGENTS.md:100–107` records the failure
mode: the substitution must match ACL2's printer exactly, and "a missed quote
makes the replace a silent no-op."

Replace it with an ACL2-side function over pseudo-terms:

```lisp
(defsubst-chain dret-label-vals-at-abort
  :from dret-label-vals
  :subst ((<old store term> <new store term>)
          (<old frame term> <new frame term>))
  :use (...))
```

The generator should check that each `old` occurs exactly the expected number
of times (default 1) and fail loudly otherwise.  This makes the silent no-op
impossible.  It also puts the substitution table in the book, where it can be
reviewed and replayed.

### 4.4 A `defclock` composition generator

The project writes `link-01` … `link-30`, `const-front-01` … `19`, and the
per-path clock facts by hand, with `:rule-classes nil` successor lemmas and
explicit `steps/%fuel` definition instances (`AGENTS.md:72-74`).  Given an
initial configuration and an ordered list of step-lemma names, a `make-event`
can emit the successor facts and the final `(equal (steps/%fuel n c0) cn)`
(or `stepn`) theorem.  The engine's `fast-run-is-spec-steps` and its
`clock`/`stepn` machinery are the model.

### 4.5 A well-formedness checker (`check-literal`)

A `make-event` that walks every generated form and rejects:

- an instruction literal whose head keyword is not in the semantics' known set
  (built from the rule table, not a hand-written list — `:TESTTOP`);
- an instruction list written as a term (`(milawa-func-body i)`,
  `(nthcdr ...)`) instead of a literal;
- a frame record whose field is a one-element list instead of the dotted pair
  (`AGENTS.md:75-77`);
- a local written unwrapped (`SUMMARY.md:831-837`);
- a pair written as `(list :%;% ...)` with the wrong nesting;
- an `icfg` call in a rule LHS (`AGENTS.md:181-187`);
- a free variable in an LHS (the "does not compose" trap);
- an instruction wrapped in an extra list, or a body that is one element short
  (`cons` vs `append`).

This is cheap and catches the most expensive silent class.  It does not prove
anything; it refuses to emit a suspect event.

### 4.6 Theory profiles instead of 1,280 hand-written disable lists

Define `deftheory`/rulesets per layer and per lift stage, and have `def-lift`
name a profile:

```lisp
(deftheory layer-2   (...))
(deftheory lift-ctxt (...))
(deftheory lift-label (...))
(deftheory lift-frame (...))
```

The engine's `practices.md` says: disable every definition after its lemmas,
enable only what a proof opens, one theory block per book, step limits not time
limits, no `"Subgoal"` hints.  Adopting this eliminates the copy-pasted
disable lists and the drift between them.

### 4.7 Close the drift checks

Add to `make check`:

- `gen_chain.py --check` (already implemented, never run by `make check`);
- a `gen_compose.py --check` (does not exist; add it or retire the script);
- `gen_bytes.py --check` (does not exist);
- a freshness check for `machine/examples.lisp`;
- a `census` target that reads each `.cert.out` and compares the number of
  proved events with the number claimed in the docs.

The last one directly addresses the three separate commits that corrected
halt's event count, and the lost-`BOOKS` bug that certified 23 of 26 books.

### 4.8 Generate the status docs

68% of commits touch `SUMMARY.md`; the measured event counts and prover steps
are retyped by hand and corrected repeatedly.  Put the per-book numbers in one
machine-readable table (a Lisp constant or JSON produced from `.cert.out`) and
generate the README/SUMMARY fragments from it, or at least add a
`make doc-check` that fails when they disagree.

### 4.9 MCP workflow

Use the MCP as the interactive REPL, with these rules (all exercised here):

```lisp
;; once per task
(start_session :name "...")
(evaluate "(ld \".../package.lsp\") (in-package \"MILAWA-WASM\")")
(include_book ".../wasm3/chain")

;; probe, don't guess
(evaluate "(value-triple (car (milawa-func-body 6)))")
(evaluate "(defun walk-steps ... )")   ; a program-mode loop over step

;; before writing a book
(check_syntax :parinfer false ...)     ; catches an unbalanced edit
(admit "(defthm ... )")                ; tests one event, then rolls it back
(query_event "w3t::step/r-ctxt-instrs")
```

Caveats measured here:

- one-off calls start a fresh kernel; use a persistent session for repeated
  work;
- a command is capped at 300 s, so long proofs still go through
  `make experiment`;
- `include_book` fails if a community dependency is uncertified (I had to
  certify `defopeners`, `install-not-normalized`, `defopener`; the generated
  semantics are certified in-tree);
- the package must be loaded explicitly before including a project book;
- parinfer repairs mismatched parens by default — pass `parinfer=false` when
  validating an edit;
- the session world is mutable: `install-not-normalized` disabled the original
  definitions in mine.  Use `save_checkpoint` before an experiment.

`defopeners` (Kestrel) is **not** a fit for `step_pure`: it reports "not needed
for non-recursive function", and the generated dispatcher is a non-recursive
lambda chain.  It may still help a recursive `run`/`steps/%fuel` function, but
not the dispatchers.

`install-not-normalized` (in `books/misc`) **does** work on the mutual
recursion: it emitted `$NOT-NORMALIZED` definition rules for the whole clique
(`step`, `step/r-ctxt-instrs`, `-label`, `-handler`, `-frame`,
`step/search21`) in 0.00 s, with `:install-body t`, `:clique` and
`:controller-alist`.  Caveat: it disables the originals, and ACL2 warns that
the new `:definition` rule "probably subsumes" the project's existing rewrite
rules (including `ctxt-instrs-steps-the-head`, `flat-body-6-general`, and the
`no-ctxt-instrs-*` facts).  Use it in a targeted/local theory or a separate
book, not globally, until the interaction is measured.

---

## 5. Community books: what to borrow, what to avoid

| Source | Technique | Where | Fit for this project |
|---|---|---|---|
| Kestrel JVM | `def-do-inst-theorem`: one generated theorem per opcode, `(do-inst 'op ...) = (execute-op ...)` | `books/kestrel/jvm/do-inst-rules.lisp:23` | Direct template for per-rule dispatch facts. |
| Kestrel JVM | symbolic term builders (`build-make-state-for-method`, `build-run-term-for-method`), `syntaxp`-guarded stepping | `books/kestrel/jvm/symbolic-execution.lisp`, `symbolic-execution2.lisp` | The `syntaxp` "step only the literal list" idea. |
| Kestrel Axe | rules are extracted from ordinary theorems (`make-axe-rule(s)`); `def-simplified`; `defthm-axe` | `books/kestrel/axe/make-axe-rules.lisp:1332`, `def-simplified.lisp:104`, `defthm-axe.lisp:24` | Good as a **discovery oracle** for the RHS of a step; not as a certified proof path (`unroll-spec` uses `skip-proofs`). |
| Kestrel Remora | `defruled` + `controlled-configuration`; derived rules from a soundness theorem; `definductive` | `books/kestrel/remora/*` | The derived-rule idea is good: prove the generic wrapper once, derive per-position facts.  `definductive` was already tried and rejected for `MILAWA-RUNS`. |
| Kestrel WASM | `defopeners` on `run`, `nth-local`, `top-n-operands` | `books/kestrel/wasm/proof-support.lisp:16` | Precedent for `defopeners`, but the model's `run` is a simple recursive function; not our dispatcher. |
| Codewalker | `def-model-api`, `def-semantics`, `def-projection`: explore a code region and derive a semantic function | `books/projects/codewalker/codewalker.lisp:4624,7102` | A long-term alternative: define a pc and a terminating region, then lift automatically.  The nested label/frame `step` and the literal-body requirement make this a research project, not a quick win. |
| x86isa / RISC-V Axe | `def-unrolled` lifters; rule sets by layer | `books/kestrel/axe/x86/unroller.lisp:1174`, `books/kestrel/axe/risc-v/unroller.lisp:926` | The **rule-set organization** is useful; the theorem generation is `skip-proofs` unless re-proved. |
| Ethereum EVM | `def-simple-op` generates `execute-<op>` and type theorems from a table | `books/kestrel/ethereum/evm/evm.lisp:1051` | Another one-table/one-macro pattern. |
| std/util | `defrule`/`defruled` with `:enable`/`:disable`, rulesets | `books/std/util/defrule.lisp:356` | Use for theory profiles (4.6). |
| `misc/install-not-normalized` | `fn-is-body`, `install-not-normalized`; clique-aware `:definition` rule | `books/misc/install-not-normalized.lisp:182` | **Tested here; works.**  The direct replacement for explicit `(:instance (:definition ...))` hints, with the subsumption caveat. |
| `misc/defopener` | runs the prover, emits a `defthm` per branch | `books/misc/defopener.lisp:511` | Could compute a step lemma's RHS; watch for `HIDE` and case splits. |
| `misc/expander` | `defthm?`/`symsim`: simplify a term and emit the theorem | `books/misc/expander.lisp:1103,1356` | Good for "what is the RHS of this concrete step?" — the `defthm?` mode. |

Note: most of these books are **not certified** in this container (689
`.cert` files overall; only 44 under `kestrel/`).  Using one means certifying
its dependency cone first.  `defopeners` + `install-not-normalized` +
`defopener` took about a minute together; the engine's `context` book took
about two minutes including its generated-semantics dependency.

---

## 6. The `engine-plan2` branch: the model to copy

The branch has a verified engine for the same semantics, and its `step2.md`
is a concise statement of the proof discipline that this project has been
rediscovering one trap at a time:

- **The generated books are the specification; never copy or edit them.**
- **Never open `W3T::STEP` with the rule definitions enabled.**  Reason about
  a rule through its generated lemmas.
- **A lemma that needs the result of another step binds it**
  (`(equal inner (w3t::step ...))`) and states its conclusion in terms of
  `inner`'s components.  A hypothesis that equates a step to a term with free
  variables is not used by the rewriter.
- **Definitions are disabled after their lemmas; a proof enables what it
  opens.**  One theory block per book.
- **Step limits, never time limits.**
- **No `"Subgoal"` hints; a case that needs one becomes a lemma.**
- **Generated families end with an exact census**, and a generator that
  prints one line per lemma and fails if the missing set differs from the
  record.
- **Constants first, both orientations**, for head-keyword rewrite rules.

The engine's V1/V2/V3 notes are the worked example of the architectural idea:
`first-nonval` and `redex-shape-p` replace ad-hoc shape reasoning;
`flat-search` makes the search openable; `step-of-flat-block`,
`step-of-admin-term`, `step-under-ctrl` compose the descent for every
instruction and every control stack.  The milestones certify in seconds to
minutes, not hours.

The branch also contains `plan/wasm-engine/plan2.md` (1,114 lines) and
`notes/` with per-milestone measurements; it is worth reading V1–V3 and the
"proof practice" table before designing the next book.

---

## 7. What automation will **not** fix

- **Prover cost.**  The 200M–560M-step books will still be expensive.  A
  generator makes the *next* position cheaper to write; it does not make the
  rewriter faster.
- **The literal-body requirement.**  The search computes only on literal
  lists, so a generator must emit the exact literals; it cannot replace them
  with accessor terms.  The engine's generic lemmas are the exception, because
  they are proved once about a symbolic list.
- **The right statement.**  `SUMMARY.md:452-459` and the memory-correspondence
  lesson ("when an induction will not close, change the statement") are
  mathematical judgment, not automation.
- **Silent failures in generated text.**  A generator can be wrong.  That is
  why the `:or` + census + well-formedness checker pattern matters more than
  the generation itself.

---

## 8. Housekeeping done in this session

- **Submodule.**  `wasm-acl2` was moved from `/workspaces/acl2/.wasm-acl2` to
  `books/projects/milawa-verified-wasm/wasm-acl2` and registered as a git
  submodule pinned at `7f96c898e6c7693c50f2b90dec820e9266224a5c`
  (`https://github.com/raymyers/wasm-acl2.git`).  It is inside the project so
  the project's `cert_pl_exclude` keeps it out of a community certification
  run.  `.gitmodules`, the gitlink, and `.git/modules/...` are in place;
  `git submodule status` reports the pin.  The old `.wasm-acl2/` line was
  removed from `.git/info/exclude`.
- **Path references.**  `Makefile`, `AGENTS.md`, `README.md`, `SUMMARY.md`,
  `harness/decode.lsp`, and the six books with absolute includes
  (`abs`, `decode`, `l1`, `numerics`, `size`, `symbolic`) now use the
  submodule path.  The generated semantics' certificates embedded the old
  absolute path, so all 26 books under
  `wasm-acl2/translate/gen/wasm-3.0` were rebuilt in place (exit 0), together
  with `translate/portcullis` and `translate/rt/*`.  The six changed project
  books were then certified in place (exit 0: `abs`, `decode`, `l1`,
  `numerics`, `size`, `symbolic`).  Books downstream of those six are now
  stale; `make -C wasm3` (or `make check`) will rebuild them.
- **Junk removed.**  The leftover `*/Makefile-tmp` files from earlier
  interrupted `cert.pl` runs were deleted (they are not tracked).
- **No commit was made.**  The changes are staged or in the working tree for
  your review.

---

## 9. Recommended pilots, in order

1. **MCP + drift checks (hours, no proof risk).**  Adopt the persistent-session
   recipe; add `gen_chain --check`, a `gen_compose --check`, a `bytes` check,
   and an `examples.lisp` freshness check to `make check`.
2. **`check-literal` + theory profiles (days).**  Build the well-formedness
   checker and the layer theories first; they make every later generator
   safer and reduce the 1,280 hand-written disable lists.
3. **`def-lift` on one family (days to a week).**  Start with
   `const-callee`'s seven positions; success is 140 facts from a table, all
   certified, with a census.  Compare the generated text with the book.
4. **Engine-reuse pilot (a week).**  Vendor or pin `engine/rules/`
   (`step-basics`, `terminal`, `shape`, `dispatch`, `arity`, `flat`,
   `context`) and prove one existing position with
   `step-of-flat-block` + `step-of-admin-term-in-block`.  Success is a
   comparable proof with fewer bespoke facts and a measured step count.
5. **`defsubst-chain` + `defclock` (a week).**  Replace the `/tmp/gen`
   substitutions and the hand-written link/clock families.
6. **Doc generation (opportunistic).**  When the per-book numbers are stable,
   generate the status tables from `.cert.out`.

The first two are safe and immediately reduce the error rate.  The fourth is
the one that changes the shape of the remaining work.

---

## Appendix: measurements made here

All commands were run as `vscode` with
`ACL2=/workspaces/acl2/saved_acl2` and
`ACL2_SYSTEM_BOOKS=/workspaces/acl2/books`.

**ACL2 MCP, persistent session.**

```lisp
(ld "/workspaces/acl2/books/projects/milawa-verified-wasm/package.lsp")
(include-book "/workspaces/acl2/books/projects/milawa-verified-wasm/wasm3/chain")
;; 3.45 s

(defun walk-steps (n c)
  (declare (xargs :mode :program))
  (prog2$ (cw "STEP ~x0: ok=~x1 len-instrs=~x2 head=~x3~%"
              n (consp c) (len (caddr c))
              (let ((x (car (caddr c)))) (if (consp x) (car x) x)))
          (if (zp n) c (walk-steps (1- n) (car (w3t::step c))))))
;; (walk-steps 9 *c0*) printed STEP 0..9 in one call; no temp file, no acl2.sh
```

`check_syntax` with `:parinfer false` on a form missing a closing paren:
"the form is incomplete (unbalanced parentheses or unexpected end of file)."
`admit` on `(defthm ... (equal (+ a b) (+ b a)))`: Q.E.D., 7 prover steps,
rolled back.

**`install-not-normalized` on the clique.**

```lisp
(acl2::install-not-normalized w3t::step/r-ctxt-instrs)
;; 14 encapsulated events; emitted $NOT-NORMALIZED definitions for
;; step/search21, step/r-ctxt-instrs, -label, -handler, -frame and step;
;; each 0.00 s; disabled the originals; ACL2 warned the new :definition rule
;; "probably subsumes" the project's existing rewrite rules.
```

**`defopeners` on the dispatcher.**

```lisp
(acl2::defopeners-names w3t::step_pure)   ; => (W3T::STEP_PURE-BASE)
(acl2::defopeners w3t::step_pure :verbose t)
;; "Warning: Defopeners not needed for non-recursive function W3T::STEP_PURE."
;; The generated body is a long non-recursive LAMBDA chain.
```

**Engine reuse.**

```sh
git -C /workspaces/acl2/.wasm-acl2 worktree add /tmp/engine-plan2 1ce59e0
ln -s /workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0 \
      /tmp/engine-plan2/translate/gen/wasm-3.0
cd /tmp/engine-plan2/engine
cert.pl --acl2 /workspaces/acl2/saved_acl2 -j 4 rules/context
# portcullis 0.2 s; machine 4.3 s; first-lemmas 4.5 s; lists 4.3 s;
# terminal 107.7 s; step-basics 4.0 s; shape 6.0 s; dispatch 9.6 s;
# arity 5.8 s; flat 7.7 s; context 5.2 s
```

Then `(include-book "/tmp/engine-plan2/engine/rules/context")` in a fresh MCP
session succeeded (3.70 s), and
`(getpropc 'we::step-of-flat-block 'acl2::theorem nil (w state))` returned the
expected theorem with the `w3t::step` conclusion and the
`vals`/`op-instr-p`/`redex-arity` hypotheses.

---

## Appendix B: first implementation steps

Implemented after the report, in the same checkout:

- **`wasm3/literals.lisp`.**  `func-body-lit`, `func-tail-lit`,
  `func-instr-lit`, `func-prefix-lit` compute the module's literal at
  macro-expansion time; `def-func-body`/`def-func-tail`/`def-func-instr`
  give the named-constant form.  A program-mode `check-instruction-list`
  rejects a non-cons element or a non-nil tail at expansion time.  Measured
  in a live session: `(w3t::step_pure (func-tail-lit 6 3)) = nil` proves by
  evaluation in **4 prover steps**, and the same fact with the `defconst`
  spelling `*literals-tail-6-3*` also proves in **4 steps**.  So the Python
  body parser in `gen_chain.py` is unnecessary: a `defconst` of
  `(milawa-func-body 6)` carries the literal the search needs.
- **`make generated-check`.**  It runs `gen_bytes.py --check` (540 bytes,
  matches), `gen_chain.py --check` (up to date) and
  `examples.py --gen-lisp --check` (10 examples, matches).  It is now part of
  `make check`; previously only `module.lisp`/`state.lisp` had a drift check.
- **`wasm3/subst.lisp`.**  `defsubst-chain` reads a theorem's stored statement,
  applies a pseudo-term substitution, checks that every pattern occurs (the
  default is at least once; `:count n` demands exactly n), and emits the new
  theorem.  A missed quote is now an error naming the pair and its count,
  which is the check the `/tmp/gen` text substitution could not make.  A
  worked `subst-demo-new` check is in the book; it certifies.
- **`gen_module.py` honors `$ACL2`.**  It previously hardcoded
  `/workspaces/acl2/saved_acl2`, so `make module-check ACL2=...` silently
  used the wrong binary.
- **Gate fix for the submodule.**  `complete` and `no-skips` used to glob
  `*/*.lisp`, which picked up Ray's root books once `wasm-acl2/` moved inside
  the project.  They now use `PROJECT_BOOKS` (the three book directories), so
  the submodule is not certified by this tree.
- **Verification.**  The full `wasm3` rebuild completed (exit 0);
  `literals.cert` was built in 3.8 s and `subst.cert` in 0.02 s; `make check`
  now passes: **47 books all certified, 10 examples agree with the artifact,
  no `skip-proofs` or `defaxiom`**.  The `literals` book's own assertion
  caught a wrong ifelse literal while it was being written (`((:global.get 3)
  (:return))`, not `((:call 4) (:return))`), which is the class of mistake the
  book exists to make loud.

