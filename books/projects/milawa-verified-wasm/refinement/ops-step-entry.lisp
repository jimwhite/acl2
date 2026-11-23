; Entering the STEP dispatcher's callee frame from $INVOKE, per opcode.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-step-call")

; The $INVOKE configuration, written out so STEP can open on it directly.
(defmacro op-step-call-cfg (j a b)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,j)
               (list :const (list :i32) ,a)
               (list :const (list :i32) ,b)
               (list :ref.func_addr 7)
               (list :call_ref *op-step-type*))))

(defmacro def-step-call-entry (j)
  (let ((name (acl2::packn-pos (list "IR-OP-STEP-CALL-ENTRY" j)
                               (quote milawa-wasm))))
    `(defthm ,name
       (equal (car (w3t::step (op-step-call-cfg ,j (sel a) (sel b))))
              (frame-cfg ,j (sel a) (sel b)
                         (append (dispatch-cmp 0)
                                 (dispatch-tail 0))))
       :hints (("Goal"
                :expand ((w3t::step (op-step-call-cfg ,j (sel a) (sel b))))
                :in-theory (e/d (no-ctxt-instrs-on-op-step-call
                                 we::step-rule-defs
                                 sel-un-p un-p-implies-ubp
                                 frame-cfg dframe ir-frame-with-locals
                                 wrt::%put-field
                                 dispatch-cmp dispatch-branch dispatch-tail
                                 dispatch-body-from
                                 append binary-append we::append-of-cons
                                 we::append-when-not-consp)
                                (ir-op-step-invoke-cfg sel tail-sel))
                :do-not-induct t)))))

(def-step-call-entry 0)
(def-step-call-entry 1)
(def-step-call-entry 2)
(def-step-call-entry 3)
(def-step-call-entry 4)
(def-step-call-entry 5)
(def-step-call-entry 6)
(def-step-call-entry 7)
