// Browser harness for the MEMFS build of wasm ECL (see wasm/build-ecl-wasm.sh,
// WEB=1).  Runs in a worker: instantiate the module, preload the ACL2 tree into
// the in-memory filesystem, then start ECL with the web driver and feed it a
// script on stdin.
//
// Messages to the page:
//   {type:'log', text}        a line of output (ACL2 or harness)
//   {type:'status', text}     one-line status for the header
//   {type:'done', seconds}    finished

let mod = null;

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

self.onmessage = async (ev) => {
  if (!ev.data || ev.data.cmd !== 'run') return;
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
