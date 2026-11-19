// Run a program on milawa-verified.wasm.
//
//   node harness/run.js <module.wasm> <opcode-word>...
//
// This is the untrusted host: it loads the module, copies the program into the
// code region, calls STEP until the machine stops, and reports what happened.  It
// is deliberately dumb, because everything clever belongs on the other side of
// the boundary, where it can be proved about.
//
// The program is given as raw instruction words, so this file needs no encoder
// and no knowledge of the opcodes beyond the convention that word 0 of the
// program sits at CODE_BASE.  A future milestone will write those words with the
// (untrusted) front end instead.

const fs = require('node:fs');

const OPCODES = { 0: 'HALT', 1: 'CONST', 2: 'ADD', 3: 'SUB', 4: 'LT', 5: 'IFZ', 6: 'JMP' };

// A program is a list of words; the ones with an immediate take the next word.
function disassemble(words) {
  const out = [];
  for (let i = 0; i < words.length; i += 1) {
    const name = OPCODES[words[i]] || `?${words[i]}`;
    if ([1, 5, 6].includes(words[i])) {
      out.push(`${i}: ${name} ${words[i + 1]}`);
      i += 1;
    } else {
      out.push(`${i}: ${name}`);
    }
  }
  return out;
}

async function main() {
  const [, , wasmPath, ...raw] = process.argv;
  if (!wasmPath || raw.length === 0) {
    console.error('usage: run.js <module.wasm> <opcode-word>...');
    process.exit(2);
  }
  const words = raw.map(Number);

  const bytes = fs.readFileSync(wasmPath);
  const { instance } = await WebAssembly.instantiate(bytes, {});
  const m = instance.exports;

  // The loader: write the program, then tell the machine how long it is.  Words
  // are little-endian 32-bit integers, which is the layout the module expects.
  const view = new DataView(m.memory.buffer);
  const codeBase = m.code_base();
  words.forEach((w, i) => view.setInt32(codeBase + 4 * i, w, true));
  m.reset(words.length);

  // The host loop: ask for a step until the machine says it has stopped.  The
  // bound is only there so that a bug in the module cannot hang the harness.
  const MAX_STEPS = 10000;
  let steps = 0;
  let status = 1;
  while (status === 1 && steps < MAX_STEPS) {
    status = m.step();
    steps += 1;
  }

  console.log(disassemble(words).join('\n'));
  const names = { 0: 'halted', 1: 'running', 2: 'aborted' };
  // The PC is reported as a word index, which is the only form the model uses;
  // the byte address is the module's business (4096 + 4*index).
  const pcWord = (m.pc() - codeBase) / 4;
  if (status === 0) {
    // The result is reported UNSIGNED.  The module's values are 32-bit words (what
    // i32.load and i32.store move), and the model's MVM-RESULT is the same word, so
    // >>> 0 here is what makes the two sides comparable: (- 0 1) is 4294967295, not
    // -1, and only i32.lt_s ever reads one of these words as signed.
    console.log(`=> halted after ${steps} steps with ${m.result() >>> 0} (pc=${pcWord})`);
    process.exit(0);
  }
  if (status === 2) {
    console.log(`=> aborted after ${steps} steps (pc=${pcWord})`);
    process.exit(1);
  }
  console.log(`=> still ${names[status] || status} after ${steps} steps`);
  process.exit(3);
}

main().catch((e) => {
  console.error(e);
  process.exit(4);
});
