; The flat/context engine lemmas, with the engine's rule set LOCAL.
;
; `chain.lisp` includes this book, not `engine.lisp`.  The engine's rule set
; is large and eager; including it globally changes the default theory of the
; chain's label/frame proofs (measured: the label lift fails after the include).
; A local include keeps the rules available to the proofs here and out of the
; theory a later book gets.
;
; The exported lemmas mention only `w3t::` functions (and project predicates).
; The bridge mentions `we::flat-search`, so it is local too.
;
; The engine books are MIT-licensed; see wasm-acl2/LICENSE.  The pin is
; wasm-acl2 1ce59e0 (engine-plan2).

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/translate/gen/wasm-3.0/wasm3")

; The engine's value-list predicate is WE::VALS-P, which cannot appear in an
; exported statement (certify-book Step 1 runs before the local include).  This
; is the same predicate in project vocabulary; the local bridge below proves
; they agree.  Callers prove it on their concrete value prefixes by evaluation.
(defun milawa-values-p (x)
  (if (atom x)
      (null x)
    (and (w3t::val-p (car x))
         (milawa-values-p (cdr x)))))

(encapsulate ()
  (local (include-book "../wasm-acl2/engine/rules/context"))

  (local
   (defthm milawa-values-p-is-we
     (equal (milawa-values-p x) (we::vals-p x))
     :hints (("Goal" :induct (milawa-values-p x)
                     :in-theory (enable milawa-values-p we::vals-p)))))

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

  ;; A VALUES PREFIX before the instruction.  `flat-search` at k = (len x)
  ;; steps the instruction alone and puts the values back in front of its
  ;; result.  This is the "const, call" shape where the call is the first
  ;; non-value and its own step is the isolated one.
  (defthm engine-ctxt-from-values-instr-step
    (implies (and (milawa-values-p x)
                  (not (w3t::val-p i))
                  (true-listp x)
                  (true-listp r)
                  (or (consp x) (consp r))
                  (equal inner (w3t::step (list :|%;%| z (list i))))
                  inner)
             (equal (w3t::step/r-ctxt-instrs
                     (list :|%;%| z (append x (cons i r))))
                    (list (list :|%;%| (cadr (car inner))
                                (append x (append (caddr (car inner)) r))))))
    :rule-classes nil
    :hints (("Goal" :use engine-flat-search-bridge
                    :expand ((we::flat-search (len x) x i r z)))))

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
