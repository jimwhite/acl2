; L0 inverse, recursive flag relation over printed contexts.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse-list")

(defun l0-vl-printed (flag x chars rest fuel)
  (declare (xargs :measure (acl2-count x))
           (irrelevant fuel))
  (if (eq flag :value)
      (cond ((l0-printable-atom-p x)
             (equal chars
                    (append (l0-print-atom-chars x) rest)))
            ((consp x)
             (let ((rest1 (append (l0-print-tail (cdr x))
                                  (cons *l0-rparen* rest))))
               (and (l0-vl-printed
                     :value
                     (car x)
                     (append (l0-print-chars (car x)) rest1)
                     rest1
                     (1- (nfix fuel)))
                    (l0-vl-printed
                     :list
                     (cdr x)
                     rest1
                     rest
                     (1- (nfix fuel)))
                    (equal chars
                           (cons *l0-lparen*
                                 (append (l0-print-chars (car x))
                                         rest1))))))
            (t nil))
    (cond ((null x)
           (equal chars (cons *l0-rparen* rest)))
          ((consp x)
           (let ((rest1 (append (l0-print-tail (cdr x))
                                (cons *l0-rparen* rest))))
             (and (l0-vl-printed
                   :value
                   (car x)
                   (append (l0-print-chars (car x)) rest1)
                   rest1
                   (1- (nfix fuel)))
                  (l0-vl-printed
                   :list
                   (cdr x)
                   rest1
                   rest
                   (1- (nfix fuel)))
                  (equal chars
                         (cons *l0-space*
                               (append (l0-print-chars (car x))
                                       rest1))))))
          (t nil))))

(defthm l0-print-tail-context-delimiter
  (implies (l0-printable-list-p x)
           (or (endp (append (l0-print-tail x)
                             (cons *l0-rparen* rest)))
               (l0-delimiter-char-p
                (car (append (l0-print-tail x)
                             (cons *l0-rparen* rest))))))
  :hints (("Goal" :cases ((consp x) (null x))
                  :use l0-print-tail-shape
                  :in-theory (enable l0-delimiter-char-p
                                     l0-whitespace-char-p))))

(defun l0-vl-read (flag chars fuel)
  (declare (xargs :guard t :verify-guards nil))
  (if (eq flag :value)
      (l0-read-sexp chars fuel nil)
    (l0-read-list chars fuel nil)))

(defun l0-vl-ind (flag x chars rest fuel)
  (declare (xargs :measure (acl2-count x))
           (ignore chars flag)
           (irrelevant fuel))
  (if (consp x)
      (let ((rest1 (append (l0-print-tail (cdr x))
                           (cons *l0-rparen* rest))))
        (list (l0-vl-ind :value
                         (car x)
                         (append (l0-print-chars (car x)) rest1)
                         rest1
                         (1- (nfix fuel)))
              (l0-vl-ind :list
                         (cdr x)
                         rest1
                         rest
                         (1- (nfix fuel)))))
    nil))

(defthm l0-vl-printed-inverse
  (implies (and (l0-vl-printed flag x chars rest fuel)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel)
                (or (endp rest)
                    (l0-delimiter-char-p (car rest))))
           (and (equal (mv-nth 0 (l0-vl-read flag chars fuel))
                       x)
                (equal (mv-nth 1 (l0-vl-read flag chars fuel))
                       rest)
                (equal (mv-nth 2 (l0-vl-read flag chars fuel))
                       nil)))
  :hints (("Goal" :induct (l0-vl-ind flag x chars rest fuel)
                  :in-theory (disable l0-read-sexp
                                      l0-read-list
                                      l0-context
                                      l0-stack-p
                                      l0-delimiter-char-p
                                      l0-whitespace-char-p))))
