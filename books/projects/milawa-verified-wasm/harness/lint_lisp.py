#!/usr/bin/env python3
"""Check the Lisp sources for the things a compiler would not complain about.

Why this exists: an editor showed "unbalanced parentheses" on
`wasm3/chain.lisp`, which is a *generated* file -- so either the generator is
broken or the editor's reader is being fooled by something in the text.  Both
are worth knowing about, and neither is visible from a successful `cert.pl`.
A book can be perfectly balanced and still have a file that makes a naive reader
give up: the usual causes are parentheses inside comments, inside strings, or in
`#\\(` character literals.

So this counts parentheses the way ACL2's reader does -- skipping `;` comments,
`#| ... |#` block comments, `"..."` strings and `|...|` escaped symbols -- and
reports the first place the depth goes negative or the file ends non-zero.

It also checks a few cheap formatting things that make generated files readable:

  * the file ends with exactly one newline
  * no tab characters (ACL2 files are spaces-indented here)
  * no trailing whitespace
  * no line longer than MAX_LINE columns, unless it is a generated file, where
    the literals are long by nature

Usage:
    python3 harness/lint_lisp.py              # every book in this project
    python3 harness/lint_lisp.py FILE ...     # just these
    python3 harness/lint_lisp.py --strict     # include the long-line check

Exit status is 0 if everything passes.
"""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent
MAX_LINE = 100

GENERATED = {"chain.lisp", "state.lisp", "module.lisp", "examples.lisp"}


def scan(text):
    """Yield (line, col, char) for every parenthesis the ACL2 reader would see."""
    i, n = 0, len(text)
    line, col = 1, 0
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            col = 0
            i += 1
            continue
        if c == ";":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "#" and text.startswith("#|", i):
            depth, i = 1, i + 2
            while i < n and depth:
                if text.startswith("#|", i):
                    depth, i = depth + 1, i + 2
                elif text.startswith("|#", i):
                    depth, i = depth - 1, i + 2
                else:
                    if text[i] == "\n":
                        line += 1
                    i += 1
            continue
        if c == '"':
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                if text[i] == "\n":
                    line += 1
                i += 1
            continue
        if c == "|":
            i += 1
            while i < n and text[i] != "|":
                if text[i] == "\\":
                    i += 1
                if i < n and text[i] == "\n":
                    line += 1
                i += 1
            i += 1
            continue
        if c == "#" and text.startswith("#\\", i):
            # A character literal: skip it whole, so `#\(` is not a parenthesis.
            j = i + 2
            if j < n and text[j].isalnum():
                while j < n and (text[j].isalnum() or text[j] == "-"):
                    j += 1
            else:
                j += 1
            i = j
            continue
        if c in "()":
            yield line, col, c
            col += 1
            i += 1
            continue
        i += 1
        col += 1


def check_parens(path, text):
    problems = []
    depth, low = 0, 0
    for line, col, c in scan(text):
        depth += 1 if c == "(" else -1
        if depth < low:
            low = depth
            problems.append(
                f"{path}: line {line}, column {col}: ')' closes past the "
                f"beginning of the file"
            )
            break
    if depth > 0:
        problems.append(f"{path}: {depth} unclosed '(' at end of file")
    elif depth < 0:
        problems.append(f"{path}: {-depth} extra ')' at end of file")
    return problems


def naive_balance(text):
    """Parenthesis count the way an editor that ignores comment context does it.

    Reported only when it disagrees with the ACL2-reading count, because that
    disagreement is exactly why an editor can claim a balanced file is broken:
    the parentheses inside `;` comments and `"..."` strings are text, not
    structure, and a generated file has a lot of them.
    """
    return sum(1 if c == "(" else -1 if c == ")" else 0 for c in text)


def check_format(path, text, strict):
    problems = []
    if not text.endswith("\n"):
        problems.append(f"{path}: does not end with a newline")
    elif text.endswith("\n\n"):
        problems.append(f"{path}: ends with a blank line")
    generated = path.name in GENERATED
    for n, line in enumerate(text.split("\n"), 1):
        if "\t" in line:
            problems.append(f"{path}: line {n}: tab character")
        if line != line.rstrip():
            problems.append(f"{path}: line {n}: trailing whitespace")
        if (strict or not generated) and len(line) > MAX_LINE:
            problems.append(
                f"{path}: line {n}: {len(line)} columns (limit {MAX_LINE})"
            )
    return problems


def main():
    args = [a for a in sys.argv[1:]]
    strict = "--strict" in args
    args = [a for a in args if not a.startswith("--")]
    if args:
        paths = [Path(a) for a in args]
    else:
        paths = sorted(
            p
            for d in ("milawa-lisp", "machine", "wasm3")
            for p in (PROJECT / d).glob("*.lisp")
        )
        if not paths:
            raise SystemExit("no .lisp files found")

    errors, warnings, notes = [], [], []
    for path in paths:
        text = path.read_text()
        rel = path.relative_to(PROJECT) if path.is_relative_to(PROJECT) else path
        errors += check_parens(rel, text)
        # Long lines are opt-in; the other format checks are warnings, because a
        # trailing blank line is not a reason to fail a build.
        warnings += [w for w in check_format(rel, text, strict)
                     if "columns (limit" not in w or strict]
        naive = naive_balance(text)
        if naive != 0:
            notes.append(
                f"{rel}: {abs(naive)} more '{'(' if naive > 0 else ')'}' than "
                f"'{')' if naive > 0 else '('}' counting comments and strings -- "
                "the file is balanced for ACL2; this is what an editor that "
                "ignores comment context reports"
            )

    for label, items in (("ERROR", errors), ("warning", warnings), ("note", notes)):
        for item in items:
            print(f"{label}: {item}")

    if errors:
        print(f"\n{len(errors)} error(s) in {len(paths)} file(s)")
        return 1
    print(f"\nlint: {len(paths)} file(s) balance the way ACL2 reads them"
          + (f"; {len(warnings)} warning(s)" if warnings else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
