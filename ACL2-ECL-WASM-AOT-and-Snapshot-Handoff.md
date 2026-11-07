# ACL2 on ECL/Wasm: AOT compilation and initialized-state restoration

Coding-agent handoff — November 5, 2026

## Status update — November 7, 2026

**Workstream A is done for books and for the executable counterparts, and wrong
for ACL2's own sources.**  Evidence and measurements are in `WASM-PORT-NOTES.md`;
the short version:

- AOT here produces *loadable side modules*, not static libraries:
  `wasm/aot-book.sh` compiles a Lisp file for the wasm target with the host ECL
  from the same source tree, and the wasm ECL `dlopen`s the result.  This works
  for a book's expansion file (the practical case) and for `acl2-exec-aot.lisp`
  (the `*1*` counterparts, 3.1 MB of module, 331.8 s -> 310.6 s of start-up).
- Validated: `(include-book "textbook/chap10/fact")` 0.03 s with no warning;
  500 x `(fact 500)` 0.39 s versus 0.747 s for the bytecode file; the
  certificate is unchanged because `.cert` hashes the source and the expansion,
  not the compiled file.
- In a browser: `wasm/web/dylink.html` loads such a module in the page in 0.4 s.
  So the *loading* half of "certified book in a browser" is proven.
- **Open:** AOT of ACL2's own 42 source files loads and runs and cuts the
  visible boot strap from 312 s to ~20 s, but `initialize-acl2` then fails at
  the first `verify-termination-boot-strap` with "X is not of type CONS", X
  varying between runs.  Bisecting localizes it to `rewrite.lisp` alone
  (6 runs, 20-90 s each); ruled out: `-O0` vs `-O2`, `(safety 3)`, direct C
  calls, and fixnum/inline declarations.  It is allocation- and heap-size
  dependent, which points at the collector or address layout, but a direct
  probe of stack-root scanning (a live object held in a local across a forced
  GC, in compiled module code) **passed**, so the simple form of that
  hypothesis is not confirmed.  This is the next thing to resolve.

**Workstream B: one measurement changes the plan for the browser.**  The
post-boot-strap linear memory was measured at ~720 MB, which is not shippable
to a page: capturing `HEAPU8` remains the shortest route for Node/self-hosted
use, but the page-suitable variant is the ACL2-level world image (serialize of
`(w state)` is 21.7 MB, ~5 MB gzipped), which is fast (1.78 s to the prompt
natively) but still not sound-equivalent.

And the constraint that makes this urgent rather than cosmetic: ACL2 cannot
boot in a page *at all* today.  The interpreted boot strap needs 128-512 MB of
V8 stack, and a page cannot raise it.  So "ACL2 in a browser" needs either the
source AOT above (which removes the boot strap from the page, and with it the
stack requirement) or a restored base; startup *speed* is the secondary issue.

## Objective

Build and distribute a ready-initialized ACL2 running on ECL/WebAssembly. Users should not repeat `initialize-acl2` on every startup. Compile the prover to actual Wasm ahead of time, initialize the target runtime once on the build machine, and capture enough state to restore it in a fresh browser or Node instance.

This is an engineering proposal based on the port notes and ECL documentation, not a tested ECL snapshot implementation. Investigate the runtime details and report evidence rather than treating the sketch as established correctness.

## Starting evidence

Read the current repository instructions and these files before making changes; branch contents may have advanced since this review:

- [WASM-PORT-NOTES.md, ecl](https://github.com/jimwhite/acl2/blob/ecl/WASM-PORT-NOTES.md)
- [ECL-PORT-NOTES.md, ecl](https://github.com/jimwhite/acl2/blob/ecl/ECL-PORT-NOTES.md)
- [WASM-PORT-NOTES.md, ecl-world-image](https://github.com/jimwhite/acl2/blob/ecl-world-image/WASM-PORT-NOTES.md)
- [wasm/acl2-wasm.lsp](https://github.com/jimwhite/acl2/blob/ecl/wasm/acl2-wasm.lsp)
- [wasm/build-ecl-wasm.sh](https://github.com/jimwhite/acl2/blob/ecl/wasm/build-ecl-wasm.sh)

The reviewed notes report about 361 seconds to the Wasm ACL2 prompt, with approximately 352 seconds in initialization. The current Wasm build uses `.fasc` bytecode for ACL2. Native measurements distinguish the cost of interpreting ACL2 from the additional cost of running ECL's interpreter in Wasm.

The world-image branch reports a small successful Emscripten memory-copy probe, but not successful full ECL restoration. Its ACL2 world replay reaches the prompt quickly natively, but loses fast-alist registrations and fails an apply$ book inclusion. Missing attachment bookkeeping is a hypothesis for the latter, not a demonstrated root cause. These failures do not establish that changing memory addresses prevented restoration.

## Architecture

| Phase | Execution environment | Result |
| --- | --- | --- |
| Cross-compile ACL2 through Lisp → C → Wasm | Native ECL and Emscripten on the builder | Target Wasm module with compiled prover functions |
| Boot ECL and initialize ACL2 | That target Wasm running on the builder | Initialized target heap and runtime state |
| Return fully to the host, then capture | Build-time Wasm host | Snapshot tied to the exact target module |
| Instantiate, restore, reconnect resources | Browser or Node | ACL2 ready for new input |

Capture the **target Wasm instance**, not the native ECL compiler process. Native and Wasm builds differ in pointer width, fixnum range, object representation, and compiled-function references. Transferring a native heap would require a different, object-level conversion design.

Start with a Wasm module plus a state file and a manifest. Embedding initialized memory in Wasm data segments can be evaluated later. Neither packaging format automatically captures JavaScript-side resources.

## Workstream A: actual AOT compilation

ECL already documents host-side cross-compilation of Lisp using the target build's `target-info.lisp`. The Wasm tutorial demonstrates compiling object files/static libraries and linking them into the Wasm application. `--with-cmp=no` on the target does not prohibit this build-time operation.

Investigate the exact supported API in the pinned ECL version. The documented pattern uses `c:read-target-info`, a compilation target supplied to `compile-file` or `with-compilation-unit`, `:system-p t`, and a static-library initialization function registered through `ecl_init_module`.

Suggested sequence:

1. Cross-compile a small Lisp library into the existing ECL Wasm executable. Demonstrate that its functions are compiled C/Wasm functions, not ECL bytecode.
2. Extend to a dependency-complete ACL2 slice, then the prover/system sources in their required order.
3. Adapt the loading path so loading `.fasc` files does not overwrite the compiled definitions.
4. Retain the bytecode compiler for runtime `compile`, `compile-file`, and newly admitted user definitions.
5. Add AOT executable counterparts where practical; they are separate from compiling the prover core.

Audit target feature conditionals, host-side macro evaluation and compile-time constants, target fixnum width, initialization ordering, and raw-code redefinition behavior. Preserve the port's fixes around direct C calls and `include-raw`; static compilation must not silently bypass later function redefinitions.

AOT accelerates initialization and proofs; it does not itself save the initialized world. Do not interpret the existing `.fasc` build as completion of actual Wasm AOT. Conversely, do not promise native-like timing before measuring.

## Workstream B: target-runtime snapshot

### Establish a clean boundary

Create a small embedding harness with conceptually separate exported operations:

- `acl2_bootstrap()`: boot ECL, load/register compiled ACL2 modules, initialize ACL2, restore temporary stream bindings, and return all the way to JavaScript without shutting down ECL.
- `acl2_resume()`: after restoration, repair/reconnect instance-local resources and enter a fresh ACL2 evaluation call.

These names describe proposed interfaces, not existing APIs. Follow ECL's supported embedding and exception conventions when implementing them.

The current driver calls `acl2-default-restart` immediately after initialization. Split that transition. Do not take the first prototype snapshot from inside an active Lisp evaluator call while simply omitting the C stack. Return first, then capture from the host.

Returning eliminates the need to resume an active Wasm call stack, but does **not** prove that ECL has no retained pointers to stack-local data. Inspect its environment, frame and binding stacks, exception contexts, and GC stack registration at the capture boundary. Any persistent pointer into a discarded frame needs a principled repair or a revised boundary.

### Why addresses may be manageable

Ordinary wasm32 C data pointers are offsets into linear memory. Restoring the same bytes at the same offsets in the same module layout preserves those pointer values even if the host places the backing buffer at another native address.

Function pointers require a compatible indirect-function table. Dynamically registered callbacks or table mutations need explicit handling. This argument does not cover arbitrary external references, host handles, or transferring pointers from native ECL.

### Inventory all state

| State category | Required investigation |
| --- | --- |
| Linear memory | Static data, heap, ECL objects, allocator and bdwgc metadata, runtime bookkeeping |
| Wasm globals | Mutable globals outside linear memory, including stack-related globals and any toolchain-generated state |
| Tables | Whether bootstrap mutates function tables; whether fresh instantiation reconstructs the required mapping |
| ECL environment | Roots, frame/binding stacks, exception contexts, cached stack limits, persistent environment pointers |
| Host runtime | Emscripten FS/streams, descriptors, callbacks, environment, cwd, clocks, JS object registries |
| Module lifecycle | Data segments, constructors, runtime initialization, automatic main invocation, exit handling |

Do not assume that copying `HEAPU8` is sufficient. Do not assume all C globals are Wasm globals: many are in linear memory, while some relevant state remains outside it. Inspect the produced module and glue.

Use a single-threaded, statically linked target for the first probe. Preserve the existing GC correctness machinery, including the required pointer-spilling pass. Avoid introducing dynamic linking or thread restoration into the initial experiment.

### Restore ordering

Use a controlled loader that initializes the host support required for a fresh instance without automatically entering ECL's normal startup. Restore only at a documented boundary where later constructors or initialization will not overwrite the restored state.

The branch notes observed constructors running even with `noInitialRun`; confirm this for the actual generated build. A successful small probe is useful evidence, not a substitute for auditing ECL's lifecycle.

Grow memory if needed before copying, refresh JS memory views after growth, restore audited globals/table state, reconnect resources, and call a fresh resume entry. Do not call `cl_boot` again over an already restored initialized ECL heap.

Close bootstrap input files before capture. Standard streams and ACL2 channel properties still exist and must be accounted for. Rebind cwd, environment, input/output, and filesystem resources for the new invocation. Node filesystem handles cannot simply become browser filesystem handles.

Keep the exact same module and memory layout for snapshot production and consumption initially. Do not shrink the stack or relink the program after capturing: that can shift addresses. A later layout change requires rebuilding the module and recapturing its image.

### Storage and compatibility

For the first correctness probe, prefer a complete, explicit capture over a clever partial dump. Once it works, measure saved ranges and omit reconstructible zero pages or proven-dead regions. Never omit pages merely because their purpose is unclear.

Measure actual snapshot bytes and compression rather than inferring download size from Node/native RSS. RSS includes host-engine memory and other allocations. Sparse storage reduces transfer size; it does not by itself reduce the target's runtime address-space requirements.

The manifest should identify the exact Wasm binary hash, matching glue/build configuration, ACL2 source revision, ECL/toolchain versions, snapshot format, memory sizes/ranges, and saved non-memory state. Reject mismatches explicitly. Capture from the final intended module layout; optimization or relinking afterward requires a new snapshot.

For browser delivery, generate the snapshot using the browser-compatible module and filesystem arrangement, potentially hosted under Node for the build. Do not assume an image from a NODERAWFS-specific build transfers unchanged to a different browser build.

## Incremental validation

Start with a small ECL harness; it need not wait for full ACL2 AOT. This makes repeated snapshot experiments cheap.

1. Build state containing shared and cyclic objects, an identity-keyed hash table, mutable globals, a bytecode closure, and an AOT function.
2. Return to the host and save. Terminate the producer.
3. Restore in a new process/instance; check values, object identity, closure behavior, and calls to both compiled and bytecode functions.
4. Force full GC, allocate heavily, repeat the checks, and exercise handled errors/nonlocal exits and subsequent evaluation.
5. Validate rebuilt streams and resource access. Restore multiple independent instances and confirm mutations do not leak between them.
6. Only then initialize and snapshot ACL2. Run initialization checks, admit recursive functions, prove inductive theorems, compute constants, and certify the four previously tested textbook books.
7. Test the known world-replay failure cases: `projects/apply/base`, attachment behavior, and fast-alist operations. Add raw-code/redefinition tests.
8. Compare cold initialization and restoration on the basic book suite, including GC pressure. Use `devel-check` where meaningful, while recording the baseline ECL failures already documented; separate pre-existing failures from restoration regressions.
9. Validate browser operation, including a reload into a genuinely fresh instance, before claiming browser readiness.

Record module load/compile time, restoration/decompression time, resource-rebinding time, time to prompt, peak memory, snapshot sizes, and representative proof times. Report AOT and snapshot gains separately.

Passing smoke tests does not establish soundness equivalence. Preserve the ordinary startup path as a reference and make unexplained divergence a release blocker.

## Scope and fallback

The preferred experiment is an exact-build Wasm runtime checkpoint. It does not require a portable general-purpose ECL `save-image`, native-to-Wasm heap conversion, or an immediate WASI port.

Wizer is useful precedent, but its import/table restrictions and the Emscripten host environment need investigation before adoption. A custom Emscripten capture/restore prototype may be the shortest way to establish feasibility.

Keep the ACL2-level world-image route available if runtime restoration proves impractical. Its next work is to identify and restore the runtime effects omitted by property-only world replay, especially attachments and fast-alist registration. Do not declare that route correct solely because the logical worlds compare equal.

## Requested implementation deliverables

- A minimal reproducible ECL snapshot probe and fresh-process restore test.
- An inventory of state captured, reconstructed, and deliberately excluded, with evidence for each exclusion.
- A demonstrated actual-Wasm AOT build path and explicit handling of remaining bytecode.
- Separate bootstrap/resume entry points and an exact-build compatibility manifest.
- ACL2 differential validation and measured startup/proof performance.
- Updated port notes distinguishing observations, diagnoses, unresolved hypotheses, and browser-specific constraints.

## Supporting references

- [ECL manual: system building and cross-compilation](https://ecl.common-lisp.dev/static/manual/System-building.html)
- [Daniel Kochmański: Common Lisp and WebAssembly](https://turtleware.eu/posts/Common-Lisp-and-WebAssembly.html) — target-info, static libraries, and embedding compiled Lisp in Wasm.
- [Wizer API and caveats](https://docs.wasmtime.dev/api/wasmtime_wizer/struct.Wizer.html) — preinitialization precedent; check the pinned version's restrictions.
- [WebAssembly runtime structure](https://webassembly.github.io/spec/core/exec/runtime.html) — memory, globals, tables, and instance state.
