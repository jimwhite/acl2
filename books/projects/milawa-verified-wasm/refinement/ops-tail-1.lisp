(in-package "MILAWA-WASM")
(include-book "ops-trace-gen")
(include-book "ops-frame-gen")
(include-book "ops-frame-6")

(defthm frame-tail-1-sel
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
               (frame-cfg
                1 (sel a) b
                (cons (list :local.get 0)
                      (cons (list :const (list :i32) 1)
                            (cons (list :relop (list :i32) (list :eq))
                                  (cons (list :ifelse
                                              (quote (:_result nil))
                                              (cons (list :local.get 1)
                                                    (cons (list :return) nil))
                                              nil)
                                        (tail-sel (dispatch-tail 1)))))))))))))))))))
   (frame-cfg
    1 (sel a) b
    (append (cons (list :const (list :i32) (sel a))
                  (cons (list :return) nil))
            (tail-sel (dispatch-tail 1)))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            if-label-step-gen
                            step-const-return-cons-rest-un-p
                            frame-label-step-of-body-x
                            sel-un-p
                            tail-sel-true-listp
                            tail-sel-no-br-p
                            frame-cfg
                            we::exit-body-p
                            we::exit-block-p
                            we::exn-throw-p
                            we::exit-head-p
                            we::first-nonval
                            we::vals-p)
                           (w3t::step dframe ir-frame-with-locals
                            sel tail-sel
                            if-label-step
                            step-label-suffix
                            step-const-return-cons-rest
                            frame-function-label-tail
                            frame-function-label-tail-un-p
                            ubp-implies-un-p
                            we::step-of-admin-term-is-context-rule
                            (:e cons)))
           :do-not-induct t)))
