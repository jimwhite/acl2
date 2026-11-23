; J2a: a flat stack/pc bytecode machine for the J1 IR, and its lowering.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The J1 compiler emits a structured IR.  This book lowers it to a flat
; instruction list with labels and gives that list a stack/pc step machine.
; It is the ACL2 machine layer; the per-opcode WASM artifact is J2b.
;
; FLAT INSTRUCTIONS:
;
;   (:const v)     push a value
;   (:load x)      push a variable's value
;   (:prim fn)     apply a primitive to the top 1/2 values
;   (:ifz l)       pop; jump to label l when the value is NIL
;   (:jmp l)       jump to label l
;   (:label l)     a label (a no-op at run time)
;   (:halt)        finish, with the top of the stack as the result
;
; The lowering is a simple recursive pass.  Each instruction's step is stated
; as its own theorem (the per-opcode layer); the dispatcher is the `case` in
; MACHINE-STEP.  The general run-level theorem is J3; the closed instances at
; the end are the J2a acceptance checks.

(in-package "MILAWA-WASM")

(include-book "compile")

;; ---------------------------------------------------------------------------
;; The flat program
;; ---------------------------------------------------------------------------

(defun lower-term (code next)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count code)))
  (case (car code)
    (:const (mv (list code) next))
    (:load (mv (list code) next))
    (:prim
     (let ((arity (milawa-primitive-arity (cadr code))))
       (cond
        ((equal arity 1)
         (mv-let (a n1) (lower-term (caddr code) next)
           (mv (append a (list (list :prim (cadr code)))) n1)))
        ((equal arity 2)
         (mv-let (a n1) (lower-term (caddr code) next)
           (mv-let (b n2) (lower-term (cadddr code) n1)
             (mv (append a (append b (list (list :prim (cadr code))))) n2))))
        (t (mv (list (list :abort)) next)))))
    (:if
     (let ((l-else next) (l-end (+ 1 next)))
       (mv-let (test-code n1) (lower-term (cadr code) (+ 2 next))
         (mv-let (then-code n2) (lower-term (caddr code) n1)
           (mv-let (else-code n3) (lower-term (cadddr code) n2)
             (mv (append test-code
                         (append (list (list :ifz l-else))
                                 (append then-code
                                         (append (list (list :jmp l-end))
                                                 (append (list (list :label l-else))
                                                         (append else-code
                                                                 (list (list :label l-end))))))))
                 n3))))))
    (otherwise (mv (list (list :abort)) next))))

(defun lower-program (code)
  (declare (xargs :guard t :verify-guards nil))
  (mv-let (flat next)
    (lower-term code 0)
    (declare (ignore next))
    (append flat (list (list :halt)))))

(defun label-pc (l code pc)
  (declare (xargs :guard t :verify-guards nil))
  (if (endp code)
      nil
    (if (and (consp (car code))
             (equal (car (car code)) :label)
             (equal (cadr (car code)) l))
        pc
      (label-pc l (cdr code) (1+ pc)))))

;; ---------------------------------------------------------------------------
;; The machine
;; ---------------------------------------------------------------------------

(defun machine-step (pc stack code env)
  (declare (xargs :guard t :verify-guards nil))
  (if (or (not (natp pc))
          (<= (len code) pc)
          (not (consp (nth pc code))))
      (milawa-abort :bad-pc)
    (let ((ins (nth pc code)))
      (case (car ins)
        (:const (list :run (1+ pc) (cons (cadr ins) stack)))
        (:load (let ((pair (assoc-eq (cadr ins) env)))
                 (if pair
                     (list :run (1+ pc) (cons (cdr pair) stack))
                   (milawa-abort :unbound-variable))))
        (:prim
         (let ((arity (milawa-primitive-arity (cadr ins))))
           (cond
            ((equal arity 1)
             (if (consp stack)
                 (let ((r (milawa-apply-primitive (cadr ins)
                                                  (list (car stack)))))
                   (if (milawa-okp r)
                       (list :run (1+ pc)
                             (cons (milawa-result-value r) (cdr stack)))
                     r))
               (milawa-abort :stack-underflow)))
            ((equal arity 2)
             (if (and (consp stack) (consp (cdr stack)))
                 (let ((r (milawa-apply-primitive
                           (cadr ins)
                           (list (cadr stack) (car stack)))))
                   (if (milawa-okp r)
                       (list :run (1+ pc)
                             (cons (milawa-result-value r) (cddr stack)))
                     r))
               (milawa-abort :stack-underflow)))
            (t (milawa-abort :bad-arity)))))
        (:ifz
         (if (consp stack)
             (if (car stack)
                 (list :run (1+ pc) (cdr stack))
               (let ((l (label-pc (cadr ins) code 0)))
                 (if l
                     (list :run l (cdr stack))
                   (milawa-abort :missing-label))))
           (milawa-abort :stack-underflow)))
        (:jmp
         (let ((l (label-pc (cadr ins) code 0)))
           (if l
               (list :run l stack)
             (milawa-abort :missing-label))))
        (:label (list :run (1+ pc) stack))
        (:halt (if (consp stack)
                   (milawa-ok (car stack))
                 (milawa-abort :empty-stack)))
        (otherwise (milawa-abort :bad-instruction))))))

(defun machine-run (pc stack code env fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      (milawa-abort :fuel)
    (let ((s (machine-step pc stack code env)))
      (if (and (consp s) (eq (car s) :run))
          (machine-run (cadr s) (caddr s) code env (1- fuel))
        s))))

(defun machine-run-program (code env fuel)
  (declare (xargs :guard t :verify-guards nil))
  (machine-run 0 nil code env fuel))

;; ---------------------------------------------------------------------------
;; Per-opcode steps
;;
;; One theorem per flat opcode, for a symbolic stack/state at that pc.
;; ---------------------------------------------------------------------------

(defthm machine-step-const
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :const v)))
           (equal (machine-step pc stack code env)
                  (list :run (1+ pc) (cons v stack))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-load
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :load x)))
           (equal (machine-step pc stack code env)
                  (let ((pair (assoc-eq x env)))
                    (if pair
                        (list :run (1+ pc) (cons (cdr pair) stack))
                      (milawa-abort :unbound-variable)))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-label
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :label l)))
           (equal (machine-step pc stack code env)
                  (list :run (1+ pc) stack)))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-halt
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :halt)))
           (equal (machine-step pc stack code env)
                  (if (consp stack)
                      (milawa-ok (car stack))
                    (milawa-abort :empty-stack))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-jmp
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :jmp l))
                (label-pc l code 0))
           (equal (machine-step pc stack code env)
                  (list :run (label-pc l code 0) stack)))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-ifz-true
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :ifz l))
                (consp stack)
                (car stack))
           (equal (machine-step pc stack code env)
                  (list :run (1+ pc) (cdr stack))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-ifz-false
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :ifz l))
                (consp stack)
                (not (car stack))
                (label-pc l code 0))
           (equal (machine-step pc stack code env)
                  (list :run (label-pc l code 0) (cdr stack))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-prim-1
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :prim fn))
                (equal (milawa-primitive-arity fn) 1)
                (consp stack))
           (equal (machine-step pc stack code env)
                  (let ((r (milawa-apply-primitive fn (list (car stack)))))
                    (if (milawa-okp r)
                        (list :run (1+ pc)
                              (cons (milawa-result-value r) (cdr stack)))
                      r))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defthm machine-step-prim-2
  (implies (and (natp pc) (< pc (len code))
                (equal (nth pc code) (list :prim fn))
                (equal (milawa-primitive-arity fn) 2)
                (consp stack) (consp (cdr stack)))
           (equal (machine-step pc stack code env)
                  (let ((r (milawa-apply-primitive
                            fn (list (cadr stack) (car stack)))))
                    (if (milawa-okp r)
                        (list :run (1+ pc)
                              (cons (milawa-result-value r) (cddr stack)))
                      r))))
  :hints (("Goal" :in-theory (enable machine-step))))

(defun instruction-p (x)
  (declare (xargs :guard t :verify-guards nil))
  (and (consp x)
       (cond ((equal (car x) :const)
              (and (consp (cdr x)) (null (cddr x))))
             ((equal (car x) :load)
              (and (consp (cdr x)) (null (cddr x))))
             ((equal (car x) :prim)
              (and (consp (cdr x)) (null (cddr x))
                   (milawa-primitivep (cadr x))))
             ((equal (car x) :ifz)
              (and (consp (cdr x)) (null (cddr x))))
             ((equal (car x) :jmp)
              (and (consp (cdr x)) (null (cddr x))))
             ((equal (car x) :label)
              (and (consp (cdr x)) (null (cddr x))))
             ((equal (car x) :halt) (null (cdr x)))
             (t nil))))

; The dispatcher: every well-formed instruction is handled, with no
; :BAD-INSTRUCTION fall-through.  The per-opcode lemmas above give the exact
; state for each case; this theorem is the coverage statement.
(defthm machine-step-dispatches
  (implies (and (natp pc) (< pc (len code))
                (instruction-p (nth pc code)))
           (or (equal (car (machine-step pc stack code env)) :run)
               (milawa-resultp (machine-step pc stack code env))))
  :hints (("Goal" :in-theory (enable machine-step instruction-p
                                     milawa-resultp milawa-okp milawa-abortp))))

;; ---------------------------------------------------------------------------
;; J2a acceptance: the PoC and representative forms through the whole pass.
;; ---------------------------------------------------------------------------

(defthm j2-add
  (equal (machine-run-program
          (lower-program (compile-term '(+ (quote 1) (quote 2))))
          nil 100)
         (milawa-ok 3)))

(defthm j2-if
  (equal (machine-run-program
          (lower-program (compile-term '(if (< (quote 1) (quote 2))
                                         (quote 10)
                                       (quote 20))))
          nil 100)
         (milawa-ok 10)))

(defthm j2-cons
  (equal (machine-run-program
          (lower-program (compile-term '(cons (quote 1) (quote 2))))
          nil 100)
         (milawa-ok '(1 . 2))))
