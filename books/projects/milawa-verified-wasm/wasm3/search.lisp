; L1, layer 9: what the search does when an instruction is not ready.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; `step/r-ctxt-instrs` finds the instruction to step next: `step/prefix7` counts
; the leading values, then `step/search21` walks k DOWN from that count, and at
; each k it hands `step` the slice
;
;   (take (- (+ 1 prefix) k) (nthcdr k instrs))
;
; -- everything from position k to the instruction inclusive.  So as k decreases
; the slice grows, and the first k whose slice is a *complete* instruction
; application is the one that steps.  A comparison needs two operands, so for
; `(v1 v2 (:relop ...) rest)` the search tries k = 2 (a lone relop), then k = 1
; (one operand), and only at k = 0 (both operands) does anything happen.
;
; **This book proves the failure half of that story**, which is what the later
; chain positions need and what nothing in the tree had: `step` is NIL on an
; instruction that is missing operands.  Without these facts, a lemma about the
; third position of a body cannot be proved at all -- ACL2 is asked what the
; search does at k = 2 and k = 1 and has nothing to go on, so it falls into
; induction.  Measured: 8,600 prover steps and a top-level induction before, and
; 30,335 for both facts together once the instances are given explicitly.
;
; The measure matters here too.  At k = 0 the slice is the whole instruction list,
; so the config handed to `step` is not smaller and the search would not fire --
; it fires because `rest` is non-empty and hence the slice is a strict prefix.
; That is why every lemma in this file carries `(consp rest)`.

(in-package "ACL2")

(include-book "head")

; A comparison with no operands is not stepped: no rule matches, the search
; cannot go lower than k = 0, and the answer is NIL.
(defthm step-nil-on-a-lone-relop
  (equal (w3t::step (list :|%;%| z (list (list :relop (list :i32) (list :ne)))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :relop (list :i32) (list :ne))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :relop (list :i32) (list :ne)))) (w3t::%t9 0)
                            (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :relop (list :i32) (list :ne))))))))))

; One operand is still not enough.  This is the case the search reaches at
; k = 1, and it is why the third position of a body needs two values before it.
(defthm step-nil-on-a-relop-with-one-value
  (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) 1)
                                         (list :relop (list :i32) (list :ne)))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) 1)
                                                           (list :relop (list :i32) (list :ne))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) 1)
                                           (list :relop (list :i32) (list :ne)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) 1)
                                            (list :relop (list :i32) (list :ne))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) 1)
                                                           (list :relop (list :i32) (list :ne))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) 1)
                                            (list :relop (list :i32) (list :ne))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) 1)
                                                           (list :relop (list :i32) (list :ne))))))))))

; ---------------------------------------------------------------------------
; The third position of function 6's body.
; ---------------------------------------------------------------------------

; The instruction's list at that point: the status the first instruction read,
; the constant the second pushed, and the comparison.  Written as a let* of three
; names in the comments so the lemma below is readable.
;
;   v1 = (:const (:i32) status)      -- pushed by (:global.get 3)
;   v2 = (:const (:i32) 1)           -- pushed by (:const (:i32) 1)
;   i3 = (:relop (:i32) (:ne))       -- consumes both, pushes one value
;
; The search tries k = 2, then k = 1 (both nil, by the two facts above), and
; succeeds at k = 0 with the whole slice `(v1 v2 i3)`; the leading values are
; empty, so the search appends the instruction's result to `rest`.
(defthm flat-body-6-third
  (implies (and (consp rest)
                (true-listp rest)
                (true-listp val)
                ; The operand has to be a real i32, or `(:CONST (:I32) status)` is
                ; not a value at all and the search has nothing to slice.  Without
                ; this the proof case-splits on (integerp status) and stalls.
                (unsigned-byte-p 32 status)
                (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) status)
                                                       (list :const (list :i32) 1)
                                                       (list :relop (list :i32) (list :ne)))))
                       (list (list :|%;%| z2 val))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) status)
                               (cons (list :const (list :i32) 1)
                                     (cons (list :relop (list :i32) (list :ne))
                                           rest)))))
                  (list (list :|%;%| z2 (append val rest)))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) status)
                                                  (cons (list :const (list :i32) 1)
                                                        (cons (list :relop (list :i32) (list :ne))
                                                              rest))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) status)
                                           (cons (list :const (list :i32) 1)
                                                 (cons (list :relop (list :i32) (list :ne))
                                                       rest)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) status)
                                            (cons (list :const (list :i32) 1)
                                                  (cons (list :relop (list :i32) (list :ne))
                                                        rest))))
                            (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) status)
                                                  (cons (list :const (list :i32) 1)
                                                        (cons (list :relop (list :i32) (list :ne))
                                                              rest))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) status)
                                            (cons (list :const (list :i32) 1)
                                                  (cons (list :relop (list :i32) (list :ne))
                                                        rest))))
                            (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) status)
                                                  (cons (list :const (list :i32) 1)
                                                        (cons (list :relop (list :i32) (list :ne))
                                                              rest))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) status)
                                            (cons (list :const (list :i32) 1)
                                                  (cons (list :relop (list :i32) (list :ne))
                                                        rest))))
                            (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) status)
                                                  (cons (list :const (list :i32) 1)
                                                        (cons (list :relop (list :i32) (list :ne))
                                                              rest)))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))
