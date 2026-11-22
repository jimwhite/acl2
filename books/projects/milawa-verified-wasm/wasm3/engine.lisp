; The label/handler/frame engine lift.
;
; This book keeps the engine's rule set GLOBAL, because `admin-term`,
; `state-shape-p` and `exit-body-p` are WE functions that the exported
; theorem mentions.  A book that includes it gets the engine's rules too; the
; flat/context lemmas live in `engine-flat.lisp`, which keeps them local so a
; chain proof's default theory is unchanged.
;
; Measured on `const-callee`'s read1 position (AUTOMATION-RESEARCH.md,
; Appendix C): `tail-cl-read1-label0-rest` is 1,173,308 prover steps; this
; generic lift is 7,189, and `tail-cl-read1-label1`/`-frame` are instances of
; it too.
;
; The engine books are MIT-licensed; see wasm-acl2/LICENSE.  The pin is
; wasm-acl2 1ce59e0 (engine-plan2).

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/engine/rules/context")

;; `admin-term` builds exactly the project's (:label_%{%}% n x b),
;; (:handler_%{%}% ...) and (:frame_%{%}% ...) literals.  `r` may be nil (the
;; admin term alone) or the rest after it; `v` (values before it) is nil in
;; every position this project has, so the lemma is stated for that case.

(defthm engine-admin-term-in-block
  (implies (and (member-equal k '(:l :h :f))
                (or (equal k :f) (true-listp x))
                (true-listp b)
                (not (we::exit-body-p b))
                (true-listp r)
                (equal inner (w3t::step (list :|%;%|
                                              (list :|%;%| s (if (equal k :f) x f))
                                              b)))
                inner
                (we::state-shape-p (cadr (car inner))))
           (equal (w3t::step (list :|%;%| (list :|%;%| s f)
                                   (cons (we::admin-term k n x b) r)))
                  (list (list :|%;%|
                              (list :|%;%| (cadr (cadr (car inner)))
                                    (if (equal k :f) f (caddr (cadr (car inner)))))
                              (cons (we::admin-term k n
                                                    (if (equal k :f)
                                                        (caddr (cadr (car inner)))
                                                      x)
                                                    (caddr (car inner)))
                                    r)))))
  :hints (("Goal" :use ((:instance we::step-of-admin-term-in-block
                                   (we::k k) (we::n n) (we::x x) (we::b b)
                                   (we::s s) (we::f f) (we::v nil) (we::r r)
                                   (we::inner inner))))))
