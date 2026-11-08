// Browser harness for the MEMFS build of wasm ECL (see wasm/build-ecl-wasm.sh,
// WEB=1).  Runs in a worker: instantiate the module, preload the ACL2 tree into
// the in-memory filesystem, then start ECL with the web driver and feed it a
// script on stdin.
//
// Messages to the page:
//   {type:'log', text}        a line of output (ACL2 or harness)
//   {type:'status', text}     one-line status for the header
//   {type:'done', seconds}    finished (cmd 'run')
//   {type:'result', lines}    output of one REPL input (cmd 'eval')
//
// Commands:
//   {cmd:'run', mode}         smoke | dylink | acl2 | acl2dylink, as before
//   {cmd:'eval', text}        REPL: evaluate TEXT in a persistent ECL
//   {cmd:'restart'}           REPL: throw the ECL instance away

let mod = null;

// An interactive ECL REPL.  The module exposes only FS, callMain and the
// stdio hooks to JS (the eval entry points are wasm exports that the glue does
// not wire up), so a REPL cannot call si_safe_eval.  It does not need to:
// CL_BOOT is idempotent -- it returns 1 when the runtime is already up -- so
// re-entering MAIN with a different stdin puts ECL back at its top level with
// the whole Lisp state live: packages, defuns, global values.  Each input is
// one such re-entry, and EOF ends it again.  Verified in the page:
//
//   (defvar *x* 41)   (print (+ *x* 1))   (defun f (n) (* n n))   (f 9)
//
// gives 42 and 81, i.e. the definitions survive between inputs.
let repl = null;

function log(text) {
  postMessage({type: 'log', text});
}

function status(text) {
  postMessage({type: 'status', text});
}

// The port forward in front of the dev container truncates a fair fraction of
// responses (net::ERR_CONTENT_LENGTH_MISMATCH), so retry generously.  The
// payload is gzipped (see make-manifest.sh), which keeps retries cheap.
async function fetchBuf(url, attempts = 10) {
  let last;
  for (let i = 0; i < attempts; i++) {
    try {
      const res = await fetch(url, {cache: 'no-store'});
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.arrayBuffer();
    } catch (e) {
      last = e;
      await new Promise((r) => setTimeout(r, 300));
    }
  }
  throw new Error(`fetch ${url}: ${last && last.message}`);
}

async function fetchGz(url) {
  const packed = await fetchBuf(url);
  const stream = new Response(packed).body
      .pipeThrough(new DecompressionStream('gzip'));
  return await new Response(stream).arrayBuffer();
}

// Lines the top level prints on every re-entry, which would otherwise repeat
// once per input.  The prompt is "> " and it lands on its own line here because
// the print hook is line-oriented.
const REPL_NOISE = [
  /^Top level\.$/,
  /^>+ $/,
  /^program exited \(with status: 0\)/,
  /unsupported syscall:/,
  // Re-entry noise, as in acl2-main.html: every input re-enters MAIN, which
  // re-loads the driver and restarts ACL2's loop.
  /^;;; Loading #P"\/acl2\/web-replay\.lsp"/,
  /^Project-dir-alist:$/, /^\(\(:SYSTEM \. /,
  /^Type :help for help\.$/,
  /^Type \(quit\) to quit completely out of ACL2\.$/,
  /^ACL2 !>Bye\.$/,
];

async function replEnsure(mode) {
  if (repl) return repl;
  const state = {mod: null, lines: [], input: {text: '', pos: 0},
                 acl2: mode === 'acl2'};
  importScripts('lib/ecl-dylink.js');
  const create = self.Module;
  state.mod = await create({
    noInitialRun: true,
    noExitRuntime: true,      // the runtime must survive the exit at EOF
    // See the note in acl2-main.html: this bdwgc is not fully sound, and
    // wasm/acl2-wasm sets the same workaround for Node.
    ENV: { GC_INITIAL_HEAP_SIZE: '500000000' },
    locateFile: (path) => 'lib/ecl-dylink.' + path.split('.').pop(),
    print: (s) => state.lines.push(s),
    printErr: (s) => state.lines.push(s),
    stdin: () => (state.input.pos < state.input.text.length
                  ? state.input.text.charCodeAt(state.input.pos++) : null),
  });
  repl = state;
  if (state.acl2) await bootWorldReplay(state);
  return state;
}

// ACL2 through the world-image replay: preload the tree, install the image once
// (about 30 s in Node), and leave the session live.  ACL2 is then re-entered
// per input; see the comment on REPL_PREFIX below.
async function bootWorldReplay(state) {
  const FS = state.mod.FS;
  const manifest = JSON.parse(
    new TextDecoder().decode(await fetchBuf('files.json')));
  let bytes = 0, done = 0;
  status('preloading ' + manifest.length + ' files');
  for (const f of manifest) {
    const buf = await fetchGz(f.src);
    bytes += buf.byteLength;
    FS.mkdirTree(f.dst.replace(/\/[^\/]*$/, ''));
    FS.writeFile(f.dst, new Uint8Array(buf));
    // See the note in acl2-main.html: book-hash includes the write date, and
    // FS.utime wants milliseconds.
    const utime = FS.utime || FS.utimes;
    if (f.mtime && utime) utime.call(FS, f.dst, f.mtime * 1000, f.mtime * 1000);
    if (++done % 10 === 0) {
      status(`preloading ${done}/${manifest.length} ` +
             `(${(bytes / 1048576).toFixed(1)} MB)`);
    }
    await new Promise((r) => setTimeout(r, 10));
  }
  log(`[web] preloaded ${manifest.length} files, ` +
      `${(bytes / 1048576).toFixed(1)} MB`);
  // LOAD-ACL2 and its callers read this to decide what state the sources are
  // in.  :INITIALIZED is what a working start has (the repo's own
  // acl2-status.txt says exactly this), because the image *is* an initialized
  // world; :COMPILED makes ACL2 think initialization still has to happen and
  // the install then fails in EXTEND-WORLD1.
  FS.writeFile('/acl2/acl2-status.txt', ':INITIALIZED');
  status('installing the world image');
  // Empty stdin: the replay runs, reaches ACL2's loop, and hits EOF at once.
  state.input = {text: '', pos: 0};
  try {
    state.mod.callMain(['--load', '/acl2/web-replay.lsp', '--']);
  } catch (e) {
    if (!(e && typeof e === 'object' && 'status' in e)) throw e;
  }
  status('ACL2 ready');
}

async function replEval(text, mode) {
  let lines;
  try {
    const state = await replEnsure(mode);
    state.lines = [];
    // Re-entering MAIN re-loads the driver (ECL caches its command line), and
    // the driver returns to ACL2's prompt when the world is already installed.
    state.input = {
      text: text + '\n',
      pos: 0,
    };
    try {
      state.mod.callMain([]);
    } catch (e) {
      // Each input ends with EOF, so ECL's top level exits and MAIN throws
      // ExitStatus.  That is the normal path, not an error: the runtime is
      // kept alive (noExitRuntime) and the next call picks up where this
      // one's definitions left off.
      if (!(e && typeof e === 'object' && 'status' in e)) throw e;
    }
    lines = state.lines.filter((l) => !REPL_NOISE.some((re) => re.test(l)));
  } catch (e) {
    repl = null;               // force a fresh instance next time
    lines = ['[harness] ' + (e && e.stack ? e.stack : e)];
  }
  postMessage({type: 'result', lines});
}

self.onmessage = async (ev) => {
  if (!ev.data) return;
  if (ev.data.cmd === 'eval') {
    await replEval(String(ev.data.text === undefined ? '' : ev.data.text),
                   ev.data.mode);
    return;
  }
  if (ev.data.cmd === 'restart') {
    repl = null;      // a fresh instance on the next input
    postMessage({type: 'result', lines: []});
    return;
  }
  if (ev.data.cmd !== 'run') return;
  const mode = ev.data.mode || 'acl2';
  const smoke = mode === 'smoke';
  const dylink = mode === 'dylink';
  // ACL2 with module loading: the same preloaded tree, but a build that can
  // dlopen the compiled files, since the .fasc files are wasm modules.
  const acl2dylink = mode === 'acl2dylink';
  const t0 = performance.now();
  const secs = () => ((performance.now() - t0) / 1000).toFixed(1);

  try {
    status('fetching module');
    // The dynamic-linking build is a different binary (built with DYLINK=1), so
    // it has its own copy of the glue next to the plain one.
    importScripts((dylink || acl2dylink) ? 'lib/ecl-dylink.js' : 'lib/ecl-dylink.js');
    const createACL2Module = self.Module;

    const script = smoke ? '(+ 1 2)\n(print 42)\n(quit)\n'
                 : dylink ? [
                     '(progn',
                     '(load "/dylink-test.fas")',
                     '(format t "; dylink-double(21) = ~s~%" (dylink-double 21))',
                     '(format t "; dylink-fib(20)   = ~s~%" (dylink-fib 20))',
                     '(format t "; dylink-vec-sum   = ~s~%" (dylink-vec-sum #(1 2 3 4)))',

                     '(si:quit))',
                   ].join(' ') + '\n'
                 : new TextDecoder().decode(
                       await fetchBuf('demo.lsp'));
    const manifest = (smoke || dylink) ? []
                           : JSON.parse(new TextDecoder().decode(
                                 await fetchBuf('files.json')));
    let pos = 0;
    status('instantiating module');
    // Inside a worker Emscripten cannot tell where the module came from, so
    // its default locateFile points at the page; keep the binary next to it.
    const libbase = (dylink || acl2dylink) ? 'lib/ecl-dylink.' : 'lib/ecl-dylink.';
    mod = await createACL2Module({
      noInitialRun: true,
      locateFile: (path) => libbase + path.split('.').pop(),
      print: (s) => log(s),
      printErr: (s) => log('stderr: ' + s),
      // ACL2 reads its commands from stdin; feed it the script text.
      stdin: () => (pos < script.length ? script.charCodeAt(pos++) : null),
    });

    const FS = mod.FS;
    if (dylink) {
      // The module ECL will dlopen: compiled by wasm/aot-book.sh for the same
      // wasm target, so it exports __ecl_init_fas_CODE and imports libecl from
      // the running module.
      status('fetching side module');
      const buf = await fetchBuf('files/dylink-test.fas');
      FS.writeFile('/dylink-test.fas', new Uint8Array(buf));
      log(`[web] wrote /dylink-test.fas (${buf.byteLength} bytes)`);
    }
    if (!smoke && !dylink) {
      status('preloading ' + manifest.length + ' files');      let bytes = 0, done = 0;
      for (const f of manifest) {
        const buf = await fetchGz(f.src);
        bytes += buf.byteLength;
        const dir = f.dst.replace(/\/[^\/]*$/, '');
        FS.mkdirTree(dir);
        FS.writeFile(f.dst, new Uint8Array(buf));
        if (++done % 10 === 0) {
          status(`preloading ${done}/${manifest.length} (${(bytes / 1048576).toFixed(1)} MB)`);
        }
        await new Promise((r) => setTimeout(r, 20));
      }
      // LOAD-ACL2 checks this file; the sources in the tree are already compiled.
      FS.writeFile('/acl2/acl2-status.txt', ':COMPILED');
      log(`[web] preloaded ${manifest.length} files, ` +
          `${(bytes / 1048576).toFixed(1)} MB in ${secs()}s`);
      status('running ACL2 (boot-strap; several minutes)');
    } else {
      status('running ECL');
    }

    const started = performance.now();
    try {
      mod.callMain((smoke || dylink) ? [] : ['--load', '/acl2/web-acl2.lsp', '--']);
    } catch (e) {
      // EXIT_RUNTIME=1 makes (quit) throw ExitStatus; anything else is a crash.
      if (e && typeof e === 'object' && 'status' in e) {
        log(`[web] ACL2 exited with status ${e.status} after ` +
            `${((performance.now() - started) / 1000).toFixed(1)}s`);
      } else {
        throw e;
      }
    }
    status('done');
    postMessage({type: 'done', seconds: (performance.now() - t0) / 1000});
  } catch (e) {
    log('[web] harness error: ' + (e && e.stack ? e.stack : e));
    status('failed');
    postMessage({type: 'done', seconds: (performance.now() - t0) / 1000});
  }
};
