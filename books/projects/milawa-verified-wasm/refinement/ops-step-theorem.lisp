; The exported STEP dispatcher theorem: for every opcode 0-7, the
; $INVOKE of function 7 reaches the opcode's value configuration.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-step-results")

(defmacro step-call-lhs (op)
  `(case ,op
     (0 (step-prefix 9 (op-step-call-cfg 0 (sel a) (sel b))))
     (1 (step-prefix 14 (op-step-call-cfg 1 (sel a) (sel b))))
     (2 (step-prefix 21 (op-step-call-cfg 2 (sel a) (sel b))))
     (3 (step-prefix 26 (op-step-call-cfg 3 (sel a) (sel b))))
     (4 (step-prefix 31 (op-step-call-cfg 4 (sel a) (sel b))))
     (5 (step-prefix 37 (op-step-call-cfg 5 (sel a) (sel b))))
     (6 (step-prefix 39 (op-step-call-cfg 6 (sel a) (sel b))))
     (7 (step-prefix 44 (op-step-call-cfg 7 (sel a) (sel b))))
     (otherwise nil)))

(defmacro step-call-value (op)
  `(case ,op
     (0 (sel a))
     (1 (sel a))
     (2 (loghead 32 (+ (sel a) (sel b))))
     (3 (loghead 32 (+ (sel a) (- (sel b)))))
     (4 (if (< (sel a) (sel b)) 1 0))
     (5 (if (equal (sel a) 0) (sel b) 0))
     (6 (sel b))
     (7 (sel a))
     (otherwise 0)))

(defthm ir-op-step-call-result
  (implies (and (natp op)
                (< op 8)
                (unsigned-byte-p 32 (sel a))
                (unsigned-byte-p 32 (sel b))
                (or (not (equal op 4))
                    (and (unsigned-byte-p 31 (sel a))
                         (unsigned-byte-p 31 (sel b)))))
           (equal
            (step-call-lhs op)
            (list
             :|%;%|
             (list :|%;%| *ir-store* *ir-call-frame*)
             (list (list :const (list :i32)
                         (step-call-value op))))))
  :hints (("Goal"
           :cases ((equal op 0) (equal op 1) (equal op 2) (equal op 3)
                   (equal op 4) (equal op 5) (equal op 6) (equal op 7))
           :in-theory (e/d (sel-un-p un-p-implies-ubp)
                           (sel tail-sel
                            frame-cfg dispatch-cmp dispatch-branch
                            dispatch-tail (:e dispatch-tail)
                            (:e dispatch-cmp) (:e dispatch-branch)
                            w3t::step ir-op-step-invoke-cfg
                            append binary-append we::append-of-cons
                            acl2::loghead acl2::loghead$inline
                            acl2::ifix acl2::mod acl2::floor
                            acl2::imod$inline acl2::expt2$inline
                            (:e cons)))
           :do-not-induct t)))
