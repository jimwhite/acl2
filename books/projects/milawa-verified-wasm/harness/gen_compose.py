#!/usr/bin/env python3
"""Generate the label-lift chains for the CONST branch's callee positions.

Each position needs the same nine facts.  The pattern is:

  spure-<p>-body   (step_pure LIT0) = nil
  sread-<p>-body   (step_read/split (:%;% Z LIT0)) = nil
  ctxt-<p>-body    (step/r-ctxt-instrs (:%;% Z LIT0)) = (list (:%;% Z LIT1))
  match-<p>-body   (step_pure/match135 (take 13 LIT0)) = nil
  search-<p>-body  (step_pure/search141 14 14 14 LIT0) = nil
  spure-<p>-label  (step_pure ((label 1 nil LIT0))) = nil
  sread-<p>-label  (step_read/split (:%;% Z ((label 1 nil LIT0)))) = nil
  lbl-dconst-<p>   (step (:%;% Z ((label 1 nil LIT0)))) = (list (:%;% Z ((label 1 nil LIT1))))

The label lifts are instances of label-lift-general (proved once above them);
the body facts come from the book's dconst-<p>-ctxt facts by lockstep
normalization.  Every literal spelling below is the *normalized* spelling that
the rewriter produces, which is what makes the stored rules fire: the frame
record is the literal :%REC term, the tail is the literal 13-instruction list,
and the i32 numtype is the quoted constant '(:I32).

This script is the data source for the generated section of const.lisp.  It
prints the Lisp forms; the book keeps the output as ordinary events so that
certification and inspection stay straightforward.
"""

STORE = "(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))"

TAIL13 = "((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))"
TAIL6 = "((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))"
TAIL4 = "((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))"
TAIL3 = "((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))"
TAIL1 = "((:RELOP (:I32) (:LT (:U))))"

Z = "(iz6 bytes sp pc clen result)"

HINTS = ("(disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ "
         "w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local "
         "frozen-store iz6 milawa-func-body dconst)")


def const(v):
    return f"(list :const '(:i32) {v})"


def body(val, tail):
    return f"(cons {const(val)} '{tail})"


def admin(b):
    """dadmin: a frame containing one label around b."""
    return f"(cons (list :frame_%{{%}}% 1 '{STORE} (list (list :label_%{{%}}% 1 nil {b}))) '{TAIL13})"


def frame(b):
    """dframe3: a frame around b."""
    return f"(cons (list :frame_%{{%}}% 1 '{STORE} {b}) '{TAIL13})"


def plain(b):
    """b appended to the tail (b is an instruction list)."""
    return f"(cons {b} '{TAIL13})"


A = const("(dsub pc)")
B1 = body("(dsub pc)", TAIL4)
B2 = f"(cons {A} (cons {const('clen')} '{TAIL3}))"
B3 = f"(cons {A} (cons {const('(dmul clen)')} '{TAIL1}))"
B4head = const('(dltu (dsub pc) (dmul clen))')   # the single instruction
B4 = f"(cons {B4head} nil)"

POSITIONS = [
    dict(name="cal-sub", ctxt="dconst-cal-sub-ctxt",
         hyps=["(unsigned-byte-p 32 pc)"],
         lit0=admin(body("pc", TAIL6)), lit1=admin(B1)),
    dict(name="cal-ldis", ctxt="dconst-cal-ldis-ctxt",
         hyps=[],
         lit0=admin(B4), lit1=frame(B4)),
    dict(name="cal-fdis", ctxt="dconst-cal-fdis-ctxt",
         hyps=[],
         lit0=frame(B4), lit1=plain(B4head)),
    dict(name="cal-read2", ctxt="dconst-cal-read2-ctxt2",
         hyps=["(unsigned-byte-p 32 pc)"],
         lit0=admin(body("(dsub pc)", TAIL4)), lit1=admin(B2)),
    dict(name="cal-mul", ctxt="dconst-cal-mul-ctxt2",
         hyps=["(unsigned-byte-p 32 pc)", "(unsigned-byte-p 32 clen)"],
         lit0=admin(B2), lit1=admin(B3)),
    dict(name="cal-ltu", ctxt="dconst-cal-ltu-ctxt2",
         hyps=["(unsigned-byte-p 32 pc)", "(unsigned-byte-p 32 clen)"],
         lit0=admin(B3), lit1=admin(B4)),
]


def implies(hyps, concl):
    if hyps:
        return f"(implies (and {' '.join(hyps)}) {concl})"
    return concl


def emit(p):
    n, c, h = p["name"], p["ctxt"], p["hyps"]
    l0, l1 = p["lit0"], p["lit1"]
    out = []
    out.append(f"(defthm spure-{n}-body")
    out.append(f"  (equal (w3t::step_pure {l0}) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_pure x))))))")
    out.append(f"(defthm sread-{n}-body")
    out.append(f"  (equal (w3t::step_read/split (list :|%;%| {Z} {l0})) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_read/split x))))))")
    out.append(f"(defthm ctxt-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step/r-ctxt-instrs (list :|%;%| {Z} {l0})) (list (list :|%;%| {Z} {l1})))')}")
    out.append("  :hints ((\"Goal\" :in-theory (disable w3t::step/r-ctxt-instrs)")
    out.append(f"           :use ({c}))))")
    out.append(f"(defthm match-{n}-body")
    out.append(f"  (equal (w3t::step_pure/match135 (take 13 {l0})) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_pure/match135 x))")
    out.append("                    (:free (x) (take 13 x))))))")
    out.append(f"(defthm search-{n}-body")
    out.append(f"  (equal (w3t::step_pure/search141 14 14 14 {l0}) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))")
    out.append(f"           :use (match-{n}-body))))")
    out.append(f"(defthm spure-{n}-label")
    out.append(f"  (equal (w3t::step_pure (list (list :label_%{{%}}% 1 nil {l0}))) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_pure x)))")
    out.append(f"           :use (search-{n}-body))))")
    out.append(f"(defthm sread-{n}-label")
    out.append(f"  (equal (w3t::step_read/split (list :|%;%| {Z} (list (list :label_%{{%}}% 1 nil {l0})))) nil)")
    out.append(f"  :hints ((\"Goal\" :in-theory {HINTS}")
    out.append("           :expand ((:free (x) (w3t::step_read/split x))))))")
    out.append(f"(defthm lbl-dconst-{n}-lit")
    out.append(f"  {implies(h, f'(equal (w3t::step (list :|%;%| {Z} (list (list :label_%{{%}}% 1 nil {l0})))) (list (list :|%;%| {Z} (list (list :label_%{{%}}% 1 nil {l1})))))')}")
    out.append("  :hints ((\"Goal\" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)")
    out.append(f"           :use ((:instance label-lift-general (z {Z}) (body {l0}) (z2 {Z}) (body2 {l1}))))))")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# THE LATER TIERS
#
# After the callee returns and the frame dissolves, the label-1 body is a
# plain instruction list sliced out of const-rest.  These positions differ in
# three ways from the six above:
#
#   * the body can begin with a value (the loaded word), so the label-level
#     pure/read facts carry the same typing hypotheses as the step itself;
#   * the store z is either the defun spelling zlset1, a variable z (when the
#     step updates the store: lset1/gset), or iz6;
#   * the search bound is the body length, not 14.
#
# The tail slices are computed from one Python list, so an off-by-one in an
# index shows up as a wrong body here, not as a mystery later.

TAIL13_XS = [
    "(:TESTOP (:I32) (:EQZ))",
    "(:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL)",
    "(:GLOBAL.GET 1)",
    "(:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0)))",
    "(:LOCAL.SET 1)",
    "(:GLOBAL.GET 1)",
    "(:CONST (:I32) 4)",
    "(:BINOP (:I32) (:ADD))",
    "(:GLOBAL.SET 1)",
    "(:LOCAL.GET 1)",
    "(:CALL 0)",
    "(:CONST (:I32) 1)",
    "(:RETURN)",
]


def lit(xs):
    """Render a Python instruction list as a quoted Lisp list."""
    return "'(" + " ".join(xs) + ")"


def cons(v, xs):
    """Render VALUE consed onto a Python instruction list."""
    return f"(cons {v} {lit(xs)})"


LOAD_HYPS = [
    "(w3t::un-p pc 32)",
    "(w3t::un-p W 32)",
    "(<= (+ pc 4) (len bytes))",
    "(equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))",
]

LATER_POSITIONS = [
    dict(name="cal-load", ctxt="dconst-load-ctxt", hyps=LOAD_HYPS,
         z="(iz6 bytes sp pc clen result)", z2="(iz6 bytes sp pc clen result)",
         l0=cons(const("pc"), TAIL13_XS[3:]), l1=cons(const("W"), TAIL13_XS[4:]),
         k=11, take=10),
    dict(name="cal-lset1", ctxt="dconst-lset1-ctxt",
         hyps=["(unsigned-byte-p 32 W)"],
         z="z", z2="(w3t::$with_local z 1 (list :const (list :i32) W))",
         l0=cons(const("W"), TAIL13_XS[4:]), l1=lit(TAIL13_XS[4:]),
         k=10, take=9),
    dict(name="cal-get1", ctxt="dconst-get1-ctxt", hyps=[],
         z="(zlset1 bytes sp pc clen result W)", z2="(zlset1 bytes sp pc clen result W)",
         l0=lit(TAIL13_XS[5:]), l1=cons(const("pc"), TAIL13_XS[6:]),
         k=8, take=7),
    dict(name="cal-add", ctxt="dconst-add-ctxt",
         hyps=["(unsigned-byte-p 32 pc)"],
         z="(zlset1 bytes sp pc clen result W)", z2="(zlset1 bytes sp pc clen result W)",
         l0=cons(const("pc"), TAIL13_XS[6:]), l1=cons(const("(dadd pc)"), TAIL13_XS[8:]),
         k=8, take=7),
    dict(name="cal-gset", ctxt="dconst-gset-ctxt",
         hyps=["(unsigned-byte-p 32 pc)"],
         z="z", z2="(w3t::$with_global z 1 (list :const (list :i32) (dadd pc)))",
         l0=cons(const("(dadd pc)"), TAIL13_XS[8:]), l1=lit(TAIL13_XS[9:]),
         k=6, take=5),
    dict(name="cal-lget", ctxt="dconst-lget-ctxt",
         hyps=["(equal (w3t::$local z 1) (list (list :const (list :i32) W)))"],
         z="z", z2="z",
         l0=lit(TAIL13_XS[9:]), l1=cons(const("W"), TAIL13_XS[10:]),
         k=4, take=3),
]


def emit_later(p):
    n, c, h, z, z2 = p["name"], p["ctxt"], p["hyps"], p["z"], p["z2"]
    l0, l1, k, tk = p["l0"], p["l1"], p["k"], p["take"]
    H = HINTS.replace("dconst)", "dconst zlset1)")
    out = []
    out.append(f"(defthm spure-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step_pure {l0}) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H}')
    out.append('           :expand ((:free (x) (w3t::step_pure x))))))')
    out.append(f"(defthm sread-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step_read/split (list :|%;%| {z} {l0})) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H}')
    out.append('           :expand ((:free (x) (w3t::step_read/split x))))))')
    out.append(f"(defthm ctxt-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step/r-ctxt-instrs (list :|%;%| {z} {l0})) (list (list :|%;%| {z2} {l1})))')}")
    out.append('  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)')
    out.append(f"           :use ({c}))))")
    out.append(f"(defthm match-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step_pure/match135 (take {tk} {l0})) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H}')
    out.append('           :expand ((:free (x) (w3t::step_pure/match135 x))')
    out.append(f"                    (:free (x) (take {tk} x))))))")
    out.append(f"(defthm search-{n}-body")
    out.append(f"  {implies(h, f'(equal (w3t::step_pure/search141 {k} {k} {k} {l0}) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H}')
    out.append(f"           :expand ((:free (x) (w3t::step_pure/search141 {k} {k} {k} x)))")
    out.append(f"           :use (match-{n}-body))))")
    out.append(f"(defthm spure-{n}-label")
    out.append(f"  {implies(h, f'(equal (w3t::step_pure (list (list :label_%{{%}}% 1 nil {l0}))) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H}')
    out.append('           :expand ((:free (x) (w3t::step_pure x)))')
    out.append(f"           :use (search-{n}-body))))")
    out.append(f"(defthm rsearch-{n}")
    out.append(f"  {implies(h, f'(equal (w3t::step_read/split/search60 (w3t::%tag-lo :RETURN_CALL_REF 1 {l0}) (w3t::%tag-lo :RETURN_CALL_REF 1 {l0}) (acl2::len {l0}) {l0}) nil)')}")
    out.append(f'  :hints (("Goal" :in-theory {H[:-1]} wrt::%tag-lo)')
    out.append('           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))')
    out.append(f"(defthm sread-{n}-label")
    out.append(f"  {implies(h, f'(equal (w3t::step_read/split (list :|%;%| {z} (list (list :label_%{{%}}% 1 nil {l0})))) nil)')}")
    out.append('  :hints (("Goal" :in-theory (disable w3t::step_read/split wrt::%tag-lo w3t::un-p mvm-word-to-bytes)')
    out.append(f'           :use ((:instance (:definition w3t::step_read/split)')
    out.append(f'                  (w3t::%a0 (list :|%;%| {z} (list (list :label_%{{%}}% 1 nil {l0})))))')
    out.append(f'                 rsearch-{n}))))')
    out.append(f"(defthm lbl-dconst-{n}-lit")
    out.append(f"  {implies(h, f'(equal (w3t::step (list :|%;%| {z} (list (list :label_%{{%}}% 1 nil {l0})))) (list (list :|%;%| {z2} (list (list :label_%{{%}}% 1 nil {l1})))))')}")
    out.append('  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)')
    out.append(f"           :use ((:instance label-lift-general (z {z}) (body {l0}) (z2 {z2}) (body2 {l1}))))))")
    return "\n".join(out)


def main():
    import sys
    later = "--later" in sys.argv
    print("; Generated by harness/gen_compose.py -- do not edit by hand.")
    for p in (LATER_POSITIONS if later else POSITIONS):
        print(emit_later(p) if later else emit(p))
        print()


if __name__ == "__main__":
    main()
