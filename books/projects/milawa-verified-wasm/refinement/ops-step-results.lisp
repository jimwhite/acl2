; The dispatcher call result per opcode: $INVOKE, the call entry, and the
; full frame trace, in one composition.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-step-entry")

(defmacro def-step-call-result (j entry tail frame-steps v hyps)
  (let ((name (acl2::packn-pos (list "IR-OP-STEP-CALL-RESULT" j)
                               (quote milawa-wasm))))
    `(defthm ,name
       (implies (and ,@hyps)
                (equal
                 (step-prefix
                  ,(1+ frame-steps)
                  (op-step-call-cfg ,j (sel a) (sel b)))
                 (list :|%;%|
                       (list :|%;%| *ir-store* *ir-call-frame*)
                       (list (list :const (list :i32) ,v)))))
       :hints (("Goal"
                :use (,entry ,tail)
                :in-theory (e/d (,entry
                                 ,tail
                                 sel-un-p
                                 un-p-implies-ubp)
                                (w3t::step dframe ir-frame-with-locals
                                 frame-cfg sel tail-sel
                                 dispatch-cmp dispatch-branch dispatch-tail
                                 (:e dispatch-tail)
                                 ir-op-step-invoke-cfg
                                 append binary-append
                                 we::append-of-cons
                                 step-const-return-cons-rest-un-p
                                 acl2::loghead acl2::loghead$inline
                                 acl2::ifix acl2::mod acl2::floor
                                 acl2::imod$inline acl2::expt2$inline
                                 (:e cons)))
                :do-not-induct t)))))

(def-step-call-result 0 ir-op-step-call-entry0 frame-trace-0 8
  (sel a) nil)

(def-step-call-result 1 ir-op-step-call-entry1 frame-trace-1-full 13
  (sel a) nil)

(def-step-call-result 2 ir-op-step-call-entry2 frame-trace-2 20
  (loghead 32 (+ (sel a) (sel b))) nil)

(def-step-call-result 3 ir-op-step-call-entry3 frame-trace-3 25
  (loghead 32 (+ (sel a) (- (sel b)))) nil)

(def-step-call-result 4 ir-op-step-call-entry4 frame-trace-4 30
  (if (< (sel a) (sel b)) 1 0)
  ((unsigned-byte-p 31 (sel a))
   (unsigned-byte-p 31 (sel b))))

(def-step-call-result 5 ir-op-step-call-entry5 frame-trace-5 36
  (if (equal (sel a) 0) (sel b) 0) nil)

(def-step-call-result 6 ir-op-step-call-entry6 frame-trace-6-op 38
  (sel b) nil)

(def-step-call-result 7 ir-op-step-call-entry7 frame-trace-7 43
  (sel a) nil)
