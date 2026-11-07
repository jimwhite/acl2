> **Status, November 7, 2026.**  Steps 2 and 3 below are implemented and
> validated; step 4 is done for module loading but not for the base; step 1 is
> not done.  Mechanically: `wasm/aot-book.sh <book>` compiles a book's
> `<book>@expansion.lsp` into a wasm side module named `<book>.fasc`, which
> `include-book` loads through ECL's `dlopen` path (`si::load-binary`).
> Measured: `(include-book "textbook/chap10/fact")` 0.03 s with no warning, and
> 500 x `(fact 500)` 0.39 s against 0.747 s for the bytecode file.  The
> certificate is unaffected, because `.cert` hashes the source and expansion,
> not the compiled file.  The browser half is proven too: the page
> `wasm/web/dylink.html` loads a module this way in 0.4 s.  Confirming the
> warning above about the base: the module-loading build needs `DYLINK=1`
> (`-sMAIN_MODULE=1`, ECL's `ENABLE_DLOPEN`), so a base snapshot must be taken
> from *that* binary -- `$WORK/dist/node-raw-dylink2` for Node,
> `$WORK/dist/web-dylink` for the browser.  Details in `WASM-PORT-NOTES.md`,
> "Books: the expansion file, and what it needs".

**The initialization work gives us the reusable base runtime. Certified books then extend that restored runtime through ordinary `include-book`; they do not each need their own saved heap.** The additional task is providing separately loadable AOT code for those books.

The two build products have different jobs:

| Product | What it saves |
|---|---|
| **ACL2 base snapshot** | The expensive bootstrap, including its initialized logical world and ECL state |
| **Certified book bundle** | Certification results, event/loading data, and compiled functions that can be installed into an existing session |

A book still takes some work to include: installing definitions, rules, tables, and other runtime effects. Certification avoids repeating its proofs; it does not eliminate all inclusion work.

**Here is the sequence I would give the coding agent.**

**1. Finish base restoration, and validate ordinary book inclusion first.**

Restore ACL2, put a small book’s source, certificate, and existing `.fasc` in its filesystem, then run `include-book`. Test dependencies, `apply$`, fast alists, and raw-code handling.

That establishes that the snapshot preserves the machinery needed to extend the world. It also provides a working reference for the AOT loader. Bytecode books can be included into an AOT-compiled ACL2; the base and books do not have to use the same compilation strategy.

**2. Make one separately compiled Wasm library load into the restored ECL instance.**

This is the missing bridge. ECL’s native compiled-file mechanism already uses shared libraries, and Emscripten supports runtime linking of Wasm modules. The experiment is to connect those mechanisms for this build—not to design another Lisp state serializer. ECL and Emscripten support the constituent mechanisms, but their combination here still needs validation. [ecl.common-lisp.dev](https://ecl.common-lisp.dev/static/manual/System-building.html)

The loaded library must use the **existing ECL heap and runtime**, register its compiled functions, and retain its constants correctly across GC.

**This affects the initialization work now:** choose and test the base’s module-loading configuration before finalizing its snapshot. Enabling dynamic linking later may change the base binary, memory layout, exports, or function table, requiring a new snapshot. Ideally, capture the base before any optional book modules are loaded.

**3. Connect that loader to ACL2’s compiled-book path.**

For each certified book:

- Retain the expansion file produced by certification.
- Cross-compile that expansion into a separately loadable Wasm artifact.
- Package it with the certificate, source, and required supporting files.
- Make ACL2’s normal compiled-book loading path recognize and load it.

Use ACL2’s generated expansion file because it contains supporting code beyond the original book. Preserve the ordering and behavior of normal inclusion rather than manually installing functions or world properties. [acl2.org](https://acl2.org/doc/index-seo.php?path=5529%2F172%2F18945%2F870\&xkey=ACL2____BOOK-COMPILED-FILE\&utm_source=chatgpt.com)

Certification and AOT compilation can be separate build stages, provided the pipeline preserves their correspondence and validates the result against the exact release runtime.

**4. Add browser delivery around that working inclusion path.**

Publish immutable, versioned book bundles and a dependency manifest alongside the base. Before invoking synchronous `include-book`, asynchronously fetch the requested book’s dependency closure into the worker’s filesystem.

Fetching files should not itself execute book initialization. Let the integrated ACL2 loading path decide when to load and initialize the compiled modules. Explicitly account for Wasm compilation/instantiation being asynchronous in the browser.

**5. Validate equivalence and measure inclusion separately.**

Compare `.fasc` inclusion with AOT inclusion: resulting events, function behavior, proofs using the book, GC, repeated inclusion, and undo/re-inclusion. Then measure download, module loading, and logical inclusion independently.

The immediate guidance is therefore: **finish a restorable base, prove that ordinary certified books still include correctly, then replace the bytecode compiled-file backend with a separately loadable Wasm backend.** Keep the existing certificate and `include-book` machinery responsible for the logical integration.
