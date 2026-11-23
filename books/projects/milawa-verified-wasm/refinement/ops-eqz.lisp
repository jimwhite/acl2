; i32.eqz with one value under the operand (the ifz branch).
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-prefix-get")

; i32.eqz on (const x) with one value (const p) below it.
(defthm d-eqz-after-const
  (implies (and (true-listp r)
                (w3t::un-p p 32) (w3t::un-p x 32))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :const (list :i32) x)
                               (cons (list :testop (list :i32) (list :eqz))
                                     r)))))
            (list
             (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :const (list :i32) p)
                         (cons (list :const (list :i32)
                                     (if (equal x 0) 1 0))
                               r))))))
  :hints (("Goal"
           :in-theory (e/d (we::op-instr-p we::redex-arity we::vals-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              d-eqz-plain)
                           (w3t::step w3t::$ieqz_
                            we::revappend-of-take-becomes-operands))
           :expand ((we::operands
                     1 (list (list :const (list :i32) x)
                             (list :const (list :i32) p))))
           :use ((:instance we::step-of-flat-block
                            (we::s *ir-store*) (we::f (dframe op a b))
                            (we::vals (list (list :const (list :i32) x)
                                            (list :const (list :i32) p)))
                            (we::i (list :testop (list :i32) (list :eqz)))
                            (we::r r) (we::a 1)
                            (we::inner
                             (list (list :|%;%| (list :|%;%| *ir-store* (dframe op a b))
                                         (list (list :const (list :i32)
                                                     (if (equal x 0) 1 0))))))))
           :do-not-induct t)))
