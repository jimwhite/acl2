; The generic engine facts, reused in this project.
;
; `wasm-acl2`'s `engine-plan2` branch proves the search/context/descent lemmas
; for the same `w3t::step` functions this project uses.  Three of them are
; stated here in MILAWA-WASM, with the project's own configuration shapes, so
; a position can be a few `:use` instances instead of a 20-lemma family.
;
; Measured on `const-callee`'s read1 position (details in
; AUTOMATION-RESEARCH.md, Appendix C):
;
;   tail-cl-read1-ctxt-d       94,813 steps -> engine-ctxt-from-instr-step 841
;   tail-cl-read1-label0-rest 1,173,308     -> engine-admin-term-in-block 7,189
;   tail-cl-read1-label1        56,263      -> the same generic lemma
;   tail-cl-read1-frame         25,820      -> the same generic lemma
;
; The engine books are MIT-licensed; see
; wasm-acl2/LICENSE.  The pin is wasm-acl2 1ce59e0 (engine-plan2).

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/engine/rules/context")

;; ---------------------------------------------------------------------------
;; 1. The search bridge.
;;
;; `step/r-ctxt-instrs` on a value prefix and one instruction becomes
;; `flat-search`, with the `%SIZE` test discharged once inside the engine.
;; Kept :rule-classes nil: it is used through :use, and as a rewrite rule it
;; subsumes the more useful context lemma below.

(defthm engine-flat-search-bridge
  (implies (and (true-listp r)
                (not (w3t::val-p i)))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons i r)))
                  (we::flat-search 0 nil i r z)))
  :rule-classes nil
  :hints (("Goal" :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                                   (we::x nil) (we::i i) (we::r r) (we::z z))))))

;; ---------------------------------------------------------------------------
;; 2. The context rule, in terms of the instruction's own step.
;;
;; No %SIZE/search arithmetic in the position's proof: the bridge above has
;; already done it.  This is the replacement for the per-position
;; `ctxt`/`match`/`search`/`label0-rest` family.

(defthm engine-ctxt-from-instr-step
  (implies (and (not (w3t::val-p i))
                (true-listp r)
                (consp r)
                (equal inner (w3t::step (list :|%;%| z (list i))))
                inner)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons i r)))
                  (list (list :|%;%| (cadr (car inner))
                              (append (caddr (car inner)) r)))))
  :hints (("Goal" :use engine-flat-search-bridge
                  :expand ((we::flat-search 0 nil i r z)))))

;; ---------------------------------------------------------------------------
;; 3. The label/handler/frame lift.
;;
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
