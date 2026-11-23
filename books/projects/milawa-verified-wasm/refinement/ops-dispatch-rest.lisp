; The dispatcher one-step configurations with an arbitrary rest (the flat-block steps).
;
(in-package "MILAWA-WASM")
(include-book "ops-dispatch")
(include-book "ops-dispatch-block")

(defthm d-local-get-plain
  (equal (w3t::step
          (list :|%;%|
                (list :|%;%| *ir-store* (dframe op a b))
                (list (list :local.get 0))))
         (list (list :|%;%|
                     (list :|%;%| *ir-store* (dframe op a b))
                     (list (list :const (list :i32) op)))))
  :hints (("Goal"
           :use d-local-get
           :in-theory (e/d (dcfg dz) (w3t::step dframe ir-frame-with-locals)))))

(defthm d-relop-false-plain
  (implies (and (unsigned-byte-p 32 op) (unsigned-byte-p 32 j)
                (not (equal op j)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (dframe op a b))
                         (list (list :const (list :i32) op)
                               (list :const (list :i32) j)
                               (list :relop (list :i32) (list :eq)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (dframe op a b))
                              (list (list :const (list :i32) 0))))))
  :hints (("Goal"
           :use d-relop-false
           :in-theory (e/d (dcfg dz) (w3t::step dframe ir-frame-with-locals)))))

(defthm d-ifelse-false-plain
  (implies (true-listp br)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) 0)
                               (list :ifelse (quote (:_result nil)) br nil))))
                  (list (list :|%;%| z
                              (list (list :block (quote (:_result nil)) nil))))))
  :hints (("Goal" :use d-ifelse-false :in-theory (enable dcfg))))

(defthm d-block-plain
  (implies (true-listp br)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :block (quote (:_result nil)) br))))
                  (list (list :|%;%| z
                              (list (list :label_%{%}% 0 nil br))))))
  :hints (("Goal" :use d-block :in-theory (enable dcfg))))

(defthm d-label-nil-plain
  (equal (w3t::step
          (list :|%;%| z (list (list :label_%{%}% 0 nil nil))))
         (list (list :|%;%| z nil)))
  :hints (("Goal" :use d-label-nil :in-theory (enable dcfg))))

(defthm d-local-get-rest
  (implies (true-listp r)
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (dframe op a b))
                         (cons (list :local.get 0) r)))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (dframe op a b))
                              (cons (list :const (list :i32) op) r)))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
                           (w3t::step dframe ir-frame-with-locals
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands 0 nil))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals nil) (we::i (list :local.get 0))
                            (we::r r) (we::a 0)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store*
                                                     (dframe op a b))
                                         (list (list :const (list :i32) op)))))))
           :do-not-induct t)))

(defthm d-relop-false-rest
  (implies (and (unsigned-byte-p 32 op) (unsigned-byte-p 32 j)
                (not (equal op j)) (true-listp r))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (dframe op a b))
                         (cons (list :const (list :i32) op)
                               (cons (list :const (list :i32) j)
                                     (cons (list :relop (list :i32) (list :eq))
                                           r)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (dframe op a b))
                              (cons (list :const (list :i32) 0) r)))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
                           (w3t::step dframe ir-frame-with-locals
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands
                     2 (list (list :const (list :i32) j)
                             (list :const (list :i32) op))))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals (list (list :const (list :i32) j)
                                            (list :const (list :i32) op)))
                            (we::i (list :relop (list :i32) (list :eq)))
                            (we::r r) (we::a 2)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store*
                                                     (dframe op a b))
                                         (list (list :const (list :i32) 0)))))))
           :do-not-induct t)))

(defthm d-ifelse-false-rest
  (implies (and (true-listp br) (true-listp r))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (cons (list :const (list :i32) 0)
                               (cons (list :ifelse (quote (:_result nil)) br nil)
                                     r))))
                  (list (list :|%;%| (list :|%;%| s f)
                              (cons (list :block (quote (:_result nil)) nil)
                                    r)))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
                           (w3t::step we::revappend-of-take-becomes-operands))
           :expand ((we::operands 1 (list (list :const (list :i32) 0))))
           :use ((:instance we::step-of-flat-block
                            (we::s s) (we::f f)
                            (we::vals (list (list :const (list :i32) 0)))
                            (we::i (list :ifelse (quote (:_result nil)) br nil))
                            (we::r r) (we::a 1)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| s f)
                                         (list (list :block (quote (:_result nil))
                                                     nil)))))))
           :do-not-induct t)))

(defthm d-block-rest
  (implies (and (true-listp br) (true-listp r))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (cons (list :block (quote (:_result nil)) br) r)))
                  (list (list :|%;%| (list :|%;%| s f)
                              (cons (list :label_%{%}% 0 nil br) r)))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              redex-arity-block-nil)
                           (w3t::step we::revappend-of-take-becomes-operands))
           :expand ((we::operands 0 nil))
           :use ((:instance we::step-of-flat-block
                            (we::s s) (we::f f)
                            (we::vals nil)
                            (we::i (list :block (quote (:_result nil)) br))
                            (we::r r) (we::a 0)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| s f)
                                         (list (list :label_%{%}% 0 nil br)))))))
           :do-not-induct t)))

(defthm d-label-nil-rest
  (implies (true-listp r)
           (equal (w3t::step
                   (list :|%;%| z (cons (list :label_%{%}% 0 nil nil) r)))
                  (list (list :|%;%| z r))))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use ((:instance we::step-of-admin-term-in-flat-block
                            (we::z z) (we::v nil)
                            (we::i (list :label_%{%}% 0 nil nil))
                            (we::r r)
                            (we::inner (list (list :|%;%| z nil)))))
           :do-not-induct t)))

