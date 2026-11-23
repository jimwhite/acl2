; Op-parameterized versions of the if-label step.
;
(in-package "MILAWA-WASM")
(include-book "ops-trace-0")

(defthm milawa-state-pair-p-dz-gen
  (milawa-state-pair-p
   (list :|%;%| *ir-store* (dframe op a b)))
  :hints (("Goal" :in-theory (enable milawa-state-pair-p))))

(encapsulate ()
  (local
   (defthm milawa-state-pair-p-is-we-gen
     (equal (milawa-state-pair-p z) (we::state-shape-p z))
     :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                       we::state-shape-p)))))

  (defthm if-label-step-cond-gen
    (implies (and (true-listp tail)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (dframe op a b))
                                (cons (list :local.get 1)
                                      (cons (list :return) nil)))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal
              (w3t::step
               (list :|%;%|
                     (list :|%;%| *ir-store* (dframe op a b))
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
                              (s *ir-store*) (f (dframe op a b))
                              (inner inner)))))))

(defthm if-label-step-gen
  (implies (true-listp tail)
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :label_%{%}% 0 nil
                               (cons (list :local.get 1)
                                     (cons (list :return) nil)))
                         tail)))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* (dframe op a b))
                   (cons (list :label_%{%}% 0 nil
                               (cons (list :const (list :i32) a)
                                     (cons (list :return) nil)))
                         tail)))))
  :hints (("Goal"
           :use ((:instance if-label-step-cond-gen
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store* (dframe op a b))
                                    (cons (list :const (list :i32) a)
                                          (cons (list :return) nil))))))
                 d-local-get-1-rest
                 milawa-state-pair-p-dz-gen)
           :in-theory (disable w3t::step dframe ir-frame-with-locals)
           :do-not-induct t)))
