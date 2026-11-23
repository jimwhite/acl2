; J0: the reference term language for the arithmetic/control subset.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The Jitawa-shaped stack starts with a small spec and a compiler that is
; judged against it.  This book is the first spec slice: core Milawa-Lisp
; terms built from QUOTE, variables, IF, and the twelve primitives (with IF
; handled specially).  It is deliberately separate from MILAWA-RUN: the
; compiler-correctness theorem in ../refinement/compile.lisp is about R-EV,
; and the bridge to the runtime's MILAWA-RUN is the next J1 increment.
;
; Terms are ACL2 s-expressions, which is exactly the core syntax the runtime's
; evaluator consumes:
;
;   variable          a symbol other than T, NIL, a keyword, QUOTE or IF
;   T, NIL, keyword   self-evaluating
;   (QUOTE x)         a value, x
;   (IF a b c)        conditional
;   (fn a ...)        a primitive application, fn in MILAWA-PRIMITIVE-ARITIES
;
; R-EV returns MILAWA-OK / MILAWA-ABORT, the same tagged results the runtime
; uses, so the compiler theorem is stated in the runtime's vocabulary.

(in-package "MILAWA-WASM")

(include-book "../milawa-lisp/values")

(defun variable-p (x)
  (declare (xargs :guard t :verify-guards nil))
  (and (symbolp x)
       (not (member-eq x '(quote if t nil)))
       (not (keywordp x))))

(defun term-p (x)
  (declare (xargs :guard t :verify-guards nil))
  (cond ((variable-p x) t)
        ((keywordp x) t)
        ((eq x t) t)
        ((eq x nil) t)
        ((atom x) nil)
        ((eq (car x) 'quote)
         (and (consp (cdr x)) (null (cddr x)) (milawa-valuep (cadr x))))
        ((eq (car x) 'if)
         (and (consp (cdr x)) (consp (cddr x)) (consp (cdddr x))
              (null (cddddr x))
              (term-p (cadr x)) (term-p (caddr x)) (term-p (cadddr x))))
        ((and (milawa-primitivep (car x)) (not (eq (car x) 'if)))
         (let ((arity (milawa-primitive-arity (car x))))
           (cond ((equal arity 1)
                  (and (consp (cdr x)) (null (cddr x)) (term-p (cadr x))))
                 ((equal arity 2)
                  (and (consp (cdr x)) (consp (cddr x)) (null (cdddr x))
                       (term-p (cadr x)) (term-p (caddr x))))
                 (t nil))))
        (t nil)))

(defun r-ev (term env)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count term)))
  (cond ((variable-p term)
         (let ((pair (assoc-eq term env)))
           (if pair (milawa-ok (cdr pair)) (milawa-abort :unbound-variable))))
        ((keywordp term) (milawa-ok term))
        ((eq term t) (milawa-ok t))
        ((eq term nil) (milawa-ok nil))
        ((atom term) (milawa-abort :unquoted-constant))
        ((eq (car term) 'quote) (milawa-ok (cadr term)))
        ((eq (car term) 'if)
         (let ((r (r-ev (cadr term) env)))
           (if (milawa-abortp r) r
             (if (milawa-result-value r)
                 (r-ev (caddr term) env)
               (r-ev (cadddr term) env)))))
        ((milawa-primitivep (car term))
         (let ((arity (milawa-primitive-arity (car term))))
           (cond ((equal arity 1)
                  (let ((r (r-ev (cadr term) env)))
                    (if (milawa-abortp r) r
                      (milawa-apply-primitive (car term)
                                              (list (milawa-result-value r))))))
                 ((equal arity 2)
                  (let ((r1 (r-ev (cadr term) env)))
                    (if (milawa-abortp r1) r1
                      (let ((r2 (r-ev (caddr term) env)))
                        (if (milawa-abortp r2) r2
                          (milawa-apply-primitive
                           (car term)
                           (list (milawa-result-value r1)
                                 (milawa-result-value r2))))))))
                 (t (milawa-abort :bad-arity)))))
        (t (milawa-abort :not-a-term))))
