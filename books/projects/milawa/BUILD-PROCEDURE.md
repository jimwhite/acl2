# Milawa build procedure

Step-by-step instructions for building Milawa, cleaning up, and rebuilding.
Written from the working setup in this container.

Quantities in this document are **measured on this container** (aarch64,
CCL 1.13 on Linux ARM64, ACL2 8.7), not copied from Jared's 2009 notes.  The
SBCL figures are retained for the fallback described in §3.1.  Where a figure
comes from a measurement, the measurement is stated so it can be re-run.
Sections that describe the *state* of a build (rather than how to run one) are
dated.

---

## 1. Directory layout

| Path | What it is |
|------|-----------|
| `/workspaces/acl2/books/projects/milawa` | **Sources directory** — `GNUmakefile`, `final-checks.sh`, the `milawa-*` launchers, `milawa.lsp`, `milawa2.lsp`, and `base.<ext>` (for CCL here, `base.ccl-linux-aarch64`) |
| `/workspaces/acl2/books/projects/milawa/ACL2` | **Build directory** — the `Makefile`, `bootstrap/`, `interface/`, `acl2-hacks/`, `acl2-images/` |
| `/workspaces/acl2/books/projects/milawa/Proofs` | Generated proof files, one subdirectory per level, plus `<level>.events` manifests |
| `/workspaces/acl2/books/projects/milawa/ACL2/acl2-images` | Generated ACL2 images (`<level>-symmetry`) |
| `/workspaces/acl2` | The ACL2 source/build tree; built here with CCL (§4.0) |

Note: the ACL2 tree must be built with the same host Lisp used for the Milawa
kernel.  With CCL, run `make LISP=ccl` in `/workspaces/acl2` and pass
`ACL2=/workspaces/acl2/saved_acl2` to the Milawa build.

Tools that live in the Sources directory:

| Tool | Purpose |
|------|---------|
| `GNUmakefile` | Builds `base.<ext>` and runs the final checks (`make`, `make help`); CCL by default |
| `final-checks.sh <lisp> <ext>` | Replays `Proofs/<level>.events` through the standalone kernel (§7) |
| `milawa-ccl` | Default `ccl --batch -I ...` launcher; stack sizes come from `MILAWA_CCL_THREAD_STACK` / `MILAWA_CCL_STACK` |
| `milawa-sbcl` | SBCL fallback launcher; heap and stack sizes come from the environment |
| `milawa-cmucl`, `milawa-clisp`, `milawa-scl`, `milawa-acl` | Launchers for running saved images; not build targets |
| `Proofs/clean-proofs.sh` | Removes the generated proofs |
| `Proofs/zip-proofs.sh` | Bundles them for distribution |

---

## 2. Levels, images, and why the numbering looks off by one

`final-checks.sh` drives these levels in this order:

```
base -> utilities -> logic -> level2 -> level3 -> level4 -> level5 -> level6
     -> level7 -> level8 -> level9 -> level10 -> level11 -> user
```

Each step loads the image for the **previous** level and replays the events for
the **next** one:

```sh
# final-checks.sh, run_milawa CURR NEXT
./milawa-$LISPNAME "$CURR.$EXT" < "Proofs/$NEXT.events" > "$NEXT.$EXT.out"
```

So `level4.<ext>` is produced by replaying `Proofs/level4.events` into
`level3.<ext>`.  (`<ext>` is derived by the Sources `GNUmakefile` from
`uname`, e.g. `ccl-linux-aarch64` here; override it with `make EXT=<tag>`.)

The ACL2 side has the same shape one step earlier: the Makefile builds
`acl2-images/level4-symmetry` from `acl2-images/level3-symmetry` plus level3's
books.

```
acl2-images/level4-symmetry: acl2-images/level3-symmetry \
                             $(PCDEPS_FOR_bootstrap__level3__level3)
```

This is **by design, not an off-by-one bug**: the books at level *N* are
certified in an image that already contains levels 1..*N*-1. It also explains
why a change in `bootstrap/levelN/` invalidates the image for level *N* and
every level above it.

---

## 3. Prerequisites

CCL is the default builder and needs no custom Lisp build:

- `ccl` on `PATH` (here `/usr/local/bin/ccl`, from the Clozure 1.13 Linux
  ARM64 release).  The Sources `GNUmakefile` uses it by default.
- ACL2 built with CCL (`make LISP=ccl` in the ACL2 tree, §4.0), so the
  ACL2-side `acl2-images/*-symmetry` wrappers invoke CCL too.
- `base.<ext>` in the Sources directory (e.g. `base.ccl-linux-aarch64` here).
  This is the **only** kernel image that must pre-exist; `make base` builds it, and
  `utilities.<ext>` and everything above it are produced by `make check` /
  `final-checks.sh`.
- Enough memory.  CCL's heap grows on demand; the kernel images size the
  listener's value (binding) and control stacks to 128 MB, and `milawa-ccl`
  passes `-Z 128M -S 128M` as well.  No runtime rebuild is involved.

SBCL fallback: `milawa-sbcl` and `make LISP=sbcl` work, but level10 needs an
SBCL runtime with a larger binding stack (32 MB), which means building SBCL
from source.  See §3.1 for that path.  The figures in §3.1 are SBCL-specific;
CCL does not need them.

---

## 3.1 SBCL fallback: the large binding stack needed by level10

CCL does **not** need this section.  CCL's value stack is the analogue of
SBCL's binding stack, and it is sized at runtime: `milawa.lsp` sets it (and the
control/temp stacks) to 128 MB, and `milawa-ccl` passes `-Z 128M -S 128M`.
The material below applies only when you choose to build or check with SBCL.

### 3.1.1 Why this exists

Milawa's level10 book `bootstrap/level10/crewrite-iffp` needs a **binding
stack** far larger than SBCL's stock value. It aborts with

```
INFO: Binding stack guard page unprotected
*** ABORTING from raw Lisp ***
Error:  Binding stack exhausted.
```

Two things are worth stating plainly, because both are easy to get wrong:

- `--control-stack-size` does **not** control this. Measured directly, a
deep-recursion test with one special-variable rebinding per frame exhausts at
the *same* depth (~60,000 frames) whether `--control-stack-size` is 64, 256 or
8192 MB. If a probe reports "no more space for function call frames" instead,
that is the control stack, a different resource (§3.1.4).
- The binding stack is a **C compile-time constant**
(`src/runtime/validate.h`: `BINDING_STACK_SIZE`). There is no
`--binding-stack-size` runtime option and `sb-vm:binding-stack-size` is not
bound at runtime.

So the only way to get a bigger binding stack is to rebuild SBCL. The
Dockerfile's `SBCL_BIG_BINDING_STACK` build arg does exactly that for container
builds (§3.1.3); see also §5.0.2 of `MILAWA-BUILD-AND-PROOF-GAPS.md`.

### 3.1.2 How much is needed: 2,000,000 frames (~32 MB)

**The shipped setting is 2,000,000 binding frames — `big_mb=32` in the
Dockerfile.** It is sized in frames rather than megabytes because frames are
the unit the exhaustion message and the measurements speak in.

Measured here by bisecting the deepest survivable special-rebinding recursion
(the probe in §3.1.4):

| quantity | value | how measured |
|---|---|---|
| bytes per binding frame | **16.03** | 256 MB stack, deepest survivable depth 16,750,000 |
| ceiling, stock 1 MB | ~65,000 frames | 1 MB / 16.03; matches the ~60k frames where stock SBCL aborts |
| ceiling, 32 MB | **~2,090,000 frames** | 2,080,000 OK, 2,100,000 `Binding stack exhausted` |
| ceiling, 256 MB | ~16.7 M frames | same bisection |

Two conclusions that matter:

1. **32 MB is enough.** The workload that originally exhausted stock SBCL is
   `bootstrap/level10/crewrite-iffp`. Run against a 32 MB runtime via
   `provisionally-certify "crewrite-iffp"` (§4.6) it completes with
   `PCERT_EXIT=44`, which is success. Raise `big_mb` only if some future book
   aborts with "Binding stack exhausted" (`frames / 65536` = MB, so 4M frames =
   64 MB).
2. **The requirement comes from the ACL2 proof builder, not the checker.**
   `final-checks.sh` was sampled holding only a few hundred bytes of binding
   stack, even while checking level10's 205 MB `crewrite-core` proof. The
   pressure is in building the proofs, not in checking them.

### 3.1.3 How to build it (what the Dockerfile does)

`SBCL_BIG_BINDING_STACK=1` switches the Dockerfile from a stock build to a
32 MB-stack build. In both cases SBCL is compiled **from source** and installed
with `sh install.sh`, so runtime, core and contribs all come from the same
build and no build-id juggling is needed — §3.1.5 exists only for retrofitting
an existing container that must keep cores it has already dumped.

The only substantive change is making `BINDING_STACK_SIZE` overridable. In some
releases (2.6.9 is one) the `#define` in `src/runtime/validate.h` is **not**
wrapped in `#ifndef`, so a `-DBINDING_STACK_SIZE=...` on the command line is
silently ignored:

```c
#define BINDING_STACK_SIZE (1024*1024)   /* chosen at random */
```

The build wraps it in an `#ifndef` guard first (the `grep` makes this a no-op on
releases that already guard it, such as current upstream master), then:

```sh
CFLAGS="-DBINDING_STACK_SIZE=$((32*1024*1024))" sh make.sh \
    --without-immobile-space \
    --without-immobile-code \
    --without-compact-instance-header \
    --fancy \
    --dynamic-space-size=4Gb
```

`--fancy` is what keeps the debug info §3.1.7 needs. Keep the `--without-*`
flags identical to whatever built the runtime that dumped the cores you intend
to load — SBCL complains when a core's feature set does not match the runtime's.

### 3.1.4 How to tell which runtime you have

`sbcl --version` will not tell you: the override is a number baked into the
binary. Stock SBCL dies at roughly 65,000 frames of "one special rebinding per
recursion level", so surviving 1,000,000 proves the override is live, and
surviving 2,080,000 proves it is at least 32 MB:

```sh
cat > /tmp/bprobe.lsp <<'EOF'
(defvar *sp* nil)
(defun rec (n) (let ((*sp* n)) (if (= n 0) 0 (1+ (rec (1- n))))))
(dolist (d '(60000 1000000 2080000))
  (handler-case (progn (rec d) (format t "~&depth ~9:d: OK~%" d))
    (error (c) (format t "~&depth ~9:d: caught ~A~%" d (type-of c)))))
(finish-output)
(sb-ext:exit :code 0)              ; <-- REQUIRED, see the trap below
EOF
sbcl --dynamic-space-size 6000 --control-stack-size 8192 \
     --noinform --disable-debugger --load /tmp/bprobe.lsp
```

Takes about 5 s. Note the large `--control-stack-size`: at the wrappers' own
`--control-stack-size 1024` (1 GB) the probe runs out of *control* stack ("no
more space for function call frames") around 2M frames, and that is easy to
misread as a binding-stack limit. To test a runtime other than the installed
one, name both the runtime and the core, and set `SBCL_HOME` so contribs
resolve:

```sh
SBCL_HOME=/usr/local/lib/sbcl /tmp/sbcl-build/sbcl-sbcl-2.6.9/src/runtime/sbcl \
    --core /usr/local/lib/sbcl/sbcl.core --load /tmp/bprobe.lsp ...
```

> **Trap that has cost time here:** after `--load` finishes, SBCL drops into
> its REPL and **waits on stdin**, which looks exactly like a hang. Always end
> probe scripts with `(sb-ext:exit)` (or pass `--non-interactive`). Likewise,
> `compilation unit aborted / caught N fatal ERROR condition` on the console
> usually means the process was *signalled* (e.g. by `timeout` or Ctrl-C)
> while it was busy, not that the Lisp code was faulty.

### 3.1.5 Retrofitting an existing container (the build-id trick)

Needed only when you must keep cores that are **already dumped** and cannot
regenerate them. SBCL bakes `hostname-user-date` into the runtime and records it
in every core it dumps, and a runtime refuses to load a core whose build-id
differs. The shortcut is therefore: keep the original core, force the new
runtime to claim the old build-id, and rebuild only the runtime (much faster
than a second full build).

This is what the separate SBCL dev container's `/usr/local/bin/sbcl` does; it
is **not** what the Dockerfile does (§3.1.3).

```sh
cd /tmp && mkdir -p sbcl-build && cd sbcl-build
wget https://github.com/sbcl/sbcl/archive/refs/tags/sbcl-2.6.9.tar.gz
tar -xzf sbcl-2.6.9.tar.gz && cd sbcl-sbcl-2.6.9

# 1. Make BINDING_STACK_SIZE overridable (no-op if already guarded)
if ! grep -q '^#ifndef BINDING_STACK_SIZE' src/runtime/validate.h; then
  sed -i -e 's|^\(#define BINDING_STACK_SIZE .*\)$|#ifndef BINDING_STACK_SIZE\n\1\n#endif|' \
      src/runtime/validate.h
fi

# 2. Full build with the project's flags
CFLAGS="-DBINDING_STACK_SIZE=$((32*1024*1024))" sh make.sh \
    --without-immobile-space --without-immobile-code \
    --without-compact-instance-header --fancy --dynamic-space-size=4Gb

# 3. Restore the ORIGINAL build-id so the existing cores still load, then
#    rebuild the runtime only.
printf '"buildkitsandbox-root-2026-10-16-23-04-40"' > output/build-id.inc
CFLAGS="-DBINDING_STACK_SIZE=$((32*1024*1024))" make -C src/runtime

# 4. Install. cp+mv, not a direct copy over a running binary ("Text file busy").
cp src/runtime/sbcl /usr/local/bin/sbcl.new
mv -f /usr/local/bin/sbcl.new /usr/local/bin/sbcl
```

The build-id in step 3 is whatever the core you intend to keep expects; a
mismatch is reported with both ids:

```sh
sbcl --core /usr/local/lib/sbcl/sbcl.core
```

> **This container is currently over-provisioned.** `/usr/local/bin/sbcl` is a
> 256 MB-stack build (it survives 2,200,000 frames) with the core left over from
> the original 2.6.9 build. That is 8x what ships, it works fine, and it is only
> a leftover of how the limit was first discovered. Treat anything measured here
> as an upper bound; the shipped 32 MB setting is validated separately (§3.1.2).

### 3.1.6 Caveats

- **Do not use the distro `sbcl`** (e.g. apt's 2.6.0). Stock 1 MB binding stack
  *and* a different build-id, so it can neither run the workload nor load the
  images here.
- **Every saved image is build-id locked.** `base.sbcl-linux64`,
  `level*.sbcl-linux64`, and `ACL2/acl2-images/*-symmetry` were all dumped by a
  runtime with build-id `buildkitsandbox-root-2026-10-16-23-04-40`. A runtime
  with any other build-id will refuse to load them; either force the same
  build-id (§3.1.5) or regenerate every image.
- The `acl2-images/*-symmetry` wrappers invoke `/usr/local/bin/sbcl` by
  absolute path, so swapping that one binary covers both the kernel side and
  the ACL2 proof-generation side.
- `SBCL_BIG_BINDING_STACK` is a **build** arg (GitHub workflow input
  `sbcl_big_binding_stack`, default `0` = stock). It takes effect when the image
  is built; changing the value later does nothing to an existing image.
- The patch is purely a compile-time number: it does not change SBCL's
  semantics, so it cannot affect which proofs are accepted. Confirmed with
  SBCL 2.6.1 built the same way: identical behaviour.
- The binding stack is **reserved virtual memory** -- only touched pages commit.
  A generous size therefore costs essentially nothing at run time, so there is
  no reason to size it tightly. Equally, nothing is gained by exceeding 32 MB
  until some workload actually needs it.

### 3.1.7 Optional: measuring the true peak

Only needed to re-derive the number above. Sample the live process while the
heaviest book is being built (needs the runtime's `struct thread` debug info,
which the `--fancy` build keeps):

```sh
# 1. start the failing build
cd ACL2 && make -j 1 bootstrap/level10/crewrite-iffp.mpcert &
# 2. sample binding-stack usage every 5 s
P=$(pgrep -f 'acl2-images/level10-symmetry' | head -1)
cat > /tmp/sample.gdb <<'EOF'
set pagination off
set confirm off
set $t = all_threads
set $mb = 0
while $t != 0
  set $b = (unsigned long)$t->binding_stack_pointer - (unsigned long)$t->binding_stack_start
  if $b > $mb
    set $mb = $b
  end
  set $t = $t->next
end
printf "USED binding=%lu\n", $mb
detach
quit
EOF
while kill -0 $P 2>/dev/null; do
  gdb -p $P -batch -x /tmp/sample.gdb 2>/dev/null | grep USED
  sleep 5
done
```

Peak bytes / 16.03 = frames needed. **Do not run this while `final-checks.sh`
is reading the same `Proofs/<level>/` files** -- the build rewrites them.

---

## 4. Building

First build ACL2 with the host Lisp you will use.  CCL is the default:

### 4.0 Build ACL2 with CCL

```sh
cd /workspaces/acl2
make LISP=ccl            # produces saved_acl2
./saved_acl2             # banner should say "Clozure Common Lisp"
```

Then point the Milawa build at that image.  All Milawa build commands are run
from the **build directory**:

```sh
cd /workspaces/acl2/books/projects/milawa/ACL2
```

Passing `ACL2=` explicitly avoids mixing CCL and SBCL images; it is required
when `acl2` is not on `PATH`.

> ### ⚠ Do NOT use `make -j` when generating proofs
>
> The upstream way to generate the proof files is `make all` **serially**
> (ACL2's own `books/GNUmakefile` runs `milawa-test-extended` as a plain
> `$(MAKE) ... all`, with no `-j`).  Several books in a level prove a theorem
> of the **same name** and therefore write the **same** proof file
> (`Proofs/<level>/thm-<name>.proof`).  In a parallel build those
> certification processes race; whichever writes last wins, and if that is a
> book whose proof differs (e.g. a `local` copy) the resulting file does **not**
> match the level's `.events` manifest and `final-checks.sh` reports
> **"The proof was rejected"**.
>
> This is a *build reproducibility* issue, not a Milawa source bug.  Always
> generate proofs with `make` (single-threaded).  See
> `MILAWA-BUILD-AND-PROOF-GAPS.md` §8 for the full diagnosis.  Parallelism is
> only safe if the `Proofs/` tree is not being (re)generated.
>
> Confidence is limited to a single comparison, so if in doubt verify: after a
> build, `md5sum` the shared proof file and confirm a `final-checks.sh` replay
> accepts it under the exact build settings you intend to ship.

> ### ⚠ Editing `interface/` (or `acl2-hacks/`) rebuilds the whole image chain
>
> The `<level>-symmetry` images are derived from the `interface/` books, so
> touching one file there makes **every** image stale. A targeted
> `make bootstrap/level10/crewrite-iffp.mpcert` will then first rebuild
> `interface-acl2` and each `<level>-symmetry` in turn — a multi-hour job — even
> though you only wanted the one book. Make is right; the surprise is real.
>
> This has bitten this project once already (it truncated
> `acl2-images/level5-symmetry.core` before it was stopped). It is *not* harmful
> to `Proofs/` or the `.<ext>` checkpoints, only to derived images, but
> it wastes hours. See §4.6 for how to run a single book without this happening.

### 4.1 Full build

```sh
cd /workspaces/acl2/books/projects/milawa/ACL2
make ACL2=/workspaces/acl2/saved_acl2 all
```

This builds every `.mpcert` and every image up to `user-symmetry`. Keep it
single-threaded — see the warning above. A full build takes many hours; the
proof-generation part is the long pole (level10 alone is ~30 min of measured
event time, with a single proof taking ~20 min).

### 4.2 Overriding Lisp memory/stack

**CCL (default).**  `milawa-ccl` reads `MILAWA_CCL` (executable),
`MILAWA_CCL_THREAD_STACK` (listener control and value stacks, default `128M`)
and `MILAWA_CCL_STACK` (initial control stack, default `128M`) from the
environment; the Sources `GNUmakefile` uses the same `-Z`/`-S` settings when it
builds `base.<ext>`.  There is no separate binding-stack flag: `-Z` sizes the
value stack, which is where special bindings live.  The image already carries
128 MB defaults from `milawa.lsp`, so these are only for extra headroom.

**SBCL fallback.**  `SBCL_USER_ARGS` is interpolated near the **end** of the command line in both
`milawa-sbcl` and the `acl2-images/*-symmetry` wrappers, and SBCL applies
runtime options in order, so a later `--control-stack-size` /
`--dynamic-space-size` genuinely wins over the wrapper default. Verified:

```sh
$ sbcl --core /usr/local/lib/sbcl/sbcl.core --dynamic-space-size 32000 \
       --dynamic-space-size 4096 --noinform \
       --eval '(format t "DS=~A~%" (sb-ext:dynamic-space-size))'
DS=4294967296
```

(The 4 GB value wins over the earlier 32 GB one; the `--core` in between makes
no difference.)

So to raise the control stack for an ACL2-side build while leaving the image's
own settings alone:

```sh
SBCL_USER_ARGS="--control-stack-size 4096" \
  make ACL2=/workspaces/acl2/saved_acl2 all
```

Note that the **binding** stack is not reachable this way (§3.1.1); this only
covers the control stack and heap.

### 4.3 Building a single book

```sh
make ACL2=/workspaces/acl2/saved_acl2 \
  bootstrap/level4/clause-basics.mpcert
```

### 4.4 Building a single image

```sh
make ACL2=/workspaces/acl2/saved_acl2 acl2-images/level4-symmetry
```

### 4.5 Running a long build detached

Long builds should be run detached with output to a log, so the terminal is
not blocked:

```sh
nohup make ACL2=/workspaces/acl2/saved_acl2 \
  bootstrap/level10/level10.mpcert > /tmp/level10.log 2>&1 &

# SBCL fallback:
# nohup env SBCL_USER_ARGS="--control-stack-size 4096" \
#   make ACL2=<acl2-root>/saved_acl2 \
#   bootstrap/level10/level10.mpcert > /tmp/level10.log 2>&1 &
```

Then inspect `/tmp/level10.log` and the per-book `.out` files.

### 4.6 Running one book without the image chain

To run a single book's certification without letting make rebuild the images,
drive the image directly. This is exactly what `pcert.pl` runs, minus the
dependency graph:

```sh
cd ACL2/bootstrap/levelN
printf '(in-package "ACL2")\n(provisionally-certify "BOOK")\n(exit 0)\n' \
  | ../../acl2-images/levelN-symmetry
# exit status 44 means success (see interface/pcert.lisp)
```

Gotchas, both of which have cost time here:

- An exit status of **44 is success**, not failure. Any other status means the
  book did not certify — commonly because the book itself errored (read the
  output) or because ACL2 exited before `provisionally-certify` returned.
- The book must be certifiable against the image you drive. `levelN-symmetry`
  contains levels 1..*N*-1, so e.g. `clause-basics` (a level4 book that needs
  level3 theorems) works against `level3-symmetry` but not against an earlier
  image. Per-book image overrides via `<book>.image` are possible
  (`pcert-util.pl:infer_book_image`) but are not used here.

---

## 5. What the build produces

For each level:

- `ACL2/bootstrap/<level>/*.mpcert` — provisional certificates.
- `ACL2/bootstrap/<level>/*.out` — per-book build logs.
- `ACL2/acl2-images/<level>-symmetry` — the level image.
- `Proofs/<level>/<book>/` — proof files (`admit-*.proofs`, `thm-*.proof`),
  one directory per certifying book.
- `Proofs/<level>.events` — the event manifest, serialized from the
  `thmfiles` table by `%save-events`.

### 5.1 Post-processing: none required

Earlier revisions of this document prescribed two Python "repair" tools,
`fix-events-inline.py` and `fix-missing-proofs.py`, which patched the generated
manifests: one cleared `inlinep` on self-recursive `DEFINE`s, the other supplied
a proof for an event that ACL2 skipped as redundant.  Both papered over bugs on
the generator side, both are fixed in `ACL2/interface/` now, and both tools have
been removed:

- `inlinep` is computed in `thmfiles-to-events` (`interface/core.lisp`), which
  clears it for self-recursive definitions (see gaps §11).
- A redundant admission now expands to nothing at all, so it records no
  `thmfiles` entry and needs no proof file (Milawa issue #2078).

So `make` followed directly by the final checks is the expected workflow.  The
sanity check worth running is that every proof file the manifests name actually
exists; see §7.1.

---

## 6. Cleaning up for a rebuild

### 6.1 Clean a single level

To force a level to rebuild from scratch, remove its certificates, outputs,
proofs, and events file:

```sh
cd /workspaces/acl2/books/projects/milawa/ACL2
rm -f bootstrap/level4/*.mpcert bootstrap/level4/*.out
rm -rf ../Proofs/level4
rm -f ../Proofs/level4.events
```

Then rebuild:

```sh
make ACL2=/workspaces/acl2/saved_acl2 bootstrap/level4/level4.mpcert
```

### 6.2 Clean a level and everything above it

Because of the image chain, if you change level *N* you must also rebuild the
images for *N+1* and up. Remove the images too:

```sh
cd /workspaces/acl2/books/projects/milawa/ACL2
rm -f acl2-images/level4-symmetry acl2-images/level5-symmetry \
      acl2-images/level6-symmetry acl2-images/level7-symmetry \
      acl2-images/level8-symmetry acl2-images/level9-symmetry \
      acl2-images/level10-symmetry acl2-images/level11-symmetry \
      acl2-images/user-symmetry
```

### 6.3 Full clean

The Makefile has a `clean` target:

```sh
cd /workspaces/acl2/books/projects/milawa/ACL2
make clean
```

This removes certificates, images, `.out`/`.time`/`.proof` files, the
dependency files, and cleans `../Proofs` via `clean-proofs.sh`.

### 6.4 Important caveat: cleaning a level does not clean its dependents

`make bootstrap/level4/level4.mpcert` rebuilds only `level4.lisp` and the
sub-books it depends on. It does **not** rebuild the other level4 sub-books
unless they are out of date. To fully regenerate a level's proofs, remove all
of that level's `.mpcert`/`.out` files (as in 6.1) before rebuilding.

---

## 7. Final proof checking

`final-checks.sh` replays each `Proofs/<level>.events` through the standalone
kernel, building one image per level. It is run from the **Sources directory**:

```sh
cd /workspaces/acl2/books/projects/milawa
make                    # builds base.<ext> and checks every level
# or directly:
./final-checks.sh ccl ccl-linux-aarch64
```

`make` derives `<ext>` from `uname` (`ccl-linux-aarch64` here, `ccl-linux-x86_64`
on x86-64) and defaults to CCL.  Use `make LISP=sbcl` for the SBCL fallback
(after building that `base.<ext>`).

- Argument 1 is the Lisp name; it must match an executable
  `milawa-<lispname>` (here `milawa-ccl`).
- Argument 2 is the image extension; it must match a pre-existing
  `base.<ext>` (here `base.ccl-linux-aarch64`).  Getting this wrong is the most
  common usage error: `final-checks.sh` immediately reports that `base.<ext>`
  does not exist.

Each step loads the image for the previous level and replays the next level's
events (§2), writing `<level>.<ext>` and a log `<level>.<ext>.out`. It processes
levels in order (`base -> utilities -> logic -> level2 -> ... -> level11 ->
user`) and stops at the first failure.

It **skips a level whose image already exists**, so to re-run a level you must
delete its image first:

```sh
rm -f level4.ccl-linux-aarch64   # use your own EXT
```

Note that this only redoes the *checking*; the proofs themselves come from the
ACL2 build (§4) and the manifests from §5.1.

### 7.1 Checking for missing proofs

The manifests name every proof file they need, so the real check is that those
paths all exist:

```sh
cd /workspaces/acl2/books/projects/milawa
grep -o 'Proofs/[a-z0-9]*/[^"]*\.proof[s]*' Proofs/level4.events | sort -u |
  while read f; do [ -e "$f" ] || echo "MISSING: $f"; done
```

---

## 8. Do I need to re-run the ACL2/Milawa `make`?

Yes, whenever you change Milawa sources (e.g. a `bootstrap/**/*.lisp` file),
you must re-run the build so the affected `.mpcert` files, images, and proofs
are regenerated. Specifically:

- Changing a book at level *N* requires rebuilding that book, the level *N*
  image, and all higher levels (see 6.2).
- Changing `interface/` or `acl2-hacks/` affects the base images and therefore
  effectively requires a full rebuild. In particular, `interface/core.lisp`
  carries the `inlinep` guard described in gaps §11, so any edit there
  invalidates every image.
- `final-checks.sh` only *checks* existing proofs; it does not regenerate them.
- After any rebuild that regenerates `Proofs/*.events`, no repair step is
  needed (§5.1); just run the final checks (§7).

`Proofs/` is **generated and not checked in** (it is large; Jared shipped
tarballs). `ACL2/acl2-images/*` are likewise generated.

---

## 9. Known issues

- **level4 `definition-of-not` — fixed in the generator (Milawa issue #2078).**
  `(%autoadmit definition-of-not)` in `bootstrap/level4/clause-basics.lisp` is
  redundant: `level4-symmetry` already contains the definition, from level3's
  books.  The replayed `make-event` used to re-create a `thmfiles` entry for it
  even though the admit never ran, so `level4.events` named an
  `admit-definition-of-not.proofs` that was never written, and the kernel
  reported `FILE-DOES-NOT-EXIST` at event 5722.  `%autoadmit-fn`
  (`interface/acl2-connection.lisp`) now makes a redundant admission expand to
  nothing, so no entry and no proof file are produced, and `level4.events`
  simply does not mention the event.  Milawa's sources and the manifests are
  not edited by hand, and nothing needs repairing after the build.  See gaps
  §6.18 and §6.19.

- **level10 `crewrite-iffp`**: CCL handles this with its runtime-sized value
  stack (`-Z 128M`), so no custom CCL build is needed.  A **stock** SBCL
  aborts with "Binding stack exhausted" (its *binding* stack, distinct from
  `--control-stack-size`); raising `--control-stack-size` does not help.
  SBCL users need the big-stack build in §3.1; see also gaps §5.0.2.
- **level9 `DEFINE RW.FAST-EQDATABASE-EXTEND` (events line 1896)**: used to
  hang for tens of minutes inside SBCL's compiler.  Root cause is inline
  expansion blow-up through a chain of inline-declared *recursive* functions
  (`RW.FIND-CONTRADICTION-IN-FAST-EQSET-LIST` ->
  `RW.FAST-FIND-EQTRACE-CONTRADICTION` -> ...).  This is handled in the
  generator now: `interface/core.lisp` clears `inlinep` for self-recursive
  definitions when it writes the `.events` manifests (§5.1), so no
  post-processing step is needed.  See gaps §11.
- **A level's `Proofs/<level>.events` can still be stale** relative to a
  repaired `Proofs/` tree.  `final-checks.sh` replays whatever is in the
  manifests, so if a level's image was built before a fix was applied, delete
  the image and re-check (§7).
- **Apparent "hang" of SBCL after `--load`** (fallback only): it is the
  interactive REPL waiting on stdin.  End scripts with `(sb-ext:exit)` or use
  `--non-interactive`.
- **CCL image compatibility**: a saved CCL image must be loaded by a compatible
  CCL kernel (here the 1.13 Linux ARM64 build).  After changing CCL, rebuild
  `base.<ext>` and the level images (§6.3 and §7).
- **Leftover probe image**: `l9probe.sbcl-linux64` in the Sources directory is
  a scratch image from the level9 investigation. `final-checks.sh` ignores it
  (it only looks for `base.<ext>` and `<level>.<ext>`), so it is safe to delete.

---

## 10. Status of the last runs

### 10.1 CCL (default builder, 2026-10-18)

`make base` builds `base.<ext>` (24 MB) in well under a second; on this host
`<ext>` is `ccl-linux-aarch64`.  The pre-pull run used the older explicit
`EXT=ccl-linux64`; `./final-checks.sh ccl ccl-linux64` completed
`base -> level8`:

| level | wall time |
|---|---|
| utilities | 3m38s |
| logic | 9m37s |
| level2 | 16m09s |
| level3 | 28m17s |
| level4 | 53m09s |
| level5 | 49m54s |
| level6 | 21m36s |
| level7 | 8m46s |
| level8 | 63m41s |

level9 then rejected `ALL-EQUALP-REMOVAL`
(`Proofs/level9/thm-all-equalp-removal.proof`).  That run predates the generator
fixes in the 2026-10-18 pull, so regenerate the proofs (§4) and re-check before
treating the rejection as a CCL discrepancy.  The CCL debugger backtrace printed
for that event is the `admit-theorem` error path, not a stack overflow.

### 10.2 SBCL fallback (historical, 2026-10-17)

> **Historical.**  This section records a run made before the generator fixes
> described in §5.1, so the proof-file names below no longer apply.

Checked with `./final-checks.sh sbcl sbcl-linux64`; every image is written to
the Sources directory. **The pipeline is complete: all 13 levels check.**

| level | image | result |
|---|---|---|
| base .. level8 | `level8.sbcl-linux64` | replayed earlier the same day, before the level9 fix |
| level9 | `level9.sbcl-linux64` (65 MB) | **EXIT=0**, ~8.5 min, with the then-current inlinep fix |
| level10 | `level10.sbcl-linux64` (68 MB) | **EXIT=0**, ~31 min of measured event time; slowest proof 1245 s |
| level11 | `level11.sbcl-linux64` (70 MB) | **EXIT=0**, 15,687 events, no missing proofs |
| user | `user.sbcl-linux64` (70 MB) | **EXIT=0**, 18 s (29 events on top of the 15,687 already in the level11 image) |

The whole chain `base -> ... -> user` replayed cleanly against the manifests
produced by that build.  The generator fixes now in `ACL2/interface/` supersede
the two temporary Python repair tools used for that run; they have been removed
(§5.1).

A from-scratch `make all` has not been attempted end to end on this container
with the current tools; the levels above were checked by replaying the manifests
produced by the earlier build, which is what `final-checks.sh` verifies anyway.
