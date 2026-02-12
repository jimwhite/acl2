; ACL2 Univariate Polynomials over a Field books -- Terms
;; Terms for Univariate Polynomials over a Field
; Copyright (C) 2006  John R. Cowles and Ruben A. Gamboa, University of
; Wyoming

; This book is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This book is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this book; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;; Modified by J. Cowles

;;   Last modified July 2006 (for ACL2 Version 3.0).

; Modified by Matt Kaufmann for ACL2 Version 3.1 because
; SBCL complains about LISP::.

;;  Based on
;;; ------------------------------------------------------------------
;;; T&eacute;rminos abstractos
;;;
;;; Autores:
;;;
;;; Inmaculada Medina Bulo
;;; Francisco Palomo Lozano
;;;
;;; Descripci&oacute;n:
;;;
;;; Un monoide conmutativo de t&eacute;rminos con un orden bien fundamentado
;;; cuya representaci&oacute;n se abstrae mediante un encapsulado. Las listas
;;; propias de n&uacute;meros naturales de ACL2 con la suma elemento a
;;; elemento y el orden lexicogr&aacute;fico sirven como modelo de la teor&iacute;a
;;; generada. La buena fundamentaci&oacute;n del orden se establece por
;;; inmersi&oacute;n en los ordinales ACL2.
;;;
;;; Notas generales:
;;;
;;; La parte m&aacute;s complicada es la inmersi&oacute;n y la buena fundamentaci&oacute;n
;;; del orden. Es curioso que los ordinales obtenidos son bastante
;;; peque&ntilde;os en relaci&oacute;n a, por ejemplo, los propuestos por Kaufmann,
;;; Manolios y Moore como soluci&oacute;n al ejercicio 6.8 de su libro
;;; &laquo;Computer-Aided Reasoning. An Approach&raquo;. V&eacute;ase el trabajo
;;; presentado en Austin.
;;; ------------------------------------------------------------------
#|
To certify this book, first, create a world with the following package:

(in-package "ACL2")

(defconst *import-symbols*
  (set-difference-eq
   (union-eq *acl2-exports*
	     *common-lisp-symbols-from-main-lisp-package*)
     '(null + * - < = / commutativity-of-* associativity-of-*
	    commutativity-of-+ associativity-of-+ distributivity)))

(defpkg "FUTER"
  *import-symbols*)

(certify-book "futermino"
	      2
	      nil ;;compile-flg
	      )
|#
(in-package "FUTER")
;; (encapsulate

;;   ;;; ---------
;;   ;;; Signatura
;;   ;;; ---------

;;   ((terminop (a) boolean)
;;    (* (a b) termino)
;;    (uno () termino)
;;    (termino->ordinal (a) ordinal)
;;    (< (a b) boolean))

;;   ;;; ----------------
;;   ;;; Testigos locales
;;   ;;; ----------------

;;   ;;; Reconocedor

;;   (local
;;     (defun terminop (a)
;;       (if (atom a)
;; 	  (equal a nil)
;; 	(and (natp (first a)) (terminop (rest a))))))
(defun
  terminop (a)
  (and (integerp a)
       (>= a 0)))

  ;;; Neutro de la operaci&oacute;n

;;   (local
;;     (defun uno ()
;;       nil))

;; hide is needed below to prevent the theorem
;; prover from ``knowing'' too much about UNO,
;; i.e. from knowing that UNO equals 0.
(defun
  uno ()
  (hide 0))
  ;;; Operaci&oacute;n

;;   (local
;;     (defun * (a b)
;;       (cond ((and (not (terminop a)) (not (terminop b)))
;; 	     (uno))
;; 	    ((not (terminop a))
;; 	     b)
;; 	    ((not (terminop b))
;; 	     a)
;; 	    ((atom a)
;; 	     b)
;; 	    ((atom b)
;; 	     a)
;; 	    (t
;; 	     (cons (ACL2::+ (first a) (first b)) (* (rest a) (rest b)))))))
(defun
  * (a b)
  (ACL2::+ a b))

  ;;; Igualdad sint&aacute;ctica entre t&eacute;rminos

(defmacro = (a b)
  `(equal ,a ,b))

  ;;; Inmersi&oacute;n en los ordinales

;;   (local
;;     (defun termino->e0-ordinal (a)
;;       (if (atom a)
;; 	  1
;; 	(cons (cons (len a) (first a)) (termino->e0-ordinal (rest a))))))


;;   (local
;;    (defun termino->ordinal (a)
;;      (if (atom a)
;; 	 1
;;        (cons (cons (len a) (1+ (first a))) (termino->ordinal (rest a))))))
(defun
  termino->ordinal (a)
  (ACL2::+ 1 a))

  ;;; Orden lexicogr&aacute;fico estricto

;;   (local
;;     (defun < (a b)
;; ;      (declare (xargs :guard (and (terminop a) (terminop b))))
;;       (cond ((or (atom a) (atom b))
;; 	     (not (atom b)))
;; 	    ((ACL2::< (len a) (len b))
;; 	     t)
;; 	    ((ACL2::> (len a) (len b))
;; 	     nil)
;; 	    ((equal (first a) (first b))
;; 	     (< (rest a) (rest b)))
;; 	    (t
;; 	     (ACL2::< (first a) (first b))))))
(defun
  < (a b)
  (ACL2::< a b))

  ;;; -------
  ;;; Axiomas
  ;;; -------

  ;;; El reconocedor es una funci&oacute;n booleana

(defthm booleanp-terminop
  (booleanp (terminop a))
  :rule-classes :type-prescription)

  ;;; Clausura de las operaciones

(defthm terminop-*
  (implies (and (terminop a) (terminop b))
	   (terminop (* a b)))
  :rule-classes :type-prescription)

(defthm terminop-uno
  (terminop (uno))
  :rule-classes :type-prescription)

  ;;; Conmutatividad de la operaci&oacute;n

(defthm |a * b = b * a|
  (implies (and (terminop a) (terminop b))
	   (= (* a b) (* b a))))

  ;;; Asociatividad de la operaci&oacute;n

(defthm |(a * b) * c = a * (b * c)|
  (implies (and (terminop a) (terminop b) (terminop c))
	   (= (* (* a b) c) (* a (* b c)))))

  ;;; Neutro de la operaci&oacute;n

(defthm |1 * a = a|
  (implies (terminop a)
	   (= (* (uno) a) a)))

  ;;; --------------------
  ;;; Buena fundamentaci&oacute;n
  ;;; --------------------

  ;;; Extensi&oacute;n de la correcci&oacute;n de la inmersi&oacute;n

;;   (local
;;     (defthm extension-correccion
;;       (implies (and (terminop a)
;; 		    (o-p (termino->ordinal (rest a))))
;; 	       (o-p (termino->ordinal a)))
;;       :otf-flg t))

  ;;; Correcci&oacute;n de la inmersi&oacute;n

;;   (local
;;     (defthm o-p-termino->ordinal
;;       (implies (terminop a)
;; 	       (o-p (termino->ordinal a)))
;;       :hints (("Goal"
;; 	       :in-theory (disable o-p termino->ordinal)))))

  ;;; Buena fundamentaci&oacute;n

  ;;; NOTA:
  ;;;
  ;;; Este teorema es &uacute;til como regla de reescritura para extender el
  ;;; orden de t&eacute;rminos a polinomios.

(defthm buena-fundamentacion-<
  (and (implies (terminop a)
		(o-p (termino->ordinal a)))
       (implies (and (terminop a) (terminop b)
		     (< a b))
		(o< (termino->ordinal a) (termino->ordinal b))))
  :rule-classes (:rewrite :well-founded-relation))

  ;;; La inmersi&oacute;n no produce 0

  ;;; NOTA:
  ;;;
  ;;; Estos teoremas facilitan la extensi&oacute;n del orden de t&eacute;rminos a
  ;;; polinomios.

(defthm |~(termino->ordinal(a) = 0)|
  (implies (terminop a)
	   (not (equal (termino->ordinal a) 0))))

(defthm |(termino->ordinal(a) >O 0)|
  (implies (terminop a)
	   (O< 0 (termino->ordinal a))))

  ;;; ---------------------
  ;;; Propiedades del orden
  ;;; ---------------------

  ;;; NOTA:
  ;;;
  ;;; En realidad estas propiedades no son independientes de los
  ;;; axiomas. Se podr&iacute;an deducir de la inmersi&oacute;n.

  ;;; Irreflexividad

(defthm |~(a < a)|
  (not (< a a)))
  ;;; Antisimetr&iacute;a

(defthm |a < b => ~(b < a)|
  (implies (< a b) (not (< b a))))

  ;;; Transitividad

(defthm |a < b & b < c => a < c|
  (implies (and (< a b) (< b c)) (< a c)))

  ;;; Tricotom&iacute;a

(defthm |a < b or b < a or a = b|
  (implies (and (terminop a) (terminop b))
	   (or (< a b) (< b a) (= a b)))
  :rule-classes
  ((:rewrite :corollary
	     (implies (and (terminop a) (terminop b)
			   (not (= a b)) (not (< a b)))
		      (< b a)))))

;; Properties of ordering on univariate terms:

(defthm
  |a < b => a * c < b * c|
  (implies (< a b)
	   (< (* a c)(* b c))))

(defthm
  |b < c => a * b < a * c|
  (implies (< b c)
	   (< (* a b)(* a c))))

(in-theory (disable terminop (terminop) * (*) uno (uno)
		    termino->ordinal (termino->ordinal) < (<)))

;;; --------
;;; Teoremas
;;; --------

;;; Teoremas que resultan de aplicar la conmutatividad a los axiomas

(defthm |a * 1 = a|
  (implies (terminop a)
	   (= (* a (uno)) a)))

;;; Complemento a la conmutatividad y la asociatividad de la operaci&oacute;n

(defthm |a * (b * c) = b * (a * c)|
  (implies (and (terminop a) (terminop b) (terminop c))
	   (= (* a (* b c)) (* b (* a c))))
  :hints (("Goal"
	   :in-theory (disable |(a * b) * c = a * (b * c)|)
	   :use (|(a * b) * c = a * (b * c)|
		 (:instance |(a * b) * c = a * (b * c)| (a b) (b a))))))
