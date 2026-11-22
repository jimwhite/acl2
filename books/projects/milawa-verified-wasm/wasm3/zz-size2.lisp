(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/engine/rules/flat")

(set-prover-step-limit 20000000)

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
  :rule-classes (:rewrite :linear))

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
  :rule-classes (:rewrite :linear))

(defthm %size-append-two-instr-zero
  (implies (and (we::vals-p x) (consp r))
           (< (wrt::%size (append x (list i j)))
              (wrt::%size (append x (list* i j r)))))
  :hints (("Goal" :use ((:instance %size-of-operands-and-two-instr
                                   (k 0) (p (+ 1 (len x))))
                        (:instance we::vals-p-true-listp (l x)))
                  :in-theory (disable %size-of-operands-and-two-instr
                                      we::vals-p-true-listp)))
  :rule-classes (:rewrite :linear))

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
        (flat-search2 (1- k) x i j r z)))))

(defthm flat-search2-when-not-natp
  (implies (not (natp k))
           (equal (flat-search2 k x i j r z) nil))
  :hints (("Goal" :expand ((flat-search2 k x i j r z)))))

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
                    (:free (r) (flat-search2 0 x i j r z))))))

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
