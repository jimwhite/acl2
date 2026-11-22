; The flat body-6 `step`, over a project state-pair predicate, isolated from
; chain.  The engine's rule set is LOCAL: the exported lemma mentions only
; `w3t::` and the project predicate, so a book including this one does not
; inherit the engine's eager rules.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "head")

(defconst *body-6* (milawa-func-body 6))

(defun milawa-state-pair-p (z)
  (and (consp z) (equal (car z) :|%;%|)
       (consp (cdr z)) (consp (cddr z)) (null (cdddr z))))

(encapsulate ()
  (local (include-book "engine"))

  (local
   (defthm milawa-state-pair-p-is-we
     (equal (milawa-state-pair-p z) (we::state-shape-p z))
     :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                       we::state-shape-p)))))

  (defthm chain-step-flat-own
    (implies (and (milawa-state-pair-p z)
                  (equal inner (w3t::step (list :|%;%| z (list (car *body-6*)))))
                  inner)
             (equal (w3t::step (list :|%;%| z *body-6*))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner)) (cdr *body-6*))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity
                              milawa-state-pair-p)
                             ())
             :use ((:instance we::step-of-flat-block
                              (we::vals nil)
                              (we::i (car *body-6*))
                              (we::r (cdr *body-6*))
                              (we::s (cadr z))
                              (we::f (caddr z))
                              (we::a 0)
                              (we::inner inner))
                   (:instance we::rebuild-when-state-shape-p (we::z z)))))))
