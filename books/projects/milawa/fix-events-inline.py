#!/usr/bin/env python3
"""Rewrite Milawa `.events` files so RECURSIVE definitions are NOT declared inline.

Why
---
`interface`-side `%defun` records an `inlinep` flag per definition (from ACL2's
`get-functions-to-inline`).  The kernel passes it to `defun-safe-fn`, which does

    (when inlinep (eval `(declaim (inline ,name))))
    (eval `(compile (defun ,name ...)))

Inlining a *recursive* function is useless (SBCL declines the self-call) and,
when such functions form a chain, SBCL's inliner blows up multiplicatively
(~x150-180 per nesting level).  That is what stalls
`DEFINE RW.FAST-EQDATABASE-EXTEND` in level9.

`inlinep` is only a compilation hint: it is read from the events file and passed
straight to `defun-safe-fn`.  It cannot affect which proofs are accepted.
Rewriting it in the events file therefore fixes the stall WITHOUT touching the
trusted kernel and WITHOUT rebuilding any ACL2 book.

Usage:
  fix-events-inline.py [--apply] Proofs/level9.events [...]
"""
import sys

DEFINE_N_FIELDS = 7          # DEFINE name formals body measure inlinep filename


class Tok:
    __slots__ = ("text", "start", "end", "depth")

    def __init__(self, text, start, end, depth):
        self.text, self.start, self.end, self.depth = text, start, end, depth


def tokenize(s):
    """Yield Tok for every atom/paren, recording offsets and paren depth."""
    i, n, depth = 0, len(s), 0
    while i < n:
        c = s[i]
        if c in " \t\r\n":
            i += 1
        elif c == ";":
            while i < n and s[i] != "\n":
                i += 1
        elif c == "(":
            yield Tok("(", i, i + 1, depth)
            depth += 1
            i += 1
        elif c == ")":
            depth -= 1
            yield Tok(")", i, i + 1, depth)
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
            yield Tok(s[i:j], i, j, depth)
            i = j
        else:
            j = i
            while j < n and s[j] not in " \t\r\n()":
                j += 1
            yield Tok(s[i:j], i, j, depth)
            i = j


def top_level_forms(s):
    """Return the token list of each top-level list form (parens included)."""
    toks = list(tokenize(s))
    forms, cur, depth = [], None, 0
    for t in toks:
        if t.text == "(":
            if depth == 0:
                cur = [t]
            elif cur is not None:
                cur.append(t)
            depth += 1
        elif t.text == ")":
            depth -= 1
            if cur is not None:
                cur.append(t)
                if depth == 0:
                    forms.append(cur)
                    cur = None
        else:
            if cur is not None:
                cur.append(t)
    return forms


def body_mentions(body_tokens, name):
    return any(t.text == name for t in body_tokens)


def rewrite(text):
    """Return (new_text, [(name,)]) for definitions whose inlinep was cleared."""
    edits, changed = [], []
    for form in top_level_forms(text):
        atom = [t for t in form if t.text not in ("(", ")")]
        if not atom or atom[0].text != "DEFINE":
            continue
        # atom == [DEFINE, name, <formals tokens...>, <body tokens...>, measure..., inlinep, filename]
        if len(atom) < DEFINE_N_FIELDS:
            continue
        name = atom[1].text
        inlinep = atom[-2]              # second-to-last atom is inlinep
        body = atom[3:-2]               # everything between formals and measure
        if inlinep.text == "T" and body_mentions(body, name):
            edits.append((inlinep.start, inlinep.end, "NIL"))
            changed.append(name)
    if not edits:
        return text, []
    out, prev = [], 0
    for start, end, repl in edits:
        out.append(text[prev:start])
        out.append(repl)
        prev = end
    out.append(text[prev:])
    return "".join(out), changed


def main():
    apply = "--apply" in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    for path in paths:
        text = open(path).read()
        new, changed = rewrite(text)
        tag = "rewrote" if apply and changed else "would rewrite"
        print(f"{path}: {tag} {len(changed)} recursive definition(s) inlinep T->NIL")
        for nm in changed[:12]:
            print(f"    {nm}")
        if len(changed) > 12:
            print(f"    ... and {len(changed) - 12} more")
        if apply and changed:
            open(path, "w").write(new)


if __name__ == "__main__":
    main()
