#!/usr/bin/env python3
"""Walk the semantics forward from the configuration a call leaves behind.

This is the tool that made the opcode chain tractable.  `step` is a logic
function, so on a *concrete* configuration ACL2 will simply compute it: iterating
it and printing what comes back gives the specification of each lemma instead of
a guess.  Before this existed, every attempt at a chain lemma had a hand-written
configuration in a hint and no way to know whether it matched the one the descent
actually produces.

    python3 harness/walk.py              # shape of each step, one line per step
    python3 harness/walk.py --steps 12   # go further
    python3 harness/walk.py --full       # print each step's whole instruction list
    python3 harness/walk.py --value 1    # a different status, so another branch runs

The output is the path: for the frozen branch (status /= 1) it is nine steps from
the post-call configuration to a stuck machine, the first eight of which keep the
frame as the head of the instruction list and never change the store.

Run through harness/acl2.sh, so the directory, timeout and log are handled the
same way as every other experiment.
"""

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent
sys.path.insert(0, str(HERE))


def func_body(index):
    """The index-th function's instruction list, as source text."""
    import importlib.util

    spec = importlib.util.spec_from_file_location("gen_chain", HERE / "gen_chain.py")
    gen = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gen)
    return gen.func_body(index)


def script(body, steps, full, value):
    L = [
        '(in-package "ACL2")',
        f"(defconst *pz* (mvm-abs-z-abstract (list 0 1 2 3) 4000 4200 100 {value} 0))",
        "(defconst *pb* '" + body + ")",
        "(defconst *c0* (list :|%;%| *pz*",
        "                       (list (list :frame_%{%}% 1 (caddr *pz*)",
        "                                   (list (list :label_%{%}% 1 nil *pb*))))))",
    ]
    for i in range(1, steps + 1):
        L.append(f"(defconst *c{i}* (car (w3t::step *c{i - 1}*)))")
    L.append('(cw "~%")')
    for i in range(steps + 1):
        if full:
            L.append(
                f'(cw "STEP {i}: len-instrs=~x0~%~x1~%~%"'
                f"\n    (len (caddr *c{i}*))"
                f"\n    (caddr *c{i}*))"
            )
        else:
            # One form, so the closing paren goes at the end of the arguments.
            L.append(
                f'(cw "STEP {i}: ok=~x0 len-instrs=~x1 head=~x2 zdiff=~x3~%"'
                f"\n    (consp *c{i}*)"
                f"\n    (len (caddr *c{i}*))"
                f"\n    (let ((x (car (caddr *c{i}*)))) (if (consp x) (car x) x))"
                f"\n    (not (equal (cadr *c{i}*) *pz*)))"
            )
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--steps", type=int, default=9)
    ap.add_argument("--dir", default="wasm3")
    ap.add_argument("--book", default="chain")
    ap.add_argument("--func", type=int, default=6, help="function index (default 6, the exported STEP)")
    ap.add_argument("--value", type=int, default=3, help="concrete status to run (default 3, i.e. frozen)")
    ap.add_argument("--full", action="store_true", help="print each step's whole instruction list")
    ap.add_argument("--timeout", default="900")
    args = ap.parse_args()

    text = script(func_body(args.func), args.steps, args.full, args.value)
    with tempfile.NamedTemporaryFile("w", suffix=".lsp", delete=False) as fh:
        fh.write(text)
        path = fh.name

    cmd = [
        str(HERE / "acl2.sh"),
        "--dir", args.dir,
        "--book", args.book,
        "--script", path,
        "--timeout", args.timeout,
        "--log", "/tmp/walk.log",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)

    # The walk's own output is the useful part; the runner's summary is noise
    # here unless something went wrong.
    for line in Path("/tmp/walk.log").read_text().split("\n"):
        if "STEP " in line:
            print(line[line.index("STEP "):])
    if result.returncode != 0:
        sys.stderr.write(result.stdout)
        return result.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
