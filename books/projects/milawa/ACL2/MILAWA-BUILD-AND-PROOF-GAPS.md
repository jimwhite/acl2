# Milawa build: how it works, and the level4/level10 proof gaps

This document explains what the Milawa build is doing, how the proof-generation
and proof-checking pipeline is supposed to work, and where the current
level4/level10 failures fit in. The short version: the system is working
correctly for the overwhelming majority of the thousands of proofs it
generates; only a small number of events are going wrong, and those are
concentrated in two places.

---

## 1. What Milawa is

Milawa is a "self-verifying" theorem prover for an ACL2-like logic, written by
Jared Davis for his Ph.D. dissertation. It is a *reflective* prover: it can
reason about its own proofs.

The key idea is a **two-level** architecture:

- **The host level (ACL2).** The bulk of Milawa is written in ACL2. This is
  where the "bootstrapping proofs" are *generated*. ACL2 is used as a
  convenient, powerful environment to construct proofs, but ACL2's own
  soundness is not trusted for the final result.

- **The kernel level (Common Lisp / Jitawa).** A small, standalone proof
  checker (`milawa.lsp`) re-checks every generated proof from scratch. This
  kernel is small enough to be formally verified (Magnus Myreen proved, in
  HOL4, that the kernel running on the Jitawa runtime on x86 can only accept
  semantically true theorems).

So the build produces a large body of proofs, and then a tiny trusted kernel
independently validates them. If the kernel accepts all the proofs, the
theorems are established without trusting ACL2.

---

## 2. The build pipeline

### 2.1 Levels

Milawa is built in a sequence of **levels**, each a directory under
`ACL2/bootstrap/`:

```
utilities -> logic -> level2 -> level3 -> level4 -> ... -> level10 -> level11 -> user
```

Each level:

1. is certified as a set of ACL2 books (`.mpcert` files), and
2. produces an ACL2 **image** (`acl2-images/<level>-symmetry`) that the next
   level is built on top of.

The image is the crucial mechanism: level *N+1* starts from an image that
already contains all of level *N*'s definitions, theorems, and rules. This is
how the build avoids re-proving everything at each level.

### 2.2 Two kinds of certificates

- **`.cert`** — ordinary ACL2 certificates, produced by `cert.pl`.
- **`.mpcert`** — "ACL2 Milawa Provisional Certificates", produced by
  `pcert.pl`. These are the interesting ones.

`pcert.pl` (see `ACL2/pcert.pl`) does the following for a book `foo.lisp`:

1. Determines which image the book should be certified against, via
   `infer_book_image` (`pcert-util.pl`): it looks for `foo.image`, then
   `cert.image` in the same directory, else falls back to a default.
2. Runs that image and feeds it:
   ```lisp
   (in-package "ACL2")
   (provisionally-certify "foo")
   (exit 0)
   ```
3. The image returns exit status **44** only on success (see
   `interface/pcert.lisp`).

`pcert-scan.pl` computes the dependency graph by scanning `include-book` forms
and emits `Makefile-pdeps`, which the top-level `Makefile` includes. The
`%.mpcert` rule in the `Makefile` runs `pcert.pl` and waits for the `.mpcert`
file to appear.

### 2.3 The event pipeline inside a book

Inside a book, Milawa definitions and theorems are introduced by macros that
live in `interface/`. The important ones:

| Macro | File:line | Purpose |
|-------|-----------|---------|
| `%autoadmit` | `acl2-connection.lisp:124` | Introduce a function by looking up its ACL2 definition |
| `%defun` | `core.lisp:767` | Part 1: register the function, install termination goals |
| `%admit` | `core.lisp:777` | Part 2: prove termination, save proofs, add axioms/defs |
| `%deftheorem` | `core.lisp` | Introduce a theorem |
| `%defderiv` | `core.lisp` | Introduce a derived rule ("builder") |
| `%save-events` | `core.lisp:1601` | Serialize the event log to `<level>.events` |

#### `%autoadmit`

```lisp
(defmacro %autoadmit (name)
  `(ACL2::make-event (%autoadmit-fn ',name (ACL2::w ACL2::state))))
```

`%autoadmit-fn` (`acl2-connection.lisp:100`) looks up the ACL2 defun for
`name`, extracts its formals, body, and measure, and expands to:

```lisp
(defsection name
  (%defun name formals body :measure measure)
  (local (%auto))
  (%admit))
```

#### `%defun` -> `%defun-fn` (`core.lisp:861`)

- Validates the name, formals, body, and measure.
- Looks up any existing definition via `tactic.find-def` in the harness
  `defs`. If one exists and differs, it is a hard error.
- Stores `goaldef` / `goalbody` / `goalmeasure`, adds the name to the arity
  table, and installs the **termination obligations** as the current proof
  goals.

#### `%admit` (`core.lisp:777`)

Expands to four steps:

1. **`%admit-check-fn`** (`core.lisp:919`)
   - If goals remain -> hard error.
   - If `(not (tactic.harness->building ...))` -> **skips proof compiling and
     saving entirely**.
   - Otherwise compiles the termination proofs and, if saving is enabled,
     writes `admit-<name>.proofs`.
2. **`%admit-update-fn`** (`core.lisp:986`) — adds the definition to `axioms`
   and `defs`.
3. **`%admit-finalize-fn`** (`core.lisp:1021`) — builds the
   `(equal (fn args) body) != nil` theorem, runs `%theorem-check` (which
   writes `thm-<name>.proof`), then pushes a `DEFINE` entry onto the
   `thmfiles` table.

#### `%save-events` -> `%save-events-fn` (`core.lisp:1655`)

Serializes the `thmfiles` table via `thmfiles-to-events` (`core.lisp:1621`)
into `<level>.events`. Each `DEFINE` entry carries the `admit-<name>.proofs`
filename; each `VERIFY` entry carries the `thm-<name>.proof` filename.

So the `.events` file is a **manifest**: it lists every event and the proof
file that backs it. The kernel later replays this manifest.

### 2.4 Proof files

Proofs are written under `Proofs/<level>/`:

- `admit-<name>.proofs` — the termination-obligation proofs for a definition.
- `thm-<name>.proof` — the proof of a theorem (or of a definition's
  `(fn args) = body` fact).

These are the "bootstrapping proofs" that the standalone kernel re-checks.

### 2.5 Final checking

`final-checks.sh` (in `Sources/`) builds one Lisp image per `Proofs/`
subdirectory by replaying the corresponding `<level>.events` file through the
kernel:

```
run_milawa base utilities
run_milawa utilities logic
run_milawa logic level2
...
run_milawa level3 level4
run_milawa level4 level5
...
```

For each step it feeds `Proofs/<next>.events` into `milawa-<lisp>` running on
the current image. If any referenced proof file is missing, the step fails.

---

## 3. What is going right

The system is fundamentally working. Concretely:

- **level3**: all 1045 referenced proof files are present. Zero missing.
- **level4**: 1162 of 1164 referenced proof files are present. Only **2**
  missing.
- **level10**: 692 of 701 referenced proof files are present. Only **9**
  missing.

Across the whole build there are thousands of proofs, and the failure is
confined to a handful of events. The pipeline — autoadmit, termination
proofs, theorem proofs, event serialization, image chaining — is doing the
right thing for the vast majority of cases. The remaining problems are
localized and specific.

---

## 4. The level4 problem: `definition-of-not`

### 4.1 Symptom

`Proofs/level4.events` references two proof files that do not exist:

- `Proofs/level4/admit-definition-of-not.proofs`
- `Proofs/level4/thm-definition-of-not.proof`

These are the only two missing files in level4.

### 4.2 What should happen

`bootstrap/level4/clause-basics.lisp:120` contains:

```lisp
(%autoadmit definition-of-not)
```

By the pipeline above, this should:

1. expand to `%defun` + `%auto` + `%admit`;
2. produce `admit-definition-of-not.proofs` (termination proofs);
3. produce `thm-definition-of-not.proof` (the `(definition-of-not) = ...`
   fact);
4. record `DEFINE DEFINITION-OF-NOT` and `VERIFY DEFINITION-OF-NOT` in the
   events file.

Steps 1, 2, and 3 are **not** happening, but step 4 **is** — the events file
records the entries even though no proofs are written. That mismatch is what
`final-checks.sh` trips on.

### 4.3 Observed facts

- In `bootstrap/level4/clause-basics.out`, at the exact position where the
  `definition-of-not` event belongs (between
  `forcing-logic.term-list-atblp-of-clause.term-list-guts` and
  `clause.substitute-iff-into-literal-bldr`), the output is two bare
  `:REDUNDANT` lines — no "Preparing to admit", no "Saving as".
- The freshly regenerated `Proofs/level4.events` **still** contains the
  `DEFINE`/`VERIFY` entries.
- `acl2-images/level4-symmetry` (the image `clause-basics` is certified
  against) already contains `definition-of-not` in its `defs`
  (`tactic.find-def` -> present; 654 defs). This image is the level3 image
  (its startup notices list "Preloaded ... level3").
- `acl2-images/level3-symmetry` is actually the level2 image (notices stop at
  level2) and does **not** contain `definition-of-not`.
- The image's `thmfiles` table is empty (length 0).
- Running `(%autoadmit definition-of-not)` directly in `level4-symmetry`
  prints `:REDUNDANT` and leaves `thmfiles` length at 0.

### 4.4 The `:REDUNDANT` sites

There are exactly three `:redundant` producers in `interface/core.lisp`:

- **line 359** — `%axiom-fn`: formula already in `axioms`.
- **line 1260** — `%raw-add-rule-fn`: rule already present and equal.
- **line 848** — commented out.

`%autoadmit` / `%defun` / `%admit` have **no** `:redundant` branch. So the
`:REDUNDANT` seen at the `definition-of-not` position must come from somewhere
else in the expansion path.

### 4.5 Open question

Why is the event treated as redundant (so no proof is written) while the
events file still records a `DEFINE`/`VERIFY` entry for it? Locating the
`:REDUNDANT` producer in the `%autoadmit` expansion path is the key.

Candidate places to inspect next: `%auto`, `%theorem-check`,
`%raw-add-theorem`, `%raw-add-rule`, and the `defsection`/`encapsulate`
machinery.

### 4.6 Why this is not a memory problem

The level4 build completes without any memory or stack error. It certifies
successfully. The missing proofs are a **logic/state** issue, not a resource
issue.

---

## 5. The level10 problem: binding stack exhaustion

### 5.0 Root cause investigated (2026-10-17)

**Reproduced.** Running

```sh
SBCL_USER_ARGS="--dynamic-space-size 64000 --control-stack-size 8192" \
  make -j 1 bootstrap/level10/crewrite-iffp.mpcert
```

fails after ~10 minutes with, in `bootstrap/level10/crewrite-iffp.out`:

```
; Compiling skeleton step #10: CLEANUP.
INFO: Binding stack guard page unprotected
Binding stack guard page temporarily disabled: proceed with caution
*** ABORTING from raw Lisp ***
Error:  Binding stack exhausted.
```

This is at the end of `CREWRITE-ALL` (total cost 521,912,205). Neither a
64 GB heap nor an 8 GB control stack helps.

**Key finding: `--control-stack-size` does NOT control SBCL's binding stack.**

Measured directly: a simple deep-recursion test with a special-variable
binding per frame exhausts at the *same* depth (~60,000 frames) whether
`--control-stack-size` is 64, 256, or 8192 MB. So `--control-stack-size` is
irrelevant to this error.

SBCL's binding stack is a **separate, fixed-size area** with **no runtime CLI
option**. `sbcl --help` lists only:

```
--dynamic-space-size <MiB>   heap
--control-stack-size <MiB>   control stack
--tls-limit                  thread-local symbols
```

There is no `--binding-stack-size`. The binding stack is sized at SBCL build
time (`sb-vm:binding-stack-size` is a compile-time constant; the `SB-VM`
symbol of that name is unbound at runtime).

**Why this bites Milawa.** The binding stack holds special-variable bindings
(`LET` of a special var) and `UNWIND-PROTECT` state. The proof code is deeply
and heavily recursive, and `CREWRITE-ALL` compiles a very large skeleton
(521 million "cost" units). Each recursive call that binds a special variable
pushes onto the fixed binding stack, and it overflows.

**Milawa's own source confirms the intent.** `Sources/milawa.lsp` and
`Sources/milawa2.lsp` both configure the *CCL* stacks explicitly:

```lisp
#+clozure
(progn
  (setq ccl::*default-control-stack-size* (expt 2 27))   ; 128 MB
  (setq ccl::*default-value-stack-size*   (expt 2 27))   ; 128 MB
  ...)
```

CCL's **value stack** is the analogue of SBCL's binding stack, and Milawa
deliberately sizes it to 128 MB. There is no SBCL equivalent of this setting,
which is why the build fails on SBCL at level10.

**This matches the README.** `Source/milawa/README` states the build
"requires both Clozure Common Lisp (CCL) and ACL2(h)". CCL is the intended
Lisp precisely because its stacks can be sized; SBCL is a fallback.

### 5.0.1 Options to fix level10

1. **Build level10 with CCL** instead of SBCL. This is the documented/tested
   configuration; CCL's 128 MB value stack is exactly what `CREWRITE-ALL`
   needs. ACL2 itself must also be built with CCL for this to work.
2. **Rebuild SBCL with a larger binding stack.** Requires changing the
   compile-time `BINDING_STACK_SIZE` in SBCL's runtime and recompiling.
   Verified to work; see 5.0.2 below.
3. **Investigate whether the recursion in `CREWRITE-ALL` can be bounded**
   (e.g. a tail-call or an iterative rewrite). This is the "real" fix, but it
   is a deep change to Milawa's proof engine and would need Jared Davis's
   input.

### 5.0.2 Verified fix: custom SBCL with a larger binding stack (2026-10-17)

**Result: works.** level10 `crewrite-iffp` now certifies, and all 9
previously-missing proofs are produced.

#### The knob

SBCL's binding stack size is a **C compile-time constant** in
`src/runtime/validate.h`:

```c
#define BINDING_STACK_SIZE (1024*1024)   /* chosen at random */
```

That 1 MB default is a 32-bit-era "chosen at random" value. In SBCL 2.6.9
this `#define` is **not** wrapped in `#ifndef`, so `-DBINDING_STACK_SIZE=...`
on the command line is silently ignored. The first required change is to make
it overridable:

```c
#ifndef BINDING_STACK_SIZE
#define BINDING_STACK_SIZE (1024*1024)   /* chosen at random */
#endif
```

(Upstream SBCL master already guards it this way; 2.6.9 predates that.)

#### Building

```sh
CFLAGS="-DBINDING_STACK_SIZE=$((256*1024*1024))" \
  sh make.sh --without-immobile-space --without-immobile-code \
             --without-compact-instance-header --fancy
```

256 MB was chosen over the 128 MB that Milawa uses for CCL's value stack
because SBCL bindings are wider on 64-bit. The compile log confirms
`-DBINDING_STACK_SIZE=268435456` reaches the runtime.

#### Measured effect

| | stock (1 MB) | custom (256 MB) |
|---|---|---|
| binding stack depth before exhaustion | ~1,000,000 | ~17,000,000 |

#### Gotcha: the core build-id

SBCL bakes `hostname-user-date` into the runtime and checks it against every
core (`src/runtime/coreparse.c`). A freshly built runtime therefore refuses to
load cores built by the original runtime:

```
core was built for runtime "buildkitsandbox-root-2026-10-16-23-04-40"
but this is "300506bb04ed-jovyan-2026-10-17-07-17-55"
```

To reuse the existing Milawa images, force the build-id back to the original
and rebuild only the runtime:

```sh
printf '"buildkitsandbox-root-2026-10-16-23-04-40"' > output/build-id.inc
CFLAGS="-DBINDING_STACK_SIZE=$((256*1024*1024))" make -C src/runtime
```

The resulting `src/runtime/sbcl` is a drop-in replacement for
`/usr/local/bin/sbcl`: the `acl2-images/*-symmetry` wrappers hardcode that
path, so swapping the binary is all that is needed.

#### Commands used

```sh
# 1. get the source
cd /tmp && mkdir sbcl-build && cd sbcl-build
wget https://github.com/sbcl/sbcl/archive/refs/tags/sbcl-2.6.9.tar.gz
tar -xzf sbcl-2.6.9.tar.gz && cd sbcl-sbcl-2.6.9

# 2. make BINDING_STACK_SIZE overridable (edit src/runtime/validate.h)

# 3. full build
CFLAGS="-DBINDING_STACK_SIZE=$((256*1024*1024))" sh make.sh \
  --without-immobile-space --without-immobile-code \
  --without-compact-instance-header --fancy

# 4. force matching build-id, rebuild runtime only
printf '"buildkitsandbox-root-2026-10-16-23-04-40"' > output/build-id.inc
CFLAGS="-DBINDING_STACK_SIZE=$((256*1024*1024))" make -C src/runtime

# 5. install (atomic rename to avoid 'Text file busy')
cp src/runtime/sbcl /usr/local/bin/sbcl.new
mv -f /usr/local/bin/sbcl.new /usr/local/bin/sbcl

# 6. rebuild the failing book
cd /home/acl2/books/projects/milawa/ACL2
make -j 1 bootstrap/level10/crewrite-iffp.mpcert
```

#### Dockerfile change

The container's `sbcl-builder` stage accepts a build arg
`SBCL_BINDING_STACK_MB`. Its default is **0**, meaning "leave SBCL alone"
(build with SBCL's stock 1 MB binding stack). Any nonzero value rebuilds SBCL
with that binding stack size, which is what Milawa needs (256 is a good value
on 64-bit).

When customizing, the stage wraps the `validate.h` define in `#ifndef` if
needed (a no-op on SBCL releases that already do), then passes the size via
`CFLAGS`:

```dockerfile
ARG SBCL_BINDING_STACK_MB=0
...
    && cd sbcl-* \
    && if [ "${SBCL_BINDING_STACK_MB}" != "0" ]; then \
           if ! grep -q '^#ifndef BINDING_STACK_SIZE' src/runtime/validate.h; then \
               sed -i \
                 -e 's|^\(#define BINDING_STACK_SIZE .*\)$|#ifndef BINDING_STACK_SIZE\n\1\n#endif|' \
                 src/runtime/validate.h; \
           fi; \
           export CFLAGS="-DBINDING_STACK_SIZE=$((SBCL_BINDING_STACK_MB*1024*1024))"; \
       fi \
    && sh make.sh \
         --without-immobile-space \
         --without-immobile-code \
         --without-compact-instance-header \
         --fancy \
         --dynamic-space-size=4Gb \
```

The `grep -q` guard makes the `sed` run at most once, so the patch is safe on
SBCL releases that already wrap the define.

The GitHub workflow (`docker-release.yml`) exposes the matching
`sbcl_binding_stack_mb` input (default `0`) and passes it through as
`SBCL_BINDING_STACK_MB` on each build. To build a Milawa-capable image, run
the workflow with `sbcl_binding_stack_mb` set to `256` (or a similar value).

### 5.1 Symptom

`bootstrap/level10/crewrite-iffp` aborts with:

```
Error:  Binding stack exhausted.
```

at `; Compiling skeleton step #10: CLEANUP.`

### 5.2 What should happen

`crewrite-iffp` should certify and emit its proofs, including 9 files that are
currently missing from `Proofs/level10/`:

- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-core.proof`
- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-relieve-hyp.proof`
- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-try-match.proof`
- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-try-matches.proof`
- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-try-rule.proof`
- `thm-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-try-rules.proof`
- `thm-forcing-rw.trace-list-iffps-of-rw.cresult-_gt_data-of-rw.crewrite-core-list.proof`
- `thm-forcing-rw.trace-list-iffps-of-rw.hypresult-_gt_traces-of-rw.crewrite-relieve-hyps.proof`
- `thm-lemma-for-forcing-rw.trace-_gt_iffp-of-rw.cresult-_gt_data-of-rw.crewrite-core.proof`

These are a **consequence** of the abort: the build died partway through, so
the later proofs were never written.

### 5.3 The resource issue

"Binding stack exhausted" is SBCL's **binding** stack, which is a *different*
resource from the control stack. The relevant SBCL runtime options are:

- `--control-stack-size` (MB) — the main control stack.
- `--dynamic-space-size` (MB) — the heap.

The `milawa-sbcl` wrapper passes `--control-stack-size 64` by default, and
`SBCL_USER_ARGS` appends later options, so a later `--control-stack-size`
wins. Raising it to 4096 did not resolve the abort, which suggests the binding
stack specifically (not the control stack) is the constraint, or that the
proof genuinely needs a different tuning.

### 5.4 Why this is different from level4

level10 is a genuine resource exhaustion during proof construction. level4 is
a state/logic issue where the build succeeds but silently skips an event.
They are unrelated problems that happen to both surface as "missing proofs".

---

## 6. ACL2 / Milawa version drift

### 6.1 The gap

- **ACL2 is now 8.7** (built 2026-10-16; see `acl2-init.lisp:1`).
- **Milawa was written 2005-2009**, when ACL2 was around 3.x/4.0.

That is roughly 15 years and many major ACL2 releases apart.

### 6.2 Milawa depends on ACL2 internals

Milawa is not a normal ACL2 book; it hooks into ACL2's guts. In
`interface/acl2-connection.lisp`:

- `get-measure` (line 84) uses `ACL2::fgetprop` on the `justification`
  property and `access justification ... :measure`.
- `%autoadmit-fn` (line 100) uses `ACL2::get-syntax-defun-entries` and
  `ACL2::get-measure`.
- `get-untranslated-defun` (line 79) uses `ACL2::decode-logical-name` and
  `ACL2::access-event-tuple-form`.
- `core.lisp` uses `ACL2::get-functions-to-inline`.

These are undocumented internals, not stable APIs. The `justification` record
(`induct.lisp:1674`) and the event-tuple layout are exactly the kind of thing
that changes between ACL2 versions.

Note also that `get-syntax-defun-entries` is **not** an ACL2 function at all —
Milawa defines it itself in `acl2-hacks/defun.lisp:202`, backed by its own
`milawa` table. So the coupling is two-way: Milawa both reads ACL2 internals
and maintains its own shadow tables that must stay consistent with them.

### 6.3 Evidence of active drift

The tree already contains **12 files with "Matt K. mod" patches** to keep
Milawa working with newer ACL2, referencing **Version 8.5** and **Version
8.7**:

- `bootstrap/level9/eqdatabasep.lisp:38` — "Avoid error noticed in preparation
  for Version 8.7 release"
- `bootstrap/level5/update-clause-bldr.lisp:135` — same
- `bootstrap/logic/disjoin-formulas.lisp:77` — same
- `bootstrap/level11/waterfall-steps.lisp:91` — same

The most telling one, `acl2-hacks/redef-okp.lisp:44`:

> "Matt K. comment 10/2022: The following definition was already out of date
> as of ACL2 Version 8.5 (maybe sooner): its argument list isn't even of the
> same length as the original. That didn't seem to interfere with pre-release
> testing, so I'm not going to fix it now."

That is a raw-mode redefinition of an ACL2 internal
(`chk-acceptable-certify-book`) whose signature no longer matches ACL2's —
knowingly left broken.

### 6.4 Hypothesis for the level4 bug

The `%autoadmit` path runs through `get-syntax-defun-entries` and
`get-measure` — both ACL2-internal lookups. If ACL2 8.7's representation of a
defun's syntax entry or justification differs from what Milawa expects,
`%autoadmit-fn` could take a wrong branch and produce the `:REDUNDANT`-style
no-op we observe, while the event still gets recorded in the events file.

This is the leading hypothesis for the `definition-of-not` mystery.

### 6.5 Next step

Inspect what `get-syntax-defun-entries` actually returns for
`definition-of-not` in the level4 image, and compare it against what
`%autoadmit-fn` expects (a `(MILAWA::%syntax-defun name args body)` entry).

### 6.6 Investigation results (2026-10-17)

Direct experiments in `acl2-images/level4-symmetry`:

1. **The syntax-defun entry is present and correct.**
   `(find-syntax-defun 'definition-of-not (ACL2::get-syntax-defun-entries ...))`
   returns:
   ```
   (%SYNTAX-DEFUN DEFINITION-OF-NOT NIL
     (LOGIC.PEQUAL (LOGIC.FUNCTION 'NOT (LIST 'X))
                   (LOGIC.FUNCTION 'IF (LIST 'X ''NIL ''T))))
   ```
   So the ACL2-internal lookup is **not** broken.

2. **`get-measure` returns NIL** for `definition-of-not`, so `%autoadmit-fn`
   takes the no-measure branch.

3. **The expansion is:**
   ```lisp
   (DEFSECTION DEFINITION-OF-NOT
     (%DEFUN DEFINITION-OF-NOT NIL
             (LOGIC.PEQUAL (LOGIC.FUNCTION 'NOT (LIST 'X))
                           (LOGIC.FUNCTION 'IF (LIST 'X ''NIL ''T))))
     (%ADMIT))
   ```

4. **Bare `%defun` works.** Submitting just the `%defun` prints
   "All goals have been proven."

5. **Bare `%defun` + `%admit` works.** It prints
   "Preparing to admit DEFINITION-OF-NOT" and attempts to save
   `admit-definition-of-not.proofs`.

6. **The full `defsection` returns `:REDUNDANT`.** Submitting the exact
   expansion from (3) produces a bare `:REDUNDANT` and nothing else — no
   "Preparing to admit", no proof saving.

7. **`definition-of-not` is defined in BOTH level3 and level4:**
   - `bootstrap/level3/not.lisp:40` — `(%autoadmit definition-of-not)`
   - `bootstrap/level4/clause-basics.lisp:120` — `(%autoadmit definition-of-not)`

8. **The level4 image already contains `definition-of-not`** (inherited from
   level3), which is why the re-admission is redundant.

### 6.7 Refined hypothesis

The `defsection` is an `encapsulate`. In level4, the image already contains
the events from level3's admission of `definition-of-not`, so ACL2's
redundancy check treats the whole `encapsulate` as redundant and skips it —
producing the bare `:REDUNDANT` and generating no proof. This is the
ACL2 redundancy mechanism interacting with Milawa's image-chaining: a symbol
admitted at one level and re-admitted at the next is silently skipped.

This is consistent with the observation that the other ~160 definitions in
level4 are new (not in the level3 image) and therefore are not skipped.

### 6.8 Remaining puzzle

If the `defsection` is skipped as redundant, `%admit-finalize-fn` should not
run, so no `DEFINE` entry should be added to `thmfiles` — yet
`Proofs/level4.events` **does** contain `DEFINE DEFINITION-OF-NOT`. Resolving
this (why the events file records an event that was skipped) is the next
question.

### 6.9 Next test

Determine whether the `DEFINE DEFINITION-OF-NOT` entry in `level4.events` is
produced by the level4 build itself or inherited from level3, by rebuilding
`level4.lisp` *after* the fresh `clause-basics` and re-checking the events
file.

### 6.10 Test results (2026-10-17, continued)

Ran the test from 6.9. Results:

1. **The events file is genuinely regenerated by the level4 build.**
   Deleted `Proofs/level4.events`, rebuilt `bootstrap/level4/level4.mpcert`;
   the file reappeared (mtime 05:21, same as `level4.out`) and **still**
   contains `DEFINE DEFINITION-OF-NOT`.

2. **The entry is NOT inherited from level3.** The level3 and level4 lines
   differ only in the path (`Proofs/level3/...` vs `Proofs/level4/...`), so
   level4's build produced its own entry.

3. **`DEFINITION-OF-NOT` is the ONLY `DEFINE` name shared between level3 and
   level4.** All other level4 definitions are new.

4. **No level4 build output shows the admit happening.** Across
   `bootstrap/level4/*.out`:
   - `grep "Preparing to admit DEFINITION-OF-NOT"` -> 0 matches
   - `grep "admit-definition-of-not"` -> 0 matches
   - `grep "Skipping proof-compiling"` -> 0 matches

5. **The `defsection` adds nothing to `thmfiles`.** Running the exact
   expansion in `level4-symmetry` with before/after probes:
   ```
   (:BEFORE 0)
   :REDUNDANT
   (:AFTER 0)
   ```
   So the `defsection` is skipped and `thmfiles` is unchanged.

6. **Bare `%defun` + `%admit` (no `defsection`) DOES work** and prints
   "Preparing to admit DEFINITION-OF-NOT".

### 6.11 The contradiction (current state)

- The `defsection` is skipped as redundant and adds nothing to `thmfiles`
  (facts 5, 6).
- Yet the freshly regenerated `level4.events` contains
  `DEFINE DEFINITION-OF-NOT` with a `Proofs/level4/...` path (facts 1, 2).
- The only code that adds a `DEFINE` entry to `thmfiles` is
  `%admit-finalize-fn` (`interface/core.lisp:1055`).
- But no build output shows `%admit-finalize-fn` running for
  `definition-of-not` (fact 4).

So either the entry is added by a path not yet identified, or the
`defsection` behaves differently in the real build than in the isolated test.

### 6.12 Next test

There are **two** `:REDUNDANT` lines at the `definition-of-not` position in
`clause-basics.out`, but only one `%autoadmit`. The second likely corresponds
to the adjacent `(%defderiv clause.substitute-iff-into-literal-bldr)`. Inspect
the `%defderiv` macro to see whether it also emits `:REDUNDANT` and whether it
touches `thmfiles`.

### 6.13 ROOT CAUSE FOUND (2026-10-17)

The `DEFINE` entries in `level4.events` come from **certificate replay during
`include-book`**, not from re-running the events.

Test: in `bootstrap/level4/`, run `(include-book "clause-basics")` in
`level4-symmetry` and measure the `thmfiles` table:

```
(:BEFORE 0)
:REDUNDANT
(:AFTER 123)
```

So including the book adds **123** entries to `thmfiles`. Listing the `DEFINE`
names among them includes:

```
DEFINITION-OF-NOT
CLAUSE.CLAUSE-FORMULA
CLAUSE.TERM-GUTS
...
```

**This is the mechanism:**

1. `clause-basics.lisp` is certified (`pcert.pl`), producing
   `clause-basics.mpcert` and its `.out`.
2. During certification, `(%autoadmit definition-of-not)` is **skipped as
   redundant** (the level4 image already has it from level3), so **no proof is
   written** and `clause-basics.out` shows only `:REDUNDANT`.
3. Later, `level4.lisp` does `(include-book "clause-basics")`. The
   `include-book` **replays the book's certificate**, which re-populates the
   `thmfiles` table with a `DEFINE DEFINITION-OF-NOT` entry pointing at
   `Proofs/level4/admit-definition-of-not.proofs`.
4. `%save-events` then serializes that `thmfiles` table into
   `level4.events` — including the `DEFINE` entry for a proof that was never
   written.

**So the events file is not stale.** It faithfully records what the
`thmfiles` table contains. The bug is that `include-book`'s certificate replay
adds a `DEFINE` entry for an event that was skipped during certification, so
the entry references a proof file that does not exist.

### 6.14 Why this happens (the real bug)

`definition-of-not` is admitted at **both** level3 (`not.lisp:40`) and level4
(`clause-basics.lisp:120`). Because the level4 image already contains it, the
level4 `%autoadmit` is redundant and produces no proof. But the certificate
replay still records the `DEFINE` entry, creating a dangling reference.

This is a genuine inconsistency between:
- what certification actually proves (nothing, for this event), and
- what the certificate/events record (a `DEFINE` entry with a proof filename).

### 6.15 Candidate fixes

1. **Remove the duplicate `(%autoadmit definition-of-not)` from
   `clause-basics.lisp:120`** — it is already admitted at level3, so level4
   does not need to re-admit it. This is the cleanest fix if level4 genuinely
   inherits it from the image.
2. **Make `%autoadmit`/`%admit` not record a `DEFINE` entry when the event is
   skipped as redundant** — a more general fix, but touches the core
   interface.
3. **Copy the level3 proofs into `Proofs/level4/`** — a workaround that makes
   `final-checks.sh` pass without addressing the root cause.

Option 1 is preferred and should be verified by rebuilding level4 and
confirming that `level4.events` no longer references the missing proofs.

### 6.16 Fix applied (2026-10-17)

**Change:** removed the duplicate `(%autoadmit definition-of-not)` from
`bootstrap/level4/clause-basics.lisp` (line 120). The `(%noexec
definition-of-not)` that followed it is retained, since the rewriter still
needs to know not to evaluate `definition-of-not`.

**Rationale (for the ACL2 maintainers):**

`definition-of-not` is admitted at level3 (`bootstrap/level3/not.lisp:40`).
The level4 image (`acl2-images/level4-symmetry`) is built on top of the level3
image, so `definition-of-not` is already present in the level4 world. The
level4 re-admission in `clause-basics.lisp` is therefore redundant.

The redundancy itself is harmless — ACL2 correctly skips the event. The
problem is the interaction with Milawa's proof-recording machinery:

1. During certification of `clause-basics.lisp`, `(%autoadmit
   definition-of-not)` expands to a `defsection` (an `encapsulate`). Because
   the definition already exists, ACL2 treats the whole `encapsulate` as
   redundant and skips it. No termination proof is generated, so no
   `Proofs/level4/admit-definition-of-not.proofs` is written, and
   `clause-basics.out` shows only `:REDUNDANT`.

2. Later, `level4.lisp` does `(include-book "clause-basics")`. The
   `include-book` replays the book's certificate, which re-populates the
   `tactic-harness` `thmfiles` table — including a `DEFINE DEFINITION-OF-NOT`
   entry pointing at `Proofs/level4/admit-definition-of-not.proofs`.

3. `%save-events` serializes the `thmfiles` table into `Proofs/level4.events`,
   so the events file references a proof file that was never written.

4. `final-checks.sh` replays `level4.events` through the kernel, which fails
   because the referenced proof file does not exist.

**Why removing the duplicate is the right fix:**

- It eliminates the inconsistency at its source: if level4 does not re-admit
  `definition-of-not`, there is no redundant event, no dangling `DEFINE` entry,
  and no missing proof file.
- It matches the intent of the image-chaining design: a definition admitted at
  an earlier level should not be re-admitted at a later level.
- It is a minimal, local change (one line) that does not touch the core
  interface.

**Alternatives considered:**

- *Make `%autoadmit`/`%admit` not record a `DEFINE` entry when the event is
  skipped as redundant.* More general, but requires detecting redundancy inside
  the Milawa interface, which is harder to do reliably and touches core code.
- *Copy the level3 proofs into `Proofs/level4/`.* A workaround that makes
  `final-checks.sh` pass without addressing the root cause; the events file
  would still reference a proof that level4 never produced.

**Verification:** rebuild `clause-basics` and `level4`, then confirm that
`Proofs/level4.events` no longer contains `DEFINE DEFINITION-OF-NOT` and that
the missing-proof check reports zero missing files for level4.

### 6.17 Verification result (2026-10-17)

After removing the duplicate `(%autoadmit definition-of-not)` and rebuilding
`level4`:

- `grep -c "DEFINE DEFINITION-OF-NOT" Proofs/level4.events` -> **0**
- `grep -c "VERIFY DEFINITION-OF-NOT" Proofs/level4.events` -> **0**
- The missing-proof check reports **no** missing file mentioning
  `definition-of-not`.

So the fix resolves the level4 `definition-of-not` failure: the events file no
longer references the two proof files that were never written.

(Note: a full `final-checks.sh` run still requires all level4 sub-books to be
certified; the verification above rebuilt only `clause-basics` and `level4`.)

---

## 8. Tracking changes: the ACL2 submodule

To keep track of Milawa changes against ACL2, the workspace
(`/workspaces/acl2-jupyter`) now includes an ACL2 submodule:

- **Path:** `context/acl2`
- **URL:** `https://github.com/jimwhite/acl2.git`
- **Branch:** `milawa`
- **Pinned commit:** `bfac1dd70dc0542436cda7e75cfd9db060203ea0`

This is the fork/branch that carries the Milawa sources and the "Matt K. mod"
patches described in section 6.3. It is the canonical place to record and
review changes to Milawa's ACL2 coupling.

Note the distinction:

- `/home/acl2` is the **build directory** — a plain (non-git) ACL2 tree used to
  actually build and run Milawa. It is not version-controlled.
- `context/acl2` is the **tracked submodule** — the git checkout of the
  `milawa` branch, used to track changes.

To update the submodule to the latest `milawa` branch:

```sh
cd /workspaces/acl2-jupyter
git submodule update --remote context/acl2
```

To record a new pinned commit after pulling changes:

```sh
cd /workspaces/acl2-jupyter
git add context/acl2
git commit -m "Update acl2 milawa submodule"
```

---

## 7. Summary

| | level4 | level10 |
|---|---|---|
| Missing proofs | 2 | 9 |
| Build outcome | succeeds | aborts |
| Cause | event treated as `:REDUNDANT`; no proof written, but events file still records it | binding stack exhausted mid-build |
| Category | logic/state bug (likely ACL2/Milawa drift) | resource exhaustion |
| Status | open — need to find the `:REDUNDANT` producer | open — need correct stack tuning |

The build is healthy overall: it generates and records thousands of proofs
correctly. The failures are a small, localized set of events, and each has a
distinct, identifiable cause.

---

## 7. Useful commands

```sh
# clean level4 and rebuild
cd ACL2
rm -f bootstrap/level4/*.mpcert bootstrap/level4/*.out
rm -rf ../Proofs/level4 ../Proofs/level4.events
nohup env SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make bootstrap/level4/level4.mpcert > /tmp/level4-clean.log 2>&1 &

# build a single sub-book
nohup env SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make bootstrap/level4/clause-basics.mpcert > /tmp/l4-cb.log 2>&1 &

# find missing proof files referenced by an events file
cd ..
grep -o 'Proofs/[a-z0-9]*/[^"]*\.proof[s]*' Proofs/level4.events | sort -u |
  while read f; do [ -e "$f" ] || echo "MISSING: $f"; done
```
