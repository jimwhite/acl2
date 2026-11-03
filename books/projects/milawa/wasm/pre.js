// Mount the real filesystem with NODEFS and start in the caller's directory,
// so that the checker can read Proofs/... and write image directories while
// the standard streams keep their normal (pollable) emscripten behaviour.
// (With -sNODERAWFS emscripten's select() has no poll operations for the
// standard streams, and ECL's LISTEN on them fails.)
Module = typeof Module === "object" ? Module : {};
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
  FS.mkdirTree("/real");
  FS.mount(NODEFS, { root: "/" }, "/real");
  FS.chdir("/real" + process.cwd());
});
