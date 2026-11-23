; Value-prefixed flat-block steps for the dispatcher branch bodies.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-label-lift")

; A flat-block step with a value prefix, for local.get 2.
(defthm d-local-get-2-prefix
  (implies (and (we::vals-p x) (true-listp x) (true-listp r))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (append x (cons (list :local.get 2) r))))
            (list
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (append x (cons (list :const (list :i32) b) r))))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              d-local-get-2-rest)
                           (w3t::step dframe ir-frame-with-locals
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands 0 nil))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals (revappend x nil))
                            (we::i (list :local.get 2))
                            (we::r r) (we::a 0)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                                         (list (list :const (list :i32) b)))))))
           :do-not-induct t)))

; local.get 2 after one value (const p) on the stack.
(defthm d-local-get-2-after-const
  (implies (and (true-listp r) (w3t::un-p p 32))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :local.get 2) r))))
            (list
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :const (list :i32) b) r))))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              d-local-get-2-rest)
                           (w3t::step dframe ir-frame-with-locals
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands 0 nil))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals (list (list :const (list :i32) p)))
                            (we::i (list :local.get 2))
                            (we::r r) (we::a 0)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                                         (list (list :const (list :i32) b)))))))
           :do-not-induct t)))

; local.get 1 after one value (const p) on the stack.
(defthm d-local-get-1-after-const
  (implies (and (true-listp r) (w3t::un-p p 32))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :local.get 1) r))))
            (list
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :const (list :i32) a) r))))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              d-local-get-1-rest)
                           (w3t::step dframe ir-frame-with-locals
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands 0 nil))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals (list (list :const (list :i32) p)))
                            (we::i (list :local.get 1))
                            (we::r r) (we::a 0)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                                         (list (list :const (list :i32) a)))))))
           :do-not-induct t)))

