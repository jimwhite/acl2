# Dynamic-linking proof of concept

Question: can a running Emscripten module load a separately compiled wasm module
and call into it?  This is the mechanism the "books as loadable modules" design
needs (a book becomes a side module that is fetched and installed into a running
ACL2 instead of a `.fasc` the bytecode compiler has to interpret).

Result with Emscripten 6.0.13 (`emcc --version`): **yes**.

```sh
. /opt/emsdk/emsdk_env.sh
emcc -sSIDE_MODULE=2 -O2 -o side.wasm side.c
emcc -sMAIN_MODULE=2 -O2 -sNODERAWFS=1 -o main.js main.c
node main.js        # side_double(21) = 42
```

Notes from doing it:

- `dlopen("side.wasm", RTLD_NOW)` succeeds and `dlsym` finds the symbol, but
  only if the side module actually exports it: a plain function is not in the
  export list, so it needs `EMSCRIPTEN_KEEPALIVE` (or `-sEXPORTED_FUNCTIONS`,
  which in a side module has to be given as the C symbol name).
- The main module has to be linked with `-sMAIN_MODULE=2`; ours (the ACL2/ECL
  module) is not, so it cannot load anything until it is rebuilt that way.
  That also means the decision has to be taken *before* a base snapshot is
  made, which is exactly the sequencing note in the delivery plan.
- For a browser there is `emscripten_dlopen` (async) in
  `system/include/emscripten/emscripten.h`, which suits fetching a book module
  after the fact.  A synchronous `dlopen` still needs the bytes to be present
  in the filesystem, which preloading into MEMFS provides.
