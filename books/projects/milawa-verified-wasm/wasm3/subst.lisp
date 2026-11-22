; Safe term substitution for the return chains.
;
; The return lifts (dret-*, p2ret-*, p2hload-*) were produced by exact-text
; substitution in a scratch script, and AGENTS.md records the failure mode: the
; substitution must match ACL2's printer exactly, and "a missed quote makes the
; replace a silent no-op."  This book does the substitution on the theorem's
; term, checks that every pattern actually occurs, and emits the new theorem.
;
;     (defsubst-chain new
;       :from base-theorem
;       :subst ((<old-term> <new-term>) ...)
;       :count 1                  ; optional; default: at least one occurrence
;       :hints (("Goal" :use base-theorem ...)))
;
; The statement of BASE-THEOREM is read from the world, so the substitution is
; over the term ACL2 actually stored, not over a printed copy of it.  A pattern
; with no occurrence is an error naming the pattern and the count, which is the
; check the text substitution could not make.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(defun subst-term (old new term)
  (declare (xargs :mode :program))
  (cond ((equal term old) new)
        ((atom term) term)
        (t (cons (subst-term old new (car term))
                 (subst-term old new (cdr term))))))

(defun subst-term-lst (pairs term)
  (declare (xargs :mode :program))
  (if (endp pairs)
      term
    (subst-term-lst (cdr pairs)
                    (subst-term (caar pairs) (cadar pairs) term))))

(defun count-term (old term)
  (declare (xargs :mode :program))
  (cond ((equal term old) 1)
        ((atom term) 0)
        (t (+ (count-term old (car term))
              (count-term old (cdr term))))))

(defun bad-pair (pairs stmt expected)
  (declare (xargs :mode :program))
  (cond ((endp pairs) nil)
        (t (let ((n (count-term (caar pairs) stmt)))
             (if (if expected (not (eql n expected)) (eql n 0))
                 (list (caar pairs) n)
               (bad-pair (cdr pairs) stmt expected))))))

(defun defsubst-chain-fn (new from pairs expected hints state)
  (declare (xargs :mode :program :stobjs state))
  (let* ((stmt (getpropc from 'acl2::theorem nil (w state)))
         (bad (and stmt (bad-pair pairs stmt expected))))
    (cond ((null stmt)
           (er soft 'defsubst-chain "~x0 has no theorem" from))
          (bad
           (er soft 'defsubst-chain
               "the pair ~x0 occurs ~x1 time(s); expected ~x2"
               (car bad) (cadr bad)
               (if expected expected :at-least-one)))
          (t
           (value `(defthm ,new
                     ,(subst-term-lst pairs stmt)
                     ,@(if hints `(:hints ,hints) nil)))))))

(defmacro defsubst-chain (new &key from subst (count 'nil) hints)
  `(make-event
    (defsubst-chain-fn ',new ',from ',subst ',count ',hints state)))

;; ---------------------------------------------------------------------------
;; A worked, executable check.  The base theorem is :rule-classes nil so the
;; book does not export an arithmetic rewrite rule.

(defthm subst-demo-base
  (implies (and (natp x) (< x 10))
           (equal (+ x 0) x))
  :rule-classes nil)

;; The symbol X occurs four times in the stored statement: (natp x), (< x 10),
;; (+ x 0), and the right-hand x.  A count of 4 checks every occurrence; the
;; default (:at-least-one) would also pass.
(defsubst-chain subst-demo-new
  :from subst-demo-base
  :subst ((x (+ y 1)))
  :count 4
  :hints (("Goal" :use (:instance subst-demo-base (x (+ y 1))))))
