; L1, the links: consecutive steps of the exported function's body.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT-X11-style license)

; Each link is one step of function 6's body, from the configuration the previous
; link leaves behind, with the store, the frame and the label carried through.
; The recipe is the same at every position and it is proved here for two of them:
;
;   flat    -- which instruction runs, and what the search hands to `step`
;              (search.lisp: k = 0 each time, with the operands in the slice)
;   label   -- the same step inside a label, re-wrapped
;   frame   -- the same step inside a frame, re-wrapped, with the frame's own
;              locals replaced by whatever the inner step left
;   link    -- the three composed, which is what the chain needs
;
; Measured, per position: 1,525,484 + 5,143,242 + 443,329 prover steps for the
; second, and 593,575 for the first (chain.lisp).
;
; The pattern that made this work, and cost several attempts to find: pass the
; lower level with :USE rather than hoping it fires as a rewrite rule, and disable
; `step/r-ctxt-instrs` so the rewriter uses the lemma instead of re-expanding the
; search.  Do NOT disable the rule the level has to apply -- disabling
; `step/r-ctxt-label` while proving a frame level costs the proof.

(in-package "MILAWA-WASM")

(include-book "search")
(include-book "chain")


; The label level at the second position.  The body there is
;   (v1 . body-tail)  =  (v1 v2 (:relop ...) rest)
; and flat-body-6-second says the flat step consumes v1 and v2 and leaves the
; comparison's value at the head.  So the label comes back with that value in
; place of the three instructions, and the store is untouched.
(defthm step-in-label-body-6-second
  (implies (and (unsigned-byte-p 32 status)
                (true-listp val)
                (equal (w3t::step
                        (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :const (list :i32) status)
                                    (list :const (list :i32) 1)
                                    (list :relop (list :i32) (list :ne)))))
                       (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                   val))))
           (equal (w3t::step
                   (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                         (list (list :label_%{%}% 1 nil
                                     (cons (list :const (list :i32) status)
                                           (cdr *body-6*))))))
                  (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :label_%{%}% 1 nil
                                          (append val (nthcdr 3 *body-6*))))))))
  :hints (("Goal"
           :use ((:instance flat-body-6-second
                            (z (mvm-abs-z-abstract bytes sp pc clen status result))
                            (z2 (mvm-abs-z-abstract bytes sp pc clen status result))
                            (rest (nthcdr 3 *body-6*)))
                 (:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                            (list (list :label_%{%}% 1 nil
                                                        (cons (list :const (list :i32) status)
                                                              (cdr *body-6*))))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

; ---------------------------------------------------------------------------
; The frame level at the second position.
; ---------------------------------------------------------------------------
;
; Same shape as frame-body-6-general, but at the body the second step actually
; sees: the value the first instruction pushed.  The label result arrives as a
; hypothesis, so this lemma is about the descent only.
(defthm step-in-frame-body-6-second
  (implies (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f-prime)
                         (list (list :label_%{%}% 1 nil
                                     (cons (list :const (list :i32) status)
                                           (cdr *body-6*))))))
                  (list (list :|%;%| (list :|%;%| s2 f2)
                              (list (list :label_%{%}% 1 nil
                                          (append val (nthcdr 3 *body-6*)))))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (list (list :frame_%{%}% 1 f-prime
                                     (list (list :label_%{%}% 1 nil
                                                 (cons (list :const (list :i32) status)
                                                       (cdr *body-6*))))))))
                  (list (list :|%;%| (list :|%;%| s2 f)
                              (list (list :frame_%{%}% 1 f2
                                          (list (list :label_%{%}% 1 nil
                                                      (append val (nthcdr 3 *body-6*))))))))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (list (list :frame_%{%}% 1 f-prime
                                                        (list (list :label_%{%}% 1 nil
                                                                    (cons (list :const (list :i32) status)
                                                                          (cdr *body-6*))))))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

; ---------------------------------------------------------------------------
; THE SECOND LINK.
; ---------------------------------------------------------------------------
;
; One more step of function 6's body, from the configuration the first link
; leaves behind.  Two instructions have now run: the read, and the comparison's
; two operands.  The value the comparison produced is `val`, which the walk says
; is `(:const (:i32) expr)` -- left abstract here, because this lemma is about
; the descent and the flat step, not about arithmetic.
(defthm step-body-6-second
  (implies (and (unsigned-byte-p 32 status)
                (true-listp val)
                (equal (w3t::step
                        (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :const (list :i32) status)
                                    (list :const (list :i32) 1)
                                    (list :relop (list :i32) (list :ne)))))
                       (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                   val))))
           (equal (w3t::step
                   (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                         (list (list :frame_%{%}% 1 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                                     (list (list :label_%{%}% 1 nil
                                                 (cons (list :const (list :i32) status)
                                                       (cdr *body-6*))))))))
                  (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :frame_%{%}% 1 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                                          (list (list :label_%{%}% 1 nil
                                                      (append val (nthcdr 3 *body-6*))))))))))
  :hints (("Goal"
           :use ((:instance step-in-frame-body-6-second
                            (s (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f-prime (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (s2 (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f2 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))))
                 step-in-label-body-6-second)
           :in-theory (disable w3t::step/r-ctxt-instrs))))


; ---------------------------------------------------------------------------
; Two steps, composed.
; ---------------------------------------------------------------------------
;
; The two links are proved separately, and separately proved lemmas can be true
; and still not *chain* -- a lesson from the vacuous `flat-body-6-second` earlier
; in this book's history.  So this composes them: step the configuration a call
; leaves behind, step the result, and check the answer is the one the second link
; predicts.
;
; `(car (step c))` is how the semantics is driven: `step` returns the list of
; successor configurations (it is single-valued when it returns at all), so the
; second step is a step of the first successor.
;
; What it says, in words: two instructions of the exported function's body have
; run -- the read of global 3 and the comparison of its value against 1 -- and the
; machine is left with the comparison's result in place of those two instructions,
; the frame and the label around it, and the store untouched.
(defthm step-body-6-two
  (implies (and (unsigned-byte-p 32 status)
                (true-listp val)
                (equal (w3t::step
                        (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :const (list :i32) status)
                                    (list :const (list :i32) 1)
                                    (list :relop (list :i32) (list :ne)))))
                       (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                   val))))
           (equal (w3t::step
                   (car (w3t::step
                         (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                               (list (list :frame_%{%}% 1
                                           (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                                           (list (list :label_%{%}% 1 nil *body-6*))))))))
                  (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (list (list :frame_%{%}% 1
                                          (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                                          (list (list :label_%{%}% 1 nil
                                                      (append val (nthcdr 3 *body-6*))))))))))
  :hints (("Goal"
           :use (step-body-6-first
                 step-body-6-second)
           :in-theory (disable w3t::step w3t::step/r-ctxt-instrs))))
