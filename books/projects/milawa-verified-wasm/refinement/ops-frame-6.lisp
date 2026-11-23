; The first six frame-level steps of the op0 dispatcher trace.
;
(in-package "MILAWA-WASM")
(include-book "ops-frame-0")
(include-book "ops-trace-0")

(defun sel (a) (if (w3t::un-p a 32) a 0))
(defun tail-sel (lst) (if (and (true-listp lst) (no-br-p lst)) lst nil))

(defthm sel-un-p
  (w3t::un-p (sel a) 32)
  :hints (("Goal" :in-theory (enable sel w3t::un-p))))

(defthm tail-sel-true-listp
  (true-listp (tail-sel lst))
  :hints (("Goal" :in-theory (enable tail-sel))))

(defthm tail-sel-no-br-p
  (no-br-p (tail-sel lst))
  :hints (("Goal" :in-theory (enable tail-sel))))

(defthm frame-trace-6
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
                                        (tail-sel tail))))))))))))))))))
   (frame-cfg0
    (sel a) b
    (append (cons (list :const (list :i32) (sel a))
                  (cons (list :return) nil))
            (tail-sel tail))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            if-label-step
                            step-const-return-cons-rest-un-p
                            frame-label-step-of-body-x
                            sel-un-p
                            tail-sel-true-listp
                            tail-sel-no-br-p
                            frame-cfg0)
                           (w3t::step dframe ir-frame-with-locals
                            sel tail-sel
                            step-label-suffix
                            step-const-return-cons-rest
                            frame-function-label-tail
                            frame-function-label-tail-un-p
                            ubp-implies-un-p
                            (:e cons)))
           :do-not-induct t)))
