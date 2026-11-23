; The op2 (add) true-branch tail of the dispatcher frame trace.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-prefix-get")

(defthm frame-tail-2-sel
  (equal
   (step-prefix
    8
    (frame-cfg
     2 (sel a) (sel b)
     (append (dispatch-cmp 2) (dispatch-tail 2))))
   (frame-cfg
    2 (sel a) (sel b)
    (append (cons (list :const (list :i32)
                        (loghead 32 (+ (sel a) (sel b))))
                  (cons (list :return) nil))
            (dispatch-tail 2))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            frame-label-label-step-of-body-x
                            frame-label-step-of-body-x
                            d-local-get-1-rest
                            d-local-get-2-after-const
                            d-add-rest
                            step-const-return-cons-rest-un-p
                            sel-un-p
                            un-p-implies-ubp
                            true-listp-dispatch-tail
                            not-exit-body-p-cons-label
                            dispatch-cmp
                            dispatch-branch
                            frame-cfg
                            we::exit-body-p
                            we::exit-block-p
                            we::exn-throw-p
                            we::exit-head-p
                            we::first-nonval)
                           (w3t::step dframe ir-frame-with-locals
                            sel tail-sel
                            dispatch-tail (:e dispatch-tail)
                            step-const-return-cons-rest
                            label-step-of-body
                            we::step-of-admin-term-is-context-rule
                            binary-append
                            acl2::loghead acl2::loghead$inline
                            acl2::ifix acl2::mod acl2::floor
                            acl2::imod$inline acl2::expt2$inline
                            (:e cons)))
           :do-not-induct t)))
