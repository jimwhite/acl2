; The flat/context engine lemmas, with the engine's rule set LOCAL.
;
; `chain.lisp` includes this book, not `engine.lisp`.  The engine's rule set
; is large and eager; including it globally changes the default theory of the
; chain's label/frame proofs (measured: the label lift fails after the include).
; A local include keeps the rules available to the proofs here and out of the
; theory a later book gets.
;
; The exported lemmas mention only `w3t::` functions.  The bridge mentions
; `we::flat-search`, so it is local too.
;
; The engine books are MIT-licensed; see wasm-acl2/LICENSE.  The pin is
; wasm-acl2 1ce59e0 (engine-plan2).

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/translate/gen/wasm-3.0/wasm3")

(encapsulate ()
  (local (include-book "../wasm-acl2/engine/rules/context"))

  ;; The bridge to the engine's flat search.  Local: its statement mentions
  ;; WE::FLAT-SEARCH, which a later book does not have.
  (local
   (defthm engine-flat-search-bridge
     (implies (and (true-listp r)
                   (not (w3t::val-p i)))
              (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons i r)))
                     (we::flat-search 0 nil i r z)))
     :rule-classes nil
     :hints (("Goal" :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                                      (we::x nil) (we::i i) (we::r r) (we::z z)))))))

  ;; The context rule, in terms of the instruction's own step.  No %SIZE or
  ;; search arithmetic in the caller.
  (defthm engine-ctxt-from-instr-step
    (implies (and (not (w3t::val-p i))
                  (true-listp r)
                  (consp r)
                  (equal inner (w3t::step (list :|%;%| z (list i))))
                  inner)
             (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons i r)))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner)) r)))))
    :rule-classes nil
    :hints (("Goal" :use engine-flat-search-bridge
                    :expand ((we::flat-search 0 nil i r z)))))

  ;; The same law for a whole body B.  1,399 prover steps.
  (defthm engine-flat-body-step
    (implies (and (consp b)
                  (not (w3t::val-p (car b)))
                  (true-listp (cdr b))
                  (consp (cdr b))
                  (equal inner (w3t::step (list :|%;%| z (list (car b)))))
                  inner)
             (equal (w3t::step/r-ctxt-instrs (list :|%;%| z b))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner)) (cdr b))))))
    :rule-classes nil
    :hints (("Goal" :use ((:instance engine-ctxt-from-instr-step
                                     (i (car b))
                                     (r (cdr b))))))))
