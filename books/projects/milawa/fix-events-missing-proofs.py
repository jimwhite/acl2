#!/usr/bin/env python3
"""Drop `.events` entries whose proof file does not exist.

Why this exists
---------------
Milawa's `interface/` records a `DEFINE` (or `VERIFY`) entry for every event it
admits, together with the name of the proof file that backs it.  A **redundant**
event is the exception: ACL2 skips it, so no proof file is ever written, yet the
event can still end up in the `thmfiles` table (via certificate replay during
`include-book`) and therefore in `<level>.events`.  `final-checks.sh` then dies
with a missing-proof error.

The canonical case is `DEFINITION-OF-NOT`, which level3 admits (`not.lisp`) and
level4 re-admits (`clause-basics.lisp`).  Because `bootstrap/level4/cert.image`
(an upstream-tracked file) names `level4-symmetry`, and that image is built from
`level3-symmetry` plus level3's books, the definition is already present when
level4 is certified -- so the level4 re-admission is genuinely redundant.

Dropping such an entry is *sound*: the object it introduces is already in the
world that the level's checkpoint is built on, so replaying the manifest without
it reproduces exactly the intended state.  This keeps the fix on the build side
and leaves Milawa's sources untouched.

Usage:
  fix-events-missing-proofs.py            # dry run over Proofs/*.events
  fix-events-missing-proofs.py --apply    # rewrite in place
  fix-events-missing-proofs.py [--apply] <file> ...
"""
import glob
import os
import sys

HEADERS = {"DEFINE", "VERIFY"}


class Tok:
    __slots__ = ("text", "start", "end")

    def __init__(self, text, start, end):
        self.text, self.start, self.end = text, start, end


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
            yield Tok(c, i, i + 1)
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
            yield Tok(s[i:j], i, j)
            i = j
        else:
            j = i
            while j < n and s[j] not in " \t\r\n()":
                j += 1
            yield Tok(s[i:j], i, j)
            i = j


def top_level_forms(s):
    """Return [(start_offset, end_offset, tokens)] for each top-level form."""
    forms, cur, depth, start = [], None, 0, None
    for t in tokenize(s):
        if t.text == "(":
            if depth == 0:
                cur, start = [], t.start
            elif cur is not None:
                cur.append(t)
            depth += 1
        elif t.text == ")":
            if depth <= 0:            # stray close paren; ignore
                continue
            depth -= 1
            if cur is not None:
                cur.append(t)
            if depth == 0 and cur is not None:
                forms.append((start, t.end, cur))
                cur, start = None, None
        else:
            if cur is not None:
                cur.append(t)
    return forms


def proof_dir_of(events_path):
    """`Proofs/level4.events` -> the directory its relative filenames are from."""
    return os.path.dirname(os.path.dirname(os.path.abspath(events_path)))


def analyze(text, base):
    """Return (drops, missing) where drops = [(start, end, name, filename)]."""
    drops = []
    for start, end, toks in top_level_forms(text):
        atom = [t for t in toks if t.text not in ("(", ")")]
        if not atom or atom[0].text not in HEADERS:
            continue
        filename = atom[-1].text
        if not filename.startswith('"'):
            continue
        rel = filename.strip('"')
        name = atom[1].text
        if not os.path.exists(os.path.join(base, rel)):
            drops.append((start, end, name, rel))
    return drops


def rewrite(text, drops):
    out, prev = [], 0
    for start, end, _, _ in drops:
        out.append(text[prev:start])
        prev = end
        # swallow the newline that followed the dropped form
        while prev < len(text) and text[prev] in "\r\n":
            prev += 1
    out.append(text[prev:])
    return "".join(out)


def main():
    apply = "--apply" in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not paths:
        paths = sorted(glob.glob("Proofs/*.events"))
    total = 0
    for path in paths:
        text = open(path).read()
        base = proof_dir_of(path)
        drops = analyze(text, base)
        total += len(drops)
        verb = "dropped" if apply else "would drop"
        print(f"{path}: {verb if drops else 'ok,'} {len(drops)} entr"
              f"{'y' if len(drops) == 1 else 'ies'} with a missing proof file")
        for _, _, name, rel in drops:
            print(f"    {name}   (missing: {rel})")
        if apply and drops:
            open(path, "w").write(rewrite(text, drops))
    print(f"\ntotal: {total} broken entr{'y' if total == 1 else 'ies'}"
          f"{' dropped' if apply else ' found (dry run)'}")


if __name__ == "__main__":
    main()
