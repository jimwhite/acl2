; The chain's label and frame levels, through engine-admin-term-in-block.
;
; The engine's rule set is LOCAL; the exported facts mention only `w3t::` and
; the project's `milawa-state-pair-p`, so `links`/`frozen` can include this
; book without inheriting the engine's rules.  The old chain proofs were
; 1,217,401 and 6,861,519 prover steps.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "chain-flat-own")

(encapsulate ()
  (local (include-book "engine"))

  (local
   (defthm milawa-state-pair-p-is-we
     (equal (milawa-state-pair-p z) (we::state-shape-p z))
     :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                       we::state-shape-p)))))

  (defthm chain-state-pair
    (milawa-state-pair-p (mvm-abs-z-abstract bytes sp pc clen status result))
    :hints (("Goal"
             :use ((:instance we::state-shape-p-of-list
                              (we::s (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                              (we::f (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))))
             :in-theory (e/d (reconstruct-abs-z) (mvm-abs-z-abstract)))))

  (defthm chain-label-step
    (equal (w3t::step
            (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                  (list (list :label_%{%}% 1 nil *body-6*))))
           (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                       (list (list :label_%{%}% 1 nil
                                   (cons (list :const (list :i32) status)
                                         (cdr *body-6*)))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (e/d (we::admin-term we::exit-body-p)
                             (mvm-abs-z-abstract))
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil) (b *body-6*)
                              (s (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))
                              (f (caddr (mvm-abs-z-abstract bytes sp pc clen status result)))
                              (r nil)
                              (inner (w3t::step (list :|%;%|
                                                      (mvm-abs-z-abstract bytes sp pc clen status result)
                                                      *body-6*))))
                   (:instance chain-step-flat-own
                              (z (mvm-abs-z-abstract bytes sp pc clen status result))
                              (inner (w3t::step (list :|%;%|
                                                      (mvm-abs-z-abstract bytes sp pc clen status result)
                                                      (list (car *body-6*))))))
                   chain-state-pair
                   step-of-global-get-3))))

  (defthm chain-frame-step
    (implies (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f-prime)
                           (list (list :label_%{%}% 1 nil *body-6*))))
                    (list (list :|%;%| (list :|%;%| s2 f2)
                                (list (list :label_%{%}% 1 nil
                                            (cons (list :const (list :i32) status)
                                                  (cdr *body-6*)))))))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (list (list :frame_%{%}% 1 f-prime
                                       (list (list :label_%{%}% 1 nil *body-6*))))))
                    (list (list :|%;%| (list :|%;%| s2 f)
                                (list (list :frame_%{%}% 1 f2
                                            (list (list :label_%{%}% 1 nil
                                                        (cons (list :const (list :i32) status)
                                                              (cdr *body-6*))))))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (enable we::admin-term we::exit-body-p)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x f-prime)
                              (b (list (list :label_%{%}% 1 nil *body-6*)))
                              (s s) (f f) (r nil)
                              (inner (w3t::step
                                      (list :|%;%| (list :|%;%| s f-prime)
                                            (list (list :label_%{%}% 1 nil *body-6*)))))))))))
