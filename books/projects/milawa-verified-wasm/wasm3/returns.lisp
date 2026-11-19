; L1, layer 7: returning.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The way out, and it is the cheapest layer in the library -- both return rules
; live in STEP_PURE, because both manipulations happen entirely inside the
; INSTRUCTION LIST: the frame and the label are admins that appear in that list, so
; unwrapping them needs no store at all.
;
; Measured, on the shape a call produces (calls.lisp), taking it apart one step at
; a time:
;
;   ((:FRAME_ 1 F ((:LABEL_ 1 nil ((:CONST 1) (:RETURN))))))   start
;   ((:FRAME_ 1 F ((:CONST 1) (:RETURN))))                     label gone
;   ((:CONST 1))                                               frame and return gone
;   NIL                                                        consumed
;
; So a return is two pure steps: out of the label, then out of the frame.  The
; value the callee produced is the prefix in front of the :RETURN, and that is
; what survives -- which is why the two lemmas below are stated with the value
; SYMBOLIC and nothing else in the instruction list.

(in-package "ACL2")

(include-book "calls")

; Out of the label: the label is dropped, its body kept whole -- including the
; :RETURN, which the next step consumes together with the frame.  The label's
; third field is its result-type list, and the rule matches on it as a list, so
; TRUE-LISTP of it is part of the hypothesis rather than an accident.  The value is
; 32-bit unsigned: the rule's own guard is (and (integerp x) (<= 0 x) (<= x
; 4294967295)), which is exactly UNSIGNED-BYTE-P 32, so stating it that way is both
; what the rule wants and what an i32 constant is.
(defthm step-pure-return-out-of-label
  (implies (and (true-listp is0) (unsigned-byte-p 32 x))
           (equal (w3t::step_pure
                   (list (list :label_%{%}% n is0
                               (list (list :const (list :i32) x) '(:return)))))
                  (list (list (list :const (list :i32) x) '(:return)))))
  :hints (("Goal" :expand ((:free (k lo hi i) (w3t::step_pure/search141 k lo hi i))))))

; Out of the frame: the frame and the :RETURN both go, and what is left is the
; callee's result.  The frame's arity is pinned to 1 because that is the module's own
; arity -- `step` returns one i32 -- and the rule requires the number of values
; returned to match it.  This is the step that hands the answer back to the caller, and
; it is worth noticing that nothing about the frame's CONTENTS matters -- the
; locals are discarded wholesale, which is what makes the lemma this cheap.
(defthm step-pure-return-out-of-frame
  (implies (unsigned-byte-p 32 x)
           (equal (w3t::step_pure
                   (list (list :frame_%{%}% 1 f
                               (list (list :const (list :i32) x) '(:return)))))
                  (list (list (list :const (list :i32) x)))))
  :hints (("Goal" :expand ((:free (k lo hi i j) (w3t::step_pure/search127 k lo hi i j))))))
