; L0 inverse, list half, with an explicit context stack.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse-ctx")

;; ---------------------------------------------------------------------------
;; Atom in a context
;; ---------------------------------------------------------------------------

(defthm l0-read-sexp-atom-append-0
  (implies (and (l0-printable-atom-p x)
                (integerp fuel)
                (<= 20 fuel)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (equal (mv-nth 0
                          (l0-read-sexp
                           (append (l0-print-atom-chars x) suffix)
                           fuel nil))
                  x))
  :hints (("Goal" :use l0-read-sexp-atom-append
                  :in-theory (enable mv-nth))))

(defthm l0-read-sexp-atom-append-1
  (implies (and (l0-printable-atom-p x)
                (integerp fuel)
                (<= 20 fuel)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (equal (mv-nth 1
                          (l0-read-sexp
                           (append (l0-print-atom-chars x) suffix)
                           fuel nil))
                  suffix))
  :hints (("Goal" :use l0-read-sexp-atom-append
                  :in-theory (enable mv-nth))))

(defthm l0-read-sexp-atom-append-2
  (implies (and (l0-printable-atom-p x)
                (integerp fuel)
                (<= 20 fuel)
                (or (endp suffix)
                    (l0-delimiter-char-p (car suffix))))
           (equal (mv-nth 2
                          (l0-read-sexp
                           (append (l0-print-atom-chars x) suffix)
                           fuel nil))
                  nil))
  :hints (("Goal" :use l0-read-sexp-atom-append
                  :in-theory (enable mv-nth))))

(defthm positive-fuel-from-read-fuel
  (implies (and (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (< 0 fuel))
  :hints (("Goal" :use l0-read-fuel-positive))
  :rule-classes :forward-chaining)

;; ---------------------------------------------------------------------------
;; One-step list reader after a car
;; ---------------------------------------------------------------------------

(defthm l0-print-tail-first-not-dot-cons
  (implies (l0-printable-list-p x)
           (not (equal (car (l0-skip-whitespace
                             (append (l0-print-tail x)
                                     (cons *l0-rparen* suffix))))
                       *l0-dot*)))
  :hints (("Goal" :use ((:instance l0-print-tail-first-not-dot-context
                                   (x x) (suffix suffix))))))

(defthm l0-print-tail-consp-cons
  (implies (l0-printable-list-p x)
           (consp (l0-skip-whitespace
                   (append (l0-print-tail x)
                           (cons *l0-rparen* suffix)))))
  :hints (("Goal" :use ((:instance l0-print-tail-context-consp
                                   (x x) (suffix suffix))))))

(defthm l0-read-list-after-car-step
  (implies (and (l0-printable-value-p a)
                (l0-printable-list-p d)
                (not (zp fuel))
                (< 1 fuel)
                (equal (mv-nth 0
                               (l0-read-sexp
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       a)
                (equal (mv-nth 1
                               (l0-read-sexp
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       (append (l0-print-tail d)
                               (append (list *l0-rparen*)
                                       (l0-context stack suffix))))
                (equal (mv-nth 2
                               (l0-read-sexp
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       nil)
                (equal (mv-nth 0
                               (l0-read-list
                                (l0-skip-whitespace
                                 (append (l0-print-tail d)
                                         (append (list *l0-rparen*)
                                                 (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       d)
                (equal (mv-nth 1
                               (l0-read-list
                                (l0-skip-whitespace
                                 (append (l0-print-tail d)
                                         (append (list *l0-rparen*)
                                                 (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       (l0-context stack suffix))
                (equal (mv-nth 2
                               (l0-read-list
                                (l0-skip-whitespace
                                 (append (l0-print-tail d)
                                         (append (list *l0-rparen*)
                                                 (l0-context stack suffix))))
                                (1- (nfix fuel))
                                nil))
                       nil))
           (and (equal (mv-nth 0
                               (l0-read-list
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                fuel
                                nil))
                       (cons a d))
                (equal (mv-nth 1
                               (l0-read-list
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                fuel
                                nil))
                       (l0-context stack suffix))
                (equal (mv-nth 2
                               (l0-read-list
                                (append (l0-print-chars a)
                                        (append (l0-print-tail d)
                                                (append (list *l0-rparen*)
                                                        (l0-context stack suffix))))
                                fuel
                                nil))
                       nil)))
  :hints (("Goal" :do-not-induct t
                  :expand ((l0-read-list
                            (append (l0-print-chars a)
                                    (append (l0-print-tail d)
                                            (cons *l0-rparen*
                                                  (l0-context stack suffix))))
                            fuel nil))
                  :in-theory (e/d (l0-read-list
                                   l0-skip-whitespace-of-print-chars
                                   l0-print-chars-first-facts
                                   l0-print-tail-first-not-dot-context
                                   l0-print-tail-first-not-dot-cons
                                   l0-print-tail-context-consp
                                   l0-print-tail-consp-cons)
                                  (l0-read-sexp
                                   l0-print-chars
                                   l0-print-tail
                                   l0-print-atom-chars
                                   l0-printable-value-p
                                   l0-printable-list-p
                                   l0-context
                                   l0-read-fuel)))))

(defthm l0-read-fuel-at-least-20
  (<= 20 (l0-read-fuel x))
  :hints (("Goal" :in-theory (enable l0-read-fuel))))

(defthm more-than-one-fuel
  (implies (and (integerp fuel)
                (<= (l0-read-fuel x) fuel))
           (< 1 fuel))
  :hints (("Goal" :use l0-read-fuel-at-least-20))
  :rule-classes :forward-chaining)

(defun l0-inv-induct (x stack suffix fuel)
  (declare (xargs :measure (acl2-count x))
           (irrelevant stack suffix fuel))
  (if (consp x)
      (and (l0-inv-induct (car x)
                          (cons (cdr x) stack)
                          suffix
                          (1- (nfix fuel)))
           (l0-inv-induct (cdr x) stack suffix (1- (nfix fuel))))
    t))

(defthm l0-skip-whitespace-of-print-tail-cons
  (implies (and (consp x) (l0-printable-list-p x))
           (equal (l0-skip-whitespace
                   (append (l0-print-tail x) suffix))
                  (append (l0-print-chars (car x))
                          (append (l0-print-tail (cdr x)) suffix))))
  :hints (("Goal" :cases ((consp x))
                  :in-theory (enable l0-print-tail-cons
                                     l0-print-tail-nil
                                     l0-printable-list-p
                                     l0-skip-whitespace-of-space-print-chars
                                     l0-skip-whitespace))))

(defthm l0-read-inverse-stack
  (and
   ;; value, context stack ++ suffix
   (implies (and (l0-printable-value-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel)
                 (or (endp (l0-context stack suffix))
                     (l0-delimiter-char-p
                      (car (l0-context stack suffix)))))
            (equal (mv-nth 0
                           (l0-read-sexp
                            (append (l0-print-chars x)
                                    (l0-context stack suffix))
                            fuel nil))
                   x))
   (implies (and (l0-printable-value-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel)
                 (or (endp (l0-context stack suffix))
                     (l0-delimiter-char-p
                      (car (l0-context stack suffix)))))
            (equal (mv-nth 1
                           (l0-read-sexp
                            (append (l0-print-chars x)
                                    (l0-context stack suffix))
                            fuel nil))
                   (l0-context stack suffix)))
   (implies (and (l0-printable-value-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel)
                 (or (endp (l0-context stack suffix))
                     (l0-delimiter-char-p
                      (car (l0-context stack suffix)))))
            (equal (mv-nth 2
                           (l0-read-sexp
                            (append (l0-print-chars x)
                                    (l0-context stack suffix))
                            fuel nil))
                   nil))
   ;; list tail, including its closing parenthesis
   (implies (and (l0-printable-list-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel))
            (equal (mv-nth 0
                           (l0-read-list
                            (l0-skip-whitespace
                             (append (l0-print-tail x)
                                     (append (list *l0-rparen*)
                                             (l0-context stack suffix))))
                            fuel nil))
                   x))
   (implies (and (l0-printable-list-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel))
            (equal (mv-nth 1
                           (l0-read-list
                            (l0-skip-whitespace
                             (append (l0-print-tail x)
                                     (append (list *l0-rparen*)
                                             (l0-context stack suffix))))
                            fuel nil))
                   (l0-context stack suffix)))
   (implies (and (l0-printable-list-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel))
            (equal (mv-nth 2
                           (l0-read-list
                            (l0-skip-whitespace
                             (append (l0-print-tail x)
                                     (append (list *l0-rparen*)
                                             (l0-context stack suffix))))
                            fuel nil))
                   nil)))
  :hints (("Goal" :induct (l0-inv-induct x stack suffix fuel)
                  :do-not (quote (generalize eliminate-destructors))
                  :in-theory (disable l0-read-sexp
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
                                      l0-skip-whitespace
                                      l0-stack-p
                                      l0-delimiter-char-p
                                      l0-whitespace-char-p
                                      l0-read-fuel))))
