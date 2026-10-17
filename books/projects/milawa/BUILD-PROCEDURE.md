# Milawa build procedure

Step-by-step instructions for building Milawa, cleaning up, and rebuilding.
Written from the working setup in this container.

---

## 1. Directory layout

| Path | What it is |
|------|-----------|
| `/home/acl2/books/projects/milawa` | **Sources directory** — contains `final-checks.sh`, `milawa-sbcl`, `milawa.lsp`, `milawa2.lsp`, and the base images (`base.sbcl-linux64`, etc.) |
| `/home/acl2/books/projects/milawa/ACL2` | **Build directory** — contains the `Makefile`, `bootstrap/`, `interface/`, `acl2-hacks/`, and `acl2-images/` |
| `/home/acl2/books/projects/milawa/Proofs` | Generated proof files, one subdirectory per level, plus `<level>.events` manifests |
| `/home/acl2/books/projects/milawa/ACL2/acl2-images` | Generated ACL2 images (`<level>-symmetry`) |
| `/home/acl2` | The ACL2 source/build tree (not git; the tracked copy is the `context/acl2` submodule in the workspace) |

Note: `/home/acl2` is the plain build tree. The version-controlled ACL2 checkout
is the `context/acl2` submodule in `/workspaces/acl2-jupyter` (branch `milawa`).

---

## 2. Levels and the image chain

Milawa builds in levels:

```
utilities -> logic -> level2 -> level3 -> level4 -> level5 -> level6
          -> level7 -> level8 -> level9 -> level10 -> level11 -> user
```

Each level produces an ACL2 image `ACL2/acl2-images/<level>-symmetry`, and the
next level is built **on top of** that image. The Makefile encodes this:

```
acl2-images/level4-symmetry: acl2-images/level3-symmetry \
                             $(PCDEPS_FOR_bootstrap__level3__level3)
```

So a change at level *N* invalidates the image for level *N* and every level
above it.

---

## 3. Prerequisites

- SBCL on `PATH` (the `milawa-sbcl` wrapper uses `sbcl`).
- The base images in the Sources directory (`base.sbcl-linux64`,
  `utilities.sbcl-linux64`, `logic.sbcl-linux64`, `level2.sbcl-linux64`,
  `level3.sbcl-linux64`).
- Enough memory. The default `milawa-sbcl` fallback is
  `--dynamic-space-size 32000 --control-stack-size 1024`, overridable via
  `MILAWA_SBCL_DYNAMIC_SPACE` and `MILAWA_SBCL_CONTROL_STACK`.

---

## 4. Building

All build commands are run from the **build directory**:

```sh
cd /home/acl2/books/projects/milawa/ACL2
```

### 4.1 Full build

```sh
make -j "$(nproc)"
```

This builds every `.mpcert` and every image up to `user-symmetry`.

### 4.2 Overriding SBCL memory/stack

`SBCL_USER_ARGS` is appended to the SBCL command line, so a later
`--control-stack-size` / `--dynamic-space-size` wins over the wrapper default:

```sh
SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make -j "$(nproc)"
```

### 4.3 Building a single book

```sh
make bootstrap/level4/clause-basics.mpcert
```

### 4.4 Building a single image

```sh
make acl2-images/level4-symmetry
```

### 4.5 Running a long build detached

Long builds should be run detached with output to a log, so the terminal is
not blocked:

```sh
nohup env SBCL_USER_ARGS="--dynamic-space-size 65536 --control-stack-size 4096" \
  make bootstrap/level4/level4.mpcert > /tmp/level4.log 2>&1 &
```

Then inspect `/tmp/level4.log` and the per-book `.out` files.

---

## 5. What the build produces

For each level:

- `ACL2/bootstrap/<level>/*.mpcert` — provisional certificates.
- `ACL2/bootstrap/<level>/*.out` — per-book build logs.
- `ACL2/acl2-images/<level>-symmetry` — the level image.
- `Proofs/<level>/` — proof files (`admit-*.proofs`, `thm-*.proof`).
- `Proofs/<level>.events` — the event manifest, serialized from the
  `thmfiles` table by `%save-events`.

---

## 6. Cleaning up for a rebuild

### 6.1 Clean a single level

To force a level to rebuild from scratch, remove its certificates, outputs,
proofs, and events file:

```sh
cd /home/acl2/books/projects/milawa/ACL2
rm -f bootstrap/level4/*.mpcert bootstrap/level4/*.out
rm -rf ../Proofs/level4
rm -f ../Proofs/level4.events
```

Then rebuild:

```sh
make bootstrap/level4/level4.mpcert
```

### 6.2 Clean a level and everything above it

Because of the image chain, if you change level *N* you must also rebuild the
images for *N+1* and up. Remove the images too:

```sh
cd /home/acl2/books/projects/milawa/ACL2
rm -f acl2-images/level4-symmetry acl2-images/level5-symmetry \
      acl2-images/level6-symmetry acl2-images/level7-symmetry \
      acl2-images/level8-symmetry acl2-images/level9-symmetry \
      acl2-images/level10-symmetry acl2-images/level11-symmetry \
      acl2-images/user-symmetry
```

### 6.3 Full clean

The Makefile has a `clean` target:

```sh
cd /home/acl2/books/projects/milawa/ACL2
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
cd /home/acl2/books/projects/milawa
./final-checks.sh sbcl linux64
```

- Argument 1 is the Lisp name (matches `milawa-<lispname>`).
- Argument 2 is the image extension (matches `base.<ext>`).

It processes levels in order (`base -> utilities -> logic -> level2 -> ... ->
user`) and stops at the first failure. It skips a level if its image already
exists, so to re-run a level you must delete its image first:

```sh
rm -f level4.linux64
```

### 7.1 Checking for missing proofs

Before running `final-checks.sh`, you can check whether an events file
references any proof file that does not exist:

```sh
cd /home/acl2/books/projects/milawa
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
  effectively requires a full rebuild.
- `final-checks.sh` only *checks* existing proofs; it does not regenerate them.

---

## 9. Known issues

- **level4 `definition-of-not`**: fixed by removing the duplicate
  `(%autoadmit definition-of-not)` from
  `bootstrap/level4/clause-basics.lisp`. See
  `ACL2/MILAWA-BUILD-AND-PROOF-GAPS.md` sections 6.13-6.17.
- **level10 `crewrite-iffp`**: aborts with "Binding stack exhausted" (SBCL's
  *binding* stack, distinct from `--control-stack-size`). Raising
  `--control-stack-size` to 4096 did not resolve it. See
  `ACL2/MILAWA-BUILD-AND-PROOF-GAPS.md` section 5.
