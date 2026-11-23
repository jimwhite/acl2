; The op5 (ifz/mul) true-branch tail of the dispatcher frame trace.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-eqz")
(include-book "ops-unp")


; The two literal-condition forms of the ifz multiply, after the eqz result
; has been simplified by the (a = 0) case split.

(defthm d-mul-1-rest
  (implies (and (unsigned-byte-p 32 x) (true-listp r))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| s f)
                   (cons (list :const (list :i32) x)
                         (cons (list :const (list :i32) 1)
                               (cons (list :binop (list :i32) (list :mul)) r)))))
            (list
             (list :|%;%| (list :|%;%| s f)
                   (cons (list :const (list :i32) x) r)))))
  :hints (("Goal"
           :use ((:instance d-mul-ifz-rest (a 0) (x x) (r r) (s s) (f f)))
           :in-theory (disable w3t::step))))

(defthm d-mul-0-rest
  (implies (and (unsigned-byte-p 32 x) (true-listp r))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| s f)
                   (cons (list :const (list :i32) x)
                         (cons (list :const (list :i32) 0)
                               (cons (list :binop (list :i32) (list :mul)) r)))))
            (list
             (list :|%;%| (list :|%;%| s f)
                   (cons (list :const (list :i32) 0) r)))))
  :hints (("Goal"
           :use ((:instance d-mul-ifz-rest (a 2) (x x) (r r) (s s) (f f)))
           :in-theory (disable w3t::step))))

(defthm frame-tail-5-sel
  (equal
   (step-prefix
    9
    (frame-cfg
     5 (sel a) (sel b)
     (append (dispatch-cmp 5) (dispatch-tail 5))))
   (frame-cfg
    5 (sel a) (sel b)
    (append (cons (list :const (list :i32)
                        (if (equal (sel a) 0) (sel b) 0))
                  (cons (list :return) nil))
            (dispatch-tail 5))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            frame-label-label-step-of-body-x
                            frame-label-step-of-body-x
                            d-local-get-2-rest
                            d-local-get-1-after-const
                            d-eqz-after-const
                            d-mul-ifz-rest
                            d-mul-1-rest
                            d-mul-0-rest
                            step-const-return-cons-rest-un-p
                            sel-un-p
                            un-p-implies-ubp
                            un-p-if-equal-zero-sel
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
                            w3t::$ieqz_
                            we::step-of-admin-term-is-context-rule
                            binary-append
                            acl2::loghead acl2::loghead$inline
                            acl2::ifix acl2::mod acl2::floor
                            acl2::imod$inline acl2::expt2$inline
                            (:e cons)))
           :do-not-induct t)))
