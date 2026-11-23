; L0, part 3: the character reader and input stream.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; Jitawa starts from ASCII input and reads one s-expression at a time.  This
; book is the corresponding L0 reader: a character-list reader for numbers,
; symbols, lists, dotted pairs, QUOTE, and the #n= / #n# sharing notation.
; It is deliberately small and total; the fuel parameter only bounds
; recursion.  The printer in l0-spec.lisp and this reader are checked against
; each other on the printed forms.

(in-package "MILAWA-WASM")

(include-book "l0-parse")

;; ---------------------------------------------------------------------------
;; Character classification and whitespace
;; ---------------------------------------------------------------------------

(defun l0-whitespace-char-p (c)
  (declare (xargs :guard t))
  (or (eql c #\Space)
      (eql c #\Tab)
      (eql c #\Newline)
      (eql c #\Return)))

(defun l0-delimiter-char-p (c)
  (declare (xargs :guard t))
  (or (l0-whitespace-char-p c)
      (eql c #\()
      (eql c #\))
      (eql c #\')
      (eql c #\.)
      (eql c #\#)))

(defun l0-skip-whitespace (chars)
  (declare (xargs :guard t :measure (acl2-count chars)))
  (if (and (consp chars)
           (l0-whitespace-char-p (car chars)))
      (l0-skip-whitespace (cdr chars))
    chars))

(defun l0-digit-char-p (c)
  (declare (xargs :guard t))
  (and (characterp c)
       (<= (char-code #\0) (char-code c))
       (<= (char-code c) (char-code #\9))))

;; ---------------------------------------------------------------------------
;; Atoms: numbers and symbols
;; ---------------------------------------------------------------------------

(defun l0-token-chars (chars)
  (declare (xargs :guard t :measure (acl2-count chars)))
  (if (and (consp chars)
           (not (l0-delimiter-char-p (car chars))))
      (cons (car chars) (l0-token-chars (cdr chars)))
    nil))

(defun l0-token-rest (chars)
  (declare (xargs :guard t :measure (acl2-count chars)))
  (if (and (consp chars)
           (not (l0-delimiter-char-p (car chars))))
      (l0-token-rest (cdr chars))
    chars))

(defun l0-all-digits-p (chars)
  (declare (xargs :guard t :measure (acl2-count chars)))
  (if (consp chars)
      (and (l0-digit-char-p (car chars))
           (l0-all-digits-p (cdr chars)))
    t))

(defun l0-chars-to-nat (chars acc)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count chars)))
  (if (consp chars)
      (l0-chars-to-nat (cdr chars)
                       (+ (* 10 acc)
                          (- (char-code (car chars)) (char-code #\0))))
    acc))

(defun l0-upcase-chars (chars)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count chars)))
  (if (consp chars)
      (cons (acl2::char-upcase (car chars))
            (l0-upcase-chars (cdr chars)))
    nil))

(defun l0-chars-to-symbol (chars)
  (declare (xargs :guard t :verify-guards nil))
  (intern-in-package-of-symbol (coerce (l0-upcase-chars chars) 'string)
                               'l0-variable-p))

(defun l0-read-atom (chars)
  (declare (xargs :guard t :verify-guards nil))
  (let ((token (l0-token-chars chars))
        (rest  (l0-token-rest chars)))
    (cond ((endp token) (mv :error chars))
          ((l0-all-digits-p token)
           (mv (l0-chars-to-nat token 0) rest))
          (t
           (mv (l0-chars-to-symbol token) rest)))))

;; ---------------------------------------------------------------------------
;; #n= and #n#
;; ---------------------------------------------------------------------------

(defun l0-hash-digits (chars acc)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count chars)))
  (if (and (consp chars) (l0-digit-char-p (car chars)))
      (l0-hash-digits (cdr chars)
                      (+ (* 10 acc)
                         (- (char-code (car chars)) (char-code #\0))))
    (mv acc chars)))

;; ---------------------------------------------------------------------------
;; S-expressions
;; ---------------------------------------------------------------------------

(mutual-recursion
 (defun l0-read-sexp (chars fuel labels)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (mv :error chars labels)
     (let ((chars (l0-skip-whitespace chars)))
       (cond ((endp chars) (mv :eof chars labels))
             ((eql (car chars) #\()
              (l0-read-list (cdr chars) (1- (nfix fuel)) labels))
             ((eql (car chars) #\))
              (mv :error chars labels))
             ((eql (car chars) #\')
              (mv-let (x rest labels2)
                (l0-read-sexp (cdr chars) (1- (nfix fuel)) labels)
                (if (or (eq x :eof) (eq x :error))
                    (mv x rest labels2)
                  (mv (list 'quote x) rest labels2))))
             ((eql (car chars) #\#)
              (l0-read-label (cdr chars) (1- (nfix fuel)) labels))
             (t
              (mv-let (x rest)
                (l0-read-atom chars)
                (mv x rest labels)))))))

 (defun l0-read-list (chars fuel labels)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (zp fuel)
       (mv :error chars labels)
     (let ((chars (l0-skip-whitespace chars)))
       (cond ((endp chars) (mv :eof chars labels))
             ((eql (car chars) #\))
              (mv nil (cdr chars) labels))
             (t
              (mv-let (x rest labels2)
                (l0-read-sexp chars (1- (nfix fuel)) labels)
                (if (or (eq x :eof) (eq x :error))
                    (mv x rest labels2)
                  (let ((rest (l0-skip-whitespace rest)))
                    (cond
                     ((and (consp rest)
                           (eql (car rest) #\.)
                           (or (endp (cdr rest))
                               (l0-delimiter-char-p (cadr rest))))
                      (mv-let (tail rest2 labels3)
                        (l0-read-sexp (cdr rest) (1- (nfix fuel)) labels2)
                        (if (or (eq tail :eof) (eq tail :error))
                            (mv tail rest2 labels3)
                          (let ((rest2 (l0-skip-whitespace rest2)))
                            (if (and (consp rest2)
                                     (eql (car rest2) #\)))
                                (mv (cons x tail) (cdr rest2) labels3)
                              (mv :error rest2 labels3))))))
                     (t
                      (mv-let (xs rest2 labels3)
                        (l0-read-list rest (1- (nfix fuel)) labels2)
                        (if (or (eq xs :eof) (eq xs :error))
                            (mv xs rest2 labels3)
                          (mv (cons x xs) rest2 labels3)))))))))))))

 (defun l0-read-label (chars fuel labels)
   (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
   (if (or (zp fuel) (endp chars))
       (mv :error chars labels)
     (if (not (l0-digit-char-p (car chars)))
         (mv :error chars labels)
       (mv-let (n rest)
         (l0-hash-digits chars 0)
         (cond
          ((endp rest) (mv :error chars labels))
          ((eql (car rest) #\=)
           (mv-let (value rest2 labels2)
             (l0-read-sexp (cdr rest) (1- (nfix fuel)) labels)
             (if (or (eq value :eof) (eq value :error))
                 (mv value rest2 labels2)
               (mv value rest2 (cons (cons n value) labels2)))))
          ((eql (car rest) #\#)
           (let ((pair (assoc-equal n labels)))
             (if pair
                 (mv (cdr pair) (cdr rest) labels)
               (mv :error chars labels))))
          (t (mv :error chars labels))))))))

(defun l0-parse-all (chars fuel labels)
  (declare (xargs :guard t :verify-guards nil :measure (nfix fuel)))
  (if (zp fuel)
      (mv nil labels)
    (let ((chars (l0-skip-whitespace chars)))
      (if (endp chars)
          (mv nil labels)
        (mv-let (x rest labels2)
          (l0-read-sexp chars (1- (nfix fuel)) labels)
          (cond ((eq x :eof) (mv nil labels2))
                ((eq x :error) (mv (list :parse-error) labels2))
                (t
                 (mv-let (xs labels3)
                   (l0-parse-all rest (1- (nfix fuel)) labels2)
                   (mv (cons x xs) labels3)))))))))

(defun l0-read-all (chars)
  (declare (xargs :guard t :verify-guards nil))
  (mv-let (sexps labels)
    (l0-parse-all chars (+ 100 (len chars)) nil)
    (declare (ignore labels))
    sexps))
