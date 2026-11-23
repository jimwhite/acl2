; The dispatcher true-comparison and branch instruction rest lemmas.
;
(in-package "MILAWA-WASM")
(include-book "ops-dispatch")
(include-book "ops-sub-body")

(defthm ieq-value-all
  (equal (w3t::$ieq_ 32 v j)
         (if (equal v j) 1 0))
  :hints (("Goal" :in-theory (enable w3t::$ieq_ w3t::$bool))))

(defthm lt-signed-value
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2))
           (equal (w3t::$ilt_ 32 (list :s) v1 v2)
                  (if (< v1 v2) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ilt_ w3t::$signed_ w3t::$bool))))

(defthm ieqz-value
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::$ieqz_ 32 v)
                  (if (equal v 0) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ieqz_ w3t::$bool))))

(defthm imul-01
  (implies (and (unsigned-byte-p 32 v)
                (or (equal c 0) (equal c 1)))
           (equal (w3t::$imul_ 32 v c)
                  (if (equal c 1) v 0)))
  :hints (("Goal"
           :in-theory (enable w3t::$imul_ rem-positive-as-mod
                              loghead-32-as-mod)
           :cases ((equal c 0) (equal c 1)))))

(defthm d-local-get-1
  (equal (w3t::step (dcfg (dz op a b) (list (list :local.get 1))))
         (list (dcfg (dz op a b) (list (list :const (list :i32) a)))))
  :hints (("Goal"
           :in-theory (enable dcfg dz dframe ir-frame-with-locals)
           :expand ((w3t::step (dcfg (dz op a b) (list (list :local.get 1)))))
           :do-not-induct t)))

(defthm d-local-get-2
  (equal (w3t::step (dcfg (dz op a b) (list (list :local.get 2))))
         (list (dcfg (dz op a b) (list (list :const (list :i32) b)))))
  :hints (("Goal"
           :in-theory (enable dcfg dz dframe ir-frame-with-locals)
           :expand ((w3t::step (dcfg (dz op a b) (list (list :local.get 2)))))
           :do-not-induct t)))

(defthm d-local-get-1-plain
  (equal (w3t::step
          (list :|%;%|
                (list :|%;%| *ir-store* (dframe op a b))
                (list (list :local.get 1))))
         (list (list :|%;%|
                     (list :|%;%| *ir-store* (dframe op a b))
                     (list (list :const (list :i32) a)))))
  :hints (("Goal"
           :use d-local-get-1
           :in-theory (e/d (dcfg dz)
                           (w3t::step dframe ir-frame-with-locals)))))

(defthm d-local-get-2-plain
  (equal (w3t::step
          (list :|%;%|
                (list :|%;%| *ir-store* (dframe op a b))
                (list (list :local.get 2))))
         (list (list :|%;%|
                     (list :|%;%| *ir-store* (dframe op a b))
                     (list (list :const (list :i32) b)))))
  :hints (("Goal"
           :use d-local-get-2
           :in-theory (e/d (dcfg dz)
                           (w3t::step dframe ir-frame-with-locals)))))

(defthm d-relop-true-plain
  (equal (w3t::step
          (list :|%;%| z
                (list (list :const (list :i32) v)
                      (list :const (list :i32) v)
                      (list :relop (list :i32) (list :eq)))))
         (list (list :|%;%| z (list (list :const (list :i32) 1)))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) v)
                                 (list :const (list :i32) v)
                                 (list :relop (list :i32) (list :eq))))))
           :in-theory (e/d (ieq-value-all w3t::val-p w3t::num_-p
                              w3t::inn-p w3t::in-p w3t::un-p dcfg dz dframe ir-frame-with-locals)
                           (ieq-value))
           :do-not-induct t)))

(defthm d-ifelse-true-plain
  (implies (true-listp br)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) 1)
                               (list :ifelse (quote (:_result nil)) br nil))))
                  (list (list :|%;%| z
                              (list (list :block (quote (:_result nil)) br))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) 1)
                                 (list :ifelse (quote (:_result nil)) br nil)))))
           :do-not-induct t)))

(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm d-local-get-1-rest
    (implies (true-listp r)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (dframe op a b))
                           (cons (list :local.get 1) r)))
                    (list (list :|%;%|
                                (list :|%;%| *ir-store* (dframe op a b))
                                (cons (list :const (list :i32) a) r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step dframe ir-frame-with-locals
                              we::revappend-of-take-becomes-operands))
             :expand ((we::operands 0 nil))
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*) (we::f (dframe op a b))
                              (we::vals nil) (we::i (list :local.get 1))
                              (we::r r) (we::a 0)
                              (we::inner
                               (list (list :|%;%|
                                           (list :|%;%| *ir-store* (dframe op a b))
                                           (list (list :const (list :i32) a)))))))
             :do-not-induct t)))

  (defthm d-local-get-2-rest
    (implies (true-listp r)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (dframe op a b))
                           (cons (list :local.get 2) r)))
                    (list (list :|%;%|
                                (list :|%;%| *ir-store* (dframe op a b))
                                (cons (list :const (list :i32) b) r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step dframe ir-frame-with-locals
                              we::revappend-of-take-becomes-operands))
             :expand ((we::operands 0 nil))
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*) (we::f (dframe op a b))
                              (we::vals nil) (we::i (list :local.get 2))
                              (we::r r) (we::a 0)
                              (we::inner
                               (list (list :|%;%|
                                           (list :|%;%| *ir-store* (dframe op a b))
                                           (list (list :const (list :i32) b)))))))
             :do-not-induct t)))

  (defthm d-relop-true-rest
    (implies (and (unsigned-byte-p 32 v) (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) v)
                                 (cons (list :const (list :i32) v)
                                       (cons (list :relop (list :i32) (list :eq))
                                             r)))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32) 1) r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands
                       2 (list (list :const (list :i32) v)
                               (list :const (list :i32) v))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) v)
                                              (list :const (list :i32) v)))
                              (we::i (list :relop (list :i32) (list :eq)))
                              (we::r r) (we::a 2)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32) 1)))))))
             :do-not-induct t)))

  (defthm d-ifelse-true-rest
    (implies (and (true-listp br) (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) 1)
                                 (cons (list :ifelse (quote (:_result nil)) br nil)
                                       r))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :block (quote (:_result nil)) br) r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands 1 (list (list :const (list :i32) 1))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) 1)))
                              (we::i (list :ifelse (quote (:_result nil)) br nil))
                              (we::r r) (we::a 1)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :block (quote (:_result nil))
                                                       br)))))))
             :do-not-induct t))))

(defthm d-add-plain
  (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 y))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) x)
                               (list :const (list :i32) y)
                               (list :binop (list :i32) (list :add)))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32)
                                          (loghead 32 (+ x y))))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) x)
                                 (list :const (list :i32) y)
                                 (list :binop (list :i32) (list :add))))))
           :in-theory (enable w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :do-not-induct t)))

(defthm d-sub-plain
  (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 y))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) x)
                               (list :const (list :i32) y)
                               (list :binop (list :i32) (list :sub)))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32)
                                          (loghead 32 (- x y))))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) x)
                                 (list :const (list :i32) y)
                                 (list :binop (list :i32) (list :sub))))))
           :in-theory (e/d (isub-rem-loghead w3t::val-p w3t::num_-p
                              w3t::inn-p w3t::in-p w3t::un-p)
                           (rem mod loghead))
           :do-not-induct t)))

(defthm d-lt-plain
  (implies (and (unsigned-byte-p 31 x) (unsigned-byte-p 31 y))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) x)
                               (list :const (list :i32) y)
                               (list :relop (list :i32) (list :lt (list :s))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32)
                                          (if (< x y) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) x)
                                 (list :const (list :i32) y)
                                 (list :relop (list :i32) (list :lt (list :s)))))))
           :in-theory (e/d (lt-signed-value w3t::val-p w3t::num_-p
                              w3t::inn-p w3t::in-p w3t::un-p)
                           (w3t::$ilt_))
           :do-not-induct t)))

(defthm d-eqz-plain
  (implies (unsigned-byte-p 32 x)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) x)
                               (list :testop (list :i32) (list :eqz)))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32)
                                          (if (equal x 0) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) x)
                                 (list :testop (list :i32) (list :eqz))))))
           :in-theory (e/d (ieqz-value w3t::val-p w3t::num_-p
                              w3t::inn-p w3t::in-p w3t::un-p)
                           ())
           :do-not-induct t)))

(defthm d-mul-ifz-plain
  (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 a))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) x)
                               (list :const (list :i32)
                                     (if (equal a 0) 1 0))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32)
                                          (if (equal a 0) x 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) x)
                                 (list :const (list :i32)
                                       (if (equal a 0) 1 0))
                                 (list :binop (list :i32) (list :mul))))))
           :in-theory (e/d (imul-01 w3t::val-p w3t::num_-p
                              w3t::inn-p w3t::in-p w3t::un-p)
                           ())
           :do-not-induct t)))

(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm d-add-rest
    (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 y)
                  (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) x)
                                 (cons (list :const (list :i32) y)
                                       (cons (list :binop (list :i32) (list :add))
                                             r)))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32)
                                            (loghead 32 (+ x y)))
                                      r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands 2 (list (list :const (list :i32) y)
                                            (list :const (list :i32) x))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) y)
                                              (list :const (list :i32) x)))
                              (we::i (list :binop (list :i32) (list :add)))
                              (we::r r) (we::a 2)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32)
                                                       (loghead 32 (+ x y)))))))))
             :do-not-induct t)))

  (defthm d-sub-rest
    (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 y)
                  (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) x)
                                 (cons (list :const (list :i32) y)
                                       (cons (list :binop (list :i32) (list :sub))
                                             r)))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32)
                                            (loghead 32 (- x y)))
                                      r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands 2 (list (list :const (list :i32) y)
                                            (list :const (list :i32) x))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) y)
                                              (list :const (list :i32) x)))
                              (we::i (list :binop (list :i32) (list :sub)))
                              (we::r r) (we::a 2)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32)
                                                       (loghead 32 (- x y)))))))))
             :do-not-induct t)))

  (defthm d-lt-rest
    (implies (and (unsigned-byte-p 31 x) (unsigned-byte-p 31 y)
                  (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) x)
                                 (cons (list :const (list :i32) y)
                                       (cons (list :relop (list :i32)
                                                   (list :lt (list :s)))
                                             r)))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32)
                                            (if (< x y) 1 0))
                                      r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands 2 (list (list :const (list :i32) y)
                                            (list :const (list :i32) x))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) y)
                                              (list :const (list :i32) x)))
                              (we::i (list :relop (list :i32) (list :lt (list :s))))
                              (we::r r) (we::a 2)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32)
                                                       (if (< x y) 1 0))))))))
             :do-not-induct t)))

  (defthm d-eqz-rest
    (implies (and (unsigned-byte-p 32 x) (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) x)
                                 (cons (list :testop (list :i32) (list :eqz))
                                       r))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32)
                                            (if (equal x 0) 1 0))
                                      r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands 1 (list (list :const (list :i32) x))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32) x)))
                              (we::i (list :testop (list :i32) (list :eqz)))
                              (we::r r) (we::a 1)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32)
                                                       (if (equal x 0) 1 0))))))))
             :do-not-induct t)))

  (defthm d-mul-ifz-rest
    (implies (and (unsigned-byte-p 32 x) (unsigned-byte-p 32 a)
                  (true-listp r))
             (equal (w3t::step
                     (list :|%;%| (list :|%;%| s f)
                           (cons (list :const (list :i32) x)
                                 (cons (list :const (list :i32)
                                             (if (equal a 0) 1 0))
                                       (cons (list :binop (list :i32) (list :mul))
                                             r)))))
                    (list (list :|%;%| (list :|%;%| s f)
                                (cons (list :const (list :i32)
                                            (if (equal a 0) x 0))
                                      r)))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p)
                             (w3t::step we::revappend-of-take-becomes-operands))
             :expand ((we::operands
                       2 (list (list :const (list :i32) (if (equal a 0) 1 0))
                               (list :const (list :i32) x))))
             :use ((:instance we::step-of-flat-block
                              (we::s s) (we::f f)
                              (we::vals (list (list :const (list :i32)
                                                    (if (equal a 0) 1 0))
                                              (list :const (list :i32) x)))
                              (we::i (list :binop (list :i32) (list :mul)))
                              (we::r r) (we::a 2)
                              (we::inner
                               (list (list :|%;%| (list :|%;%| s f)
                                           (list (list :const (list :i32)
                                                       (if (equal a 0) x 0))))))))
             :do-not-induct t))))
