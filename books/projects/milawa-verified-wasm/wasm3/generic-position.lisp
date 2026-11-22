; A position stated through the generic engine lemma.
;
; `chain.lisp`'s `step-flat-body-6-first` proves the first flat step of
; function 6's body from the search's definition and the `%SIZE` arithmetic:
; 145,059 prover steps.  This book proves the same law generically, with the
; head instruction's own step as a hypothesis, from `engine-ctxt-from-instr-step`
; (itself proved in `engine.lisp` from the engine's flat-search bridge).  A
; position is then two `:use` facts, not a search expansion.
;
; The concrete instance is one line:
;
;   (engine-flat-body-6-step
;    :z (mvm-abs-z-abstract bytes sp pc clen status result)
;    :inner (list (list :|%;%| z (list (list :const (list :i32) status)))))
;   + step-of-global-get-3
;
; which is what a future rewrite of `chain.lisp` should emit.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "engine")
(include-book "chain")

(defthm engine-flat-body-6-step
  (implies (and (equal inner (w3t::step (list :|%;%| z (list (car *body-6*)))))
                inner)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z *body-6*))
                  (list (list :|%;%| (cadr (car inner))
                              (append (caddr (car inner)) (cdr *body-6*))))))
  :hints (("Goal" :use ((:instance engine-ctxt-from-instr-step
                                   (i (car *body-6*))
                                   (r (cdr *body-6*)))))))
