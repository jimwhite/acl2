(in-package "MILAWA-WASM")
(include-book "ops-frame-gen")
(include-book "ops-dispatch-skips")

(defthm frame-skip-1-0
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
             (frame-cfg
              1 a b
              (cons (list :local.get 0)
                    (cons (list :const (list :i32) 0)
                          (cons (list :relop (list :i32) (list :eq))
                                (cons (list :ifelse
                                            (quote (:_result nil))
                                            (cons (list :local.get 1)
                                                  (cons (list :return) nil))
                                            nil)
                                      (dispatch-tail 0))))))))))))))))
   (frame-cfg 1 a b (dispatch-tail 0)))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-false-rest
                            d-ifelse-false-rest
                            d-block-rest
                            d-label-nil-rest
                            frame-label-step-of-body-x
                            dispatch-cmp
                            dispatch-branch
                            dispatch-tail
                            true-listp-dispatch-tail
                            true-listp-dispatch-branch
                            frame-cfg
                            we::exit-body-p
                            we::exit-block-p
                            we::exn-throw-p
                            we::exit-head-p
                            we::first-nonval
                            we::vals-p)
                           (w3t::step dframe ir-frame-with-locals
                            (:e cons)))
           :do-not-induct t)))
