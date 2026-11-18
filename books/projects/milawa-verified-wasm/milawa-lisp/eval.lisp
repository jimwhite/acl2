; Milawa-Lisp, part 2: the evaluator, as a step function plus a run loop.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The interpreter is split in two:
;
;   MILAWA-STEP   one step of an abstract machine.  Non-recursive.  This is the
;                 function the WASM module will have to implement, so the
;                 refinement books talk about it directly.
;
;   MILAWA-RUN    fuel-counted loop around MILAWA-STEP.  A single recursive
;                 function with one tail call, which is what makes the
;                 metatheory (fuel monotonicity) go through: a step at fuel m is
;                 the same step at fuel n, and the recursive calls are at (1- m)
;                 and (1- n).
;
; Writing the interpreter as a mutual recursion instead would have given neither
; an induction machine nor a machine to refine.
;
; Core terms (this is exactly ACL2's translated term language, which is why a
; Milawa-Lisp program can be the ACL2 source text itself):
;
;   variable              a symbol other than T, NIL, or a keyword
;   (quote x)             a constant
;   (if test then else)   a conditional
;   (fn arg1 ... argn)    an application of a function symbol FN
;   ((lambda (v1...vn) body) arg1 ... argn)
;
; A function table maps a symbol to (name formals body).  Recursion works
; because the table is in scope at every call.
;
; Modes: :EVAL means OBJ is a term to evaluate; :RETURN means OBJ is a value
; being returned to the waiting frame on the stack.
;
; Frames:
;   (:IF then else env)              waiting for the value of a test
;   (:ARGS fn rest done env)         waiting for arguments
;      REST are the terms still to evaluate, DONE the values already obtained
;      in reverse order, ENV the environment the terms are evaluated in.
;
; The outcome is (:MILAWA-OK . value) or (:MILAWA-ABORT . reason).  Running out
; of fuel is an abort, so the loop is total and no partiality enters the logic.

(in-package "ACL2")

(include-book "values")

;; ---------------------------------------------------------------------------
;; Applying a function given evaluated arguments
;;
;; Returns (LIST :CALL body env), telling the machine to evaluate BODY in ENV,
;; or a tagged result.  Non-recursive.
;; ---------------------------------------------------------------------------

(defun milawa-apply-step (fn args ftbl)
  (declare (xargs :guard t
                  :verify-guards nil))
  (cond
   ((consp fn)
    ;; A lambda application, ((lambda (v1...vn) body) a1...an).
    (if (and (equal (car fn) 'lambda)
             (consp (cdr fn))
             (consp (cddr fn))
             (equal (cdddr fn) nil)
             (symbol-listp (cadr fn)))
        (if (equal (len (cadr fn)) (len args))
            (list :call (caddr fn) (pairlis$ (cadr fn) args))
          (milawa-abort :arity))
      (milawa-abort :ill-formed-lambda)))

   ((milawa-primitivep fn)
    (if (equal (len args) (milawa-primitive-arity fn))
        (milawa-apply-primitive fn args)
      (milawa-abort :arity)))

   (t
    (let ((def (assoc-eq fn ftbl)))
      (cond
       ((not def)
        (milawa-abort :undefined-function))
       ((not (and (consp def)
                  (symbol-listp (cadr def))
                  (consp (cddr def))))
        (milawa-abort :ill-formed-definition))
       ((equal (len (cadr def)) (len args))
        (list :call (caddr def) (pairlis$ (cadr def) args)))
       (t
        (milawa-abort :arity)))))))

(defun milawa-apply-or-run (fn args env stack ftbl)
  (declare (xargs :guard t
                  :verify-guards nil))
  (let ((r (milawa-apply-step fn args ftbl)))
    (cond ((eq (car r) :call)
           ;; A function body: evaluate it and return to the same frames.
           (list :run :eval (cadr r) (caddr r) stack))
          ((milawa-okp r)
           ;; A primitive's value: hand it to the waiting frames.  Returning it
           ;; as the step's result would skip them, which is wrong whenever the
           ;; application is not itself the whole program.
           (list :run :return (milawa-result-value r) env stack))
          (t r))))

;; ---------------------------------------------------------------------------
;; One step
;;
;; Returns (LIST :RUN mode obj env stack) for the next configuration, or a
;; tagged result when the machine has finished.
;; ---------------------------------------------------------------------------

(defun milawa-step (mode obj env stack ftbl)
  (declare (xargs :guard t
                  :verify-guards nil))
  (if (eq mode :eval)
      (cond
       ((symbolp obj)
        (cond ((keywordp obj) (list :run :return obj env stack))
              ((eq obj t)     (list :run :return t env stack))
              ((eq obj nil)   (list :run :return nil env stack))
              (t (let ((pair (assoc-eq obj env)))
                   (if pair
                       (list :run :return (cdr pair) env stack)
                     (milawa-abort :unbound-variable))))))
       ((atom obj)
        ;; A constant must be written (QUOTE x), as in ACL2's internal terms.
        (milawa-abort :unquoted-constant))
       ((eq (car obj) 'quote)
        (if (and (consp (cdr obj))
                 (equal (cddr obj) nil))
            (list :run :return (cadr obj) env stack)
          (milawa-abort :ill-formed-quote)))
       ((eq (car obj) 'if)
        (if (and (consp (cdr obj))        ; test
                 (consp (cddr obj))       ; then
                 (consp (cdddr obj))      ; else
                 (equal (cddddr obj) nil))
            (list :run :eval (cadr obj) env
                  (cons (list :if (caddr obj) (cadddr obj) env) stack))
          (milawa-abort :ill-formed-if)))
       (t
        (let ((args (cdr obj)))
          (cond
           ((not (true-listp args))
            (milawa-abort :ill-formed-argument-list))
           ((endp args)
            (milawa-apply-or-run (car obj) nil env stack ftbl))
           (t
            (list :run :eval (car args) env
                  (cons (list :args (car obj) (cdr args) nil env) stack)))))))

    ;; ---------------------------------------------------------------- :RETURN
    (if (endp stack)
        (milawa-ok obj)
      (let* ((frame      (car stack))
             (rest-stack (cdr stack)))
        (cond
         ((eq (car frame) :if)
          (list :run :eval (if obj (cadr frame) (caddr frame))
                (cadddr frame) rest-stack))
         ((eq (car frame) :args)
          (let* ((fn    (cadr frame))
                 (terms (caddr frame))
                 (done  (cadddr frame))
                 (fenv  (nth 4 frame)))
            (if (endp terms)
                (milawa-apply-or-run fn (reverse (cons obj done)) fenv rest-stack ftbl)
              (list :run :eval (car terms) fenv
                    (cons (list :args fn (cdr terms) (cons obj done) fenv)
                          rest-stack)))))
         (t
          (milawa-abort :ill-formed-frame)))))))

;; ---------------------------------------------------------------------------
;; The run loop
;; ---------------------------------------------------------------------------

(defun milawa-run (mode obj env stack ftbl fuel)
  (declare (xargs :measure (nfix fuel)
                  :verify-guards nil))
  (if (zp fuel)
      (milawa-abort :fuel)
    (let ((s (milawa-step mode obj env stack ftbl)))
      (if (eq (car s) :run)
          (milawa-run (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s) ftbl (1- fuel))
        s))))

(defun milawa-eval (term env ftbl fuel)
  (declare (xargs :guard t
                  :verify-guards nil))
  (milawa-run :eval term env nil ftbl fuel))

(defun milawa-call (fn args ftbl fuel)
  (declare (xargs :guard t
                  :verify-guards nil))
  (let ((def (assoc-eq fn ftbl)))
    (cond
     ((not def)
      (milawa-abort :undefined-function))
     ((not (and (consp def)
                (symbol-listp (cadr def))
                (consp (cddr def))))
      (milawa-abort :ill-formed-definition))
     ((not (equal (len (cadr def)) (len args)))
      (milawa-abort :arity))
     ((not (milawa-value-listp args))
      (milawa-abort :non-value-argument))
     (t
      (milawa-eval (caddr def)
                   (pairlis$ (cadr def) args)
                   ftbl
                   fuel)))))
