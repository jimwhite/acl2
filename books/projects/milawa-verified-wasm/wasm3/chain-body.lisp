; The first link, through the refactored label/frame facts.
;
; `chain.lisp` no longer proves the label or frame levels; this book gets them
; from `chain-label-generic` (`chain-label-step`, `chain-frame-step`) and
; instantiates them at the abstract store.  The old chain proof of this lemma
; used `frame-body-6-general` (6,861,519 prover steps); the new facts are the
; admin-lift instances.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "chain")
(include-book "chain-label-generic")

(defthm step-body-6-first
  (equal (w3t::step
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :frame_%{%}% 1 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                            (list (list :label_%{%}% 1 nil *body-6*))))))
         (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                     (list (list :frame_%{%}% 1 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))
                                 (list (list :label_%{%}% 1 nil
                                             (cons (list :const (list :i32) status)
                                                   (cdr *body-6*)))))))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                               mvm-abs-z-abstract)
           :use ((:instance chain-frame-step
                            (s (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f-prime (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (s2 (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                            (f2 (caddr (mvm-abs-z-abstract bytes sp pc clen status result))))
                 chain-label-step))))
