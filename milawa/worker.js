// Browser harness for the WebAssembly build of Milawa's proof checker.
//
// The page sends {cmd:'run', events}; the worker instantiates the module,
// writes the image, the events text and the proof files into the in-memory
// filesystem under /real, changes to that directory, and calls main with
// /base.wasm and /demo.events -- milawa-wasm.c prefixes absolute paths with
// /real, and the checker opens the proof files by their relative paths.
//
// Messages back: {type:'status', text}, {type:'log', text},
// {type:'done', ok, seconds}.

importScripts('milawa-wasm.js');   // defines the global factory `Module`

const FILES = [
  'base.wasm/state.lisp',
  'Proofs/utilities/prepare-for-bootstrapping/thm-theorem-substitute-into-not-pequal.proof',
  'Proofs/utilities/prepare-for-bootstrapping/thm-theorem-not-t-or-not-nil.proof',
  'Proofs/utilities/prepare-for-bootstrapping/admit-not.proofs',
  'Proofs/utilities/prepare-for-bootstrapping/thm-not.proof',
];

function log(text) { postMessage({type: 'log', text}); }
function status(text) { postMessage({type: 'status', text}); }

async function fetchBuf(url, attempts = 5) {
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

async function run(events) {
  const t0 = performance.now();
  status('instantiating the checker');
  let lost = 0;
  // Restoring the image redefines the kernel's own functions, and ECL reports
  // each of them as a lost definition (on stderr, though it looks like output).
  // That is expected; it would be most of the log.
  const emit = (s) => {
    if (/lost the original function definition/.test(s)) {
      lost++;
      return;
    }
    log(s);
  };
  const mod = await Module({
    noInitialRun: true,
    // Inside a worker Emscripten cannot locate the module from the page, so
    // keep the binary next to this script.
    locateFile: (path) => new URL(path, self.location.href).href,
    print: emit,
    printErr: emit,
  });
  const FS = mod.FS;
  for (const f of FILES) {
    status('fetching ' + f);
    const buf = await fetchBuf(f);
    FS.mkdirTree('/real/' + f.replace(/\/[^\/]*$/, ''));
    FS.writeFile('/real/' + f, new Uint8Array(buf));
  }
  FS.mkdirTree('/real');
  FS.writeFile('/real/demo.events', new TextEncoder().encode(events));
  FS.chdir('/real');
  status('checking');
  try {
    mod.callMain(['/base.wasm', '/demo.events']);
  } catch (e) {
    // The checker returns from main; anything thrown with a status is the
    // runtime's exit, which is not an error here.
    if (!(e && typeof e === 'object' && 'status' in e)) throw e;
  }
  if (lost) {
    log(`[harness] ${lost} kernel definitions were reloaded from the image`);
  }
  postMessage({type: 'done', ok: true,
               seconds: (performance.now() - t0) / 1000});
}

self.onmessage = async (ev) => {
  if (!ev.data || ev.data.cmd !== 'run') return;
  try {
    await run(String(ev.data.events === undefined ? '' : ev.data.events));
  } catch (e) {
    log('[harness] ' + (e && e.stack ? e.stack : e));
    postMessage({type: 'done', ok: false, seconds: 0});
  }
};
