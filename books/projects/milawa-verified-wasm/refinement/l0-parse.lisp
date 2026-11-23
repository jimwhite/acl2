; L0, part 1: surface Lisp -> core terms (macros and closure conversion).
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This is the Jitawa-shaped source front end for L0.  It is deliberately
; untrusted: the checked object is the parser's output and the big-step
; semantics in l0-spec.lisp.  The macros are the ones Milawa's kernel uses:
; LET, LET*, COND, AND, OR, LIST; LAMBDA applications are closed over their
; free variables because the evaluator's lambdas are not closures.  DEFUN is
; turned into a L0-DEFUN call whose body is parsed when the definition is
; evaluated; FUNCALL is a normal call to L0-FUNCALL, not the kernel-specific
; LOGIC.PROOFP specialization used by milawa-check.lisp.

(in-package "MILAWA-WASM")

(include-book "../milawa-lisp/values")

;; ---------------------------------------------------------------------------
;; Macro expansion helpers
;; ---------------------------------------------------------------------------

(defun l0-strip-vars (bindings)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count bindings)))
  (if (endp bindings)
      nil
    (cons (car (car bindings)) (l0-strip-vars (cdr bindings)))))

(defun l0-strip-inits (bindings)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count bindings)))
  (if (endp bindings)
      nil
    (cons (cadr (car bindings)) (l0-strip-inits (cdr bindings)))))

(mutual-recursion
 (defun l0-sfv-env (x bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       nil
     (let ((f (1- fuel)))
       (cond ((atom x)
              (if (and (symbolp x)
                       (not (eq x t))
                       (not (eq x nil))
                       (not (keywordp x))
                       (not (member-eq x bound)))
                  (list x)
                nil))
             ((eq (car x) 'quote) nil)
             ((eq (car x) 'let)
              (union-eq (l0-sfv-env-list (l0-strip-inits (cadr x)) bound f)
                        (l0-sfv-env-list (cddr x)
                                         (append (l0-strip-vars (cadr x)) bound)
                                         f)))
             ((eq (car x) 'let*)
              (l0-sfv-env-let* (cadr x) (cddr x) bound f))
             ((eq (car x) 'cond)
              (l0-sfv-env-cond (cdr x) bound f))
             ((eq (car x) 'lambda)
              (if (and (consp (cdr x)) (true-listp (cadr x)))
                  (l0-sfv-env-list (cddr x) (append (cadr x) bound) f)
                nil))
             (t (l0-sfv-env-list (cdr x) bound f))))))
 (defun l0-sfv-env-list (forms bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp forms))
       nil
     (union-eq (l0-sfv-env (car forms) bound (1- fuel))
               (l0-sfv-env-list (cdr forms) bound (1- fuel)))))
 (defun l0-sfv-env-let* (bindings body bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp bindings))
       (if (zp fuel) nil (l0-sfv-env-list body bound (1- fuel)))
     (union-eq (l0-sfv-env (cadr (car bindings)) bound (1- fuel))
               (l0-sfv-env-let* (cdr bindings) body
                                (cons (car (car bindings)) bound)
                                (1- fuel)))))
 (defun l0-sfv-env-cond (clauses bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp clauses))
       nil
     (union-eq (l0-sfv-env-list (car clauses) bound (1- fuel))
               (l0-sfv-env-cond (cdr clauses) bound (1- fuel))))))

;; ---------------------------------------------------------------------------
;; The core walk
;; ---------------------------------------------------------------------------

(defun l0-core-walk (mode x fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      x
    (let ((f (1- fuel)))
      (case mode
        (:tr
         (cond ((atom x)
                (cond ((or (eq x t) (eq x nil) (keywordp x)) x)
                      ((acl2-numberp x) (list 'quote x))
                      ((stringp x) (list 'quote x))
                      ((characterp x) (list 'quote x))
                      (t x)))
               ((eq (car x) 'quote) x)
               ((eq (car x) 'if)
                (list 'if
                      (l0-core-walk :tr (cadr x) f)
                      (l0-core-walk :tr (caddr x) f)
                      (l0-core-walk :tr (cadddr x) f)))
               ((eq (car x) 'let)
                (l0-core-walk :let (cons (cadr x) (cddr x)) f))
               ((eq (car x) 'let*)
                (l0-core-walk :let* (cons (cadr x) (cddr x)) f))
               ((eq (car x) 'cond)
                (l0-core-walk :cond (cdr x) f))
               ((eq (car x) 'and)
                (l0-core-walk :and (cdr x) f))
               ((eq (car x) 'or)
                (l0-core-walk :or (cdr x) f))
               ((eq (car x) 'list)
                (l0-core-walk :conslist (cdr x) f))
               ((and (consp (car x)) (eq (caar x) 'lambda))
                (let* ((formals (cadar x))
                       (body (cddar x))
                       (fvs (l0-sfv-env-list body formals f)))
                  (cons (list 'lambda
                              (append fvs formals)
                              (l0-core-walk :progn body f))
                        (append fvs (l0-core-walk :list (cdr x) f)))))
               (t (cons (car x) (l0-core-walk :list (cdr x) f)))))
        (:list
         (if (endp x)
             nil
           (cons (l0-core-walk :tr (car x) f)
                 (l0-core-walk :list (cdr x) f))))
        (:conslist
         (if (endp x)
             nil
           (list 'cons
                 (l0-core-walk :tr (car x) f)
                 (l0-core-walk :conslist (cdr x) f))))
        (:progn
         (cond ((endp x) nil)
               ((endp (cdr x)) (l0-core-walk :tr (car x) f))
               (t (list 'if t
                        (l0-core-walk :tr (car x) f)
                        (l0-core-walk :progn (cdr x) f)))))
        (:cond
         (if (endp x)
             nil
           (let ((clause (car x)))
             (list 'if
                   (l0-core-walk :tr (car clause) f)
                   (if (endp (cdr clause))
                       (l0-core-walk :tr (car clause) f)
                     (l0-core-walk :progn (cdr clause) f))
                   (l0-core-walk :cond (cdr x) f)))))
        (:and
         (cond ((endp x) t)
               ((endp (cdr x)) (l0-core-walk :tr (car x) f))
               (t (list 'if
                        (l0-core-walk :tr (car x) f)
                        (l0-core-walk :and (cdr x) f)
                        nil))))
        (:or
         (cond ((endp x) nil)
               ((endp (cdr x)) (l0-core-walk :tr (car x) f))
               (t (let ((a (l0-core-walk :tr (car x) f)))
                    (list 'if a a (l0-core-walk :or (cdr x) f))))))
        (:let
         (let* ((bindings (car x))
                (vars (l0-strip-vars bindings))
                (fvs (l0-sfv-env-list (cdr x) vars f)))
           (cons (list 'lambda
                       (append fvs vars)
                       (l0-core-walk :progn (cdr x) f))
                 (append fvs (l0-core-walk :list (l0-strip-inits bindings) f)))))
        (:let*
         (if (endp (car x))
             (l0-core-walk :progn (cdr x) f)
           (l0-core-walk :tr
                         (list 'let
                               (list (car (car x)))
                               (cons 'let* (cons (cdr (car x)) (cdr x))))
                         f)))
        (otherwise x)))))

;; ---------------------------------------------------------------------------
;; Preprocessing: DEFUN and FUNCALL
;; ---------------------------------------------------------------------------

(mutual-recursion
 (defun l0-preprocess (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (cond ((atom x) x)
         ((eq (car x) 'quote) x)
         ((eq (car x) 'defun)
          (list 'l0-defun
                (list 'quote (cadr x))
                (list 'quote (caddr x))
                (list 'quote (cadddr x))))
         ((eq (car x) 'funcall)
          (cons 'l0-funcall (l0-preprocess-list (cdr x))))
         (t (cons (l0-preprocess (car x))
                  (l0-preprocess-list (cdr x))))))
 (defun l0-preprocess-list (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (if (atom x)
       x
     (cons (l0-preprocess (car x)) (l0-preprocess-list (cdr x))))))

(defun l0-sexp2term (x)
  (declare (xargs :guard t :verify-guards nil))
  (l0-core-walk :tr (l0-preprocess x) (expt 2 24)))
