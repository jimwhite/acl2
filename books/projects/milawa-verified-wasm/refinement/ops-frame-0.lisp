(in-package "MILAWA-WASM")
(include-book "ops-dispatch-rest")
(include-book "ops-dispatch-true")
(include-book "ops-return-suffix")
(include-book "ops-dispatch-tail")

(defun frame-cfg0 (a b body)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1 (dframe 0 a b)
                    (list (list :label_%{%}% 1 nil body))))))

(defconst *b0*
  (cons (list :local.get 0)
        (cons (list :const (list :i32) 0)
              (cons (list :relop (list :i32) (list :eq))
                    (cons (list :ifelse (quote (:_result nil))
                                (cons (list :local.get 1)
                                      (cons (list :return) nil))
                                nil)
                          nil)))))

(defconst *b1*
  (cons (list :const (list :i32) 0)
        (cdr *b0*)))

(defthm frame-step0
  (implies (unsigned-byte-p 32 a)
           (equal (car (w3t::step (frame-cfg0 a b *b0*)))
                  (frame-cfg0 a b *b1*)))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            frame-label-step-of-body-x
                            frame-cfg0)
                           (w3t::step dframe ir-frame-with-locals
                            (:e cons)))
           :do-not-induct t)))

(defthm ubp-implies-un-p
  (implies (unsigned-byte-p 32 v)
           (w3t::un-p v 32))
  :hints (("Goal" :in-theory (enable w3t::un-p))))

(defthm frame-function-label-tail
  (implies (and (unsigned-byte-p 32 v)
                (true-listp tail)
                (equal tail (dispatch-tail 0)))
           (equal
            (w3t::step
             (frame-cfg0 a b
                         (cons (list :const (list :i32) v)
                               (cons (list :return) tail))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1 (dframe 0 a b)
                               (list (list :const (list :i32) v)
                                     (list :return))))))))
  :hints (("Goal"
           :use ((:instance engine-admin-term-in-block
                            (k :f) (n 1) (x (dframe 0 a b))
                            (b (list (list :label_%{%}% 1 nil
                                           (cons (list :const (list :i32) v)
                                                 (cons (list :return) tail)))))
                            (r nil) (s *ir-store*) (f *ir-call-frame*)
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store* (dframe 0 a b))
                                    (list (list :const (list :i32) v)
                                          (list :return))))))
                 (:instance step-function-label-tail
                            (j 0)))
           :in-theory (e/d (frame-cfg0)
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))

(defthm frame-function-label-tail-un-p
  (implies (and (w3t::un-p v 32)
                (true-listp tail)
                (equal tail (dispatch-tail 0)))
           (equal
            (w3t::step
             (frame-cfg0 a b
                         (cons (list :const (list :i32) v)
                               (cons (list :return) tail))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1 (dframe 0 a b)
                               (list (list :const (list :i32) v)
                                     (list :return))))))))
  :hints (("Goal"
           :use ((:instance frame-function-label-tail))
           :in-theory (enable un-p-implies-ubp)
           :do-not-induct t)))

(defthm frame-function-label-tail-no-br
  (implies (and (w3t::un-p v 32)
                (true-listp tail)
                (no-br-p tail))
           (equal
            (w3t::step
             (frame-cfg0 a b
                         (cons (list :const (list :i32) v)
                               (cons (list :return) tail))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1 (dframe 0 a b)
                               (list (list :const (list :i32) v)
                                     (list :return))))))))
  :hints (("Goal"
           :use ((:instance engine-admin-term-in-block
                            (k :f) (n 1) (x (dframe 0 a b))
                            (b (list (list :label_%{%}% 1 nil
                                           (cons (list :const (list :i32) v)
                                                 (cons (list :return) tail)))))
                            (r nil) (s *ir-store*) (f *ir-call-frame*)
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store* (dframe 0 a b))
                                    (list (list :const (list :i32) v)
                                          (list :return))))))
                 (:instance step-label-suffix
                            (n 1) (suffix tail)))
           :in-theory (e/d (frame-cfg0)
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))

(defthm frame-step-body-append
  (implies (and (w3t::un-p v 32)
                (true-listp tail)
                (no-br-p tail))
           (equal
            (w3t::step
    (frame-cfg0
     a b
     (append (cons (list :const (list :i32) v)
                   (cons (list :return) nil))
             tail)))
   (list
    (list :|%;%|
          (list :|%;%| *ir-store* *ir-call-frame*)
          (list (list :frame_%{%}% 1 (dframe 0 a b)
                      (list (list :const (list :i32) v)
                            (list :return))))))))
  :hints (("Goal"
           :use ((:instance frame-function-label-tail-no-br
                            (tail tail)))
           :in-theory (e/d (frame-cfg0
                            we::append-of-cons)
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))
