; A short ACL2 regression, to check that the interpreter still means what it
; says after the trampoline change.  Every step prints a marker, so a log in
; which a marker is missing tells us exactly which form was lost.
(in-package "ACL2")

(cw "~%MARK start~%")

; rewriting and linear arithmetic
(thm (equal (+ x y) (+ y x)))
(cw "~%MARK commutativity~%")

(thm (implies (and (integerp x) (< 0 x)) (< 0 (* x x))))
(cw "~%MARK nonlinear~%")

; induction
(thm (equal (append (append x y) z) (append x (append y z))))
(cw "~%MARK append-assoc~%")

(defun my-natp (x) (if (zp x) t (my-natp (- x 1))))
(defthm my-natp-is-natp (implies (natp x) (my-natp x)))
(cw "~%MARK defun-defthm~%")

; mutual recursion
(mutual-recursion
 (defun evenp2 (n) (if (zp n) t (oddp2 (- n 1))))
 (defun oddp2 (n) (if (zp n) nil (evenp2 (- n 1)))))
(thm (evenp2 100))
(thm (oddp2 101))
(cw "~%MARK mutual-recursion~%")

; guards
(defun add-one (n) (declare (xargs :guard (natp n))) (+ 1 n))
(verify-guards add-one)
(thm (equal (add-one 5) 6))
(cw "~%MARK guards~%")

; macros and encapsulate
(defmacro twice (x) `(* 2 ,x))
(encapsulate
 (((foo *) => *))
 (local (defun foo (x) x))
 (defthm foo-id (equal (foo x) x)))
(thm (equal (twice (foo 3)) 6))
(cw "~%MARK encapsulate~%")

; computed hints and :use
(defun my-hint (stable-under-simplificationp clause)
  (declare (ignore clause))
  (and stable-under-simplificationp '(:in-theory (enable)))) 
(thm (equal (car (cons a b)) a) :hints (("Goal" :use ((:instance car-cons)))))
(cw "~%MARK hints~%")

; defstobj
(defstobj cnt (cnt-field :initially 0) :inline t)
(defun bump (cnt)
  (declare (xargs :stobjs cnt :guard t))
  (update-cnt-field (+ 1 (nfix (cnt-field cnt))) cnt))
(cw "~%MARK stobj~%")

; apply$ and the community book, which is the deep case
(include-book "projects/apply/top" :dir :system)
(cw "~%MARK apply-top~%")
(thm (equal (apply$ 'binary-+ (list 1 2)) 3))
(cw "~%MARK apply-thm~%")

; certify a small book, which runs the whole admission machinery
(cw "~%MARK certify-start~%")
(certify-book "tramp-check" ? t)
(cw "~%MARK certify-done~%")

(good-bye)
