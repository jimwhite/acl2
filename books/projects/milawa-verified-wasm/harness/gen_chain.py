#!/usr/bin/env python3
"""Generate wasm3/chain.lisp: the opcode chain's links, with literal bodies.

The measurements settled that the chain's lemmas must carry the module's bodies as
LITERALS: with the body behind the MILAWA-FUNC-BODY accessor the same statement
costs 229,292 prover steps and still stalls, because the semantics' context rules
search the instruction list and a term is not a list they can walk.

The bodies are an artifact, so their literal form is a generated artifact, exactly
like state.lisp and module.lisp.

    python3 harness/gen_chain.py          # writes wasm3/chain.lisp
    python3 harness/gen_chain.py --check  # fails if it has drifted

THE HINTS, which are the real content here.  STEP, STEP/R-CTXT-INSTRS,
STEP/R-CTXT-LABEL and STEP/R-CTXT-FRAME are one mutual recursion, so :expand cannot
unfold the non-top members -- adding :expand for the symbol, or enabling its
definition rule, changes nothing at all (measured: 23,319 prover steps in every
variant).  Instantiating the definition axiom by hand does unfold them, and with
the two instances below the head-instruction law for a flat configuration proves in
138,429 prover steps:

  (:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 CFG))
  (:instance (:definition w3t::step/search21)
             (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
             (w3t::%t6 BODY) (w3t::%t9 0) (w3t::z Z) (w3t::%a0 CFG))

and one more for the descent through a frame:

  (:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 CFG))

The bodies have to be literals and every configuration in a hint has to be written
out at the exact literal shape the descent produces, which is why this is a
generator: see SUMMARY.md, 'How step descends'.
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent
STATE = PROJECT / "wasm3" / "state.lisp"
OUT = PROJECT / "wasm3" / "chain.lisp"

Z = "(mvm-abs-z-abstract bytes sp pc clen status result)"


def form_at(src, start):
    """The s-expression beginning at src[start], balanced."""
    depth = 0
    i = start
    while i < len(src):
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
            if depth == 0:
                return src[start : i + 1]
        i += 1
    raise SystemExit("unbalanced form")


def func_body(i):
    """The i-th function's instruction list, as source text."""
    src = STATE.read_text()
    idx = -1
    for _ in range(i + 1):
        idx = src.index("(:CODE", idx + 1)
    code = form_at(src, idx)
    # (:CODE :FUNC ty locals body) -- the body is the last element
    depth = 0
    starts, last = [], None
    for j, c in enumerate(code):
        if c == "(":
            if depth == 1:
                starts.append(j)
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 1:
                last = j
    return code[starts[-1] : last + 1]


def probe_text(body):
    """A script that asks the semantics what one step actually does.

    Guessing the intermediate configurations of the descent has cost several
    rounds.  `step` is a logic function, so on a *concrete* configuration ACL2 will
    just compute it, and the answer is the specification of the lemma -- not a
    guess.  Run it with:

        python3 harness/gen_chain.py --probe > /tmp/probe.lisp
        cd wasm3 && echo '(include-book \"head\") (ld \"/tmp/probe.lisp\")' \
            | ../../../../saved_acl2
    """
    return "\n".join([
        '(in-package "ACL2")',
        "(defconst *pz* (mvm-abs-z-abstract (list 0 1 2 3) 4000 4200 100 1 0))",
        "(defconst *pb* '" + body + ")",
        "(defconst *pc0*",
        "  (list :|%;%| *pz*",
        "        (list (list :frame_%{%}% 1 (caddr *pz*)",
        "                    (list (list :label_%{%}% 1 nil *pb*))))))",
        "(defconst *pr* (w3t::step *pc0*))",
        '(cw "~%ONE STEP GIVES:~%~x0~%Z UNCHANGED: ~x1~%"',
        "    (car *pr*)",
        "    (equal (cadr (car *pr*)) *pz*))",
        "",
    ])


def render():
    body = func_body(6)
    Z = "(mvm-abs-z-abstract bytes sp pc clen status result)"
    CFG = "(list :|%;%| " + Z + " *body-6*)"
    RHS = ("(list (list :|%;%| " + Z
           + " (cons (list :const (list :i32) status) (cdr *body-6*))))")

    def bal(x):
        return sum(1 if c == "(" else -1 if c == ")" else 0 for c in x)

    flat = "\n".join([
        "; The body's first instruction, stepped, with the rest of the body",
        "; symbolic-ish: the body is a literal because the search only computes on",
        "; literals.  145,059 prover steps, and 0.09 seconds -- the step count is not",
        "; the wall clock.",
        "(defthm step-flat-body-6-first",
        "  (equal (w3t::step/r-ctxt-instrs " + CFG + ")",
        "         " + RHS + ")",
        '  :hints (("Goal"',
        "           :use ((:instance (:definition w3t::step/r-ctxt-instrs)",
        "                            (w3t::%a0 " + CFG + "))",
        "                 (:instance (:definition w3t::step/search21)",
        "                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)",
        "                            (w3t::%t6 *body-6*) (w3t::%t9 0)",
        "                            (w3t::z " + Z + ")",
        "                            (w3t::%a0 " + CFG + ")))",
    ])
    flat += ")" * bal(flat)
    assert bal(flat) == 0

    # -- the general flat rule: z symbolic, the instruction's step as a hypothesis.
    # This is the form that applies at ANY store, which the concrete lemma above
    # cannot.  683,415 prover steps.
    INC = "(list :|%;%| z (list (list :global.get 3)))"
    flatg = "\n".join([
        "; The same law at an arbitrary store, with the instruction's own step taken",
        "; as a hypothesis.  This is the one that composes: because `z` is a",
        "; variable, the literal body in the left-hand side matches ANY store, so no",
        "; lemma about the store is needed.  683,415 prover steps.",
        "(defthm flat-body-6-general",
        "  (implies (and (true-listp val)",
        "                (consp (cdr *body-6*))",
        "                (equal (w3t::step " + INC + ")",
        "                       (list (list :|%;%| z2 val))))",
        "           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z *body-6*))",
        "                  (list (list :|%;%| z2 (append val (cdr *body-6*))))))",
        '  :hints (("Goal"',
        "           :use ((:instance (:definition w3t::step/r-ctxt-instrs)",
        "                            (w3t::%a0 (list :|%;%| z *body-6*)))",
        "                 (:instance (:definition w3t::step/search21)",
        "                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)",
        "                            (w3t::%t6 *body-6*) (w3t::%t9 0)",
        "                            (w3t::z z)",
        "                            (w3t::%a0 (list :|%;%| z *body-6*)))))",
    ])
    flatg += ")" * bal(flatg)
    assert bal(flatg) == 0

    # -- the label level on top of it.  Concrete store, because with a symbolic one
    # the rewriter has to reason about `append` and the proof explodes to 48.6M
    # steps without finishing; with the abstract store the value stays concrete.
    LCFG = "(list :|%;%| " + Z + " (list (list :label_%{%}% 1 nil *body-6*)))"
    LRHS = ("(list (list :|%;%| " + Z + " (list (list :label_%{%}% 1 nil"
            " (cons (list :const (list :i32) status) (cdr *body-6*))))))")
    label = "\n".join([
        "; The label level: a step inside a label is a step of its body, re-wrapped.",
        "; The flat lemma has to be passed with :USE rather than left to fire as a",
        "; rewrite rule, and `step/r-ctxt-instrs` has to be DISABLED so that ACL2",
        "; applies the lemma instead of expanding the search again.  Both are load-",
        "; bearing: without the disable the same goal costs 288,294 steps and stalls.",
        "; 1,217,401 prover steps.",
        "(defthm step-in-label-body-6-first",
        "  (equal (w3t::step " + LCFG + ")",
        "         " + LRHS + ")",
        '  :hints (("Goal"',
        "           :use (step-flat-body-6-first",
        "                 (:instance (:definition w3t::step/r-ctxt-label)",
        "                            (w3t::%a0 " + LCFG + ")))",
        "           :in-theory (disable w3t::step/r-ctxt-instrs)))",
    ])
    label += ")" * bal(label)
    assert bal(label) == 0

    # -- the label level at an arbitrary store, with the value kept concrete (so the
    # rewriter never has to reason about `append`, which is what blew the first
    # attempt up to 48.6M steps).  487,458 prover steps.
    VAL = "(cons (list :const (list :i32) status) (cdr *body-6*))"
    LAB = "(list (list :label_%{%}% 1 nil *body-6*))"
    LAB2 = "(list (list :label_%{%}% 1 nil " + VAL + "))"
    LBLG = "(list :|%;%| z " + LAB + ")"
    labelg = "\n".join([
        "; The label level at an arbitrary store.  The value is kept CONCRETE: with",
        "; it symbolic the rewriter has to reason about `append` and the same statement",
        "; runs to 48.6M prover steps without finishing.  487,458 steps here.",
        "(defthm label-body-6-general",
        "  (implies (equal (w3t::step/r-ctxt-instrs (list :|%;%| z *body-6*))",
        "                  (list (list :|%;%| z2 " + VAL + ")))",
        "           (equal (w3t::step " + LBLG + ")",
        "                  (list (list :|%;%| z2 " + LAB2 + "))))",
        '  :hints (("Goal"',
        "           :use ((:instance (:definition w3t::step/r-ctxt-label)",
        "                            (w3t::%a0 " + LBLG + ")))",
        "           :in-theory (disable w3t::step/r-ctxt-instrs)))",
    ])
    labelg += ")" * bal(labelg)
    assert bal(labelg) == 0

    # -- the frame level.  Note what is NOT disabled: disabling
    # `step/r-ctxt-label` here costs the proof, because ACL2 then still has to
    # establish that the label rule applies and cannot unfold it to do so.
    ZIN = "(list :|%;%| s f-prime)"
    LBLCFG = "(list :|%;%| " + ZIN + " " + LAB + ")"
    LBLRES = "(list (list :|%;%| (list :|%;%| s2 f2) " + LAB2 + "))"
    FCFG = ("(list :|%;%| (list :|%;%| s f)"
            " (list (list :frame_%{%}% 1 f-prime " + LAB + ")))")
    FRES = ("(list (list :|%;%| (list :|%;%| s2 f)"
            " (list (list :frame_%{%}% 1 f2 " + LAB2 + "))))")
    frame = "\n".join([
        "; The frame level, which is where the descent starts for a call to this",
        "; function.  6,861,519 prover steps -- the largest proof in the project -- and",
        "; the last of the three bridge lemmas.",
        ";",
        "; One thing to know: `step/r-ctxt-label` must be LEFT ENABLED here.  Disabling",
        "; it costs the proof, because ACL2 then still has to establish that the label",
        "; rule applies, and cannot unfold the rule to do it.",
        "(defthm frame-body-6-general",
        "  (implies (equal (w3t::step " + LBLCFG + ")",
        "                  " + LBLRES + ")",
        "           (equal (w3t::step " + FCFG + ")",
        "                  " + FRES + "))",
        '  :hints (("Goal"',
        "           :use ((:instance (:definition w3t::step/r-ctxt-frame)",
        "                            (w3t::%a0 " + FCFG + ")))",
        "           :in-theory (disable w3t::step/r-ctxt-instrs)))",
    ])
    frame += ")" * bal(frame)
    assert bal(frame) == 0

    L = [
        "; L1, the opcode chain: the bottom of the descent, generated.",
        ";",
        "; Copyright (C) 2026 Kookamara LLC",
        ";",
        "; License: (An MIT/X11-style license)",
        "",
        "; GENERATED by ../harness/gen_chain.py from ../wasm3/state.lisp.  Do not edit.",
        ";",
        "; The artifact's body for function 6 is written out as a LITERAL here, because",
        "; the semantics' search only computes on literals -- and a rewrite rule whose",
        "; left-hand side contains (cons instr rest) cannot match a literal, so the",
        "; general rules in head.lisp cannot be used at this position.  An instance is",
        "; what works.",
        "",
        '(in-package "ACL2")',
        "",
        '(include-book "head")',
        "",
        "; The body of function 6, the exported STEP, as the artifact holds it.",
        "(defconst *body-6*",
        "  '" + body + ")",
        "",
        flat,
        "",
        flatg,
        "",
        label,
        "",
        labelg,
        "",
        frame,
        "",
        "; WHAT ONE STEP OF A WHOLE FRAME DOES, derived rather than guessed:",
        ";",
        ";   (python3 ../harness/gen_chain.py --probe) gives, for a concrete store,",
        ";",
        ";     ((:FRAME_ 1 <frame-record> ((:LABEL_ 1 NIL (<value> . <rest-of-body>)))))",
        ";",
        ";   with Z UNCHANGED, i.e. the value pushed into the label's body list with the",
        ";   first instruction replaced, the label's own stack still NIL, and the frame",
        ";   and store untouched.  That is the right-hand side the link needs; what it",
        ";   still needs is for the descent above this lemma to be stated at the exact",
        ";   configuration it produces, which is what --probe is for.",
        "",
    ]
    return "\n".join(L)


def main():
    if "--probe" in sys.argv:
        print(probe_text(func_body(6)))
        return
    text = render()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            raise SystemExit("chain.lisp has drifted from the artifact")
        print("chain.lisp is up to date")
        return
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(PROJECT)} ({len(text)} bytes)")


if __name__ == "__main__":
    main()
