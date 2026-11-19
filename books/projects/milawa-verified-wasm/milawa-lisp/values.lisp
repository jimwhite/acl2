; Milawa-Lisp, part 1: the value domain and the primitive operations.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.

; Milawa-Lisp is the language of the simplified Milawa kernel, milawa2.lsp in
; books/projects/milawa.  It is a first-order Lisp with twelve primitives.
; The definitions below are transcriptions of MILAWA::natp, MILAWA::symbol-<,
; MILAWA::<, MILAWA::+, MILAWA::-, MILAWA::car and MILAWA::cdr from that file,
; and they preserve the two details that matter for verification:
;
;   * Integers are BOUNDED.  (MILAWA::+ x y) signals an error when the sum
;     reaches 2^30, and the kernel then quits.  There is no bignum arithmetic
;     anywhere in the target; we model the error as an :OVERFLOW abort.
;
;   * SYMBOL-< compares symbol-name with STRING<, after replacing a non-symbol
;     by NIL.  Only symbol names are ever observed.
;
; Every function here is total.  Primitives that can fail return a tagged
; result (see MILAWA-OK / MILAWA-ABORT) rather than a bare value.

(in-package "ACL2")

(defconst *milawa-integer-bound*
  (expt 2 30))

;; ---------------------------------------------------------------------------
;; The value domain
;;
;; Milawa-Lisp values are symbols, conses, and integers from 0 up to 2^30.
;; ---------------------------------------------------------------------------

(defun milawa-fixnump (x)
  (declare (xargs :guard t))
  (and (integerp x)
       (<= 0 x)
       (< x (expt 2 30))))

(defthm milawa-fixnump-bounds
  (implies (milawa-fixnump x)
           (and (integerp x)
                (<= 0 x)
                (< x (expt 2 30))))
  :rule-classes ((:forward-chaining :trigger-terms ((milawa-fixnump x))))
  :hints (("Goal" :in-theory (enable milawa-fixnump))))

(defthm milawa-fixnump-of-nil
  (not (milawa-fixnump nil))
  :hints (("Goal" :in-theory (enable milawa-fixnump))))

(defthm milawa-fixnump-of-cons
  (not (milawa-fixnump (cons a b)))
  :hints (("Goal" :in-theory (enable milawa-fixnump))))

(defun milawa-valuep (x)
  (if (consp x)
      (and (milawa-valuep (car x))
           (milawa-valuep (cdr x)))
    (or (symbolp x)
        (milawa-fixnump x))))

(defthm milawa-valuep-of-nil
  (milawa-valuep nil))

(defthm milawa-valuep-of-t
  (milawa-valuep t))

(defthm milawa-valuep-of-car
  (implies (milawa-valuep x)
           (milawa-valuep (car x))))

(defthm milawa-valuep-of-cdr
  (implies (milawa-valuep x)
           (milawa-valuep (cdr x))))

(defthm milawa-valuep-of-cons
  (equal (milawa-valuep (cons a b))
         (and (milawa-valuep a)
              (milawa-valuep b))))

(defun milawa-value-listp (x)
  (if (consp x)
      (and (milawa-valuep (car x))
           (milawa-value-listp (cdr x)))
    (equal x nil)))

(defthm milawa-value-listp-of-nil
  (milawa-value-listp nil))

(defthm milawa-value-listp-of-cons
  (equal (milawa-value-listp (cons a b))
         (and (milawa-valuep a)
              (milawa-value-listp b))))

;; ---------------------------------------------------------------------------
;; Tagged results
;;
;; (:MILAWA-OK . value)  or  (:MILAWA-ABORT . reason).
;;
;; A result is never confused with a value by these books: OKP and ABORTP are
;; only ever applied to results.  An abort is the modelled form of every place
;; where the Common Lisp kernel would signal, quit, or run out of stack.
;; ---------------------------------------------------------------------------

(defun milawa-ok (value)
  (declare (xargs :guard t))
  (cons :milawa-ok value))

(defun milawa-abort (reason)
  (declare (xargs :guard t))
  (list :milawa-abort reason))

(defun milawa-okp (r)
  (declare (xargs :guard t))
  (and (consp r)
       (eq (car r) :milawa-ok)))

(defun milawa-abortp (r)
  (declare (xargs :guard t))
  (and (consp r)
       (eq (car r) :milawa-abort)))

(defun milawa-resultp (r)
  (declare (xargs :guard t))
  (and (consp r)
       (or (eq (car r) :milawa-ok)
           (eq (car r) :milawa-abort))))

(defun milawa-result-value (r)
  (declare (xargs :guard t))
  (if (consp r)
      (cdr r)
    nil))

(defun milawa-abort-reason (r)
  (declare (xargs :guard t))
  (if (and (consp r)
           (consp (cdr r)))
      (cadr r)
    nil))

(defthm milawa-okp-of-milawa-ok
  (milawa-okp (milawa-ok value))
  :hints (("Goal" :in-theory (enable milawa-okp milawa-ok))))

(defthm milawa-abortp-of-milawa-abort
  (milawa-abortp (milawa-abort reason))
  :hints (("Goal" :in-theory (enable milawa-abortp milawa-abort))))

(defthm milawa-abortp-of-milawa-ok
  (not (milawa-abortp (milawa-ok value)))
  :hints (("Goal" :in-theory (enable milawa-abortp milawa-ok))))

(defthm milawa-okp-of-milawa-abort
  (not (milawa-okp (milawa-abort reason)))
  :hints (("Goal" :in-theory (enable milawa-okp milawa-abort))))

(defthm milawa-result-value-of-milawa-ok
  (equal (milawa-result-value (milawa-ok value))
         value)
  :hints (("Goal" :in-theory (enable milawa-result-value milawa-ok))))

(defthm milawa-abort-reason-of-milawa-abort
  (equal (milawa-abort-reason (milawa-abort reason))
         reason)
  :hints (("Goal" :in-theory (enable milawa-abort-reason milawa-abort))))

;; ---------------------------------------------------------------------------
;; The primitives
;;
;; These are total, guard-free transcriptions.  NIL is a legal argument to
;; all of them, which is what the kernel relies on.
;; ---------------------------------------------------------------------------

(defun milawa-natp (x)
  (declare (xargs :guard t))
  (integerp x))

(defun milawa-symbolp (x)
  (declare (xargs :guard t))
  (symbolp x))

(defun milawa-consp (x)
  (declare (xargs :guard t))
  (consp x))

(defun milawa-equal (x y)
  (declare (xargs :guard t))
  (equal x y))

(defun milawa-cons (x y)
  (declare (xargs :guard t))
  (cons x y))

(defun milawa-car (x)
  (declare (xargs :guard t))
  (if (consp x)
      (car x)
    nil))

(defun milawa-cdr (x)
  (declare (xargs :guard t))
  (if (consp x)
      (cdr x)
    nil))

(defun milawa-< (x y)
  (declare (xargs :guard t))
  (< (if (integerp x) x 0)
     (if (integerp y) y 0)))

(defun milawa-symbol-< (x y)
  (declare (xargs :guard t))
  (if (string< (symbol-name (if (symbolp x) x nil))
               (symbol-name (if (symbolp y) y nil)))
      t
    nil))

(defun milawa-- (x y)
  (declare (xargs :guard t))
  (let* ((x-fix (if (integerp x) x 0))
         (y-fix (if (integerp y) y 0))
         (diff  (- x-fix y-fix)))
    (if (< diff 0)
        0
      diff)))

(defun milawa-+ (x y)
  (declare (xargs :guard t))
  (let* ((x-fix (if (integerp x) x 0))
         (y-fix (if (integerp y) y 0))
         (sum   (+ x-fix y-fix)))
    (if (< sum (expt 2 30))
        (milawa-ok sum)
      (milawa-abort :overflow))))

(defthm milawa-natp-on-values
  (implies (milawa-valuep x)
           (equal (milawa-natp x)
                  (milawa-fixnump x)))
  :hints (("Goal" :in-theory (enable milawa-natp milawa-fixnump))))

;; The primitives, their arities, and their application.

(defconst *milawa-primitive-arities*
  '((if . 3)
    (equal . 2)
    (consp . 1)
    (cons . 2)
    (car . 1)
    (cdr . 1)
    (symbolp . 1)
    (symbol-< . 2)
    (natp . 1)
    (< . 2)
    (+ . 2)
    (- . 2)))

(defun milawa-primitivep (fn)
  (declare (xargs :guard t))
  (consp (assoc-eq fn *milawa-primitive-arities*)))

(defun milawa-primitive-arity (fn)
  (declare (xargs :guard (milawa-primitivep fn)))
  (cdr (assoc-eq fn *milawa-primitive-arities*)))

(defthm milawa-primitive-arity-of-if
  (equal (milawa-primitive-arity 'if) 3)
  :hints (("Goal" :in-theory (enable milawa-primitive-arity
                                     milawa-primitivep))))

(defun milawa-apply-primitive (fn args)
  (declare (xargs :guard t
                  :verify-guards nil))
  (case fn
    (equal    (milawa-ok (milawa-equal (car args) (cadr args))))
    (consp    (milawa-ok (milawa-consp (car args))))
    (cons     (milawa-ok (milawa-cons (car args) (cadr args))))
    (car      (milawa-ok (milawa-car (car args))))
    (cdr      (milawa-ok (milawa-cdr (car args))))
    (symbolp  (milawa-ok (milawa-symbolp (car args))))
    (symbol-< (milawa-ok (milawa-symbol-< (car args) (cadr args))))
    (natp     (milawa-ok (milawa-natp (car args))))
    (<        (milawa-ok (milawa-< (car args) (cadr args))))
    (+        (milawa-+ (car args) (cadr args)))
    (-        (milawa-ok (milawa-- (car args) (cadr args))))
    (otherwise (milawa-abort :not-a-primitive))))
