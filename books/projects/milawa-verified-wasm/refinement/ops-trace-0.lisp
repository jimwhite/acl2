(in-package "MILAWA-WASM")
(include-book "ops-dispatch-rest")
(include-book "ops-dispatch-true")
(include-book "ops-return-suffix")
(include-book "ops-dispatch-tail")

(defthm not-exit-body-p-branch0
  (not (we::exit-body-p
        (cons (list :local.get 1)
              (cons (list :return) nil))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm step-const-return-cons-rest
  (implies (and (unsigned-byte-p 32 v) (true-listp r))
           (equal
            (w3t::step
             (list :|%;%| z
                   (cons (list :label_%{%}% 0 nil
                               (cons (list :const (list :i32) v)
                                     (cons (list :return) nil)))
                         r)))
            (list
             (list :|%;%| z
                   (append (cons (list :const (list :i32) v)
                                 (cons (list :return) nil))
                           r)))))
  :hints (("Goal"
           :use ((:instance step-const-return-rest-ubp
                            (vals nil)))
           :in-theory (disable w3t::step)
           :do-not-induct t)))

(defun milawa-state-pair-p (z)
  (and (consp z) (equal (car z) :|%;%|)
       (consp (cdr z)) (consp (cddr z)) (null (cdddr z))))

(defthm milawa-state-pair-p-dz
  (milawa-state-pair-p
   (list :|%;%| *ir-store* (dframe 0 a b)))
  :hints (("Goal" :in-theory (enable milawa-state-pair-p))))

(encapsulate ()
  (local
   (defthm milawa-state-pair-p-is-we
     (equal (milawa-state-pair-p z) (we::state-shape-p z))
     :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                       we::state-shape-p)))))

  (defthm if-label-step-cond
    (implies (and (true-listp tail)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (dframe 0 a b))
                                (cons (list :local.get 1)
                                      (cons (list :return) nil)))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal
              (w3t::step
               (list :|%;%|
                     (list :|%;%| *ir-store* (dframe 0 a b))
                     (cons (list :label_%{%}% 0 nil
                                 (cons (list :local.get 1)
                                       (cons (list :return) nil)))
                           tail)))
              (list
               (list :|%;%|
                     (cadr (car inner))
                     (cons (list :label_%{%}% 0 nil
                                 (caddr (car inner)))
                           tail)))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 0) (x nil)
                              (b (cons (list :local.get 1)
                                       (cons (list :return) nil)))
                              (r tail)
                              (s *ir-store*) (f (dframe 0 a b))
                              (inner inner)))))))

(defthm if-label-step
  (implies (true-listp tail)
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* (dframe 0 a b))
                   (cons (list :label_%{%}% 0 nil
                               (cons (list :local.get 1)
                                     (cons (list :return) nil)))
                         tail)))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* (dframe 0 a b))
                   (cons (list :label_%{%}% 0 nil
                               (cons (list :const (list :i32) a)
                                     (cons (list :return) nil)))
                         tail)))))
  :hints (("Goal"
           :use ((:instance if-label-step-cond
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store* (dframe 0 a b))
                                    (cons (list :const (list :i32) a)
                                          (cons (list :return) nil))))))
                 d-local-get-1-rest
                 milawa-state-pair-p-dz)
           :in-theory (disable w3t::step dframe ir-frame-with-locals)
           :do-not-induct t)))

(defthm not-exit-body-p-b0
  (not (we::exit-body-p
        (cons (list :local.get 0)
              (cons (list :const (list :i32) 0)
                    (cons (list :relop (list :i32) (list :eq))
                          (cons (list :ifelse (quote (:_result nil))
                                      (cons (list :local.get 1)
                                            (cons (list :return) nil))
                                      nil)
                                tail))))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm not-exit-body-p-b1
  (not (we::exit-body-p
        (cons (list :const (list :i32) 0)
              (cons (list :const (list :i32) 0)
                    (cons (list :relop (list :i32) (list :eq))
                          (cons (list :ifelse (quote (:_result nil))
                                      (cons (list :local.get 1)
                                            (cons (list :return) nil))
                                      nil)
                                tail))))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm not-exit-body-p-b2
  (not (we::exit-body-p
        (cons (list :const (list :i32) 1)
              (cons (list :ifelse (quote (:_result nil))
                          (cons (list :local.get 1)
                                (cons (list :return) nil))
                          nil)
                    tail))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm not-exit-body-p-b3
  (not (we::exit-body-p
        (cons (list :block (quote (:_result nil))
                    (cons (list :local.get 1)
                          (cons (list :return) nil)))
              tail)))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm not-exit-body-p-b4
  (not (we::exit-body-p
        (cons (list :label_%{%}% 0 nil
                    (cons (list :local.get 1)
                          (cons (list :return) nil)))
              tail)))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm not-exit-body-p-b5
  (not (we::exit-body-p
        (cons (list :label_%{%}% 0 nil
                    (cons (list :const (list :i32) a)
                          (cons (list :return) nil)))
              tail)))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm body-trace-cons-0
  (implies (and (unsigned-byte-p 32 a)
                (unsigned-byte-p 32 b)
                (true-listp tail))
           (equal
            (car
             (w3t::step
              (car
               (w3t::step
                (car
                 (w3t::step
                  (car
                   (w3t::step
                    (car
                     (w3t::step
                      (car
                       (w3t::step
                        (list :|%;%|
                              (list :|%;%| *ir-store* (dframe 0 a b))
                              (cons (list :local.get 0)
                                    (cons (list :const (list :i32) 0)
                                          (cons (list :relop (list :i32)
                                                      (list :eq))
                                                (cons (list :ifelse
                                                            (quote (:_result nil))
                                                            (cons (list :local.get 1)
                                                                  (cons (list :return) nil))
                                                            nil)
                                                      tail)))))))))))))))))
            (list :|%;%|
                  (list :|%;%| *ir-store* (dframe 0 a b))
                  (cons (list :const (list :i32) a)
                        (cons (list :return) tail)))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-local-get-1-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            if-label-step
                            step-const-return-cons-rest
                            step-const-return-rest-ubp
                            engine-admin-term-in-block)
                           (w3t::step dframe ir-frame-with-locals
                            (:e cons)))
           :do-not-induct t)))
