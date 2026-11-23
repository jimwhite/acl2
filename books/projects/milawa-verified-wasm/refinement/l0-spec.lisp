; L0, part 2: the relational Lisp specification.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This is the Jitawa-shaped big-step specification for the core Lisp.  It is
; relational in the sense that it returns a result/state pair, not a number of
; steps: a term either returns a value with a new function table and output
; stream, or aborts.  The fuel parameter only bounds recursion (Jitawa's
; `terminates` premise); it is not part of the correctness statement.
;
; Core syntax, as in milawa-lisp/eval.lisp:
;
;   variable, (quote v), (if a b c), (f a1 ... an),
;   ((lambda (v1 ... vn) body) a1 ... an)
;
; The parser in l0-parse.lisp expands the surface macros and closes LET over
; its free variables; this book only evaluates core terms.

(in-package "MILAWA-WASM")

(include-book "l0-read")
(include-book "std/strings/decimal" :dir :system)

;; ---------------------------------------------------------------------------
;; Terms
;; ---------------------------------------------------------------------------

(defun l0-variable-p (x)
  (declare (xargs :guard t))
  (and (symbolp x)
       (not (member-eq x '(quote if t nil)))
       (not (keywordp x))))

(mutual-recursion
 (defun l0-term-p (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (cond ((l0-variable-p x) t)
         ((atom x) nil)
         ((eq (car x) 'quote)
          (and (consp (cdr x))
               (null (cddr x))
               (milawa-valuep (cadr x))))
         ((eq (car x) 'if)
          (and (consp (cdr x))
               (consp (cddr x))
               (consp (cdddr x))
               (null (cddddr x))
               (l0-term-p (cadr x))
               (l0-term-p (caddr x))
               (l0-term-p (cadddr x))))
         ((and (consp (car x)) (eq (caar x) 'lambda))
          (and (consp (cdar x))
               (true-listp (cadar x))
               (symbol-listp (cadar x))
               (consp (cddar x))
               (null (cdddar x))
               (l0-term-p (caddar x))
               (l0-term-list-p (cdr x))))
         ((symbolp (car x))
          (l0-term-list-p (cdr x)))
         (t nil)))
 (defun l0-term-list-p (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (if (consp x)
       (and (l0-term-p (car x))
            (l0-term-list-p (cdr x)))
     (equal x nil))))

;; ---------------------------------------------------------------------------
;; Results
;; ---------------------------------------------------------------------------

(defun l0-ok (value ftbl io)
  (declare (xargs :guard t))
  (list :ok value ftbl io))

(defun l0-abort (reason ftbl io)
  (declare (xargs :guard t))
  (list :abort reason ftbl io))

(defun l0-okp (r) (declare (xargs :guard t)) (and (consp r) (eq (car r) :ok)))
(defun l0-abortp (r) (declare (xargs :guard t)) (and (consp r) (eq (car r) :abort)))
(defun l0-resultp (r) (declare (xargs :guard t)) (or (l0-okp r) (l0-abortp r)))
(defun l0-value (r) (declare (xargs :guard t :verify-guards nil)) (if (consp r) (cadr r) nil))
(defun l0-ftbl (r) (declare (xargs :guard t :verify-guards nil)) (if (and (consp r) (consp (cddr r))) (caddr r) nil))
(defun l0-io (r) (declare (xargs :guard t :verify-guards nil)) (if (and (consp r) (consp (cddr r)) (consp (cdddr r))) (cadddr r) nil))

(defthm l0-okp-of-l0-ok
  (l0-okp (l0-ok v ftbl io))
  :hints (("Goal" :in-theory (enable l0-okp l0-ok))))

(defthm l0-resultp-of-l0-ok
  (l0-resultp (l0-ok v ftbl io))
  :hints (("Goal" :in-theory (enable l0-resultp l0-okp l0-ok))))

;; ---------------------------------------------------------------------------
;; Builtins and application
;; ---------------------------------------------------------------------------

(defun l0-from-milawa (r ftbl io)
  (declare (xargs :guard t))
  (if (milawa-okp r)
      (l0-ok (milawa-result-value r) ftbl io)
    (l0-abort (milawa-abort-reason r) ftbl io)))

(defun l0-bind (formals args)
  (declare (xargs :guard t :verify-guards nil))
  (pairlis$ formals args))

(mutual-recursion
 (defun l0-ev (term env ftbl io fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (l0-abort :fuel ftbl io)
     (let ((f (1- (nfix fuel))))
       (cond
        ((l0-variable-p term)
         (let ((pair (assoc-eq term env)))
           (if pair
               (l0-ok (cdr pair) ftbl io)
             (l0-abort :unbound-variable ftbl io))))
        ((keywordp term) (l0-ok term ftbl io))
        ((eq term t) (l0-ok t ftbl io))
        ((eq term nil) (l0-ok nil ftbl io))
        ((atom term) (l0-abort :unquoted-constant ftbl io))
        ((eq (car term) 'quote)
         (if (and (consp (cdr term)) (null (cddr term)))
             (l0-ok (cadr term) ftbl io)
           (l0-abort :ill-formed-quote ftbl io)))
        ((eq (car term) 'if)
         (if (and (consp (cdr term))
                  (consp (cddr term))
                  (consp (cdddr term))
                  (null (cddddr term)))
             (let ((r (l0-ev (cadr term) env ftbl io f)))
               (if (l0-abortp r)
                   r
                 (l0-ev (if (l0-value r) (caddr term) (cadddr term))
                        env (l0-ftbl r) (l0-io r) f)))
           (l0-abort :ill-formed-if ftbl io)))
        (t
         (let ((r (l0-evl (cdr term) env ftbl io f)))
           (if (l0-abortp r)
               r
             (l0-ap (car term) (l0-value r)
                    (l0-ftbl r) (l0-io r) f))))))))

 (defun l0-evl (terms env ftbl io fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (l0-abort :fuel ftbl io)
     (if (endp terms)
         (l0-ok nil ftbl io)
       (let ((r (l0-ev (car terms) env ftbl io (1- (nfix fuel)))))
         (if (l0-abortp r)
             r
           (let ((r2 (l0-evl (cdr terms) env (l0-ftbl r) (l0-io r) (1- (nfix fuel)))))
             (if (l0-abortp r2)
                 r2
               (l0-ok (cons (l0-value r) (l0-value r2))
                      (l0-ftbl r2) (l0-io r2)))))))))

 (defun l0-ap (fn args ftbl io fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (l0-abort :fuel ftbl io)
     (let ((f (1- (nfix fuel))))
       (cond
        ((eq fn 'define)
         (if (and (consp args) (consp (cdr args)) (consp (cddr args)))
             (let ((name (car args))
                   (formals (cadr args))
                   (body (caddr args)))
               (if (and (symbolp name)
                        (symbol-listp formals)
                        (not (assoc-eq name ftbl)))
                   (let ((core (l0-sexp2term body)))
                     (if (l0-term-p core)
                         (l0-ok nil (cons (list name formals core) ftbl) io)
                       (l0-abort :ill-formed-definition ftbl io)))
                 (l0-abort :ill-formed-definition ftbl io)))
           (l0-abort :arity ftbl io)))
        ((eq fn 'l0-defun)
         (if (and (consp args) (consp (cdr args)) (consp (cddr args)))
             (let ((name (car args))
                   (formals (cadr args))
                   (body (caddr args)))
               (if (and (symbolp name)
                        (symbol-listp formals)
                        (not (assoc-eq name ftbl)))
                   (let ((core (l0-sexp2term body)))
                     (if (l0-term-p core)
                         (l0-ok nil (cons (list name formals core) ftbl) io)
                       (l0-abort :ill-formed-definition ftbl io)))
                 (l0-abort :ill-formed-definition ftbl io)))
           (l0-abort :arity ftbl io)))
        ((eq fn 'print)
         (l0-ok nil ftbl (append io args)))
        ((eq fn 'error)
         (l0-abort :error ftbl (append io args)))
        ((eq fn 'l0-funcall)
         (if (and (consp args) (car args))
             (l0-apply-defined (car args) (cdr args) ftbl io f)
           (l0-abort :undefined-function ftbl io)))
        ((eq fn 'first) (l0-ok (milawa-car (car args)) ftbl io))
        ((eq fn 'second) (l0-ok (milawa-car (milawa-cdr (car args))) ftbl io))
        ((eq fn 'third) (l0-ok (milawa-car (milawa-cdr (milawa-cdr (car args)))) ftbl io))
        ((eq fn 'fourth) (l0-ok (milawa-car (milawa-cdr (milawa-cdr (milawa-cdr (car args))))) ftbl io))
        ((eq fn 'fifth) (l0-ok (milawa-car (milawa-cdr (milawa-cdr (milawa-cdr (milawa-cdr (car args)))))) ftbl io))
        ((eq fn 'endp) (l0-ok (if (consp (car args)) nil t) ftbl io))
        ((eq fn 'null) (l0-ok (equal (car args) nil) ftbl io))
        ((milawa-primitivep fn)
         (if (equal (len args) (milawa-primitive-arity fn))
             (l0-from-milawa (milawa-apply-primitive fn args) ftbl io)
           (l0-abort :arity ftbl io)))
        ((and (consp fn) (eq (car fn) 'lambda))
         (if (and (consp (cdr fn))
                  (true-listp (cadr fn))
                  (symbol-listp (cadr fn))
                  (consp (cddr fn))
                  (null (cdddr fn))
                  (l0-term-p (caddr fn))
                  (equal (len (cadr fn)) (len args))
                  (milawa-value-listp args))
             (l0-ev (caddr fn) (l0-bind (cadr fn) args) ftbl io f)
           (l0-abort :ill-formed-lambda ftbl io)))
        (t (l0-apply-defined fn args ftbl io f))))))

 (defun l0-apply-defined (name args ftbl io fuel)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (l0-abort :fuel ftbl io)
     (let ((def (assoc-eq name ftbl)))
       (cond ((not def)
              (l0-abort :undefined-function ftbl io))
             ((not (and (consp def)
                        (symbol-listp (cadr def))
                        (consp (cddr def))
                        (l0-term-p (caddr def))))
              (l0-abort :ill-formed-definition ftbl io))
             ((not (equal (len (cadr def)) (len args)))
              (l0-abort :arity ftbl io))
             ((not (milawa-value-listp args))
              (l0-abort :non-value-argument ftbl io))
             (t
              (l0-ev (caddr def)
                     (l0-bind (cadr def) args)
                     ftbl io (1- (nfix fuel)))))))))

;; ---------------------------------------------------------------------------
;; The read-eval-print loop specification
;; ---------------------------------------------------------------------------

(defconst *l0-initial-ftbl*
  '((first (x) (car x))
    (second (x) (car (cdr x)))
    (third (x) (car (cdr (cdr x))))
    (fourth (x) (car (cdr (cdr (cdr x)))))
    (fifth (x) (car (cdr (cdr (cdr (cdr x))))))
    (endp (x) (if (consp x) nil t))
    (null (x) (equal x nil))))

(defun l0-exec (cmds ftbl io fuel)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      (l0-abort :fuel ftbl io)
    (if (endp cmds)
        (l0-ok nil ftbl io)
      (let ((r (l0-ev (car cmds) nil ftbl io (1- (nfix fuel)))))
        (if (l0-abortp r)
            r
          (l0-exec (cdr cmds)
                   (l0-ftbl r)
                   (append (l0-io r) (list (l0-value r)))
                   (1- (nfix fuel))))))))

(defun l0-run (cmds fuel)
  (declare (xargs :guard t :verify-guards nil))
  (l0-exec cmds *l0-initial-ftbl* nil fuel))

(defun l0-parse-commands (sexps)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count sexps)))
  (if (endp sexps)
      nil
    (cons (l0-sexp2term (car sexps))
          (l0-parse-commands (cdr sexps)))))

(defun l0-run-source (sexps fuel)
  (declare (xargs :guard t :verify-guards nil))
  (l0-run (l0-parse-commands sexps) fuel))

(defun l0-run-chars (chars fuel)
  (declare (xargs :guard t :verify-guards nil))
  (let ((sexps (l0-read-all chars)))
    (if (equal sexps '(:parse-error))
        (l0-abort :parse-error nil nil)
      (l0-run-source sexps fuel))))

;; ---------------------------------------------------------------------------
;; Printer (the output side of the read-eval-print loop)
;; ---------------------------------------------------------------------------

(defun l0-print-atom-chars (x)
  (declare (xargs :guard t :verify-guards nil))
  (cond ((symbolp x) (coerce (symbol-name x) 'list))
        ((natp x) (str::nat-to-dec-chars x))
        (t (coerce "#<value>" 'list))))

(mutual-recursion
 (defun l0-print-chars (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (if (consp x)
       (append (list #\() (l0-print-chars (car x))
               (l0-print-tail (cdr x)) (list #\)))
     (l0-print-atom-chars x)))
 (defun l0-print-tail (x)
   (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
   (cond ((consp x)
          (append (list #\space) (l0-print-chars (car x))
                  (l0-print-tail (cdr x))))
         ((null x) nil)
         (t (append (list #\space #\. #\space)
                    (l0-print-atom-chars x))))))

(defun l0-print-value (x)
  (declare (xargs :guard t :verify-guards nil))
  (coerce (l0-print-chars x) 'string))

(defun l0-print-values (vals)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count vals)))
  (if (consp vals)
      (cons (l0-print-value (car vals)) (l0-print-values (cdr vals)))
    nil))

;; ---------------------------------------------------------------------------
;; Small checks and entry points
;; ---------------------------------------------------------------------------

(defthm l0-ev-quote
  (equal (l0-ev (l0-sexp2term '5) nil *l0-initial-ftbl* nil 100)
         (l0-ok 5 *l0-initial-ftbl* nil))
  :hints (("Goal" :in-theory (enable l0-sexp2term l0-preprocess
                                     l0-core-walk l0-ev l0-ok))))

(defthm l0-ev-add
  (equal (l0-ev (l0-sexp2term '(+ 1 2)) nil *l0-initial-ftbl* nil 100)
         (l0-ok 3 *l0-initial-ftbl* nil))
  :hints (("Goal" :in-theory (enable l0-sexp2term l0-preprocess
                                     l0-core-walk l0-ev l0-evl l0-ap
                                     l0-ok l0-from-milawa))))

(defthm l0-term-p-add
  (l0-term-p (l0-sexp2term '(+ 1 2)))
  :hints (("Goal" :in-theory (enable l0-sexp2term l0-preprocess
                                     l0-core-walk l0-term-p l0-term-list-p))))

(defthm l0-term-p-let
  (l0-term-p (l0-sexp2term '(let ((x 1)) (+ x 2))))
  :hints (("Goal" :in-theory (enable l0-sexp2term l0-preprocess
                                     l0-core-walk l0-sfv-env-list
                                     l0-sfv-env l0-term-p l0-term-list-p))))

(defthm l0-exec-defun
  (equal (l0-run
          (list (l0-sexp2term '(defun inc (n) (+ n 1)))
                (l0-sexp2term '(funcall 'inc 5)))
          1000)
         (l0-ok nil
                (cons (list 'inc '(n) '(+ n (quote 1)))
                      *l0-initial-ftbl*)
                '(nil 6)))
  :hints (("Goal" :in-theory (enable l0-run l0-exec l0-ev l0-evl l0-ap
                                     l0-sexp2term l0-preprocess l0-core-walk
                                     l0-apply-defined l0-bind l0-ok))))

(assert-event (equal (l0-print-value 5) "5"))
(assert-event (equal (l0-print-value '(1 2 3)) "(1 2 3)"))
(assert-event
 (equal (l0-run-source '((defun inc (n) (+ n 1))
                         (funcall 'inc 5))
                       1000)
        (l0-ok nil
               (cons (list 'inc '(n) '(+ n (quote 1)))
                     *l0-initial-ftbl*)
               '(nil 6))))

; Reader and printer agree on printed values.
(assert-event (equal (l0-read-all (coerce "(+ 1 2)" 'list))
                     '((+ 1 2))))
(value-triple
 (list :read (l0-read-all
              (coerce "(defun inc (n) (+ n 1)) (funcall 'inc 5)" 'list))
       :run (l0-run-chars
             (coerce "(defun inc (n) (+ n 1)) (funcall 'inc 5)" 'list)
             10000)))

(assert-event
 (equal (l0-run-chars
         (coerce "(defun inc (n) (+ n 1)) (funcall 'inc 5)" 'list)
         10000)
        (l0-ok nil
               (cons (list 'inc '(n) '(+ n (quote 1)))
                     *l0-initial-ftbl*)
               '(nil 6))))
(assert-event
 (equal (l0-read-all (coerce "#1=(a b) #1#" 'list))
        '((a b) (a b))))
(assert-event
 (mv-let (x rest labels)
   (l0-read-sexp (l0-print-chars '(1 2 3)) 100 nil)
   (declare (ignore labels))
   (and (equal x '(1 2 3)) (null rest))))
(assert-event
 (mv-let (x rest labels)
   (l0-read-sexp (l0-print-chars '(1 . 2)) 100 nil)
   (declare (ignore labels))
   (and (equal x '(1 . 2)) (null rest))))

(value-triple
 (list :add-code (l0-sexp2term '(+ 1 2))
       :let-code (l0-sexp2term '(let ((x 1)) (+ x 2)))
       :defun-code (l0-sexp2term '(defun inc (n) (+ n 1)))
       :printed (l0-print-values '(nil 6 (1 2 3)))
       :run (l0-run-source '((defun inc (n) (+ n 1))
                             (funcall 'inc 5))
                           1000)))
