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
                                     (r (cdr b)))))))  (local
   (defthm %size-of-operands-and-two-instr
  (implies (and (natp k) (<= k (len x)) (true-listp x)
                (equal p (+ 1 (len x)))
                (or (posp k) (consp r)))
           (< (wrt::%size
               (take (- (+ 1 p) k)
                     (nthcdr k (append x (cons i (cons j r))))))
              (wrt::%size (append x (cons i (cons j r))))))
  :hints (("Goal" :use ((:instance we::%size-check-of-sublist
                                   (k k)
                                   (m (- (+ 1 p) k))
                                   (l (append x (cons i (cons j r))))
                                   (z2 z)))
                  :in-theory (disable we::%size-check-of-sublist)))
  :rule-classes (:rewrite :linear)))

  (local
   (defthm %size-append-two-instr
  (implies (and (we::vals-p x) (natp k) (<= k (len x))
                (equal p (+ 1 (len x)))
                (or (< 0 k) (consp r)))
           (< (wrt::%size (append (nthcdr k x) (list i j)))
              (wrt::%size (append x (cons i (cons j r))))))
  :hints (("Goal" :use (%size-of-operands-and-two-instr
                        (:instance we::vals-p-true-listp (l x)))
                  :in-theory (e/d (posp) (%size-of-operands-and-two-instr
                                                  we::vals-p-true-listp))))
  :rule-classes (:rewrite :linear)))

  (local
   (defthm %size-append-two-instr-zero
  (implies (and (we::vals-p x) (consp r))
           (< (wrt::%size (append x (list i j)))
              (wrt::%size (append x (list* i j r)))))
  :hints (("Goal" :use ((:instance %size-of-operands-and-two-instr
                                   (k 0) (p (+ 1 (len x))))
                        (:instance we::vals-p-true-listp (l x)))
                  :in-theory (disable %size-of-operands-and-two-instr
                                      we::vals-p-true-listp)))
  :rule-classes (:rewrite :linear)))

  (local
   (defun flat-search2 (k x i j r z)
  (declare (xargs :measure (nfix (+ 1 k))))
  (if (not (natp k))
      nil
    (let ((inner (w3t::step (list :|%;%| z
                                 (append (nthcdr k x) (list i) (list j))))))
      (if (and (or (posp k) (consp r)) inner)
          (list (list :|%;%| (cadr (car inner))
                      (append (take k x)
                              (append (caddr (car inner)) r))))
        (flat-search2 (1- k) x i j r z))))))

  (local
   (defthm flat-search2-when-not-natp
  (implies (not (natp k))
           (equal (flat-search2 k x i j r z) nil))
  :hints (("Goal" :expand ((flat-search2 k x i j r z))))))

  (local
   (defthm step/search21-becomes-flat-search2
  (implies (and (we::vals-p x)
                (true-listp x)
                (not (w3t::val-p i))
                (not (w3t::val-p j))
                (true-listp r)
                (natp k)
                (<= k (len x))
                (equal p (+ 1 (len x))))
           (equal (w3t::step/search21
                   k 0 p (append x (cons i (cons j r))) p z
                   (list :|%;%| z (append x (cons i (cons j r)))))
                  (flat-search2 k x i j r z)))
  :hints (("Goal"
           :induct (flat-search2 k x i j r z)
           :in-theory (disable (:definition flat-search2)
                               we::step/search21-becomes-flat-search)
           :expand ((:free (p l c) (w3t::step/search21 k 0 p l p z c))
                    (flat-search2 k x i j r z)
                    (:free (p l c) (w3t::step/search21 0 0 p l p z c))
                    (:free (r) (flat-search2 0 x i j r z)))))))

  ;; TWO VALUES then the instruction: the call-entry shape (const argument,
  ;; function reference, call_ref).  `flat-search` at k = 2 steps only the
  ;; lone instruction (nil), k = 1 the reference plus it (nil), and k = 0 the
  ;; whole slice (the call entry); the result drops both values.
  (defthm engine-ctxt-two-values-instr-step
    (implies (and (w3t::val-p v)
                  (w3t::val-p w)
                  (not (w3t::val-p i))
                  (true-listp r)
                  (consp r)
                  (equal (w3t::step (list :|%;%| z (list i))) nil)
                  (equal (w3t::step (list :|%;%| z (list w i))) nil)
                  (equal inner (w3t::step (list :|%;%| z (list v w i))))
                  inner)
             (equal (w3t::step/r-ctxt-instrs
                     (list :|%;%| z (cons v (cons w (cons i r)))))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner)) r)))))
    :rule-classes nil
    :hints (("Goal"
             :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                              (we::x (list v w)) (we::i i)
                              (we::r r) (we::z z)))
             :expand ((we::flat-search 2 (list v w) i r z)
                      (we::flat-search 1 (list v w) i r z)
                      (we::flat-search 0 (list v w) i r z))
             :do-not-induct t)))

  (defthm engine-ctxt-pair-instr-step
  (implies (and (w3t::val-p v)
                (consp i)
                (consp j)
                (not (w3t::val-p i))
                (not (w3t::val-p j))
                (true-listp r)
                (consp r)
                (equal (w3t::step/prefix7 (cons v (cons i (cons j r)))) 2)
                (equal (w3t::step (list :|%;%| z (list j))) nil)
                (equal (w3t::step (list :|%;%| z (list i j))) nil)
                (equal inner (w3t::step (list :|%;%| z (list v i j))))
                inner)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cons v (cons i (cons j r)))))
                  (list (list :|%;%| (cadr (car inner))
                              (append (caddr (car inner)) r)))))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                               w3t::step/search21 w3t::step/prefix7)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (cons v (cons i (cons j r))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons v (cons i (cons j r)))) (w3t::%t9 2)
                            (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (cons v (cons i (cons j r))))))
                 (:instance step/search21-becomes-flat-search2
                            (k 1) (x (list v)) (i i) (j j) (r r) (z z)
                            (p 2)))
           :do-not-induct t)))
)
