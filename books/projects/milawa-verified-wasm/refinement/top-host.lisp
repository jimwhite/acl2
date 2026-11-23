; J3: the host loop over the verified opcode library.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The J2 machine (machine.lisp) runs flat bytecode with its primitives
; evaluated by MILAWA-APPLY-PRIMITIVE.  The J2b artifact exports a pure
; STEP(op,a,b); the host holds the pc/stack and calls STEP for the
; arithmetic primitives.  This book models that host loop:
;
;   HOST-PRIM-2  calls the verified opcode model (IR-STEP) for +, -, <,
;                checking the artifact's 30-bit range first; other
;                primitives stay in the host.
;   HOST-STEP    is MACHINE-STEP except for a two-argument arithmetic
;                primitive, which goes through HOST-PRIM-2.
;   HOST-RUN     is the loop.
;
; The general theorem is HOST-RUN-REFINES-MACHINE-RUN: whenever the run
; does not hit the artifact's range limit, the host loop and the ACL2
; machine agree at every step.  The range check is the artifact's honest
; boundary: WASM i32 ADD/SUB wrap and LT is signed, while the Milawa
; primitives are 30-bit with overflow aborts, subtraction clamped at 0,
; and T/NIL predicates.

(in-package "MILAWA-WASM")

(include-book "machine")
(include-book "ops")

;; ---------------------------------------------------------------------------
;; The exported STEP's contribution: one two-argument arithmetic value
;; ---------------------------------------------------------------------------

; The artifact's step is the dispatcher; IR-STEP is its checked model
; (ops.lisp).  These three functions call the model only when the operands
; are in the range where the artifact's i32 result is the Milawa value.

(defun host-add-2 (a b)
  (declare (xargs :guard t :verify-guards nil))
  (if (and (unsigned-byte-p 30 a)
           (unsigned-byte-p 30 b)
           (< (+ a b) (expt 2 30)))
      (milawa-ok (ir-step 2 a b))
    (milawa-abort :wasm-range)))

; The Milawa subtraction clamps at 0; the artifact wraps, so underflow is
; outside the artifact's range.
(defun host-sub-2 (a b)
  (declare (xargs :guard t :verify-guards nil))
  (if (and (unsigned-byte-p 30 a)
           (unsigned-byte-p 30 b)
           (<= b a))
      (milawa-ok (ir-step 3 a b))
    (milawa-abort :wasm-range)))

; The Milawa < returns T/NIL; the artifact returns 1/0.  The host reads the
; artifact's 1/0 and produces the predicate value the machine expects.
(defun host-lt-2 (a b)
  (declare (xargs :guard t :verify-guards nil))
  (if (and (unsigned-byte-p 30 a)
           (unsigned-byte-p 30 b))
      (milawa-ok (not (equal (ir-step 4 a b) 0)))
    (milawa-abort :wasm-range)))

;; ---------------------------------------------------------------------------
;; The host step and loop
;; ---------------------------------------------------------------------------


(defthm host-add-2-in-range
  (implies (and (unsigned-byte-p 30 a)
                (unsigned-byte-p 30 b)
                (< (+ a b) (expt 2 30)))
           (equal (host-add-2 a b)
                  (milawa-apply-primitive '+ (list a b))))
  :hints (("Goal" :in-theory (enable host-add-2
                                     ir-step
                                     milawa-apply-primitive
                                     milawa-+
                                     milawa-ok
                                     milawa-result-value))))

(defthm host-sub-2-in-range
  (implies (and (unsigned-byte-p 30 a)
                (unsigned-byte-p 30 b)
                (<= b a))
           (equal (host-sub-2 a b)
                  (milawa-apply-primitive '- (list a b))))
  :hints (("Goal" :in-theory (enable host-sub-2
                                     ir-step
                                     milawa-apply-primitive
                                     milawa--
                                     milawa-ok
                                     milawa-result-value))))

(defthm host-lt-2-in-range
  (implies (and (unsigned-byte-p 30 a)
                (unsigned-byte-p 30 b))
           (equal (host-lt-2 a b)
                  (milawa-apply-primitive '< (list a b))))
  :hints (("Goal" :in-theory (enable host-lt-2
                                     ir-step
                                     milawa-apply-primitive
                                     milawa-<
                                     milawa-ok
                                     milawa-result-value))))

(defun host-step (pc stack code env)
  (declare (xargs :guard t :verify-guards nil))
  (if (and (natp pc)
           (< pc (len code))
           (consp (nth pc code))
           (equal (car (nth pc code)) :prim)
           (equal (milawa-primitive-arity (cadr (nth pc code))) 2)
           (or (eq (cadr (nth pc code)) '+)
               (eq (cadr (nth pc code)) '-)
               (eq (cadr (nth pc code)) '<)))
      (if (and (consp stack) (consp (cdr stack)))
          (let ((r (cond ((eq (cadr (nth pc code)) '+)
                          (host-add-2 (cadr stack) (car stack)))
                         ((eq (cadr (nth pc code)) '-)
                          (host-sub-2 (cadr stack) (car stack)))
                         (t (host-lt-2 (cadr stack) (car stack))))))
            (if (milawa-okp r)
                (list :run (1+ pc)
                      (cons (milawa-result-value r) (cddr stack)))
              r))
        (milawa-abort :stack-underflow))
    (machine-step pc stack code env)))

(defun host-run (pc stack code env fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      (milawa-abort :fuel)
    (let ((s (host-step pc stack code env)))
      (if (and (consp s) (eq (car s) :run))
          (host-run (cadr s) (caddr s) code env (1- fuel))
        s))))

(defun host-run-program (code env fuel)
  (declare (xargs :guard t :verify-guards nil))
  (host-run 0 nil code env fuel))

;; ---------------------------------------------------------------------------
;; The refinement
;; ---------------------------------------------------------------------------

(defthm host-step-equal-or-range
  (or (equal (host-step pc stack code env)
             (machine-step pc stack code env))
      (equal (host-step pc stack code env)
             (milawa-abort :wasm-range)))
  :hints (("Goal" :in-theory (e/d (host-step
                                   host-add-2-in-range
                                   host-sub-2-in-range
                                   host-lt-2-in-range
                                   machine-step)
                                  ()))))

(defthm host-step-equal-when-not-range
  (implies (not (equal (host-step pc stack code env)
                       (milawa-abort :wasm-range)))
           (equal (host-step pc stack code env)
                  (machine-step pc stack code env)))
  :hints (("Goal" :use host-step-equal-or-range
                  :in-theory (disable host-step machine-step
                                      milawa-primitive-arity
                                      milawa-primitivep))))

(defun host-safe (pc stack code env fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      t
    (let ((s (host-step pc stack code env)))
      (if (equal s (milawa-abort :wasm-range))
          nil
        (if (and (consp s) (eq (car s) :run))
            (host-safe (cadr s) (caddr s) code env (1- fuel))
          t)))))

(defthm host-safe-implies-refines
  (implies (host-safe pc stack code env fuel)
           (equal (host-run pc stack code env fuel)
                  (machine-run pc stack code env fuel)))
  :hints (("Goal" :induct (host-safe pc stack code env fuel)
                  :in-theory (e/d (host-safe host-run machine-run
                                             host-step-equal-when-not-range)
                                  (host-step machine-step
                                   milawa-primitive-arity
                                   milawa-primitivep)))))

(defthm not-host-safe-implies-range
  (implies (not (host-safe pc stack code env fuel))
           (equal (host-run pc stack code env fuel)
                  (milawa-abort :wasm-range)))
  :hints (("Goal" :induct (host-safe pc stack code env fuel)
                  :in-theory (e/d (host-safe host-run)
                                  (host-step machine-step
                                   milawa-primitive-arity
                                   milawa-primitivep)))))

(defthm host-run-refines-machine-run
  (implies (not (equal (host-run pc stack code env fuel)
                       (milawa-abort :wasm-range)))
           (equal (host-run pc stack code env fuel)
                  (machine-run pc stack code env fuel)))
  :hints (("Goal" :cases ((host-safe pc stack code env fuel))
                  :in-theory (disable host-safe host-run machine-run
                                      host-step
                                      host-safe-implies-refines
                                      not-host-safe-implies-range)
                  :use (host-safe-implies-refines
                        not-host-safe-implies-range))))
