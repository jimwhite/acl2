; L0, part 4: the reader/printer inverse theorem.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The printed form of an L0 atom is read back by the L0 reader.  This book
; proves the atom half of the reader/printer inverse for the printable domain:
; natural numbers and symbols whose names the printer round-trips (raw or
; |...| escaped).  The fuel is the size-based L0-READ-FUEL; it is an internal
; bound, not a correctness clock.
;
; The list half is deliberately not asserted here.  A cons is printed as
; "(" car tail ")", so after the first element the reader switches from
; l0-read-sexp to l0-read-list and consumes the closing parenthesis; the
; inverse induction must therefore carry a suffix and mirror both functions.
; The atom lemmas below (including the suffix-general L0-READ-SEXP-ATOM-APPEND)
; are the pieces that induction will need.

(in-package "MILAWA-WASM")

(include-book "l0-spec")

;; ---------------------------------------------------------------------------
;; Token facts
;; ---------------------------------------------------------------------------

(defthm l0-digit-char-not-delimiter
  (implies (l0-digit-char-p c)
           (not (l0-delimiter-char-p c)))
  :hints (("Goal" :in-theory (enable l0-digit-char-p l0-delimiter-char-p
                                     l0-whitespace-char-p))))

(defthm l0-token-chars-of-dec-chars
  (implies (and (true-listp chars)
                (str::dec-digit-char-list*p chars))
           (equal (l0-token-chars chars) chars))
  :hints (("Goal" :in-theory (enable l0-token-chars
                                     str::dec-digit-char-list*p))))

(defthm l0-token-rest-of-dec-chars
  (implies (and (true-listp chars)
                (str::dec-digit-char-list*p chars))
           (equal (l0-token-rest chars) nil))
  :hints (("Goal" :in-theory (enable l0-token-rest
                                     str::dec-digit-char-list*p))))

(defthm dec-digit-char-not-pipe
  (implies (str::dec-digit-char-p c)
           (not (equal c #\|)))
  :hints (("Goal" :in-theory (enable str::dec-digit-char-p))))

(defthm car-nat-to-dec-chars-not-pipe
  (not (equal (car (str::nat-to-dec-chars n)) #\|))
  :hints (("Goal" :cases ((consp (str::nat-to-dec-chars n)))
                  :use ((:instance str::dec-digit-char-list*p-of-nat-to-dec-chars)
                        (:instance dec-digit-char-not-pipe
                                   (c (car (str::nat-to-dec-chars n)))))
                  :in-theory (enable str::dec-digit-char-list*p))))

(defthm l0-read-atom-nat
  (implies (natp n)
           (mv-let (y rest)
             (l0-read-atom (str::nat-to-dec-chars n))
             (and (equal y n) (null rest))))
  :hints (("Goal" :in-theory (enable l0-read-atom
                                     l0-token-chars-of-dec-chars
                                     l0-token-rest-of-dec-chars
                                     str::dec-digit-chars-value-of-nat-to-dec-chars
                                     str::dec-digit-char-list*p-of-nat-to-dec-chars
                                     str::true-listp-of-nat-to-dec-chars
                                     car-nat-to-dec-chars-not-pipe))))

;; ---------------------------------------------------------------------------
;; Symbol facts
;; ---------------------------------------------------------------------------

(defthm upcase-char-of-upper
  (implies (and (standard-char-p c)
                (<= 65 (char-code c))
                (<= (char-code c) 90))
           (equal (str::upcase-char c) c))
  :hints (("Goal" :in-theory (enable str::upcase-char))))

(defthm upcase-char-of-digit
  (implies (and (standard-char-p c)
                (<= 48 (char-code c))
                (<= (char-code c) 57))
           (equal (str::upcase-char c) c))
  :hints (("Goal" :in-theory (enable str::upcase-char))))

(defthm l0-symbol-char-upcase
  (implies (l0-symbol-char-ok-p c)
           (equal (acl2::char-upcase c) c))
  :hints (("Goal" :in-theory (enable l0-symbol-char-ok-p l0-digit-char-p
                                     str::char-upcase-is-upcase-char)
                  :use (upcase-char-of-upper upcase-char-of-digit))))

(defthm l0-token-chars-of-symbol-chars
  (implies (and (true-listp chars)
                (l0-symbol-chars-ok-p chars))
           (equal (l0-token-chars chars) chars))
  :hints (("Goal" :in-theory (enable l0-token-chars
                                     l0-symbol-chars-ok-p))))

(defthm l0-token-rest-of-symbol-chars
  (implies (and (true-listp chars)
                (l0-symbol-chars-ok-p chars))
           (equal (l0-token-rest chars) nil))
  :hints (("Goal" :in-theory (enable l0-token-rest
                                     l0-symbol-chars-ok-p))))

(defthm l0-upcase-chars-of-symbol-chars
  (implies (and (true-listp chars)
                (l0-symbol-chars-ok-p chars))
           (equal (l0-upcase-chars chars) chars))
  :hints (("Goal" :in-theory (enable l0-upcase-chars
                                     l0-symbol-chars-ok-p
                                     l0-symbol-char-upcase))))

;; ---------------------------------------------------------------------------
;; Printable atoms
;; ---------------------------------------------------------------------------

(defun l0-raw-symbol-p (x)
  (and (symbolp x)
       (let ((chars (coerce (symbol-name x) 'list)))
         (and (true-listp chars)
              (l0-symbol-chars-ok-p chars)
              (not (str::dec-digit-char-list*p chars))
              (equal x (intern-in-package-of-symbol
                        (coerce (l0-upcase-chars chars) 'string)
                        'l0-variable-p))))))

(defun l0-pipe-symbol-p (x)
  (and (symbolp x)
       (let ((chars (coerce (symbol-name x) 'list)))
         (and (true-listp chars)
              (not (and (l0-symbol-chars-ok-p chars)
                        (not (str::dec-digit-char-list*p chars))))
              (not (member-equal #\| chars))
              (equal x (intern-in-package-of-symbol
                        (coerce chars 'string)
                        'l0-variable-p))))))

(defun l0-printable-symbol-p (x)
  (or (l0-raw-symbol-p x) (l0-pipe-symbol-p x)))

(defun l0-printable-atom-p (x)
  (or (natp x) (l0-printable-symbol-p x)))

(defthm l0-read-atom-raw-symbol
  (implies (l0-raw-symbol-p x)
           (mv-let (y rest)
             (l0-read-atom (l0-symbol-print-chars x))
             (and (equal y x) (null rest))))
  :hints (("Goal" :in-theory (enable l0-raw-symbol-p
                                     l0-symbol-print-chars
                                     l0-read-atom
                                     l0-token-chars-of-symbol-chars
                                     l0-token-rest-of-symbol-chars
                                     l0-upcase-chars-of-symbol-chars))))

(defthm l0-take-until-pipe-append
  (implies (and (true-listp name)
                (not (member-equal #\| name)))
           (equal (l0-take-until-pipe (append name (cons #\| rest)))
                  (mv name rest)))
  :hints (("Goal" :induct (l0-take-until-pipe
                           (append name (cons #\| rest))))))

(defthm l0-read-atom-pipe-symbol
  (implies (l0-pipe-symbol-p x)
           (mv-let (y rest)
             (l0-read-atom (l0-symbol-print-chars x))
             (and (equal y x) (null rest))))
  :hints (("Goal" :in-theory (enable l0-pipe-symbol-p
                                     l0-symbol-print-chars
                                     l0-read-atom
                                     l0-take-until-pipe-append))))

(defthm l0-read-atom-printable
  (implies (l0-printable-atom-p x)
           (mv-let (y rest)
             (l0-read-atom (l0-print-atom-chars x))
             (and (equal y x) (null rest))))
  :hints (("Goal" :cases ((natp x) (l0-raw-symbol-p x) (l0-pipe-symbol-p x))
                  :in-theory (enable l0-printable-atom-p l0-print-atom-chars)
                  :use ((:instance l0-read-atom-nat (n x))
                        (:instance l0-read-atom-raw-symbol (x x))
                        (:instance l0-read-atom-pipe-symbol (x x))))))

;; ---------------------------------------------------------------------------
;; Printable values and the size-based reader fuel
;; ---------------------------------------------------------------------------

(defun l0-printable-value-p (x)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
  (if (consp x)
      (and (l0-printable-value-p (car x))
           (l0-printable-value-p (cdr x))
           (or (null (cdr x))
               (consp (cdr x))))
    (l0-printable-atom-p x)))

(defun l0-printable-list-p (x)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
  (if (consp x)
      (and (l0-printable-value-p (car x))
           (l0-printable-list-p (cdr x)))
    (null x)))

(defun l0-read-fuel (x)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
  (if (consp x)
      (+ 20 (l0-read-fuel (car x)) (l0-read-fuel (cdr x)))
    20))

(defthm l0-read-fuel-positive
  (< 0 (l0-read-fuel x))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defun l0-value-induct (x)
  (declare (xargs :measure (acl2-count x)))
  (if (consp x)
      (and (l0-value-induct (car x))
           (l0-value-induct (cdr x)))
    t))

(defthm l0-skip-whitespace-when-not-whitespace
  (implies (and (consp chars)
                (not (l0-whitespace-char-p (car chars)))
                (not (eql (car chars) #\;)))
           (equal (l0-skip-whitespace chars) chars))
  :hints (("Goal" :in-theory (enable l0-skip-whitespace))))

(defun l0-no-delimiter-chars-p (chars)
  (declare (xargs :guard t :measure (acl2-count chars)))
  (if (consp chars)
      (and (not (l0-delimiter-char-p (car chars)))
           (l0-no-delimiter-chars-p (cdr chars)))
    t))

(defthm l0-no-delimiter-chars-p-of-dec-chars
  (implies (and (true-listp chars)
                (str::dec-digit-char-list*p chars))
           (l0-no-delimiter-chars-p chars))
  :hints (("Goal" :in-theory (enable l0-no-delimiter-chars-p
                                     str::dec-digit-char-list*p
                                     l0-digit-char-not-delimiter))))

(defthm l0-no-delimiter-chars-p-of-symbol-chars
  (implies (and (true-listp chars)
                (l0-symbol-chars-ok-p chars))
           (l0-no-delimiter-chars-p chars))
  :hints (("Goal" :in-theory (enable l0-no-delimiter-chars-p
                                     l0-symbol-chars-ok-p
                                     l0-delimiter-char-p
                                     l0-whitespace-char-p))))

(defthm l0-token-chars-append-delimiter
  (implies (and (true-listp chars)
                (l0-no-delimiter-chars-p chars)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (equal (l0-token-chars (append chars suffix)) chars))
  :hints (("Goal" :induct (l0-no-delimiter-chars-p chars)
                  :in-theory (enable l0-token-chars
                                     l0-no-delimiter-chars-p))))

(defthm l0-token-rest-append-delimiter
  (implies (and (true-listp chars)
                (l0-no-delimiter-chars-p chars)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (equal (l0-token-rest (append chars suffix)) suffix))
  :hints (("Goal" :induct (l0-no-delimiter-chars-p chars)
                  :in-theory (enable l0-token-rest
                                     l0-no-delimiter-chars-p))))

(defthm l0-read-sexp-atom-case
  (implies (and (consp chars)
                (not (equal (car chars) #\())
                (not (equal (car chars) #\)))
                (not (equal (car chars) #\'))
                (not (equal (car chars) #\#))
                (not (eql (car chars) #\;))
                (not (l0-whitespace-char-p (car chars)))
                (not (zp fuel)))
           (equal (l0-read-sexp chars fuel labels)
                  (mv-let (v rest)
                    (l0-read-atom chars)
                    (mv v rest labels))))
  :hints (("Goal" :in-theory (enable l0-read-sexp
                                     l0-read-atom))))

(defthm l0-digit-char-not-special
  (implies (l0-digit-char-p c)
           (and (not (equal c #\())
                (not (equal c #\)))
                (not (equal c #\'))
                (not (equal c #\#))
                (not (eql c #\;))
                (not (equal c #\.))
                (not (l0-whitespace-char-p c))))
  :hints (("Goal" :in-theory (enable l0-digit-char-p
                                     l0-whitespace-char-p))))

(defthm dec-digit-char-p-car-when-list*p
  (implies (and (consp x)
                (str::dec-digit-char-list*p x))
           (str::dec-digit-char-p (car x)))
  :hints (("Goal" :in-theory (enable str::dec-digit-char-list*p))))

(defthm l0-digit-char-p-of-dec-digit-char-p
  (implies (str::dec-digit-char-p c)
           (l0-digit-char-p c))
  :hints (("Goal" :in-theory (enable str::dec-digit-char-p
                                     l0-digit-char-p)))
  :rule-classes :rewrite)

(defthm l0-symbol-char-not-special
  (implies (l0-symbol-char-ok-p c)
           (and (not (equal c #\())
                (not (equal c #\)))
                (not (equal c #\'))
                (not (equal c #\#))
                (not (eql c #\;))
                (not (equal c #\.))
                (not (l0-whitespace-char-p c))))
  :hints (("Goal" :in-theory (enable l0-symbol-char-ok-p
                                     l0-digit-char-p
                                     l0-whitespace-char-p))))

(defthm consp-of-coerce-symbol-name
  (implies (and (symbolp x)
                (not (equal "" (symbol-name x))))
           (consp (coerce (symbol-name x) 'list)))
  :hints (("Goal" :in-theory (enable coerce))))

(defthm l0-symbol-chars-ok-p-car
  (implies (and (consp chars)
                (l0-symbol-chars-ok-p chars))
           (l0-symbol-char-ok-p (car chars)))
  :hints (("Goal" :in-theory (enable l0-symbol-chars-ok-p))))

(defthm l0-car-nat-to-dec-chars-digit
  (l0-digit-char-p (car (str::nat-to-dec-chars n)))
  :hints (("Goal" :use ((:instance str::dec-digit-char-list*p-of-nat-to-dec-chars (n n))
                        (:instance dec-digit-char-p-car-when-list*p
                                   (x (str::nat-to-dec-chars n))))
                  :in-theory (enable str::dec-digit-char-list*p
                                     l0-digit-char-p))))

(defthm not-zp-when-<=-20
  (implies (and (integerp fuel)
                (<= 20 fuel))
           (not (zp fuel)))
  :rule-classes :forward-chaining)

(defthm l0-print-atom-chars-consp
  (implies (l0-printable-atom-p x)
           (consp (l0-print-atom-chars x)))
  :hints (("Goal" :cases ((natp x) (l0-raw-symbol-p x) (l0-pipe-symbol-p x))
                  :in-theory (enable l0-printable-atom-p
                                     l0-print-atom-chars
                                     l0-symbol-print-chars
                                     l0-raw-symbol-p
                                     l0-pipe-symbol-p
                                     str::nat-to-dec-chars))))

(defthm l0-read-atom-printable-append
  (implies (and (l0-printable-atom-p x)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (mv-let (y rest)
             (l0-read-atom (append (l0-print-atom-chars x) suffix))
             (and (equal y x) (equal rest suffix))))
  :hints (("Goal" :cases ((natp x) (l0-raw-symbol-p x) (l0-pipe-symbol-p x))
                  :in-theory (enable l0-printable-atom-p
                                     l0-print-atom-chars
                                     l0-symbol-print-chars
                                     l0-raw-symbol-p
                                     l0-pipe-symbol-p
                                     l0-read-atom
                                     l0-token-chars-append-delimiter
                                     l0-token-rest-append-delimiter
                                     l0-take-until-pipe-append
                                     l0-no-delimiter-chars-p-of-dec-chars
                                     l0-no-delimiter-chars-p-of-symbol-chars
                                     str::true-listp-of-nat-to-dec-chars
                                     str::dec-digit-char-list*p-of-nat-to-dec-chars
                                     str::dec-digit-chars-value-of-nat-to-dec-chars
                                     l0-upcase-chars-of-symbol-chars))))

(defthm l0-read-sexp-atom-append
  (implies (and (l0-printable-atom-p x)
                (integerp fuel)
                (<= 20 fuel)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (mv-let (y rest labels)
             (l0-read-sexp (append (l0-print-atom-chars x) suffix) fuel nil)
             (and (equal y x) (equal rest suffix) (null labels))))
  :hints (("Goal" :in-theory (enable l0-print-atom-chars
                                     l0-read-sexp
                                     l0-skip-whitespace
                                     l0-print-atom-chars-consp
                                     l0-read-atom-printable-append
                                     l0-skip-whitespace-when-not-whitespace
                                     l0-digit-char-not-special
                                     l0-symbol-char-not-special)
                  :use ((:instance l0-read-atom-printable-append
                                   (x x) (suffix suffix))))))

(defthm l0-read-sexp-atom
  (implies (and (l0-printable-atom-p x)
                (integerp fuel)
                (<= 20 fuel))
           (mv-let (y rest labels)
             (l0-read-sexp (l0-print-chars x) fuel nil)
             (and (equal y x) (null rest) (null labels))))
  :hints (("Goal" :in-theory (enable l0-print-chars
                                     l0-read-sexp
                                     l0-read-atom-printable)
                  :use l0-read-atom-printable)))

(defthm l0-printable-list-p-car
  (implies (and (l0-printable-list-p x)
                (consp x))
           (l0-printable-value-p (car x)))
  :hints (("Goal" :in-theory (enable l0-printable-list-p))))

(defthm l0-printable-list-p-cdr
  (implies (and (l0-printable-list-p x)
                (consp x))
           (l0-printable-list-p (cdr x)))
  :hints (("Goal" :in-theory (enable l0-printable-list-p))))

(defthm l0-printable-value-p-car
  (implies (and (l0-printable-value-p x)
                (consp x))
           (l0-printable-value-p (car x)))
  :hints (("Goal" :in-theory (enable l0-printable-value-p
                                     l0-printable-list-p-car))))

(defthm l0-printable-value-p-cdr
  (implies (and (l0-printable-value-p x)
                (consp x))
           (l0-printable-value-p (cdr x)))
  :hints (("Goal" :in-theory (enable l0-printable-value-p))))

(defthm l0-printable-list-p-of-value-cdr
  (implies (and (l0-printable-value-p x)
                (consp x))
           (l0-printable-list-p (cdr x)))
  :hints (("Goal" :in-theory (enable l0-printable-value-p))))

(defthm l0-read-fuel-car-bound
  (implies (and (consp x)
                (<= (l0-read-fuel x) fuel))
           (<= (l0-read-fuel (car x)) fuel))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defthm l0-read-fuel-cdr-bound
  (implies (and (consp x)
                (<= (l0-read-fuel x) fuel))
           (<= (l0-read-fuel (cdr x)) fuel))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defthm l0-printable-atom-p-when-value-not-consp
  (implies (and (l0-printable-value-p x)
                (not (consp x)))
           (l0-printable-atom-p x))
  :hints (("Goal" :in-theory (enable l0-printable-value-p))))

(defthm l0-read-sexp-print-value-atom
  (implies (and (not (consp x))
                (l0-printable-value-p x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (mv-let (y rest labels)
             (l0-read-sexp (l0-print-chars x) fuel nil)
             (and (equal y x) (null rest) (null labels))))
  :hints (("Goal" :in-theory (enable l0-printable-value-p
                                     l0-read-fuel)
                  :use ((:instance l0-read-sexp-atom
                                   (x x) (fuel fuel))))))

(defthm l0-read-sexp-print-value-atom-0
  (implies (and (not (consp x))
                (l0-printable-value-p x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (equal (mv-nth 0 (l0-read-sexp (l0-print-chars x) fuel nil))
                  x))
  :hints (("Goal" :use l0-read-sexp-print-value-atom
                  :in-theory (enable mv-nth))))

(defthm l0-read-sexp-print-value-atom-1
  (implies (and (not (consp x))
                (l0-printable-value-p x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (equal (mv-nth 1 (l0-read-sexp (l0-print-chars x) fuel nil))
                  nil))
  :hints (("Goal" :use l0-read-sexp-print-value-atom
                  :in-theory (enable mv-nth))))

(defthm l0-read-sexp-print-value-atom-2
  (implies (and (not (consp x))
                (l0-printable-value-p x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (equal (mv-nth 2 (l0-read-sexp (l0-print-chars x) fuel nil))
                  nil))
  :hints (("Goal" :use l0-read-sexp-print-value-atom
                  :in-theory (enable mv-nth))))

; TODO: the cons/proper-list half of the inverse theorem.  The atom half is
; above; the list half needs a suffix-general induction over the reader's
; l0-read-list recursion.
