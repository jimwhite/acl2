# Porting ACL2 to ECL: implementation notes

Last updated: 2026-11-05
Branch: `ecl` in the ACL2 repository
Host Lisp: patched ECL 26.5.5 (`/opt/ecl-26.5.5/bin/ecl`)
Platform: Ubuntu 26.04, aarch64, 16 cores

## Status

Done (as of 2026-11-05):

- Patched ECL 26.5.5 built and installed at `/opt/ecl-26.5.5` (bytecode
  operand widening; see `ECL-MR.md`).
- `make compile LISP=/opt/ecl-26.5.5/bin/ecl` (~2m40s) and
  `make init LISP=/opt/ecl-26.5.5/bin/ecl` (~8 s) succeed.
- `./saved_acl2` starts ACL2 in **~6.5 s** (was ~17 s; see
  "Where `initialize-acl2` spends its time"), or **~5.4 s** when the
  ahead-of-time file of executable counterparts is present. It evaluates
  forms, admits recursive `defun`s, proves `defthm`s, and certifies books.
- `initialize-acl2` no longer runs the irrelevant-formals check during the
  boot-strap, which was two thirds of the startup cost. Details and the
  measurement method are below; the profiler is `ecl-tools/init-profile.lsp`.
- The executable counterparts can be compiled ahead of time: `make exec-aot`
  builds `acl2-exec-aot.fas` and the launcher uses it when it is up to date,
  which is worth another ~1.2 s of startup. See "Ahead-of-time compilation of
  the executable counterparts".
- The WebAssembly experiment was merged in (see `WASM-PORT-NOTES.md`); its
  ACL2 source changes are guarded by `:emscripten` and do not affect native
  ECL.
- Startup output is quiet (~1.5 KB instead of ~1.23 MB).
- Full `make -k -j 16 basic` on a clean tree (all book artifacts deleted,
  1486 books): **1486 certificates, 0 failures, 23 min 8 s** (1385 s) on
  2026-11-05, against ~48 minutes for the same suite on 2026-11-04, before the
  boot-strap and ahead-of-time changes. One book,
  `std/strings/char-kinds`, failed on the first pass with `Cannot open
  "acl2-status.txt"` during initialization -- a transient of the parallel run,
  not a proof failure -- and re-running the suite certified it and the three
  books that depend on it in 38 s.
- Earlier dependency-chain checks: `std/lists/append.cert`,
  `textbook/chap10/fact.cert`, `misc/records0.cert`, and parallel `cert.pl
  -j 8` runs.

Not done yet:

- Book suites beyond `basic` (full `make all`/regression; see “What’s left”).
- Quicklisp books (`shellpool` is not ported to ECL; they are skipped).
- Upstream ECL merge request (branches are pushed; the MR is not created).
- Upstream ACL2 submission: the patches work but are not yet in a form the
  ACL2 maintainers are likely to accept as-is (see “What’s left”).
- Caching or avoiding `initialize-acl2` on every startup (see below for why
  this is hard). It is now 5.7 s rather than 17.6 s, so this is much less
  pressing.

## What's left

In rough priority order.

### 1. Make the ACL2 patches acceptable upstream

Several changes are already narrowly conditionalized with `#+ecl`, but these
touch generic code paths and need review:

- `note-compile-ok` / `note-acl2-status` (`acl2.lisp`, `interface-raw.lisp`).
  The atomic-write helper uses `ext:getpid`, `random`, and
  `rename-file ... :if-exists :supersede`. An upstream-friendly version could
  use a portable "write to a fresh file and rename" helper, or only change the
  ECL branch.
- `df-call` and the `guard-is-t` case of `oneify-cltl-code-1`
  (`interface-raw.lisp`). These emit `(funcall 'fn ...)` under ECL so that
  `include-raw` redefinitions are seen.
- `compile-certified-file` (`interface-raw.lisp`) turns off
  `ext:use-direct-C-call` while compiling book files. This is the most
  intrusive change and the ~10% slowdown it implies should be measured on real
  books before proposing it. Alternatives to investigate:
  1. Patch ECL so that redefining a function invalidates or redirects existing
     direct calls (closest to correct semantics, most work).
  2. Declare `notinline` only for symbols in `logic-fns-with-raw-code` /
     `program-fns-with-raw-code` when compiling a book. This does not fix
     `xdoc/base` (the stub is compiled before the raw code is loaded), so it
     would need an additional mechanism such as recompiling affected callers
     or a per-book `declaim`.
  3. Keep the global policy change but make it opt-in with a documented
     trade-off.
- `redefine-*1*-fns-for-raw-code` (`other-events.lisp`). After `include-raw`
  replaces a definition, it redefines the `*1*` function as `(&rest args)` +
  `apply`. Upstream may prefer keeping the original formals or reusing the
  existing `*1*` regeneration machinery.
- Add ECL to ACL2's documentation/manual wherever host Lisps are listed, and
  check any host-suitability tables or version checks (for example
  `:doc host-lisp`, the installation notes, and `check-suitability-for-acl2`).
- Exercise `save-exec`, trust-tag heavy books, and ACL2(p) paths; none of these
  have been tested yet.

### 2. Run more of the book suite

`basic` is a large but limited subset. The next validation steps are:

- `make -k -j 16 all` (or the regression target used by the project) and
  inventory failures. Expect host-specific raw code (`#+sbcl`, `#+ccl`, ...),
  memoization, and parallel books to be the usual suspects.
- Decide whether to port Quicklisp's `shellpool` to ECL. Until then,
  `uses-quicklisp` books are skipped (`tools/oracle-timelimit` is the one that
  pulls Quicklisp into `basic`).

### 3. Startup and performance

Startup is 6.5 s, or 5.4 s with the ahead-of-time file described below, of
which `initialize-acl2` is 5.7–6.3 s (4.3–5.0 s with it). The measured
breakdown is in "Where `initialize-acl2` spends its time" below: 2.0 s for the
first pass over the sources, 1.4 s for the second pass, and 1.26 s for the
single `(comp-fn :exec ...)` that ends the boot-strap. The two remaining
levers are therefore:

- Ahead-of-time compilation of the `*1*` functions. Done for ECL: it removes
  the 1.26 s write/compile/load step, leaving 0.017 s, and takes startup to
  5.0–5.5 s. `make exec-aot` builds the file; the launcher ignores it when it
  is stale. See "Ahead-of-time compilation of the executable counterparts".
- An image, which removes all of the boot-strap.

- Re-measure proof performance with `ext:use-direct-C-call` disabled for book
  files, and decide whether a narrower fix is worth the engineering.
- Consider benchmarking ACL2 on ECL against CCL/SBCL on the same books to know
  where ECL stands.

### 4. ECL merge request

The branches are ready but the upstream MR has not been created. Before
opening it, decide between uniform 32-bit operands and a long-jump encoding,
and run the GitLab CI pipeline on `develop`. See `ECL-MR.md`.

### 5. Repository hygiene

- `.devcontainer/` and `acl2-ecl.code-workspace` are untracked. Decide whether
  they belong in the branch.
- The port is currently a series of commits on `ecl`; an upstream submission
  will probably want a cleaner split (infrastructure, raw-code handling,
  book-build fixes, docs).

## Quick start

Build ECL 26.5.5 with the bytecode-operand patch:

```sh
cd /tmp/ecl-src                 # tag 26.5.5 plus patch
./configure --prefix=/opt/ecl-26.5.5
make -j16
sudo make install
```

Build ACL2:

```sh
cd /workspaces/acl2-ecl
make clean-all
make compile LISP=/opt/ecl-26.5.5/bin/ecl   # ~2 min 40 s on 16 cores
make init    LISP=/opt/ecl-26.5.5/bin/ecl   # ~8 s
```

Run:

```sh
cd /workspaces/acl2-ecl
./saved_acl2
```

Certify a book:

```sh
cd books
./build/cert.pl -j 8 --acl2 /workspaces/acl2-ecl/saved_acl2 std/lists/append.cert
```

When switching ECL versions, delete stale book artifacts first. `cert.pl`
does not notice that the host Lisp changed, and old native `.fas` files can
cause bogus failures such as:

```
The value :CREATE is illegal for :LOAD-COMPILED-FILE
```

The cleanup used here was:

```sh
find books -name '*.cert' -delete
find books -name '*.fas'  -delete
find books -name '*.port' -delete
find books -name '*.o'    -delete
```

## How `saved_acl2` works on ECL

ECL 24.5/26.5 has no equivalent of GCL's `si:save-system` or SBCL's
`sb-ext:save-lisp-and-die`; there is no way to dump the initialized ACL2
state. Therefore `save-acl2-in-ecl` (in `acl2-init.lisp`) writes:

1. `nsaved_acl2.lsp`, a Lisp bootstrap file.
2. `nsaved_acl2`, a shell script that runs:

```sh
exec /opt/ecl-26.5.5/bin/ecl -norc -load "$THISSCRIPTDIR/nsaved_acl2.lsp" -- "$@"
```

The bootstrap file:

```lisp
(setq *load-verbose* nil)
(defparameter cl-user::*acl2-ecl-invocation-dir* (ext:getcwd))
(ext:chdir (make-pathname :name nil :type nil :defaults *load-pathname*))
(ext:set-limit 'ext:frame-stack 262144)
(load "init.lisp")
(in-package "ACL2")
(load-acl2)
(defparameter cl-user::*acl2-ecl-real-standard-co*
  (common-lisp:get 'acl2-output-channel::standard-character-output-0
                   *open-output-channel-key*))
(setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                       *open-output-channel-key*)
      (make-broadcast-stream))
(ext:install-bytecodes-compiler)
(unwind-protect
    (let ((*standard-output* (make-broadcast-stream))
          (*error-output* (make-broadcast-stream))
          (*trace-output* (make-broadcast-stream)))
      (ACL2::INITIALIZE-ACL2 (QUOTE ACL2::INCLUDE-BOOK)))
  (setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                       *open-output-channel-key*)
        cl-user::*acl2-ecl-real-standard-co*))
(ext:install-c-compiler)
(ext:chdir cl-user::*acl2-ecl-invocation-dir*)
(acl2-default-restart)
```

Important details:

- The caller's working directory is saved and restored. The books build system
  expects ACL2 to run in the book directory (for `.port` files, certificates,
  and relative paths). Earlier versions of this launcher `cd`'d permanently to
  the ACL2 directory, which broke `features.sh` and `cert.pl`.
- `init.lisp` and `load-acl2` run with the ACL2 source directory as the current
  directory, so all relative file names in the sources resolve.
- `initialize-acl2` re-LDs the ACL2 sources, so the ECL "image" is
  directory-dependent: the `.lisp` sources and `.fas` files must remain beside
  `saved_acl2`.
- The bytecodes compiler is installed for initialization only. It makes
  bootstrapping much faster than invoking gcc for every admitted function.
  The native C compiler is restored before the ACL2 loop starts, so books and
  user functions compile to native `.fas` files.
- `acl2-default-restart` was extended with `#+ecl (eval '(lp))`.
- Initialization normally prints over a megabyte of output on every startup.
  The bootstrap binds ECL's standard streams to a broadcast stream, points the
  `standard-character-output-0` channel at a broadcast stream, and sets
  `*load-verbose*` to `nil`; the real channel stream is restored before the
  banner and the ACL2 loop. Output drops to ~1.5 KB with no change in time.
  This matters for logs: `cert.pl` stores each book's output in a `.out` file.

### Why startup is not cached

Without an image dump there is no cheap way to skip initialization. The
resulting state is not just data: it contains thousands of ACL2 events, and the
corresponding `*1*` functions are compiled code that must be loaded or rebuilt.
ACL2(h)'s serializer can persist a hons space and parts of the world, but it
does not persist compiled Lisp functions, and the bootstrap would still have to
process the source events. The practical mitigation is parallelism: each book
pays ~5.3 s of startup, but `cert.pl -j N` hides it behind useful work.


- ECL package locking:
  - `(require :package-locks)`.
  - `(ext:unlock-package "COMMON-LISP")` before reading the symbol list from
    `axioms.lisp`, and again after `*compiled-file-extension*` is computed,
    because loading ECL's compiler (`cmp`) re-locks `COMMON-LISP`.
  - `with-suppression` uses `ext:with-unlocked-packages ("COMMON-LISP")` for
    ECL.
- Character encoding:
  - `acl2-set-character-encoding` sets
    `ext:*default-external-format*` to `:latin-1`. ECL defaults to UTF-8, but
    ACL2 assumes ISO-8859-1 (see `acl2-characters`).
- Dispatch macro characters:
  - ECL predefines `#Y` and `#Z`; they are safe to redefine in ACL2's private
    readtable.
  - ECL stores function objects in the readtable. Allow replacing an existing
    function-valued dispatch macro, and compare a symbol argument against the
    symbol's function.
- `initialize-state-globals`: recognize `#+ecl :ecl` as `host-lisp`.
- `exit-lisp`: add `#+ecl (if status-p (ext:quit status) (ext:quit))`.
  Without this, `(exit 43)` returned to ECL instead of terminating, which made
  `cert.pl` report `**CERTIFICATION FAILED**` even though the certificate was
  written.
- `acl2-fns` startup:
  - For ECL, reuse an up-to-date `acl2-fns.fas` instead of deleting and
    recompiling it on every startup. Recompiling on every ACL2 invocation is
    slow and makes parallel book builds race on the same `.c`, `.o`, and `.fas`
    files.
  - When compilation is needed, compile to a process-specific file
    (`acl2-fns-<pid>.fas`) and move it into place with `mv -f`, so concurrent
    ACL2 processes do not clobber each other.
- `note-acl2-status`: under ECL, write `acl2-status.txt` atomically (temporary
  file plus `rename-file` with `:if-exists :supersede`). Every ACL2 invocation
  runs `initialize-acl2`, which deletes and rewrites this file with
  `:INITIALIZED`; during a parallel books build that raced with `load-acl2`'s
  read of the token and produced spurious "Please run (COMPILE-ACL2)" errors.

### `acl2-fns.lisp`

- `getenv$-raw`: use `ext:getenv`.
- `without-interrupts` / `with-interrupts`: use `mp:without-interrupts` /
  `mp:with-interrupts`.
- `our-truename`: ECL's `namestring` returns a non-simple string (an array with
  a fill pointer). ACL2 requires simple strings, so the namestring is copied
  with `(common-lisp::coerce ... 'simple-string)`. `common-lisp::coerce` is used
  because ACL2's own `coerce` only accepts `string` and `list`.

### `acl2-init.lisp`

- `system-call`: `ext:system`. ECL returns the raw wait status; decode it with
  `(ash code -8)` when it is at least 256.
- `system-call+`: `ext:run-program ... :input nil :output :stream
  :error :output :wait t`; read lines from the returned stream and use the
  second value as the exit code.
- `getpid$`: `ext:getpid`.
- `save-acl2-in-ecl`, `save-exec-raw`, and the `save-acl2` dispatcher as
  described above.
- `acl2-default-restart`: enter the ACL2 loop with `(eval '(lp))` for ECL.
- `save-acl2-in-ecl` raises ECL's frame-stack limit to 262144 frames with
  `(ext:set-limit 'ext:frame-stack 262144)`. The default of 2048 frames is
  exhausted by `defconst` of a large quoted constant (`misc/getprop`) and by
  proof-builder work (`system/apply/apply-prim`), producing
  "FRAME-STACK overflow at size 2048".

### `axioms.lisp`

- `setenv$`: use `si::setenv` for ECL. `(setf (ext:getenv ...) ...)` does not
  exist in ECL.
- `gc$-fn`: `#+ecl (apply 'ext:gc args)`.

### `hons-raw.lisp`

- `hl-with-lock-grabbed`: ECL's reader mishandles the adjacent
  `#-`/`#+` conditional idiom

  ```lisp
  #-(or ccl gcl)
  #+gcl (declare ...)
  #-(or ccl gcl)
  (error ...)
  ```

  and reports an unmatched right parenthesis. The ECL branch is now a single
  `#-(or ccl gcl) (progn (declare ...) (error ...))` form.

### `interface-raw.lisp`

- Bootstrap batch compilation:
  - `compile-file-for-acl2-bootstrap` wraps `compile-file`. If ECL's bytecodes
    compiler is active (`:ecl-bytecmp` is in `*features*`) and compilation
    signals an error, ACL2 switches to the native compiler, recompiles the
    batch, then restores the bytecodes compiler. This is a generic safety net
    for stock ECL and replaces hardcoded exclusions for `apply$-prim` and
    `ev-fncall-rec-logical`.
  - Caveat: the native compiler is extremely slow on very large batches, so
    this is a fallback, not a performance path.
- Cleanup of compiled bootstrap files:
  - When the bytecodes compiler is active, `compile-file` writes `.fasc`, while
    `*compiled-file-extension*` remains `fas`. The cleanup now tries both
    extensions. Without this, ACL2 tries to delete a nonexistent `.fas` and
    aborts the `comp-fn` event after successfully loading the `.fasc`.
- `initialize-acl2`: write `acl2-status.txt` via `note-acl2-status` (see
  `acl2.lisp`) instead of deleting and rewriting it non-atomically.
- `df-call` and the `guard-is-t` case of `oneify-cltl-code-1`: under ECL, emit
  `(funcall 'fn ...)` rather than `(fn ...)` when a `*1*` function calls the raw
  Lisp definition, so that a later redefinition (as done by `include-raw`) is
  seen.
- Book compilation (`compile-certified-file`): under ECL, bind
  `ext:use-direct-C-call` to `nil` while calling `compile-file`, and restore it
  afterwards. ECL otherwise compiles calls to functions defined earlier in the
  same file as direct C calls, so an `include-raw` definition loaded at run
  time would be ignored by already-compiled callers. This is what makes
  `xdoc/defxdoc-raw` work: `defxdoc-raw-after-check` is compiled in
  `xdoc/base` against the stub `defxdoc-raw-fn`.

### `other-events.lisp`

- `redefine-*1*-fns-for-raw-code`: after `include-raw` smashes definitions,
  replace the `*1*` function of each affected guard-verified `:logic` function
  by `(lambda (&rest args) (apply 'fn args))`, so that logical evaluation uses
  the new raw definition. This is needed on ECL because `*1*` functions can
  have been compiled with a direct call to the previous definition.

## ECL API mapping

| ACL2 use | ECL API |
| --- | --- |
| Run a shell command, ignore output | `ext:system` (returns raw wait status) |
| Run a command and capture output | `ext:run-program` |
| Process id | `ext:getpid` |
| Environment variable | `ext:getenv` |
| Garbage collection | `ext:gc` |
| Exit process with status | `ext:quit` |
| Block/unblock interrupts | `mp:without-interrupts`, `mp:with-interrupts` |
| Unlock a package | `ext:unlock-package` after `(require :package-locks)` |
| Unlock packages temporarily | `ext:with-unlocked-packages` |
| Bytecode compiler | `ext:install-bytecodes-compiler` |
| Native compiler | `ext:install-c-compiler` |
| Current directory | `ext:getcwd`, `ext:chdir` |
| Feature for bytecodes compiler | `:ecl-bytecmp` |

## Gotchas and lessons

- ECL's `namestring` is not a simple string. Any ACL2 pathname code that
  assumes simple strings must copy the result.
- Loading ECL's compiler module (`cmp`) re-locks `COMMON-LISP`; unlock after it
  is loaded, not only before.
- ECL's `ext:system` does not return a shell-style exit code; decode the wait
  status.
- ECL's readtable stores function objects, not the symbols passed to
  `set-dispatch-macro-character`.
- ECL's `#Y`/`#Z` conflict with ACL2's serialization readers; they can be
  replaced in ACL2's private readtable.
- Adjacent `#-`/`#+` read-time conditionals are not portable. Use a single
  conditional whose body is a `progn`.
- ECL's bytecode compiler writes `.fasc`, whereas the native compiler writes
  `.fas`. `*compiled-file-extension*` is computed once, before the bytecodes
  compiler is installed, so code that deletes or loads compiled files must
  tolerate both.
- ECL 24.5 and 26.5 both limit bytecode jump offsets to `MAX_OPARG` (0x7FFF).
  ACL2's `apply$-prim` and `ev-fncall-rec-logical` executable counterparts
  exceed that. Options:
  1. Patch ECL to widen operand slots (current proposal; see `ECL-MR.md`).
  2. Add long-jump opcodes that index 32-bit deltas in a side table (more
     compact, more complex).
  3. Fall back to the native compiler on error (implemented in ACL2 as a
     safety net; slow for large batches).
- `exit-lisp` must really terminate the process for the books build system.
  `cert.pl` relies on the ACL2 process exiting with status 43 after a
  successful certification.
- Parallel ACL2 invocations must not share writable compiled artifacts. The
  `acl2-fns.fas` quick-start check and process-specific compile output fix the
  race seen with `cert.pl -j`.
- The books build system invokes ACL2 from the book's directory. Never `cd`
  permanently in the launcher; save and restore the working directory.
- `features.sh` must be run from `books/build` with `ACL2` pointing at the
  built `saved_acl2`:

  ```sh
  cd books/build
  ACL2=/workspaces/acl2-ecl/saved_acl2 STARTJOB=/bin/bash ./features.sh
  ```

  It produces `Makefile-features` with `ACL2_HOST_LISP := ECL` and
  `ACL2_COMP_EXT := fas`.
- ECL's bytecodes compiler and native compiler have very different performance
  characteristics. Use bytecodes for bootstrapping, native for books and user
  code.
- ECL's C compiler emits direct C calls for functions defined earlier in the
  same file. Redefining such a function later (which `include-raw` does) has no
  effect on the already-compiled callers. Compile book files with
  `ext:use-direct-C-call` off, and make `*1*` functions use `funcall`.
- ECL's default frame stack (2048 frames) is far too small for ACL2; raise it in
  the launcher.
- `initialize-acl2` rewrites `acl2-status.txt` on every ECL startup, so
  concurrent invocations must not see a truncated file; write it atomically.

## Building the books

From `books/`, with `saved_acl2` built:

```sh
make -k -j 16 basic ACL2=/workspaces/acl2-ecl/saved_acl2
```

or for individual books:

```sh
./build/cert.pl -j 16 --acl2 /workspaces/acl2-ecl/saved_acl2 std/lists/append
```

Notes:

- Delete `*.cert`, `*.fas`, `*.fasc`, `*.port`, and `*.o` after rebuilding ACL2.
  Certificates are not automatically invalidated when ACL2 changes, and stale
  `.fas` files can produce confusing errors (for example, a bogus
  `:LOAD-COMPILED-FILE :CREATE` failure).
- Quicklisp books are skipped by default (`USE_QUICKLISP` is ignored for ECL,
  as for GCL) because Quicklisp's `shellpool` says "Shellpool has not yet been
  ported to this Lisp".
- Book files are compiled with ECL's `use-direct-C-call` policy disabled. This
  costs roughly 10% in call-heavy code but is required for `include-raw`'s
  run-time redefinitions to take effect. ACL2's own sources are still compiled
  with direct calls.

A clean run of `make -k -j 16 basic` (16 cores, all book artifacts deleted
first) on 2026-11-04 built 1486 certificates with no failures in about 48
minutes. The books that failed before the fixes above are now certified:
`misc/getprop`, `system/apply/apply-prim` (frame stack), `tools/time-dollar-with-gc`
(status race), `std/io/read-string-tests`, `std/io/serialize-tests`,
`xdoc/defxdoc-raw` (raw-code redefinition). `quicklisp/*` is skipped.

## Measurements

Environment as above, one process at a time, with initialization output
suppressed as in `saved_acl2`.

- ACL2 startup from `saved_acl2` to the first prompt: **6.4–6.8 s** (three
  runs), of which `load "init.lisp"` is ~0.1 s, `load-acl2` ~0.7 s, and
  `initialize-acl2` 5.7–6.3 s. Before the boot-strap change described below,
  the same measurement was 16.8–17.4 s.
- Certifying a trivial book (three `defthm`s, no dependencies) takes
  6.7–6.8 s, essentially the startup alone; it was 16.7–17.0 s before.
- Bytecode functions in the built ACL2 image: 6,772.
- Bytecode array memory with 32-bit slots: ~6.95 MB; with 16-bit slots:
  ~3.47 MB (estimated by halving the vector lengths).
- `std/lists/append.cert` fresh dependency chain with `-j 8`: ~227 s.
- Simple `cert.pl` book with no dependencies: ~27 s before the boot-strap
  change (expect ~15 s now; not re-measured).

### Where `initialize-acl2` spends its time

Measured with `ecl-tools/init-profile.lsp` (see "Profiling initialization"),
which wraps `ld-fn` and the two `compile-uncompiled-*` functions from outside
and accumulates seconds and call counts by label.

| phase | before | after |
| --- | --- | --- |
| pass 1: `ld` of the system source files (all of `*acl2-files*` except the pass-2 and `-raw` files) | 11.8 s | 2.0 s |
| pass 2: `ld` of the pass-2 forms | 1.4 s | 1.4 s |
| `(comp-fn :exec ...)`: write, compile, load the `*1*` definitions | 1.35 s | 1.26 s |
| outside those `ld` calls | 0.7 s | 1.1 s |
| **`initialize-acl2` total** | **15.3 s** | **5.8 s** |

The `*1*` step writes about 1,600 definitions (a 1.5 MB `TMP1.lisp`), which
takes ~0.2 s, compiles them with the bytecodes compiler in ~1.0 s, and loads
them in ~0.05 s. So compiling the executable counterparts was never the main
cost of the boot-strap: there are fewer of them than the "~8,600" estimated
earlier, and bytecode compilation of small functions is fast (about 0.6 ms
each on average here).

Most of the old pass-1 cost was ACL2's own analysis of each `defun` event.
Sampling the running process with `gdb` (`bt 45`, 374 samples at ~0.2 s
intervals) put at least a third of the samples inside `chk-irrelevant-formals`
(much of the remainder was `ecl_equal` recursion on its clique-alists, which
the 45-frame backtrace did not always reach past). The check closes a
clique-alist by iterating `relevant-posns-clique-recur`, which uses
`assoc-equal` on the growing clique-alist on every round, so its cost is
super-linear in the size of the clique. The rest of the pass-1 time was
`translate11`, `type-set-and-returned-formals`/`normalize`, the reader, and
about 10% in ECL's bytecode compiler.

### The boot-strap no longer checks irrelevant formals

`chk-irrelevant-formals` (`defuns.lisp`) now returns immediately when
`boot-strap-flg` is set, mirroring the existing skip of
`chk-badged-quoted-subfunctions` in the same routine. The check is a
user-interface aid for catching typos, not a soundness check, and the system
sources are known to be free of irrelevant formals. It still applies to user
code in the loop: `(set-ignore-ok t)` followed by `(defun f2 (x y) x)` still
reports "The second formal of F2, Y, is irrelevant...". Delete the new `cond`
branch to check the system sources again.

This is not ECL-specific, so it should speed up the build on any host. It is
worth more on ECL than elsewhere because every ACL2 invocation (each book
certified by `cert.pl`, for example) pays for the boot-strap: re-certifying
all 1486 books took 23 min instead of 48, and 1486 invocations times the
~13.7 s saved divided by 16 cores accounts for essentially all of the
difference. The before figure is not available for the ahead-of-time file
separately, since it landed in the same working tree.

### Ahead-of-time compilation of the executable counterparts (prototype)

The executable counterparts (the `*1*` functions) of all `:logic` mode
functions are bytecode in the standard build: the single `(comp-fn :exec ...)`
at the end of the boot-strap writes about 1,600 definitions to `TMP1.lisp`,
compiles them with the bytecodes compiler, and loads them. That step is 1.26 s
of the 5.8 s that `initialize-acl2` takes. If the same definitions are compiled
ahead of time with ECL's C compiler and merely loaded, the step costs 0.017 s.

The mechanism is in place. `*acl2-*1*-aot-file*` (`interface-raw.lisp`), when
set, makes `compile-uncompiled-*1*-defuns` load that file during the boot-strap
instead of scanning the world, regenerating the definitions with
`oneify-cltl-code`, writing `TMP1.lisp`, compiling it, and loading it.
`acl2-*1*-aot-file`, in the same file, supplies a value only when the compiled
file is up to date: newer than every source in `*acl2-files*` and
`acl2-fns.lisp`, with a stamp recording the host Lisp, itself no newer than
the compiled file. The launcher that `save-acl2-in-ecl` writes calls it.

To produce the file, after `make compile`:

```sh
make exec-aot LISP=/opt/ecl-26.5.5/bin/ecl
```

(`ecl-tools/make-exec-aot.lsp`, which runs a full `initialize-acl2`, keeps the
`TMP1.lisp` that the boot-strap writes, renames it to `acl2-exec-aot.lisp`,
compiles it with the C compiler, and writes `acl2-exec-aot.stamp`.)

Measured, three runs each:

| | without AOT | with AOT |
| --- | --- | --- |
| `(comp-fn :exec ...)` step | 1.26 s | 0.017 s |
| `initialize-acl2` | 5.84–6.08 s | 4.32–4.97 s |
| startup to prompt (`saved_acl2`) | 6.41–6.78 s | 5.29–5.50 s |

Costs and caveats:

- The file takes the C compiler about 30 s to produce and is 8.6 MB, against
  1.7 MB for the bytecode `TMP1.fasc`. Loading it is cheap because ECL maps a
  compiled FASL rather than reading it eagerly.
- It must be produced by a full initialization of these sources on this host
  Lisp, and compiled by that host; like `acl2-fns.fas`, it is not portable. A
  file that is out of date in either respect is ignored, so the worst case is
  the slow path and a `make exec-aot` to get the fast one back. Verified: after
  `touch basis-a.lisp` startup went back to 6.4–6.7 s, and so it did when the
  stamp was changed to name another host Lisp; rebuilding the file restored
  5.3 s.
- It covers the `:logic` mode functions that go into `TMP1.lisp`. The
  `:program` mode counterparts are compiled one at a time during the
  boot-strap; together they cost about 0.1 s, so they are not worth including.
- Checks run: `initialize-acl2` still passes `check-acl2-initialization`
  (which evaluates the built-in constants, exercising the counterparts); a
  `defconst` computed by a counterpart, an inductive `defthm`, the
  user-level irrelevant-formals error, and `certify-book` on a small book all
  behave as before.

What it does *not* buy: the prover's own functions (`rewrite`, `type-set`,
`ev-fncall`, ...) are compiled to C from the sources, not bytecoded, so
rewriting is unaffected. The counterparts are what `ev-fncall` runs, so the
gain there is in evaluation — `defconst`, `make-event`, guard checking, clause
processors, and the boot-strap itself — not in the rewrite loop. (This
corrects an earlier guess in `WASM-PORT-NOTES.md`.)

### Profiling initialization

`ecl-tools/init-profile.lsp` reproduces what `nsaved_acl2.lsp` does — load
`init.lisp`, load the compiled sources, install the bytecodes compiler — and
then calls `initialize-acl2` with timers installed:

```sh
/opt/ecl-26.5.5/bin/ecl -norc -load ecl-tools/init-profile.lsp
```

It writes `ecl-init-profile.txt` with one line per label: total seconds, call
count, label. `ACL2_INIT_PROFILE_KEEP_TMP=1` keeps the generated `TMP*.lisp`
and compiled files, and `ACL2_INIT_PROFILE_VERBOSE=1` lets initialization print
normally instead of through a broadcast stream. `ACL2_INIT_PROFILE_EXTRA` is a
comma-separated list of ACL2 function names to time as well, which is the way
to look inside pass 2 in the wasm build, where every call goes through the
function cell; in a native build such calls are often direct C calls and
cannot be intercepted.

The same script runs in the WebAssembly build (see `WASM-PORT-NOTES.md`):

```sh
./wasm/acl2-wasm-compile      # only needed after changing ACL2 sources
ACL2_WASM_DRIVER=ecl-tools/init-profile.lsp ./wasm/acl2-wasm
```

The timers go on `ld-fn`, `compile-uncompiled-defuns` and
`compile-uncompiled-*1*-defuns` because each of those is called from a
different file than the one that defines it; such calls go through the
symbol's function cell and can therefore be replaced at run time. Calls to
`compile`/`compile-file`/`eval` are mostly *direct* C calls, or internal to the
evaluator, and so are invisible to symbol wrapping — that is why the earlier
attempt to time `compile` captured only a small fraction of the work. To look
inside that code, attach a debugger to the running process and sample stacks;
`gdb -p $pid -batch -ex "bt 45"` in a loop is enough, and 374 samples were
sufficient to identify the hot path.

## Useful debugging commands

Check ECL features and compiler state:

```lisp
(member :ecl-bytecmp *features*)
(member :ieee-floating-point *features*)
```

Check a function's bytecode size:

```lisp
(multiple-value-bind (lex vec) (si::bc-split (symbol-function 'fn))
  (declare (ignore lex))
  (length vec))   ; bytes; divide by 4 for 32-bit slots
```

Run a saved ACL2 with a script:

```sh
./saved_acl2 < /tmp/test.lsp
```

Inspect the generated launcher after `make init`:

```sh
cat saved_acl2
cat nsaved_acl2.lsp
```

## Work log

ACL2 repository, branch `ecl` (pushed to `origin/ecl` at `2d307edf78`):

| Commit | Contents |
| --- | --- |
| `6a41b44d0d` | Core port: packages/readtable/encoding, host API (`ext:system`, `getenv`, `quit`, interrupts, `namestring`), ECL launcher, bootstrap compilation fallback |
| `b974861b25` | `ECL-PORT-NOTES.md` and `ECL-MR.md` |
| `cea3e4cd38` | Quiet initialization (~1.23 MB to ~1.5 KB) |
| `cb4794f92a`, `48d69940f5` | Startup timing and rationale for not caching it |
| `9937f90c96` | Frame stack, status-file race, `include-raw`/direct-call fixes, `setenv$`, Quicklisp skip |
| `757ec5f2ee`, `2d307edf78` | Documentation of the book-build fixes and the clean `basic` result |
| `a0da110269` | Merge of the WebAssembly experiment (`WASM-PORT-NOTES.md`, `wasm/`); its ACL2 source changes are `:emscripten`-only |
| `13e73966e5` | `ecl-tools/init-profile.lsp`: timing profile of `initialize-acl2` |
| `6baeefb5b4` | Skip `chk-irrelevant-formals` during the boot-strap: startup 17 s to 6.5 s |

ECL fork (`jimwhite/ecl`):

| Branch | Base | Commit | Purpose |
| --- | --- | --- | --- |
| `widen-bytecode-operands` | `develop` | `cb1e2e84` | Upstream MR branch |
| `widen-bytecode-operands-26.5.5` | tag `26.5.5` | `51b3f4d5` | Release-line branch |

## Resuming

Current environment (as of 2026-11-05):

- Patched ECL installed at `/opt/ecl-26.5.5`; `/usr/bin/ecl` is the stock
  24.5.10 and must not be used for ACL2.
- ACL2 sources at `/workspaces/acl2-ecl`, branch `ecl`.
- `books/` contains the certificates from the clean `basic` run; delete them
  before comparing builds (see below).
- Sources for the ECL build were under `/tmp/ecl-src`; if that is gone, clone
  the fork branch and rebuild/reinstall:

  ```sh
  git clone -b widen-bytecode-operands-26.5.5 \
      git@gitlab.com:jimwhite/ecl.git /tmp/ecl-src
  cd /tmp/ecl-src
  ./configure --prefix=/opt/ecl-26.5.5
  make -j16
  sudo make install
  ```

- `make clean-all` in `/workspaces/acl2-ecl` removes the generated ACL2 `.fas`
  files and `saved_acl2`; a full rebuild after reinstalling ECL is `make
  clean-all`, then `make compile` and `make init` as above.

Rebuild ACL2 after changing ACL2 sources:

```sh
make -C /workspaces/acl2-ecl compile LISP=/opt/ecl-26.5.5/bin/ecl
make -C /workspaces/acl2-ecl init    LISP=/opt/ecl-26.5.5/bin/ecl
```

Run the clean `basic` build:

```sh
cd /workspaces/acl2-ecl/books
find . \( -name '*.cert' -o -name '*.cert.out' -o -name '*.fas' \
          -o -name '*.fasc' -o -name '*.port' -o -name '*.o' \) -delete
make -k -j 16 basic ACL2=/workspaces/acl2-ecl/saved_acl2 \
  > /tmp/basic-ecl.log 2>&1; echo BASIC_EXIT=$?
```

Scan the result for failures:

```sh
grep -a 'CERTIFICATION FAILED' /tmp/basic-ecl.log
grep -a 'make: \*\*\*'        /tmp/basic-ecl.log
```

If ECL itself is rebuilt or a different ECL is installed, do a full ACL2
rebuild (`make clean-all` first) and delete all book artifacts, as above.
Certificates do not record the host Lisp version.
