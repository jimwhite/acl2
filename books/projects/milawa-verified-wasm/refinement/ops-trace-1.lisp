(in-package "MILAWA-WASM")
(include-book "ops-skip-1")
(include-book "ops-tail-1")

; n nested (car (w3t::step ...)) wrappers.

(defun step-prefix-term (n x)
  (if (zp n)
      x
    (list 'car (list 'w3t::step (step-prefix-term (1- n) x)))))

(defmacro step-prefix (n x)
  (step-prefix-term n x))

; Opening the skipped comparison's tail far enough to meet the true-branch
; frame trace.  Kept out of the default theory, since the trace lemmas below
; match on the unopened (dispatch-tail 0).

(defthm dispatch-tail-0-open
  (equal
   (dispatch-tail 0)
   (cons (list :local.get 0)
         (cons (list :const (list :i32) 1)
               (cons (list :relop (list :i32) (list :eq))
                     (cons (list :ifelse
                                 (quote (:_result nil))
                                 (cons (list :local.get 1)
                                       (cons (list :return) nil))
                                 nil)
                           (tail-sel (dispatch-tail 1)))))))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (e/d (dispatch-tail dispatch-body-from
                            dispatch-cmp dispatch-branch
                            tail-sel)
                           (w3t::step))
           :use ((:instance true-listp-dispatch-tail (j 1))
                 (:instance no-br-p-dispatch-tail (j 1)))
           :do-not-induct t)))

(defthm frame-skip-1-0-open
  (equal
   (step-prefix
    5
    (frame-cfg
     1 (sel a) b
     (cons (list :local.get 0)
           (cons (list :const (list :i32) 0)
                 (cons (list :relop (list :i32) (list :eq))
                       (cons (list :ifelse
                                   (quote (:_result nil))
                                   (cons (list :local.get 1)
                                         (cons (list :return) nil))
                                   nil)
                             (dispatch-tail 0)))))))
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
                            (tail-sel (dispatch-tail 1))))))))
  :hints (("Goal"
           :use ((:instance frame-skip-1-0 (a (sel a)))
                 (:instance dispatch-tail-0-open))
           :in-theory (e/d ()
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))

(defthm frame-trace-1
  (equal
   (step-prefix
    13
    (frame-cfg
     1 (sel a) b
     (cons (list :local.get 0)
           (cons (list :const (list :i32) 0)
                 (cons (list :relop (list :i32) (list :eq))
                       (cons (list :ifelse
                                   (quote (:_result nil))
                                   (cons (list :local.get 1)
                                         (cons (list :return) nil))
                                   nil)
                             (dispatch-tail 0)))))))
   (list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) (sel a)))))
  :hints (("Goal"
           :in-theory (e/d (frame-skip-1-0-open
                            frame-tail-1-sel
                            frame-step-body-append-gen
                            step-frame-ret-cfg-gen
                            sel-un-p
                            tail-sel-true-listp
                            tail-sel-no-br-p)
                           (w3t::step dframe ir-frame-with-locals
                            frame-cfg sel tail-sel
                            append binary-append we::append-of-cons
                            dispatch-tail dispatch-cmp dispatch-branch
                            (:e dispatch-tail) (:e dispatch-body-from)
                            (:e dispatch-cmp) (:e dispatch-branch)
                            frame-skip-1-0
                            frame-step-body-append
                            step-frame-ret-cfg
                            step-label-suffix
                            step-const-return-cons-rest-un-p
                            d-local-get-rest d-relop-true-rest
                            d-relop-false-rest d-ifelse-true-rest
                            d-ifelse-false-rest d-block-rest
                            d-label-nil-rest
                            if-label-step if-label-step-gen
                            frame-label-step-of-body-x
                            ubp-implies-un-p
                            we::step-of-admin-term-is-context-rule
                            (:e cons)))
           :do-not-induct t)))
