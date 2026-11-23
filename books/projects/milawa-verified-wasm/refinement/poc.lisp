; J3 front door: the run-level theorems applied to the PoC and to
; representative if and cons programs.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The general theorems are:
;   COMPILE-CORRECT     bc-eval (compile-term term) = r-ev term
;   HOST-RUN-REFINES-MACHINE-RUN
;                       the host loop (calling the verified STEP for +,-,<)
;                       equals the bytecode machine run, unless the
;                       artifact's 30-bit range is exceeded
;   IR-OP-STEP-CALL-RESULT
;                       the exported dispatcher returns the opcode value
;                       after its W3T clock
;
; The closed theorems below are instances: the machine/host runs are the
; existing J2a closed passes, and the W3T theorems are dispatcher instances
; derived from IR-OP-STEP-CALL-RESULT (no concrete W3T step chain).

(in-package "MILAWA-WASM")

(include-book "top-host")
(include-book "ops-step-theorem")

;; ---------------------------------------------------------------------------
;; Machine and host runs
;; ---------------------------------------------------------------------------

(defthm host-safe-poc-add
  (host-safe 0 nil
             (lower-program (compile-term '(+ (quote 1) (quote 2))))
             nil 100)
  :hints (("Goal" :in-theory (enable host-safe host-step
                                     host-add-2
                                     milawa-apply-primitive
                                     milawa-+))))

(defthm poc-host-add
  (equal (host-run-program
          (lower-program (compile-term '(+ (quote 1) (quote 2))))
          nil 100)
         (milawa-ok 3))
  :hints (("Goal"
           :use (host-safe-poc-add
                 (:instance host-safe-implies-refines
                            (pc 0) (stack nil)
                            (code (lower-program
                                   (compile-term '(+ (quote 1) (quote 2)))))
                            (env nil) (fuel 100))
                 j2-add)
           :in-theory (disable host-run-program machine-run-program))))

(defthm host-safe-poc-if
  (host-safe 0 nil
             (lower-program
              (compile-term '(if (< (quote 1) (quote 2))
                                 (quote 10)
                               (quote 20))))
             nil 100)
  :hints (("Goal" :in-theory (enable host-safe host-step
                                     host-lt-2
                                     milawa-apply-primitive
                                     milawa-<))))

(defthm poc-host-if
  (equal (host-run-program
          (lower-program
           (compile-term '(if (< (quote 1) (quote 2))
                              (quote 10)
                            (quote 20))))
          nil 100)
         (milawa-ok 10))
  :hints (("Goal"
           :use (host-safe-poc-if
                 (:instance host-safe-implies-refines
                            (pc 0) (stack nil)
                            (code (lower-program
                                   (compile-term '(if (< (quote 1) (quote 2))
                                                      (quote 10)
                                                    (quote 20)))))
                            (env nil) (fuel 100))
                 j2-if)
           :in-theory (disable host-run-program machine-run-program))))

(defthm host-safe-poc-cons
  (host-safe 0 nil
             (lower-program (compile-term '(cons (quote 1) (quote 2))))
             nil 100)
  :hints (("Goal" :in-theory (enable host-safe host-step
                                     milawa-apply-primitive))))

(defthm poc-host-cons
  (equal (host-run-program
          (lower-program (compile-term '(cons (quote 1) (quote 2))))
          nil 100)
         (milawa-ok '(1 . 2)))
  :hints (("Goal"
           :use (host-safe-poc-cons
                 (:instance host-safe-implies-refines
                            (pc 0) (stack nil)
                            (code (lower-program
                                   (compile-term '(cons (quote 1) (quote 2)))))
                            (env nil) (fuel 100))
                 j2-cons)
           :in-theory (disable host-run-program machine-run-program))))

;; ---------------------------------------------------------------------------
;; Closed W3T dispatcher instances (the artifact's STEP)
;; ---------------------------------------------------------------------------

(defthm poc-w3t-add
  (equal (step-prefix 21 (op-step-call-cfg 2 1 2))
         (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :const (list :i32) 3))))
  :hints (("Goal"
           :use ((:instance ir-op-step-call-result (op 2) (a 1) (b 2)))
           :in-theory (e/d (sel)
                           (w3t::step sel-un-p un-p-implies-ubp)))))

(defthm poc-w3t-lt
  (equal (step-prefix 31 (op-step-call-cfg 4 1 2))
         (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :const (list :i32) 1))))
  :hints (("Goal"
           :use ((:instance ir-op-step-call-result (op 4) (a 1) (b 2)))
           :in-theory (e/d (sel)
                           (w3t::step sel-un-p un-p-implies-ubp)))))

(defthm poc-w3t-ifz
  (equal (step-prefix 37 (op-step-call-cfg 5 0 42))
         (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :const (list :i32) 42))))
  :hints (("Goal"
           :use ((:instance ir-op-step-call-result (op 5) (a 0) (b 42)))
           :in-theory (e/d (sel)
                           (w3t::step sel-un-p un-p-implies-ubp)))))

;; ---------------------------------------------------------------------------
;; make poc prints these
;; ---------------------------------------------------------------------------

(value-triple
 (list :term '(+ (quote 1) (quote 2))
       :spec (r-ev '(+ (quote 1) (quote 2)) nil)
       :machine (machine-run-program
                 (lower-program (compile-term '(+ (quote 1) (quote 2))))
                 nil 100)
       :host (host-run-program
              (lower-program (compile-term '(+ (quote 1) (quote 2))))
              nil 100)
       :wasm-dispatcher-value (ir-step 2 1 2)))

(value-triple
 (list :term '(if (< (quote 1) (quote 2)) (quote 10) (quote 20))
       :spec (r-ev '(if (< (quote 1) (quote 2)) (quote 10) (quote 20)) nil)
       :machine (machine-run-program
                 (lower-program
                  (compile-term '(if (< (quote 1) (quote 2))
                                     (quote 10)
                                   (quote 20))))
                 nil 100)
       :host (host-run-program
              (lower-program
               (compile-term '(if (< (quote 1) (quote 2))
                                  (quote 10)
                                (quote 20))))
              nil 100)))

(value-triple
 (list :term '(cons (quote 1) (quote 2))
       :spec (r-ev '(cons (quote 1) (quote 2)) nil)
       :machine (machine-run-program
                 (lower-program (compile-term '(cons (quote 1) (quote 2))))
                 nil 100)
       :host (host-run-program
              (lower-program (compile-term '(cons (quote 1) (quote 2))))
              nil 100)))
