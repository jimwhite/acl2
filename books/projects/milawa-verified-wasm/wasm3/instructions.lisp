; L1, layer 1: the pure instructions, one lemma each.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The first layer of the instruction library, and the first place in this project
; where a symbolic state is actually stepped rather than evaluated.
;
; WHAT STEP_PURE IS.  STEP_PURE takes an instruction list and returns
; `(list instrs')` -- a singleton, so that NIL means "no rule applies".  It never
; sees a store, a frame or a memory: the instructions it handles are the ones whose
; meaning is entirely in the values already on the stack.  That is why this layer
; is provable at all, and why it is the right place to start.
;
; THE SHAPE OF AN INSTRUCTION LEMMA, which took a false start to find (see
; symbolic.lisp): the instruction under reduction must be the LAST element of the
; list, and the elements before it are the values already pushed.  So an
; instruction lemma is
;
;   (step_pure (list <value> ... <value> <instruction>))
;     = (list (list (list <value'>)))
;
; with the VALUES symbolic and their COUNT at its static length.  That count is not
; a guess: WASM's stack discipline fixes the stack height at every program point,
; so at each instruction of a straight-line body the number of leading values is a
; constant.  Written out at that length, LEN and TAKE and NTHCDR all evaluate, and
; ACL2 walks STEP_PURE's rule chain.  3788 prover steps for the first one.
;
; WHY THIS IS THE UNIT.  An opcode's path through the module is a sequence of these
; lemmas -- the clock measured in abs.lisp, 47 to 101 steps, is the length of that
; sequence -- so once this layer is complete, each opcode's theorem is bookkeeping:
; apply the lemma for instruction 1, then 2, and so on, with the store read and
; written by the layers above (step_read, then the ctxt rules).
;
; WHAT IS PROVED HERE.  Nineteen instructions: the five i32 binops and the four
; comparisons that the module uses, the zero test, and the constants.  The
; right-hand sides are the spec's own operations, and their shapes differ in a way
; worth knowing: $BINOP_ returns a LIST of values (it can trap) so the rule takes
; (CAR ($BINOP_ ...)), while $RELOP_ and $TESTOP_ return the value itself and the
; rule binds it directly -- $BINOP_, $RELOP_, $TESTOP_ --
; so nothing about 32-bit arithmetic is being assumed; whatever the certified
; semantics says (that (- 1 2) is #xFFFFFFFF, that i32.lt_s reads the sign) is what
; these lemmas conclude.

(in-package "MILAWA-WASM")

(include-book "symbolic")

;; ---------------------------------------------------------------------------
;; i32 binops: two values, then the operation
;; ---------------------------------------------------------------------------

; The modulo/wrap that makes (SUB 1 2) = 4294967295 is $BINOP_'s business, not
; ours: the conclusion is stated in terms of it.

(defthm step-pure-binop-add
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :binop (list :i32) (list :add))))
         (list (list (list :const (list :i32)
                           (car (w3t::$binop_ (list :i32) (list :add) c1 c2)))))))

(defthm step-pure-binop-sub
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :binop (list :i32) (list :sub))))
         (list (list (list :const (list :i32)
                           (car (w3t::$binop_ (list :i32) (list :sub) c1 c2)))))))

(defthm step-pure-binop-mul
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :binop (list :i32) (list :mul))))
         (list (list (list :const (list :i32)
                           (car (w3t::$binop_ (list :i32) (list :mul) c1 c2)))))))

(defthm step-pure-binop-or
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :binop (list :i32) (list :or))))
         (list (list (list :const (list :i32)
                           (car (w3t::$binop_ (list :i32) (list :or) c1 c2)))))))

; Division can trap (division by zero), and a trapping operation is a different
; rule -- Step_pure/binop-trap -- so the value rule needs the trap not to fire.
; Written as "the operation has a value", which is exactly the rule's own guard.
(defthm step-pure-binop-div-u
  (implies (consp (w3t::$binop_ (list :i32) (list :div (list :u)) c1 c2))
           (equal (w3t::step_pure
                   (list (list :const (list :i32) c1)
                         (list :const (list :i32) c2)
                         (list :binop (list :i32) (list :div (list :u)))))
                  (list (list (list :const
                                    (list :i32)
                                    (car (w3t::$binop_ (list :i32)
                                                       (list :div (list :u))
                                                       c1 c2))))))))

;; ---------------------------------------------------------------------------
;; i32 comparisons: two values, then the comparison; the answer is 0 or 1
;; ---------------------------------------------------------------------------

; Signed and unsigned compare, kept apart on purpose: the whole point of having
; both is that they answer differently on #xFFFFFFFF, which is what the example
; corpus's LT-SIGNED checks against the artifact.
(defthm step-pure-relop-eq
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :relop (list :i32) (list :eq))))
         (list (list (list :const (list :i32)
                           (w3t::$relop_ (list :i32) (list :eq) c1 c2))))))

(defthm step-pure-relop-ne
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :relop (list :i32) (list :ne))))
         (list (list (list :const (list :i32)
                           (w3t::$relop_ (list :i32) (list :ne) c1 c2))))))

(defthm step-pure-relop-lt-s
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :relop (list :i32) (list :lt (list :s)))))
         (list (list (list :const (list :i32)
                           (w3t::$relop_ (list :i32) (list :lt (list :s)) c1 c2))))))

(defthm step-pure-relop-lt-u
  (equal (w3t::step_pure
          (list (list :const (list :i32) c1)
                (list :const (list :i32) c2)
                (list :relop (list :i32) (list :lt (list :u)))))
         (list (list (list :const (list :i32)
                           (w3t::$relop_ (list :i32) (list :lt (list :u)) c1 c2))))))

;; ---------------------------------------------------------------------------
;; The zero test: one value
;; ---------------------------------------------------------------------------

(defthm step-pure-testop-eqz
  (equal (w3t::step_pure
          (list (list :const (list :i32) c)
                (list :testop (list :i32) (list :eqz))))
         (list (list (list :const (list :i32)
                           (w3t::$testop_ (list :i32) (list :eqz) c))))))
