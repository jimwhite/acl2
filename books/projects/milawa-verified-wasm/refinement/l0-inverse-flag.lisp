; L0 inverse, mutual induction over the reader's value/list switch.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse-list")

(mutual-recursion
 (defun l0-v-induct (x stack suffix fuel)
   (declare (xargs :measure (acl2-count x))
            (irrelevant stack suffix fuel))
   (if (consp x)
       (and (l0-v-induct (car x)
                         (cons (cdr x) stack)
                         suffix
                         (1- (nfix fuel)))
            (l0-l-induct (cdr x) stack suffix (1- (nfix fuel))))
     t))
 (defun l0-l-induct (x stack suffix fuel)
   (declare (xargs :measure (acl2-count x))
            (irrelevant stack suffix fuel))
   (if (consp x)
       (and (l0-v-induct (car x)
                         (cons (cdr x) stack)
                         suffix
                         (1- (nfix fuel)))
            (l0-l-induct (cdr x) stack suffix (1- (nfix fuel))))
     t)))

(defun l0-v-ok (x stack suffix fuel)
  (declare (xargs :guard t :verify-guards nil))
  (mv-let (y rest labels)
    (l0-read-sexp
     (append (l0-print-chars x)
             (l0-context stack suffix))
     fuel nil)
    (and (equal y x)
         (equal rest (l0-context stack suffix))
         (null labels))))

(defun l0-l-ok (x stack suffix fuel)
  (declare (xargs :guard t :verify-guards nil))
  (mv-let (y rest labels)
    (l0-read-list
     (l0-skip-whitespace
      (append (l0-print-tail x)
              (append (list *l0-rparen*)
                      (l0-context stack suffix))))
     fuel nil)
    (and (equal y x)
         (equal rest (l0-context stack suffix))
         (null labels))))

(defthm l0-vl-ok-true
  (and
   (implies (and (l0-printable-value-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel)
                 (or (endp (l0-context stack suffix))
                     (l0-delimiter-char-p
                      (car (l0-context stack suffix)))))
            (l0-v-ok x stack suffix fuel))
   (implies (and (l0-printable-list-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel))
            (l0-l-ok x stack suffix fuel)))
  :hints (("Goal" :induct (l0-v-induct x stack suffix fuel)
                  :in-theory (e/d (l0-v-ok l0-l-ok)
                                  (l0-read-sexp
                                   l0-read-list
                                   l0-print-chars
                                   l0-print-tail
                                   l0-print-atom-chars
                                   l0-symbol-print-chars
                                   l0-read-atom
                                   l0-take-until-pipe
                                   l0-token-chars
                                   l0-token-rest
                                   l0-printable-value-p
                                   l0-printable-list-p
                                   l0-printable-atom-p
                                   l0-printable-symbol-p
                                   l0-raw-symbol-p
                                   l0-pipe-symbol-p
                                   l0-context
                                   l0-stack-p
                                   l0-delimiter-char-p
                                   l0-whitespace-char-p
                                   l0-read-fuel)))))
