; Running the Milawa kernel on the verified Milawa-Lisp evaluator: the
; untrusted front end from milawa2.lsp's surface Lisp to core syntax.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; milawa2.lsp is the simplified Milawa kernel.  Its QUOTEed function bodies
; use the usual Lisp macros (COND, AND, OR, LET, LET*, LIST) on top of the
; twelve primitives; the verified evaluator (milawa-lisp/eval.lisp) accepts
; only CORE syntax.  CORE-WALK expands those macros.  It is untrusted, as in
; Jitawa: the run at the end of MILAWA-CHECK is the check.
;
; The data comes from:
;   *milawa2-source-forms*  the DEFINE forms of milawa2.lsp (data book)
;   *milawa-100-events*     /home/vscode/milawa-on-jitawa/100.events
;
; The only CL-specific form in the kernel is (CL-USER::FUNCALL CHECKER
; PROOF AXIOMS THMS ATBL) in CORE.CHECK-PROOF.  The build step renames it
; FUNCALL; the front end specializes it to the initial checker LOGIC.PROOFP,
; which is exactly what MILAWA-MAIN installs.

(in-package "MILAWA-WASM")

(include-book "milawa2-data")
(include-book "milawa-events")
(include-book "../milawa-lisp/eval")

;; ---------------------------------------------------------------------------
;; Extracting the DEFINE forms and the MILAWA-INIT payload
;; ---------------------------------------------------------------------------

(defun strip-quote (x)
  (declare (xargs :guard t :verify-guards nil))
  (if (and (consp x)
           (eq (car x) 'quote)
           (consp (cdr x))
           (null (cddr x)))
      (cadr x)
    x))

(defun find-define (name forms)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count forms)))
  (cond ((endp forms) nil)
        ((and (consp (car forms))
              (eq (car (car forms)) 'define)
              (consp (cdr (car forms)))
              (equal (strip-quote (cadr (car forms))) name))
         (car forms))
        (t (find-define name (cdr forms)))))

(defun define-name (form)
  (declare (xargs :guard t :verify-guards nil))
  (strip-quote (cadr form)))

(defun define-formals (form)
  (declare (xargs :guard t :verify-guards nil))
  (strip-quote (caddr form)))

(defun define-body (form)
  (declare (xargs :guard t :verify-guards nil))
  (strip-quote (cadddr form)))

(defun init-payload ()
  (declare (xargs :guard t :verify-guards nil))
  (define-body (find-define 'milawa-init *milawa2-source-forms*)))

(defun init-ill-formed ()
  (declare (xargs :guard t :verify-guards nil))
  (strip-quote (cadr (init-payload))))

(defun init-kernel ()
  (declare (xargs :guard t :verify-guards nil))
  (strip-quote (caddr (init-payload))))

(defun system-define (name)
  (declare (xargs :guard t :verify-guards nil))
  (find-define name *milawa2-source-forms*))

(defun system-triple (name)
  (declare (xargs :guard t :verify-guards nil))
  (let ((form (system-define name)))
    (and form
         (list (define-name form)
               (define-formals form)
               (define-body form)))))

;; ---------------------------------------------------------------------------
;; The macro-expanding front end
;; ---------------------------------------------------------------------------

(defun strip-vars (bindings)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count bindings)))
  (if (endp bindings)
      nil
    (cons (car (car bindings)) (strip-vars (cdr bindings)))))

(defun strip-inits (bindings)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count bindings)))
  (if (endp bindings)
      nil
    (cons (cadr (car bindings)) (strip-inits (cdr bindings)))))

; Surface free variables.  The evaluator's lambdas are not closures: a
; lambda body is evaluated with its formals as the whole environment.  LET
; therefore becomes a lambda whose formals include the body's free variables,
; and whose actuals pass those variables along -- the same closure conversion
; the kernel's LOGIC.TRANSLATE-LET-TERM does for event terms.

(mutual-recursion
 (defun sfv-env (x bound fuel)
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
              (union-eq (sfv-env-list (strip-inits (cadr x)) bound f)
                        (sfv-env-list (cddr x)
                                      (append (strip-vars (cadr x)) bound)
                                      f)))
             ((eq (car x) 'let*)
              (sfv-env-let* (cadr x) (cddr x) bound f))
             ((eq (car x) 'cond)
              (sfv-env-cond (cdr x) bound f))
             ((eq (car x) 'lambda)
              (if (and (consp (cdr x)) (true-listp (cadr x)))
                  (sfv-env-list (cddr x) (append (cadr x) bound) f)
                nil))
             (t (sfv-env-list (cdr x) bound f))))))
 (defun sfv-env-list (forms bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp forms))
       nil
     (union-eq (sfv-env (car forms) bound (1- fuel))
               (sfv-env-list (cdr forms) bound (1- fuel)))))
 (defun sfv-env-let* (bindings body bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp bindings))
       (if (zp fuel) nil (sfv-env-list body bound (1- fuel)))
     (union-eq (sfv-env (cadr (car bindings)) bound (1- fuel))
               (sfv-env-let* (cdr bindings) body
                             (cons (car (car bindings)) bound)
                             (1- fuel)))))
 ; COND clauses are lists of terms, not calls: every element is scanned.
 (defun sfv-env-cond (clauses bound fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp clauses))
       nil
     (union-eq (sfv-env-list (car clauses) bound (1- fuel))
               (sfv-env-cond (cdr clauses) bound (1- fuel))))))

(defun core-walk (mode x fuel)
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
                      (core-walk :tr (cadr x) f)
                      (core-walk :tr (caddr x) f)
                      (core-walk :tr (cadddr x) f)))
               ((eq (car x) 'let) (core-walk :let (cons (cadr x) (cddr x)) f))
               ((eq (car x) 'let*) (core-walk :let* (cons (cadr x) (cddr x)) f))
               ((eq (car x) 'cond) (core-walk :cond (cdr x) f))
               ((eq (car x) 'and) (core-walk :and (cdr x) f))
               ((eq (car x) 'or) (core-walk :or (cdr x) f))
               ((eq (car x) 'list) (core-walk :conslist (cdr x) f))
               ((eq (car x) 'funcall)
                (list '|LOGIC.PROOFP|
                      (core-walk :tr (caddr x) f)
                      (core-walk :tr (cadddr x) f)
                      (core-walk :tr (car (cddddr x)) f)
                      (core-walk :tr (cadr (cddddr x)) f)))
               ((and (consp (car x)) (eq (caar x) 'lambda))
                (let* ((formals (cadar x))
                       (body (cddar x))
                       (fvs (sfv-env-list body formals f)))
                  (cons (list 'lambda
                              (append fvs formals)
                              (core-walk :progn body f))
                        (append fvs (core-walk :list (cdr x) f)))))
               (t (cons (car x) (core-walk :list (cdr x) f)))))
        (:list
         (if (endp x)
             nil
           (cons (core-walk :tr (car x) f)
                 (core-walk :list (cdr x) f))))
        (:conslist
         (if (endp x)
             nil
           (list 'cons
                 (core-walk :tr (car x) f)
                 (core-walk :conslist (cdr x) f))))
        (:progn
         (cond ((endp x) nil)
               ((endp (cdr x)) (core-walk :tr (car x) f))
               (t (list 'if t
                        (core-walk :tr (car x) f)
                        (core-walk :progn (cdr x) f)))))
        (:cond
         (if (endp x)
             nil
           (let ((clause (car x)))
             (list 'if
                   (core-walk :tr (car clause) f)
                   (if (endp (cdr clause))
                       (core-walk :tr (car clause) f)
                     (core-walk :progn (cdr clause) f))
                   (core-walk :cond (cdr x) f)))))
        (:and
         (cond ((endp x) t)
               ((endp (cdr x)) (core-walk :tr (car x) f))
               (t (list 'if
                        (core-walk :tr (car x) f)
                        (core-walk :and (cdr x) f)
                        nil))))
        (:or
         (cond ((endp x) nil)
               ((endp (cdr x)) (core-walk :tr (car x) f))
               (t (let ((a (core-walk :tr (car x) f)))
                    (list 'if a a (core-walk :or (cdr x) f))))))
        (:let
         (let* ((bindings (car x))
                (vars (strip-vars bindings))
                (fvs (sfv-env-list (cdr x) vars f)))
           (cons (list 'lambda
                       (append fvs vars)
                       (core-walk :progn (cdr x) f))
                 (append fvs (core-walk :list (strip-inits bindings) f)))))
        (:let*
         (if (endp (car x))
             (core-walk :progn (cdr x) f)
           (core-walk :tr
                      (list 'let
                            (list (car (car x)))
                            (cons 'let* (cons (cdr (car x)) (cdr x))))
                      f)))
        (otherwise x)))))

;; ---------------------------------------------------------------------------
;; Translated definitions, validation, and the core function table
;; ---------------------------------------------------------------------------

(defun translate-triples (triples fuel)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count triples)))
  (if (endp triples)
      nil
    (cons (list (caar triples)
                (cadar triples)
                (core-walk :tr (caddar triples) fuel))
          (translate-triples (cdr triples) fuel))))

; System functions the kernel calls through the function table.  DEFINE is
; the runtime's function-definition hook; in the interpreted model the table
; entry is what matters, so its return value is irrelevant (NIL).  ERROR is
; only reached on a malformed event; PRINT's value is irrelevant (the
; checker ignores it), so both return NIL -- output is not modelled.
(defun system-core-triples (fuel)
  (declare (xargs :guard t :verify-guards nil))
  (list (list 'define '(name formals body) nil)
        (list 'error '(description) nil)
        (list 'print '(obj) nil)
        ; Extralogical Lisp system functions (the Jitawa runtime provides
        ; these; they are not in the kernel's function table).
        (list 'first '(x) (list 'car 'x))
        (list 'second '(x) (list 'car (list 'cdr 'x)))
        (list 'third '(x) (list 'car (list 'cdr (list 'cdr 'x))))
        (list 'fourth '(x) (list 'car (list 'cdr (list 'cdr (list 'cdr 'x)))))
        (list 'fifth '(x) (list 'car (list 'cdr (list 'cdr (list 'cdr (list 'cdr 'x))))))
        (list 'endp '(x) (list 'if (list 'consp 'x) nil t))
        (list 'null '(x) (list 'equal 'x nil))
        (let ((trip (system-triple 'lookup)))
          (and trip (list (car trip) (cadr trip) (core-walk :tr (caddr trip) fuel))))
        (let ((trip (system-triple 'define-safe)))
          (and trip (list (car trip) (cadr trip) (core-walk :tr (caddr trip) fuel))))
        (let ((trip (system-triple 'define-safe-list)))
          (and trip (list (car trip) (cadr trip) (core-walk :tr (caddr trip) fuel))))))

(defun names-of (triples)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count triples)))
  (if (endp triples)
      nil
    (cons (car (car triples)) (names-of (cdr triples)))))

(defun remove-named (names triples)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count triples)))
  (if (endp triples)
      nil
    (if (member-equal (caar triples) names)
        (remove-named names (cdr triples))
      (cons (car triples) (remove-named names (cdr triples))))))

(defun core-ftbl (fuel)
  (declare (xargs :guard t :verify-guards nil))
  (let* ((sys (remove nil (system-core-triples fuel)))
         (kern (translate-triples (init-kernel) fuel))
         (initial (remove-named (append (names-of sys) (names-of kern))
                                (init-ill-formed))))
    (append sys kern initial)))

;; The core function table, built once at certification.

(defconst *core-ftbl*
  (core-ftbl (expt 2 24)))

;; Validation: after translation no surface macro or FUNCALL may remain in
;; head position, and every head must be a primitive, a core special form, or
;; a defined function.

(mutual-recursion
 (defun bad-heads (x defined fuel)
   (declare (xargs :measure (nfix fuel)))
   (if (zp fuel)
       nil
     (let ((f (1- fuel)))
       (cond ((atom x) nil)
             ((eq (car x) 'quote) nil)
             ((and (consp (car x)) (eq (caar x) 'lambda))
              (append (bad-heads (caddr (car x)) defined f)
                      (bad-heads-in-list (cdr x) defined f)))
             ((symbolp (car x))
              (append
               (if (or (member-eq (car x) '(let let* cond and or list funcall))
                       (and (not (eq (car x) 'if))
                            (not (eq (car x) 'quote))
                            (not (milawa-primitivep (car x)))
                            (not (member-equal (car x) defined))
                            (not (member-eq (car x) '(lookup define-safe
                                                            define-safe-list
                                                            define error print)))))
                   (list (car x))
                 nil)
               (bad-heads-in-list (cdr x) defined f)))
             (t (list (car x)))))))
 (defun bad-heads-in-list (x defined fuel)
   (declare (xargs :measure (nfix fuel)))
   (if (or (zp fuel) (endp x))
       nil
     (append (bad-heads (car x) defined (1- fuel))
             (bad-heads-in-list (cdr x) defined (1- fuel))))))

(defun bad-heads-in-triples (triples defined fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (or (zp fuel) (endp triples))
      nil
    (append (bad-heads (caddar triples) defined (1- fuel))
            (bad-heads-in-triples (cdr triples) defined (1- fuel)))))

(value-triple
 (list :kernel-defs (len (init-kernel))
       :ill-formed (len (init-ill-formed))
       :ftbl-entries (len *core-ftbl*)
       :bad-heads (bad-heads-in-triples *core-ftbl*
                                        (names-of *core-ftbl*)
                                        (expt 2 24))))
