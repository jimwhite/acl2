; L0 inverse, list context layer.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse")

;; Keep the special characters out of the proof text: the `#\)` literal is
;; easy to mangle when editing and is the only source of the earlier reader
;; errors.
(defconst *l0-rparen* #\))
(defconst *l0-lparen* #\()
(defconst *l0-dot* #\.)
(defconst *l0-space* #\Space)
(defconst *l0-semicolon* #\;)

(defthm l0-print-chars-cons
  (implies (consp x)
           (equal (l0-print-chars x)
                  (append (list *l0-lparen*)
                          (l0-print-chars (car x))
                          (l0-print-tail (cdr x))
                          (list *l0-rparen*))))
  :hints (("Goal" :in-theory (enable l0-print-chars))))

(defthm l0-print-chars-atom
  (implies (not (consp x))
           (equal (l0-print-chars x)
                  (l0-print-atom-chars x)))
  :hints (("Goal" :in-theory (enable l0-print-chars))))

(defthm l0-print-tail-cons
  (implies (consp x)
           (equal (l0-print-tail x)
                  (append (list *l0-space*)
                          (l0-print-chars (car x))
                          (l0-print-tail (cdr x)))))
  :hints (("Goal" :in-theory (enable l0-print-tail))))

(defthm l0-print-tail-nil
  (equal (l0-print-tail nil) nil)
  :hints (("Goal" :in-theory (enable l0-print-tail))))

(defthm l0-print-atom-chars-first-not-special
  (implies (l0-printable-atom-p x)
           (and (consp (l0-print-atom-chars x))
                (not (equal (car (l0-print-atom-chars x)) *l0-dot*))
                (not (equal (car (l0-print-atom-chars x)) *l0-rparen*))))
  :hints (("Goal" :cases ((natp x) (l0-raw-symbol-p x) (l0-pipe-symbol-p x))
                  :in-theory (enable l0-printable-atom-p
                                     l0-print-atom-chars
                                     l0-symbol-print-chars
                                     l0-raw-symbol-p
                                     l0-pipe-symbol-p
                                     l0-digit-char-not-special
                                     l0-symbol-char-not-special
                                     str::nat-to-dec-chars))))

(defthm l0-print-chars-first-facts
  (implies (l0-printable-value-p x)
           (and (consp (l0-print-chars x))
                (not (equal (car (l0-print-chars x)) *l0-dot*))
                (not (equal (car (l0-print-chars x)) *l0-rparen*))
                (not (l0-whitespace-char-p (car (l0-print-chars x))))
                (not (eql (car (l0-print-chars x)) *l0-semicolon*))))
  :hints (("Goal" :cases ((consp x) (not (consp x)))
                  :in-theory (enable l0-print-chars-cons
                                     l0-print-chars-atom
                                     l0-printable-value-p
                                     l0-printable-atom-p
                                     l0-raw-symbol-p
                                     l0-pipe-symbol-p
                                     l0-symbol-print-chars
                                     l0-print-atom-chars
                                     l0-print-atom-chars-first-not-special
                                     l0-digit-char-not-special
                                     l0-symbol-char-not-special
                                     l0-whitespace-char-p))))

(defthm l0-print-chars-consp
  (implies (l0-printable-value-p x)
           (consp (l0-print-chars x)))
  :hints (("Goal" :use l0-print-chars-first-facts)))

(defthm l0-print-chars-first-not-whitespace
  (implies (l0-printable-value-p x)
           (not (l0-whitespace-char-p (car (l0-print-chars x)))))
  :hints (("Goal" :use l0-print-chars-first-facts)))

(defthm l0-print-chars-first-not-semicolon
  (implies (l0-printable-value-p x)
           (not (eql (car (l0-print-chars x)) *l0-semicolon*)))
  :hints (("Goal" :use l0-print-chars-first-facts)))

(defthm l0-print-chars-first-not-rparen
  (implies (l0-printable-value-p x)
           (not (equal (car (l0-print-chars x)) *l0-rparen*)))
  :hints (("Goal" :use l0-print-chars-first-facts)))

(defthm l0-skip-whitespace-of-safe-append
  (implies (and (consp chars)
                (not (l0-whitespace-char-p (car chars)))
                (not (eql (car chars) *l0-semicolon*)))
           (equal (l0-skip-whitespace (append chars suffix))
                  (append chars suffix)))
  :hints (("Goal" :in-theory (enable l0-skip-whitespace-when-not-whitespace))))

(defthm l0-skip-whitespace-of-space-safe
  (implies (and (consp chars)
                (not (l0-whitespace-char-p (car chars)))
                (not (eql (car chars) *l0-semicolon*)))
           (equal (l0-skip-whitespace (cons *l0-space* chars)) chars))
  :hints (("Goal" :in-theory (enable l0-skip-whitespace
                                     l0-skip-whitespace-when-not-whitespace))))

(defthm l0-skip-whitespace-of-print-chars
  (implies (l0-printable-value-p x)
           (equal (l0-skip-whitespace (append (l0-print-chars x) suffix))
                  (append (l0-print-chars x) suffix)))
  :hints (("Goal" :use ((:instance l0-print-chars-consp (x x))
                        (:instance l0-print-chars-first-not-whitespace (x x))
                        (:instance l0-print-chars-first-not-semicolon (x x)))
                  :do-not-induct t
                  :in-theory (e/d (l0-skip-whitespace-of-safe-append)
                                  (l0-print-chars
                                   l0-print-chars-atom
                                   l0-print-chars-cons
                                   l0-print-atom-chars
                                   l0-symbol-print-chars
                                   l0-print-tail)))))

(defthm l0-skip-whitespace-of-space-print-chars
  (implies (l0-printable-value-p x)
           (equal (l0-skip-whitespace
                   (cons *l0-space* (append (l0-print-chars x) rest)))
                  (append (l0-print-chars x) rest)))
  :hints (("Goal" :use ((:instance l0-print-chars-consp (x x))
                        (:instance l0-print-chars-first-not-whitespace (x x))
                        (:instance l0-print-chars-first-not-semicolon (x x)))
                  :do-not-induct t
                  :in-theory (e/d (l0-skip-whitespace-of-space-safe)
                                  (l0-print-chars
                                   l0-print-chars-atom
                                   l0-print-chars-cons
                                   l0-print-atom-chars
                                   l0-symbol-print-chars
                                   l0-print-tail)))))

(defthm l0-print-tail-shape
  (implies (l0-printable-list-p x)
           (or (equal (l0-print-tail x) nil)
               (and (consp (l0-print-tail x))
                    (equal (car (l0-print-tail x)) *l0-space*))))
  :hints (("Goal" :cases ((consp x) (null x))
                  :in-theory (enable l0-print-tail-cons
                                     l0-print-tail-nil
                                     l0-printable-list-p))))

(defthm l0-print-tail-first-not-dot
  (implies (l0-printable-list-p x)
           (and (consp (l0-skip-whitespace
                        (append (l0-print-tail x) (list *l0-rparen*))))
                (not (equal (car (l0-skip-whitespace
                                  (append (l0-print-tail x)
                                          (list *l0-rparen*))))
                            *l0-dot*))))
  :hints (("Goal" :cases ((consp x) (null x))
                  :in-theory (enable l0-print-tail-cons
                                     l0-print-tail-nil
                                     l0-printable-list-p
                                     l0-skip-whitespace-of-print-chars
                                     l0-print-chars-first-facts))))

(defthm l0-print-tail-first-not-dot-append
  (implies (l0-printable-list-p x)
           (and (consp (l0-skip-whitespace
                        (append (l0-print-tail x)
                                (append (list *l0-rparen*) suffix))))
                (not (equal (car (l0-skip-whitespace
                                  (append (l0-print-tail x)
                                          (append (list *l0-rparen*) suffix))))
                            *l0-dot*))))
  :hints (("Goal" :use l0-print-tail-first-not-dot
                  :in-theory (enable l0-skip-whitespace))))

(defthm l0-print-tail-first-not-dot-context
  (implies (l0-printable-list-p x)
           (not (equal (car (l0-skip-whitespace
                             (append (l0-print-tail x)
                                     (append (list *l0-rparen*) suffix))))
                       *l0-dot*)))
  :hints (("Goal" :use l0-print-tail-first-not-dot-append)))

(defthm l0-print-tail-context-consp
  (implies (l0-printable-list-p x)
           (consp (l0-skip-whitespace
                   (append (l0-print-tail x)
                           (append (list *l0-rparen*) suffix)))))
  :hints (("Goal" :use l0-print-tail-first-not-dot-append)))

(defthm l0-printable-list-p-nil
  (equal (l0-printable-list-p nil) t)
  :hints (("Goal" :in-theory (enable l0-printable-list-p))))

(defthm l0-printable-list-p-cons
  (implies (consp x)
           (equal (l0-printable-list-p x)
                  (and (l0-printable-value-p (car x))
                       (l0-printable-list-p (cdr x)))))
  :hints (("Goal" :in-theory (enable l0-printable-list-p))))

(defthm l0-printable-list-p-null-when-not-consp
  (implies (and (l0-printable-list-p d)
                (not (consp d)))
           (null d))
  :hints (("Goal" :in-theory (enable l0-printable-list-p))))

(defthm l0-printable-list-p-equal-nil-when-not-consp
  (implies (and (l0-printable-list-p d)
                (not (consp d)))
           (equal d nil))
  :hints (("Goal" :use l0-printable-list-p-null-when-not-consp))
  :rule-classes :forward-chaining)

(defthm l0-read-sexp-cons-append
  (implies (and (consp x)
                (not (zp fuel)))
           (equal (l0-read-sexp (append (l0-print-chars x) suffix)
                                fuel nil)
                  (l0-read-list
                   (append (l0-print-chars (car x))
                           (append (l0-print-tail (cdr x))
                                   (append (list *l0-rparen*) suffix)))
                   (1- (nfix fuel))
                   nil)))
  :hints (("Goal" :in-theory (enable l0-read-sexp
                                     l0-print-chars-cons
                                     l0-skip-whitespace-when-not-whitespace))))

(defthm l0-read-list-close
  (implies (not (zp fuel))
           (equal (l0-read-list (cons *l0-rparen* suffix) fuel labels)
                  (mv nil suffix labels)))
  :hints (("Goal" :in-theory (enable l0-read-list))))

(defthm l0-read-fuel-atom
  (implies (not (consp x))
           (equal (l0-read-fuel x) 20))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defthm l0-read-fuel-car-bound-1
  (implies (and (consp x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (<= (l0-read-fuel (car x)) (1- fuel)))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defthm l0-read-fuel-cdr-bound-1
  (implies (and (consp x)
                (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (<= (l0-read-fuel (cdr x)) (1- fuel)))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

;; ---------------------------------------------------------------------------
;; Context stack
;; ---------------------------------------------------------------------------

(defun l0-context (stack suffix)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count stack)))
  (if (consp stack)
      (append (l0-print-tail (car stack))
              (list *l0-rparen*)
              (l0-context (cdr stack) suffix))
    suffix))

(defun l0-stack-p (stack)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count stack)))
  (if (consp stack)
      (and (l0-printable-list-p (car stack))
           (l0-stack-p (cdr stack)))
    t))

(defthm l0-context-nil
  (equal (l0-context nil suffix) suffix))

(defthm l0-context-cons
  (equal (l0-context (cons d stack) suffix)
         (append (l0-print-tail d)
                 (list *l0-rparen*)
                 (l0-context stack suffix))))

(defthm l0-context-nonempty
  (implies (consp stack)
           (consp (l0-context stack suffix))))

(defthm l0-context-first-delimiter
  (implies (and (l0-stack-p stack)
                (consp stack))
           (l0-delimiter-char-p (car (l0-context stack suffix))))
  :hints (("Goal" :use ((:instance l0-print-tail-shape (x (car stack))))
                  :in-theory (enable l0-context
                                     l0-stack-p
                                     l0-delimiter-char-p
                                     l0-whitespace-char-p))))

(defthm l0-stack-p-cdr
  (implies (l0-stack-p stack)
           (l0-stack-p (cdr stack)))
  :hints (("Goal" :in-theory (enable l0-stack-p))))

(defthm l0-stack-p-cons
  (implies (and (l0-printable-list-p d)
                (l0-stack-p stack))
           (l0-stack-p (cons d stack)))
  :hints (("Goal" :in-theory (enable l0-stack-p))))
