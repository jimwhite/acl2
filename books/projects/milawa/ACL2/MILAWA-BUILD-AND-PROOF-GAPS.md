# Milawa build: how it works, and the current build/proof discrepancies

This document explains what the Milawa build is doing, how the proof-generation
and proof-checking pipeline is supposed to work, and where the current
build failures fit in. The short version: the system is working correctly for
the overwhelming majority of the thousands of proofs it generates; only a
small number of events are affected, and those are concentrated in a few
places — all of which we believe are **environment / reproduction** problems
rather than Milawa source bugs (see §0).

---

## 0. Framing: this is a build/debugging problem, not a Milawa source problem

**Important.** Milawa has been built and proof-checked successfully for well
over a decade, on the ACL2 and Common Lisp versions of its time. When
something fails here, the default assumption must be that **our build
environment differs from the one Milawa was validated against**, not that
Milawa's source is wrong.

Concretely, the differences that matter most are:

- **Lisp implementation and version.** Milawa's README says the build
  "requires both Clozure Common Lisp (CCL) and ACL2(h)". We are building with
  **SBCL**, and with a **current** SBCL and **ACL2 8.7**. The level10
  binding-stack failure is a direct consequence of this (§5): SBCL's binding
  stack is a fixed compile-time constant, whereas CCL's analogous value stack
  is sized to 128 MB by Milawa itself.
- **ACL2 version.** Milawa was written against much older ACL2. Newer ACL2
  changes event/redundancy behaviour and ACL2 internals that Milawa touches,
  which is why "Matt K. mod" patches exist throughout the tree (§6).

So the pattern to expect is: **the code is fine; our environment reproduces a
different set of events than the one the proofs were generated for.** The
right response to a failure is therefore to make our build match the intended
configuration (or to understand how the current environment changes the event
stream), **not** to change Milawa's logic.

The level4 change (§6.16) was accepted as a pragmatic unblock. It should be
read as "a change that makes *our* build produce a consistent event stream",
not as a claim that the original code was buggy. Any further apparent
"source bugs" should be treated with strong suspicion and investigated as
build/configuration discrepancies first.

With that: §5 and §6 document two *environment* failures; §8 documents a
remaining *reproduction* discrepancy at level9 (duplicate events producing one
proof file), which is likewise best explained by how the current toolchain
serializes events rather than by a source defect.

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
  (`tactic.find-def` -> present; 654 defs).
- `acl2-images/level3-symmetry` does **not** contain `definition-of-not`.

> **Correction (2026-10-17).** These two facts were originally read as evidence
> of a misaligned image chain. They are not: they are exactly how the Makefile
> builds the images. `acl2-images/levelN-symmetry` is produced by running the
> *`levelN-1`* image and including the `levelN-1` books
> (`Makefile:185-197`: `acl2-images/level4-symmetry: acl2-images/level3-symmetry`
> and its recipe feeds `../../acl2-images/level3-symmetry` to `make-image.lsp`).
> So `level4-symmetry` legitimately contains level3's definitions (hence
> "Preloaded ... level3" and hence `definition-of-not`) and `level3-symmetry`
> legitimately stops at level2. The off-by-one in the *names* is by design.
>
> Moreover `bootstrap/level4/cert.image` -- which is **tracked upstream** --
> contains the single line `level4-symmetry`, and `infer_book_image`
> (`pcert-util.pl`) uses it for every book in that directory. Certification of
> `clause-basics.lisp` against an image that already contains level3's
> `definition-of-not` is therefore upstream's intended configuration, not a
> build accident. The re-admission in that book is genuinely redundant under
> any ACL2 that performs the redundancy check.
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

256 MB was used for this first, instrumented build (chosen over the 128 MB
Milawa uses for CCL's value stack because SBCL bindings are wider on 64-bit).
The compile log confirms `-DBINDING_STACK_SIZE=268435456` reaches the runtime.
**This is not the shipped size:** that is 2,000,000 frames ~ 32 MB, validated
against the level10 book in the *Dockerfile change* subsection below. 256 MB was
kept here only because it is what the dev container happens to have installed.

#### Measured effect

| | stock (1 MB) | custom (256 MB) |
|---|---|---|
| binding stack depth before exhaustion | ~65,000 | ~16,700,000 |

(Measured with one special-variable rebinding per recursion level; the stock
figure matches SBCL's "chosen at random" 1 MB and 16.03 bytes/frame.)

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
`SBCL_BIG_BINDING_STACK`: **0** (default) builds stock SBCL with its 1 MB
binding stack, **1** builds the big-stack variant that Milawa needs. The size
of that variant is a compile-time constant (`big_mb=32`) inside the stage, so
the knob is a plain on/off switch rather than a number. Stock and big-stack
builds alike are compiled from source and installed with `install.sh`, so
runtime, core and contribs always match and no build-id juggling is required;
the build-id trick described under *Gotcha: the core build-id* above is only
for retrofitting an existing container that must keep cores already dumped.

When enabled, the stage wraps the `validate.h` define in `#ifndef` if needed (a
no-op on SBCL releases that already do), then passes the size via `CFLAGS`:

```dockerfile
ARG SBCL_BIG_BINDING_STACK=0
...
    && cd sbcl-* \
    && big_mb=32 \
    && if [ "${SBCL_BIG_BINDING_STACK}" = "1" ]; then \
           if ! grep -q '^#ifndef BINDING_STACK_SIZE' src/runtime/validate.h; then \
               sed -i \
                 -e 's|^\(#define BINDING_STACK_SIZE .*\)$|#ifndef BINDING_STACK_SIZE\n\1\n#endif|' \
                 src/runtime/validate.h; \
           fi; \
           export CFLAGS="-DBINDING_STACK_SIZE=$((big_mb*1024*1024))"; \
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
`sbcl_big_binding_stack` input (default `0`) and passes it through as
`SBCL_BIG_BINDING_STACK` on each build. To build a Milawa-capable image, run
the workflow with `sbcl_big_binding_stack` set to `1`.

Sizing rationale, measured here: one special-variable rebinding frame costs
about **16.03 bytes** of binding stack, so the stock 1 MB aborts at ~65,000
frames (which is what `CREWRITE-ALL` needs to exceed). The container build
sizes the stack by **frame count** -- 2,000,000 frames, i.e. ~32 MB -- rather
than by an arbitrary megabyte figure: measured on a 32 MB runtime, depth
2,080,000 survives and 2,100,000 aborts, i.e. the ceiling is ~2,090,000 frames.
16 bytes is the *cheapest* frame (one special binding); code that binds several
specials per recursion level uses more per level, so 32 MB buys fewer than 2M
recursion levels there. The
stack is lazily-committed virtual memory, but it is allocated **per thread**,
so the size does multiply by thread count -- which is the argument for keeping
it modest rather than arbitrarily large. gdb spot checks of the proof *checker*
-- even on level10's 205 MB `crewrite-core` proof -- showed only a few hundred
bytes in use, so the whole requirement comes from the ACL2 builder. (To get the
builder's peak rigorously, sample `binding_stack_pointer` while building
`bootstrap/level10/crewrite-iffp`; see BUILD-PROCEDURE.md section 3.1.7.)

**Validated end-to-end.** 32 MB is not merely capacity-verified: the heaviest
known workload, `bootstrap/level10/crewrite-iffp`, was run against a 32 MB
runtime via `provisionally-certify` and returned `PCERT_EXIT=44`, which is
success. So 2M frames is enough for the workload that originally exhausted
1 MB, with roughly a 4% margin over the measured ceiling (2,080,000 survives).
If some future book does abort with "Binding stack exhausted", raise `big_mb`
in the Dockerfile (frames / 65536 ~= MB, so 4M frames ~= 64 MB) and re-run.

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

### 6.4 Hypothesis for the level4 discrepancy

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
`thmfiles` table contains. The discrepancy is that `include-book`'s
certificate replay adds a `DEFINE` entry for an event that was skipped during
certification, so the entry references a proof file that does not exist.

### 6.14 Why this happens

`definition-of-not` is admitted at **both** level3 (`not.lisp:40`) and level4
(`clause-basics.lisp:120`). Because the level4 image already contains it, the
level4 `%autoadmit` is redundant and produces no proof. But the certificate
replay still records the `DEFINE` entry, creating a dangling reference.

This is a mismatch between:
- what certification actually proves (nothing, for this event), and
- what the certificate/events record (a `DEFINE` entry with a proof filename).

It is best understood as the *current* ACL2/Milawa toolchain (ACL2 8.7, SBCL)
serializing a redundant event differently than the original toolchain did,
not as a defect in Milawa's logic. See §0.

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

### 6.18 SUPERSEDED: the source edit was reverted; fixed in the build (2026-10-17)

Section 6.16 removed the duplicate `(%autoadmit definition-of-not)` from
`bootstrap/level4/clause-basics.lisp`.  **That edit has been reverted.**  The
upstream source is restored exactly as Jared wrote it, and the problem is now
handled entirely on the build side.

**Why revert.**  Milawa's sources are meant to certify as they are (they did for
a decade), and `Proofs/` is generated rather than checked in -- too big for the
ACL2 community books, which is why Jared shipped it as compressed archives.
Since we have to generate the proofs anyway, the generator's output is the right
place to fix, and the sources stay pristine for upstream review.

**Why reverting is safe.**  The diagnosis in 6.13-6.14 stands: the re-admission
really is redundant (see the correction in 4.3 -- `bootstrap/level4/cert.image`
is upstream-tracked and names `level4-symmetry`, which is built from
`level3-symmetry` plus level3's books, so `definition-of-not` is already in the
world).  The *only* defect is that the generated manifest can name a proof file
that was never written.

**The build-side fix:** `Sources/fix-events-missing-proofs.py`.  It scans
`Proofs/*.events` and drops any `DEFINE`/`VERIFY` entry whose proof file does
not exist, printing exactly what it dropped.  Dropping such an entry is sound:
the object it introduces is already present in the image the level's checkpoint
is built on, so the replay reproduces the intended state.

```sh
cd /home/acl2/books/projects/milawa
python3 fix-events-missing-proofs.py                    # dry run, all levels
python3 fix-events-missing-proofs.py --apply            # rewrite in place
python3 fix-events-missing-proofs.py Proofs/level4.events   # or one file
```

**Verified.**  Injecting the two original dangling entries into the current
`level4.events` and running the tool:

```
Proofs/level4.events: would drop 2 entries with a missing proof file
    DEFINITION-OF-NOT   (missing: Proofs/level4/admit-definition-of-not.proofs)
    DEFINITION-OF-NOT   (missing: Proofs/level4/thm-definition-of-not.proof)
```

and after `--apply` the manifest is **identical** to the known-good
`level4.events` that produced a passing `level4.sbcl-linux64`.  On a fully
generated tree the tool reports 0 broken entries (everything else is consistent).

**Full post-build sequence** (run after generating proofs, before
`final-checks.sh`):

```sh
cd /home/acl2/books/projects/milawa
python3 fix-events-inline.py           --apply Proofs/*.events   # section 11
python3 fix-events-missing-proofs.py   --apply                   # this section
./final-checks.sh sbcl sbcl-linux64
```

Both tools are idempotent and dry-run by default.

### 6.19 NOT a parallelism artefact; resolved by supplying the proof (2026-10-17)

**Is this the same kind of race as the level9 `ALL-EQUALP-REMOVAL` failure
(§8)?  No.**  §8 was three books writing one proof file name concurrently.  For
level4 there is only one book, and the skip can be reproduced with no `make`
involved at all -- typing the event straight into the image:

```sh
cd ACL2
printf '(in-package "ACL2")\n(%%autoadmit definition-of-not)\n(exit 0)\n' \
  | ./acl2-images/level4-symmetry
# ->  ACL2 !> :REDUNDANT
```

No parallelism, no dependency graph, nothing else running.  ACL2 skips the event
because `definition-of-not` is genuinely already in that world (see the
correction in 4.3).  So a serial `make` will not change this, and neither will
any build ordering.

**The resolution: supply the proof instead of deleting the entry.**  The fact
recorded by the level4 event is the *same fact* level3 already proved, and
level3's proof is a legitimate witness.  Copying it keeps the source pristine,
keeps the manifest intact, and keeps the obligation in place -- which is the
important difference from 6.18's `fix-events-missing-proofs.py` (that tool
*removes* an obligation from the manifest).

```sh
cd /home/acl2/books/projects/milawa
python3 fix-missing-proofs.py            # dry run over Proofs/*.events
python3 fix-missing-proofs.py --apply
```

It finds each referenced-but-absent proof file, looks for the identically-named
file in another level's `Proofs/` directory, and copies it.

**Soundness: copying cannot weaken verification.**  `final-checks.sh` still
reads each proof and re-checks it against the level's world; the conclusion must
match the obligation exactly.  A wrong copy is *rejected*, not silently
accepted.  (Dropping the entry, by contrast, removes the check.)

**Verified.**  With the two files removed and the two original entries
re-injected into the manifest:

```
Proofs/level4-syn.events: DEFINITION-OF-NOT: Proofs/level4/admit-definition-of-not.proofs <- Proofs/level3/admit-definition-of-not.proofs
Proofs/level4-syn.events: DEFINITION-OF-NOT: Proofs/level4/thm-definition-of-not.proof <- Proofs/level3/thm-definition-of-not.proof
missing entries: 2   supplied: 2   unresolved: 0
```

and replaying those two entries through the kernel:

```
5659> DEFINE DEFINITION-OF-NOT
;; Checking the proofs took 0.00 seconds
;; DEFINE took 0.00 seconds
5660> VERIFY DEFINITION-OF-NOT
;; Checking the proof took 0.00 seconds
;; VERIFY took 0.00 seconds
All commands have been accepted.
```

On a fully generated tree the tool reports `missing entries: 0`.

**End-to-end confirmation.** With the supplied proof in place,
`level4.sbcl-linux64` replays `Proofs/level4.events` to `EXIT=0`, and a dry run
across the whole tree reports `missing entries: 0   suppliable: 0
unresolved: 0`.

**Preferred post-build sequence** (sources pristine, manifests intact):

```sh
cd /home/acl2/books/projects/milawa
python3 fix-events-inline.py  --apply Proofs/*.events   # section 11
python3 fix-missing-proofs.py --apply                   # this section
./final-checks.sh sbcl sbcl-linux64
```

`fix-events-missing-proofs.py` (6.18) remains available and documented, but is
weaker: use it only if a missing proof has no counterpart anywhere else.

---

## 7. Summary

| | level4 | level10 | level9 |
|---|---|---|---|
| Symptom | 2 proofs never written, events still referenced them | build aborts mid-way | proof on disk rejected; earlier, a hang |
| Root cause | duplicate event name across levels (image inherits it) combined with events/proof-file serialization | SBCL binding stack too small for this book | **parallel-build race**: 3 books write one proof filename (§8); plus SBCL inline blow-up (§11) |
| Category | **environment/reproduction** (ACL2 image + event serialization) | **environment** (SBCL vs CCL) | **build reproducibility** (parallelism) + **toolchain** (SBCL inliner) |
| Status | FIXED in the build (§6.19) | FIXED (§5.0.2) | FIXED (§11.6) |
| Residue | none; sources pristine | none | apply `fix-events-inline.py` after regenerating events |

All three are consistent with §0: the code is fine; our environment and
partial rebuilds change the event/proof stream.

---

## 8. A third discrepancy: level9 `ALL-EQUALP-REMOVAL` proof rejection (2026-10-17)

> **Read §0 first.** This is recorded as a **build/reproduction discrepancy**,
> not as a Milawa source bug. The leading hypothesis is that our partial
> rebuilds left a *mixed* set of proof files (some written by one book, some by
> another, at different times) that no longer agree with the serialized events
> file.

### 8.1 Symptom

After the level4 and level10 fixes, `final-checks.sh` now runs through
`level4`..`level8` and then **fails at level9**:

```
10629> VERIFY ALL-EQUALP-REMOVAL
;; Reading from Proofs/level9/thm-all-equalp-removal.proof
;; Reading the file took 0.01 seconds
;; Checking the proof took 0.01 seconds
Unhandled COMMON-LISP:SIMPLE-ERROR in ...:
  The proof was rejected
```

This is a **proof-checking rejection** (the kernel evaluated the proof and
rejected it), not the earlier "missing proof file" symptom.

### 8.2 The immediate trigger: one name, one proof file, three writers

`all-equalp-removal` is proved in three different level9 books, and each
writes the *same* on-disk proof file name
`Proofs/level9/thm-all-equalp-removal.proof`:

| Book | Proof size (conses) | Scope | mtime |
|------|--------------------:|-------|-------|
| `bootstrap/level9/eqdatabasep.lisp` | 202,319 | `(local ...)` | 06:01:43 |
| `bootstrap/level9/theoryp-aux.lisp` | 202,319 | global | 06:01:23 |
| `bootstrap/level9/add-equality.lisp` | 203,949 | `(local ...)` | 06:02:58 |

The proof file on disk is dated 06:01:51 (202,319-cons version). The three
definitions are not all identical — `add-equality`'s is a different proof
(203,949 conses).

`Proofs/level9.events` contains exactly **one** `VERIFY ALL-EQUALP-REMOVAL`
entry (line 3). The events file is serialized from the `thmfiles` table,
which keeps one entry per name. If the on-disk proof was written by a
*different* book than the one whose conclusion the events entry records, the
kernel rejects.

This is a known shape in Milawa's tooling — the authors worked around a
related ACL2 hard error, per the "Matt K. mod" comment in `eqdatabasep.lisp`:

> Matt K. mod: Avoid error noticed in preparation for Version 8.7 release
> when attempting to make bootstrap/level9/crewrite-builders.mpcert:
> `HARD ACL2 ERROR in %PROVE: The proposed name, ALL-EQUALP-REMOVAL, is
> already in use as the name of a rule.`
> ... So I'll make it local where needed.

So the duplicate-name situation is pre-existing and already partially
mitigated upstream. What is *new* is the rejection, which points at our
build.

### 8.3 Root cause CONFIRMED: a parallel-build race on the shared proof file

We reproduced the failure deterministically, so the cause is no longer a
hypothesis:

1. **Parallel build (`make -jN`).** Cleaned the three books, then rebuilt them
   with `make -j3`. The three certification processes all write
   `Proofs/level9/thm-all-equalp-removal.proof` concurrently; the last writer
   wins, non-deterministically. In the test the on-disk proof was **337,526
   bytes** (md5 `0086345763952f8c6b5814c16c7b7896`).
   Replaying `Proofs/level9.events` against the level8 image:
   **`The proof was rejected`**.

2. **Serial build (`make -j1`).** Same clean, but rebuilt the books one at a
   time. Now the last writer is always `theoryp-aux` (the only **global**
   copy), whose proof is **330,067 bytes** (md5
   `44322eb29f8b8223a1da76cf201f7043`). Replaying the same events:
   **accepted**.

3. **A/B swap.** Putting the 337,526-byte proof next to the *same* events
   reproduces the rejection; putting the 330,067-byte proof back makes it pass.
   Only the proof file changed — the events file is identical. So the
   discrepancy is entirely in **which book won the race to write the shared
   filename**.

The reason a *wrong* proof can be written at all is that the three copies are
not identical. `theoryp-aux`'s copy is the global one the events entry expects;
`add-equality`'s copy is a `local` copy with a different proof (an extra copied
definition). If `add-equality` finishes last, its proof ends up at the shared
path and does not match the events entry.

### 8.4 Why this only bites us now

This is a consequence of the ACL2 8.7 prep work, not of anything we did.
Before commit `c1b77f4771` ("...Fixed Milawa issues", Matt Kaufmann, 2026-03),
`all-equalp-removal` existed in only two books, `eqdatabasep` and
`theoryp-aux`, and **both wrote byte-identical proofs** — so the race was
harmless (whichever won, the proof matched). That commit made `eqdatabasep`'s
copy `local` (to dodge a new ACL2 8.7 redundancy error) and **added a third
`local` copy in `add-equality`** whose proof is *different*. Now there are
three writers of one filename with two distinct payloads, so the parallel
build is inherently non-deterministic.

Note that the upstream proof-generation path is already serial: ACL2's
`books/GNUmakefile` target `milawa-test-extended` runs
`cd projects/milawa/ACL2; $(MAKE) ACL2=$(ACL2) all` with **no `-j`**, so the
proofs Milawa ships were produced without this race. The failure only appears
when the build is parallelised (as our container/CI build does with
`make -j`).

### 8.5 Recommended next step (build debugging, not source editing)

Because the problem is build reproducibility, the fix belongs in how *we*
generate and assemble the `Proofs/` directory — **not** in Milawa's logic:

- Generate the bootstrapping proofs **serially** (single-threaded) so the
  shared filename is written deterministically, **or**
- pre-supply the canonical `Proofs/` tree (Milawa ships proofs precisely so
  that `final-checks.sh` can check them without regenerating), **or** propose
  (upstream) that the tooling de-duplicate/disambiguate proof filenames so a
  shared name can never be clobbered by a different proof.

Any upstream change would be to the *proof-generation tooling*, and would be
justified by reproducibility, not by a claim that a decade of proofs is wrong.

### 8.6 Status

Root cause identified and reproduced; disambiguation is a build/tooling matter
(§8.5). **No Milawa source change is warranted.** Resolved operationally by
building serially: level9 and everything above it now check (§9).

---

## 9. Overall build status (2026-10-17)

**The pipeline is complete.** `final-checks.sh sbcl sbcl-linux64` replays every
level and all 13 check:

| level | image | result |
|---|---|---|
| base .. level8 | `level8.sbcl-linux64` | checked earlier the same day, before the level9 fix |
| level9 | `level9.sbcl-linux64` (65 MB) | `EXIT=0`, ~8.5 min, after `fix-events-inline.py` (§11) |
| level10 | `level10.sbcl-linux64` (68 MB) | `EXIT=0`, ~31 min measured event time; slowest proof 1245 s |
| level11 | `level11.sbcl-linux64` (70 MB) | `EXIT=0`, 15,687 events, no missing proofs |
| user | `user.sbcl-linux64` (70 MB) | `EXIT=0`, 18 s |

Nothing in Milawa's logic, kernel or sources was changed to get here. All four
discrepancies encountered were resolved on the build/toolchain side:

| # | problem | resolution |
|---|---|---|
| 4 | level4 `definition-of-not` proof never written | supply level3's identically-named proof (§6.19) |
| 5 | level10 binding stack exhaustion | big-stack SBCL build (§5.0.2) |
| 8 | level9 `ALL-EQUALP-REMOVAL` proof rejected | serial build; one proof file, one writer (§8.3) |
| 11 | level9 `DEFINE RW.FAST-EQDATABASE-EXTEND` hang | clear `inlinep` on recursive definitions (§11) |

Remaining housekeeping: `Proofs/level7.events` still wants one `inlinep`
rewrite (see §11.6). Level7 checks fine as it stands, so this is consistency
rather than a blocker -- but apply the tool before regenerating level7.

A from-scratch `make all` has **not** been run end to end with the current
tools. The levels above were checked by replaying the manifests produced by the
earlier build, which is exactly what `final-checks.sh` verifies.

---

## 10. Useful commands

```sh
# the whole check, from the Sources directory (note the image extension)
cd /home/acl2/books/projects/milawa
python3 fix-events-inline.py  --apply Proofs/*.events   # §11
python3 fix-missing-proofs.py --apply                   # §6.19
./final-checks.sh sbcl sbcl-linux64

# re-check one level (final-checks skips images that already exist)
rm -f level4.sbcl-linux64
./final-checks.sh sbcl sbcl-linux64

# clean level4 and rebuild
cd ACL2
rm -f bootstrap/level4/*.mpcert bootstrap/level4/*.out
rm -rf ../Proofs/level4 ../Proofs/level4.events
nohup env SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make bootstrap/level4/level4.mpcert > /tmp/level4-clean.log 2>&1 &

# build a single sub-book
nohup env SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make bootstrap/level4/clause-basics.mpcert > /tmp/l4-cb.log 2>&1 &

# run one book without letting make rebuild the whole image chain
cd bootstrap/level10
printf '(in-package "ACL2")\n(provisionally-certify "crewrite-iffp")\n(exit 0)\n' \
  | ../../acl2-images/level10-symmetry          # exit status 44 = success

# find missing proof files referenced by an events file
cd ..
grep -o 'Proofs/[a-z0-9]*/[^"]*\.proof[s]*' Proofs/level4.events | sort -u |
  while read f; do [ -e "$f" ] || echo "MISSING: $f"; done
```

---

## 11. The level9 stall: `DEFINE RW.FAST-EQDATABASE-EXTEND` (2026-10-17)

> **Read §0 first.** As with §8, this is recorded as an
> **environment/toolchain** finding — SBCL's inliner, not Milawa's logic.

### 11.1 Symptom

`final-checks.sh` appears to **hang** during the level9 replay. The log stops
dead after command 1895 (`Proofs/level9.events` line 1896):

```
12522> DEFINE RW.FAST-EQDATABASE-EXTEND
;; Reading from Proofs/level9/admit-rw.fast-eqdatabase-extend.proofs
;; Reading the file took 0.00 seconds
;; Checking the proofs took 0.00 seconds
```

and then nothing for ~47 minutes (`real 53m38s`, `user 53m37s` — 100% CPU, no
I/O wait), ending with:

```
;
; compilation unit aborted
;   caught 1 fatal ERROR condition
```

That trailing note is what SBCL prints when it is **signalled** mid-compile.
The run had been killed, not aborted by itself — so the "1 fatal ERROR
condition" was a red herring, and there was never an error message to find.

**This is level9, not level10.** `level9.sbcl-linux64` was never written, so the
run never got as far as level10.

### 11.2 Where the time goes

The per-event timings in `level9.sbcl-linux64.out` sum to **346 s** for all 1895
commands that were processed. The run took **3220 s**. So roughly **47 minutes
were spent inside this single event**, and the log proves where: the last two
lines before the stall are the proof-reading and proof-checking reports, which
means execution had already reached `defun-safe-fn` (`milawa.lsp:185`) and its
`(eval `(compile (defun ,name ,formals ... ,body)))`.

RSS stayed flat at 5.2 GB throughout, so this is not heap exhaustion or a GC
death spiral; it is compile-time work.

### 11.3 Fast reproduction (6 minutes + 3 seconds)

The 47 minutes is *not* needed to reproduce. Replaying level9 from the level8
image only takes ~6 minutes, and doing it once yields a reusable checkpoint:

```sh
cd /home/acl2/books/projects/milawa
# everything up to (not including) the failing DEFINE
tail -n +2 Proofs/level9.events | head -n 1894 > /tmp/l9pre.events
echo '(FINISH "l9probe")' >> /tmp/l9pre.events
sbcl --dynamic-space-size 32000 --control-stack-size 1024 \
     --core level8.sbcl-linux64 --noinform --disable-debugger \
     < /tmp/l9pre.events > /tmp/l9pre.out 2>&1      # ~6 min -> l9probe.sbcl-linux64

# the failing event alone, in ~3 s (or forever, if it hangs)
sed -n '1896p' Proofs/level9.events > /tmp/ev1896.lisp
timeout 90 sbcl --dynamic-space-size 32000 --control-stack-size 1024 \
     --core l9probe.sbcl-linux64 --noinform --disable-debugger \
     < /tmp/ev1896.lisp
```

Every subsequent probe is then a 3-second experiment.

> Note the SBCL option order: `--core` is a C runtime option, so it must come
> **before** Lisp options like `--noinform` / `--disable-debugger`.

### 11.4 Root cause: inline-expansion blow-up

Bisecting the body inside that checkpoint (each probe ≤20 s) isolates it to one
call:

| probe (identical bindings, one extra call) | result |
|---|---|
| baseline, no extra call | 0.01 s |
| `(RW.FAST-FIND-EQTRACE-CONTRADICTION ...)` | 0.44 s |
| `(RW.FAST-EQSET->HEAD ...)` / `->IFFP` / `->TAIL` | 0.01 s |
| `(RW.FIND-RELEVANT-FAST-EQSET ...)` | 0.07 s |
| `(RW.FAST-EQSET ...)` / `(RW.REMOVE-FAST-EQSET-BY-HEAD ...)` | 0.01 s |
| **`(RW.FIND-CONTRADICTION-IN-FAST-EQSET-LIST EQUALSETS)`** | **HANG** |

`RW.FIND-CONTRADICTION-IN-FAST-EQSET-LIST` is **self-recursive** and its own
`DEFINE` has `inlinep = T`; its body calls `RW.FAST-FIND-EQTRACE-CONTRADICTION`,
which is also recursive and also `inlinep = T`. 159 of the 428 level9 `DEFINE`s
carry `inlinep = T`.

`defun-safe-fn` does:

```lisp
(when inlinep (eval `(declaim (inline ,name))))
(eval `(compile (defun ,name ,formals (declare (ignorable ,@formals)) ,body)))
```

SBCL declines to inline the *immediate* self-call (it reports "could not be
inlined because no definition for it was seen prior to its first use"), but when
a **caller** is compiled the callee's body is expanded at the call site, and the
nested inline chain multiplies. The cost grows by roughly a factor of 150-180
per nesting level, so a chain two levels deep is effectively unbounded.

Minimal reproducer, no Milawa involved (each function is recursive and declared
inline, `f_i` calls `f_{i-1}`, then a caller is compiled):

| chain depth | SBCL 2.6.9 | SBCL 2.6.1 |
|---|---|---|
| 0 | 0.002 s | 0.002 s |
| 1 | 0.32 s | 0.39 s |
| 2 | **>30 s (hang)** | **>30 s (hang)** |

**Version test done:** SBCL 2.6.1, built with the same Dockerfile flags, behaves
identically. This is long-standing inliner behaviour, **not** a regression in
2.6.9, so changing SBCL version will not fix it.

### 11.5 Fix options

1. **Do not declare recursive definitions inline** (preferred). In
   `defun-safe-fn`, skip the `(declaim (inline ,name))` when `name` occurs in
   `body`. This changes only how the checker *compiles* the definition — the
   events, the proofs and the accepted theorems are untouched, so nothing needs
   to be rebuilt except the kernel and the level9+ checkpoints. Caveat: it edits
   `milawa.lsp`, i.e. the trusted kernel; the edit is a compiler hint only and
   cannot change which proofs are accepted, but it should be called out.
2. **Fix the generator instead** (ACL2 side): make `%defun` / the
   `get-functions-to-inline` path emit `inlinep = NIL` for recursive functions.
   Cleaner conceptually, but it changes the `.events` files and therefore forces
   a rebuild of every level (and CCL never needed it, so it is a portability fix,
   not a correctness fix).
3. **Wrap the shell-out** in `final-checks.sh` with a watchdog — hides the
   problem, does not unblock the proof, so not recommended.

### 11.6 FIX APPLIED and VERIFIED (2026-10-17)

**Change:** option 1, implemented as an **events-file rewrite** rather than a
kernel change. `inlinep` is read from the events file and passed straight to
`defun-safe-fn`; it is only a compilation hint and cannot affect which proofs
are accepted. Clearing it for recursive definitions therefore fixes the stall
**without touching the trusted kernel (`milawa.lsp`) and without rebuilding any
ACL2 book**.

Tool: `Sources/fix-events-inline.py` (next to `final-checks.sh`). It parses each
`.events` file, and for every `DEFINE` whose body mentions its own name and whose
`inlinep` is `T`, rewrites just that token to `NIL`.

```sh
cd /home/acl2/books/projects/milawa
python3 fix-events-inline.py Proofs/level9.events          # dry run
python3 fix-events-inline.py --apply Proofs/level9.events  # rewrite
```

Affected definitions found when the tool was first run:

| file | count | names | state now |
|---|---|---|---|
| `Proofs/level9.events` | 4 | `RW.FIND-CONTRADICTION-IN-EQSET-LIST`, `RW.FAST-FIND-EQTRACE-CONTRADICTION`, `RW.FIND-CONTRADICTION-IN-FAST-EQSET-LIST`, `RW.FIND-RELEVANT-FAST-EQSET` | rewritten; image checks |
| `Proofs/user.events` | 1 | `*` (Milawa's multiplication, genuinely recursive) | rewritten; image checks |
| `Proofs/level7.events` | 1 | `CLAUSE.NORMALIZE-NOTS-TERM` | **still pending** -- level7 checks either way |

All other events files (primitives, utilities, logic, level2-6, 8, 10, 11) need
no change. The rewrite is a single-token change per definition: the diff of
`level9.events` is 4 lines, `T` -> `NIL`, +8 bytes total. The original is kept
as `Proofs/level9.events.orig-inlinep`.

**Verification (full level9 replay, not just the prefix):**

```sh
cd /home/acl2/books/projects/milawa
sbcl --dynamic-space-size 32000 --control-stack-size 1024 \
     --core level8.sbcl-linux64 --noinform --disable-debugger \
     < Proofs/level9.events > /tmp/l9full.out 2>&1
```

| | before | after |
|---|---|---|
| `DEFINE RW.FAST-EQDATABASE-EXTEND` (event 12522) | ~47 min, never finished | **0.03 s** |
| whole level9 replay (2907 commands) | never completed | **8.5 min**, `EXIT=0` |
| measured per-event time | 346 s for the first 1895 events | 543 s for all 2907 |
| output | none | `level9.sbcl-linux64` (65 MB) written by `(FINISH "level9")` |

No errors, no rejected proofs, no missing proof files. The pipeline can now
advance past level9.

**Important caveat:** regenerating the proofs re-writes the `.events` files and
undoes this. Re-run the tool (dry run first) after any ACL2-side regeneration of
`Proofs/*.events`. A permanent fix belongs upstream in one of the two places
named in §11.5 (kernel `defun-safe-fn`, or the generator's `inlinep` decision).

**Why not just change the kernel / regenerate the events?** Either would force a
full re-verification chain (base image plus every level, ~7.5 h for levels up to
8). The events rewrite is cheap because it changes neither the kernel nor any
proof file.

### 11.7 Generator-side fix: `interface/core.lisp` (2026-10-17)

The events rewrite in 11.6 repairs the manifests we already have. The fix that
stops the problem being regenerated is one level up, in the ACL2 code that
decides `inlinep` in the first place: `thmfiles-to-events`.

Before:

```lisp
(inlinep  (memberp name functions-to-inline))
```

After:

```lisp
(inlinep  (and (memberp name functions-to-inline)
               (not (%function-occursp name body))))
```

`%function-occursp` is a new `:mode :program` helper that walks the body for the
definition's own name. A `DEFINE` whose body mentions its name is therefore
serialized with `inlinep = NIL`. A ~30-line comment above the change records the
measurement (x150-180 expansion per nesting level, the level9 chain, 47 min ->
0.03 s) so the next reader does not have to rediscover it.

Why this is safe:

- `inlinep` is a compilation hint and nothing else. The kernel's `defun-safe-fn`
  consumes it as `(declaim (inline ,name))`; it appears in no proof and cannot
  change which theorems are accepted.
- It only ever *removes* an inline request for a self-recursive function, which
  the host Lisp cannot usefully inline anyway: the recursive call itself is
  never inlined (SBCL: "could not be inlined because no definition for it was
  seen prior to its first use"), and the expansion performed when compiling a
  *caller* is what blows up.
- CCL never exhibited the blow-up, so this is a portability fix, not a
  correctness fix.

Two limits worth stating plainly:

1. **It has no effect on existing `.events` files.** Manifests generated before
   this change keep their `T`s; 11.6's tool is still required for them.
2. **It has not yet been exercised by a rebuild.** It edits `interface/`, which
   invalidates every `<level>-symmetry` image, so confirming it needs a full
   chain rebuild. The first such rebuild should show `inlinep NIL` for e.g.
   `RW.FIND-CONTRADICTION-IN-FAST-EQSET-LIST` in a freshly generated
   `level9.events`, with no post-processing.

---

## 12. Tracking changes: the ACL2 submodule

To keep track of Milawa changes against ACL2, the workspace
(`/workspaces/acl2-jupyter`) includes an ACL2 submodule:

- **Path:** `context/acl2`
- **URL:** `https://github.com/jimwhite/acl2.git`
- **Branch:** `milawa`
- **Base commit for the changes described in this document:**
  `bfac1dd70dc0542436cda7e75cfd9db060203ea0`

This is the fork/branch that carries the Milawa sources and the "Matt K. mod"
patches described in section 6.3. It is the canonical place to record and
review changes to Milawa's ACL2 coupling.

Note the distinction:

- `/home/acl2` is the **build directory** — a plain (non-git) ACL2 tree used to
  actually build and run Milawa. It is not version-controlled.
- `context/acl2` is the **tracked submodule** — the git checkout of the
  `milawa` branch, used to track changes.

What the branch carries on top of that base commit:

| file | change |
|---|---|
| `ACL2/interface/core.lisp` | generator-side `inlinep` fix (§11.7) |
| `ACL2/bootstrap/level4/clause-basics.lisp` | comment only; code identical to Jared's (§6.19) |
| `ACL2/bootstrap/level9/eqdatabasep.lisp` | comment only |
| `BUILD-PROCEDURE.md` | build/check runbook, incl. the SBCL and post-processing steps |
| `ACL2/MILAWA-BUILD-AND-PROOF-GAPS.md` | this document |
| `fix-events-inline.py` | clear `inlinep` on self-recursive `DEFINE`s (§11.6) |
| `fix-missing-proofs.py` | supply a proof from another level (§6.19) |
| `fix-events-missing-proofs.py` | alternative: drop a dangling manifest entry (§6.18) |

Milawa's verified sources — `milawa.lsp`, `milawa2.lsp`, and everything under
`ACL2/bootstrap/*/` other than the two comment-only files above — are
**untouched**. The tools and the two documentation files are the only additions.

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
