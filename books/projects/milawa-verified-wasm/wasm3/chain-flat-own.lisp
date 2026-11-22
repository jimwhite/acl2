; The flat body-6 `step`, over a state-shape-p pair, isolated from chain.
;
; The earlier concrete statements omitted the configuration's leading :%;%.
; With the keyword in place, `step-of-flat-block` applies directly: the state
; is the pair z (state-shape-p), and the body's head is the instruction.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "head")
(include-book "engine")

(defconst *body-6* (milawa-func-body 6))

(defthm chain-step-flat-own
  (implies (and (we::state-shape-p z)
                (equal inner (w3t::step (list :|%;%| z (list (car *body-6*)))))
                inner)
           (equal (w3t::step (list :|%;%| z *body-6*))
                  (list (list :|%;%| (cadr (car inner))
                              (append (caddr (car inner)) (cdr *body-6*))))))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity) ())
           :use ((:instance we::step-of-flat-block
                            (we::vals nil)
                            (we::i (car *body-6*))
                            (we::r (cdr *body-6*))
                            (we::s (cadr z))
                            (we::f (caddr z))
                            (we::a 0)
                            (we::inner inner))
                 (:instance we::rebuild-when-state-shape-p (we::z z))))))
