; The remaining dispatcher true-branch frame tails (ops 1, 3, 4, 6, 7).
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-tail-2")

; A branch that pushes one local and returns it: op1 and op7 push local 1,
; op6 pushes local 2.

(defmacro def-frame-tail-get (name op get-lemma v)
  `(defthm ,name
     (equal
      (step-prefix
       6
       (frame-cfg ,op (sel a) (sel b)
                  (append (dispatch-cmp ,op) (dispatch-tail ,op))))
      (frame-cfg
       ,op (sel a) (sel b)
       (append (cons (list :const (list :i32) ,v)
                     (cons (list :return) nil))
               (dispatch-tail ,op))))
     :hints (("Goal"
              :in-theory (e/d (d-local-get-rest
                               d-relop-true-rest
                               d-ifelse-true-rest
                               d-block-rest
                               frame-label-label-step-of-body-x
                               frame-label-step-of-body-x
                               ,get-lemma
                               step-const-return-cons-rest-un-p
                               sel-un-p
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
              :do-not-induct t))))

; A branch that loads both locals, combines them with one operation, and
; returns the result: the operation consumes exactly the two loaded values.

(defmacro def-frame-tail-binop (name op binop-lemma v)
  `(defthm ,name
     (equal
      (step-prefix
       8
       (frame-cfg ,op (sel a) (sel b)
                  (append (dispatch-cmp ,op) (dispatch-tail ,op))))
      (frame-cfg
       ,op (sel a) (sel b)
       (append (cons (list :const (list :i32) ,v)
                     (cons (list :return) nil))
               (dispatch-tail ,op))))
     :hints (("Goal"
              :in-theory (e/d (d-local-get-rest
                               d-relop-true-rest
                               d-ifelse-true-rest
                               d-block-rest
                               frame-label-label-step-of-body-x
                               frame-label-step-of-body-x
                               d-local-get-1-rest
                               d-local-get-2-after-const
                               ,binop-lemma
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
              :do-not-induct t))))

(def-frame-tail-get frame-tail-0-raw 0 d-local-get-1-rest (sel a))
(def-frame-tail-get frame-tail-1-raw 1 d-local-get-1-rest (sel a))
(def-frame-tail-get frame-tail-7-raw 7 d-local-get-1-rest (sel a))
(def-frame-tail-get frame-tail-6-raw 6 d-local-get-2-rest (sel b))

(def-frame-tail-binop frame-tail-3-raw 3 d-sub-rest
  (loghead 32 (- (sel a) (sel b))))

; The signed comparison needs 31-bit operands.
(defthm frame-tail-4-raw
  (implies (and (unsigned-byte-p 31 (sel a))
                (unsigned-byte-p 31 (sel b)))
           (equal
            (step-prefix
             8
             (frame-cfg 4 (sel a) (sel b)
                        (append (dispatch-cmp 4) (dispatch-tail 4))))
            (frame-cfg 4 (sel a) (sel b)
                       (append (cons (list :const (list :i32)
                                           (if (< (sel a) (sel b)) 1 0))
                                     (cons (list :return) nil))
                               (dispatch-tail 4)))))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                            d-relop-true-rest
                            d-ifelse-true-rest
                            d-block-rest
                            frame-label-label-step-of-body-x
                            frame-label-step-of-body-x
                            d-local-get-1-rest
                            d-local-get-2-after-const
                            d-lt-rest
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
                            w3t::$ilt_
                            we::step-of-admin-term-is-context-rule
                            binary-append
                            acl2::loghead acl2::loghead$inline
                            acl2::ifix acl2::mod acl2::floor
                            acl2::imod$inline acl2::expt2$inline
                            (:e cons)))
           :do-not-induct t)))
