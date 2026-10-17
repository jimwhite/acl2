#!/usr/bin/env python3
"""Supply proof files that a `.events` manifest references but that were never
written, by copying the identically-named proof from the level that proved it.

Why this exists
---------------
A *redundant* event is skipped by ACL2, so no proof file is written for it, yet
the manifest can still reference one.  The canonical case is
`DEFINITION-OF-NOT`: level3 admits it (`not.lisp`), level4 re-admits it
(`clause-basics.lisp`), and because `bootstrap/level4/cert.image` names
`level4-symmetry` (built from `level3-symmetry` plus level3's books) the
definition is already in the world, so the level4 event is redundant.

The fact being recorded is the *same* fact level3 already proved, so the level3
proof is a legitimate witness.  Copying it is sound and, crucially, **cannot
weaken verification**: `final-checks.sh` still reads the proof and re-checks it
against the level's world (the conclusion must match the obligation exactly).
If the copy were wrong, the kernel would reject it -- nothing is silently
accepted.

This differs from `fix-events-missing-proofs.py`, which *drops* the entry.  Both
are build-side; this one keeps the manifest and the obligation intact.

Usage:
  fix-missing-proofs.py                    # dry run over Proofs/*.events
  fix-missing-proofs.py --apply            # copy the files in place
  fix-missing-proofs.py [--apply] Proofs/level4.events
"""
import glob
import os
import shutil
import sys

HEADERS = {"DEFINE", "VERIFY"}


class Tok:
    __slots__ = ("text",)

    def __init__(self, text):
        self.text = text


def tokenize(s):
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in " \t\r\n":
            i += 1
        elif c == ";":
            while i < n and s[i] != "\n":
                i += 1
        elif c in "()":
            yield Tok(c)
            i += 1
        elif c == '"':
            j = i + 1
            while j < n:
                if s[j] == "\\":
                    j += 2
                    continue
                if s[j] == '"':
                    j += 1
                    break
                j += 1
            yield Tok(s[i:j])
            i = j
        else:
            j = i
            while j < n and s[j] not in " \t\r\n()":
                j += 1
            yield Tok(s[i:j])
            i = j


def events_in(text):
    """Yield the atom list of each top-level DEFINE/VERIFY form."""
    toks, cur, depth = [], None, 0
    for t in tokenize(text):
        if t.text == "(":
            if depth == 0:
                cur = []
            elif cur is not None:
                cur.append(t)
            depth += 1
        elif t.text == ")":
            if depth <= 0:
                continue
            depth -= 1
            if depth == 0 and cur is not None:
                if cur and cur[0].text in HEADERS:
                    yield cur
                cur = None
        else:
            if cur is not None:
                cur.append(t)


def main():
    apply = "--apply" in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not paths:
        paths = sorted(glob.glob("Proofs/*.events"))

    missing_total = supplied_total = unresolved_total = 0
    for path in paths:
        base = os.path.dirname(os.path.dirname(os.path.abspath(path)))
        this_level = os.path.basename(path)[:-len(".events")]
        for atom in events_in(open(path).read()):
            filename = atom[-1].text
            if not filename.startswith('"'):
                continue
            rel = filename.strip('"')
            target = os.path.join(base, rel)
            if os.path.exists(target):
                continue
            missing_total += 1
            name = atom[1].text
            # look for the same file name in any other level's Proofs dir
            src = None
            for other in sorted(glob.glob(os.path.join(base, "Proofs", "*", os.path.basename(rel)))):
                if os.sep + this_level + os.sep in other:
                    continue
                src = other
                break
            if src is None:
                unresolved_total += 1
                print(f"{path}: {name}: NO SOURCE for {rel}")
                continue
            supplied_total += 1
            print(f"{path}: {name}: {rel} <- {os.path.relpath(src, base)}"
                  f"{'' if apply else '  (dry run)'}")
            if apply:
                os.makedirs(os.path.dirname(target), exist_ok=True)
                shutil.copyfile(src, target)

    print(f"\nmissing entries: {missing_total}   "
          f"{'supplied' if apply else 'suppliable'}: {supplied_total}   "
          f"unresolved: {unresolved_total}")


if __name__ == "__main__":
    main()
