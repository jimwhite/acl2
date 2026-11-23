; Generic (op-parameterized) frame configuration and frame steps.
;
(in-package "MILAWA-WASM")
(include-book "ops-frame-0")

(defun frame-cfg (op a b body)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1 (dframe op a b)
                    (list (list :label_%{%}% 1 nil body))))))

(defthm frame-step-body-append-gen
  (implies (and (w3t::un-p v 32)
                (true-listp tail)
                (no-br-p tail))
           (equal
            (w3t::step
             (frame-cfg
              op a b
              (append (cons (list :const (list :i32) v)
                            (cons (list :return) nil))
                      tail)))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1 (dframe op a b)
                               (list (list :const (list :i32) v)
                                     (list :return))))))))
  :hints (("Goal"
           :use ((:instance engine-admin-term-in-block
                            (k :f) (n 1) (x (dframe op a b))
                            (b (list (list :label_%{%}% 1 nil
                                           (append (cons (list :const (list :i32) v)
                                                         (cons (list :return) nil))
                                                   tail))))
                            (r nil) (s *ir-store*) (f *ir-call-frame*)
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store* (dframe op a b))
                                    (list (list :const (list :i32) v)
                                          (list :return))))))
                 (:instance step-label-suffix
                            (n 1) (suffix tail)))
           :in-theory (e/d (frame-cfg)
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))

(defthm step-frame-ret-cfg-gen
  (implies (w3t::un-p v 32)
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1 (dframe op a b)
                               (list (list :const (list :i32) v)
                                     (list :return))))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :const (list :i32) v))))))
  :hints (("Goal"
           :use ((:instance step-frame-return
                            (v v)
                            (f (dframe op a b))
                            (z (list :|%;%| *ir-store* *ir-call-frame*))))
           :in-theory (disable w3t::step dframe ir-frame-with-locals)
           :do-not-induct t)))
