(in-package "MILAWA-WASM")
(include-book "ops-frame-6")
(include-book "ops-frame-0")

(defthm frame-trace-8
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
               (car
                (w3t::step
                 (car
                  (w3t::step
                   (frame-cfg0
                    (sel a) b
                    (cons (list :local.get 0)
                          (cons (list :const (list :i32) 0)
                                (cons (list :relop (list :i32) (list :eq))
                                      (cons (list :ifelse
                                                  (quote (:_result nil))
                                                  (cons (list :local.get 1)
                                                        (cons (list :return) nil))
                                                  nil)
                                            (tail-sel tail))))))))))))))))))))))
   (list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) (sel a)))))
  :hints (("Goal"
           :in-theory (e/d (frame-trace-6
                            frame-step-body-append
                            frame-function-label-tail-no-br
                            step-frame-ret-cfg
                            sel-un-p
                            tail-sel-true-listp
                            tail-sel-no-br-p)
                           (w3t::step dframe ir-frame-with-locals
                            frame-cfg0 sel tail-sel
                            frame-function-label-tail
                            frame-function-label-tail-un-p
                            step-label-suffix
                            step-const-return-cons-rest-un-p
                            d-local-get-rest d-relop-true-rest
                            d-ifelse-true-rest d-block-rest
                            if-label-step
                            frame-label-step-of-body-x
                            ubp-implies-un-p
                            we::step-of-admin-term-is-context-rule
                            (:e cons)))
           :do-not-induct t)))
