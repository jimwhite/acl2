; J1: the compiler and its correctness theorem for the arithmetic/control
; subset.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This is the first Jitawa-shaped layer: an untrusted COMPILE-TERM and ONE
; theorem, COMPILE-CORRECT, for all terms of the subset.  The target is a
; STRUCTURED bytecode (an instruction tree, the IR a later lowering pass will
; flatten):
;
;   (:CONST v)                 push a value
;   (:LOAD x)                  read a variable
;   (:PRIM fn arg1 [arg2])     a primitive application
;   (:IF test then else)       conditional
;
; BC-EVAL is the IR's semantics.  It is deliberately a tree evaluator here:
; J1a is the compiler-correctness theorem.  The flat stack/pc machine
; (BC-STEP/BC-RUN) and the lowering theorem are J1b, and the per-opcode WASM
; machine is J2; both consume this theorem rather than replacing it.
;
; COMPILE-CORRECT is the BC_ev_thm analogue: an untrusted compiler plus one
; parametric theorem.  The corollaries are the PoC's expressions as
; instances; they are evaluation checks, not separate proofs.

(in-package "MILAWA-WASM")

(include-book "spec")

(defun compile-term (term)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count term)))
  (cond ((variable-p term) (list :load term))
        ((keywordp term) (list :const term))
        ((eq term t) (list :const t))
        ((eq term nil) (list :const nil))
        ((eq (car term) 'quote) (list :const (cadr term)))
        ((eq (car term) 'if)
         (list :if (compile-term (cadr term))
               (compile-term (caddr term))
               (compile-term (cadddr term))))
        ((milawa-primitivep (car term))
         (let ((arity (milawa-primitive-arity (car term))))
           (cond ((equal arity 1)
                  (list :prim (car term) (compile-term (cadr term))))
                 ((equal arity 2)
                  (list :prim (car term)
                        (compile-term (cadr term))
                        (compile-term (caddr term))))
                 (t (list :abort)))))
        (t (list :abort))))

(defun bc-eval (code env)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count code)))
  (case (car code)
    (:const (milawa-ok (cadr code)))
    (:load (let ((pair (assoc-eq (cadr code) env)))
             (if pair (milawa-ok (cdr pair)) (milawa-abort :unbound-variable))))
    (:prim
     (let ((arity (milawa-primitive-arity (cadr code))))
       (cond ((equal arity 1)
              (let ((r (bc-eval (caddr code) env)))
                (if (milawa-abortp r) r
                  (milawa-apply-primitive (cadr code)
                                          (list (milawa-result-value r))))))
             ((equal arity 2)
              (let ((r1 (bc-eval (caddr code) env)))
                (if (milawa-abortp r1) r1
                  (let ((r2 (bc-eval (cadddr code) env)))
                    (if (milawa-abortp r2) r2
                      (milawa-apply-primitive
                       (cadr code)
                       (list (milawa-result-value r1)
                             (milawa-result-value r2))))))))
             (t (milawa-abort :bad-arity)))))
    (:if (let ((r (bc-eval (cadr code) env)))
           (if (milawa-abortp r) r
             (if (milawa-result-value r)
                 (bc-eval (caddr code) env)
               (bc-eval (cadddr code) env)))))
    (otherwise (milawa-abort :bad-instruction))))

(defthm compile-correct
  (implies (term-p term)
           (equal (bc-eval (compile-term term) env)
                  (r-ev term env)))
  :hints (("Goal" :induct (r-ev term env)
                  :in-theory (enable milawa-abortp milawa-okp milawa-result-value)
                  :expand ((compile-term term)
                           (bc-eval (compile-term term) env)
                           (r-ev term env)))))

; Instances: the PoC's expressions and a CONS, as corollaries of the theorem.
(defthm compile-correct-add
  (equal (bc-eval (compile-term '(+ (quote 1) (quote 2))) nil)
         (milawa-ok 3)))

(defthm compile-correct-if
  (equal (bc-eval (compile-term '(if (< (quote 1) (quote 2))
                                    (quote 10)
                                  (quote 20)))
                  nil)
         (milawa-ok 10)))

(defthm compile-correct-cons
  (equal (bc-eval (compile-term '(cons (quote 1) (quote 2))) nil)
         (milawa-ok '(1 . 2))))
