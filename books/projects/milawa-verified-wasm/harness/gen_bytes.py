#!/usr/bin/env python3
"""Regenerate wasm3/bytes.lisp from wasm/milawa-verified.wasm.

A certified book cannot read a file, so the artifact's bytes have to appear in the
source as a ground term.  Generating them from the .wasm is what stops the proof
from being about a stale copy of the module; run wasm/build.sh first.

    ./wasm/build.sh && ./harness/gen_bytes.py
    ./harness/gen_bytes.py --check    # fails if bytes.lisp has drifted
"""
import hashlib
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
wasm = root / 'wasm' / 'milawa-verified.wasm'
out = root / 'wasm3' / 'bytes.lisp'


def render(bs):
    lines = [('   ' + ' '.join(str(b) for b in bs[i:i + 12])) for i in range(0, len(bs), 12)]
    body = '\n'.join(lines)
    return f"""; The bytes of ../wasm/milawa-verified.wasm, as a literal list.
;
; This file is GENERATED: run ../wasm/build.sh and then `make -C wasm3 bytes` (or
; the `bytes` target in wasm3/Makefile) to regenerate it.  It exists because a
; certified book cannot read a file: the artifact has to be a ground term for the
; theorems below to be about it, and generating it from the .wasm keeps the
; artifact and the proof from drifting apart.
;
; {len(bs)} bytes, sha256 {hashlib.sha256(bs).hexdigest()}

(in-package "MILAWA-WASM")

(defconst *milawa-verified-wasm-bytes*
  '({body}))
"""


def main():
    check = '--check' in sys.argv[1:]
    bs = wasm.read_bytes()
    text = render(bs)
    if check:
        if not out.exists():
            sys.exit(f'{out} is missing; run {sys.argv[0]}')
        if out.read_text() != text:
            sys.exit(
                f'{out} is stale: regenerate it with {sys.argv[0]} '
                f'(artifact {len(bs)} bytes, sha256 {hashlib.sha256(bs).hexdigest()[:16]}...)')
        print(f'ok {out.relative_to(root)} matches the artifact ({len(bs)} bytes)')
        return
    out.write_text(text)
    print(f'wrote {out} ({len(bs)} bytes, sha256 {hashlib.sha256(bs).hexdigest()[:16]}...)')


if __name__ == '__main__':
    main()
