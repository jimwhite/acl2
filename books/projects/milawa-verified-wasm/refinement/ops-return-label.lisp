; The exit body  ((const v) (return))  under a label:
; STEP of the label is the body, through the RETURN-LABEL rule.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "../wasm3/engine")
(include-book "../wasm-acl2/engine/rules/exits")

;; ---------------------------------------------------------------------------
;; VAL-P of a symbolic i32 constant, and MATCH135 of a one-value prefix.
;; ---------------------------------------------------------------------------

(defthm val-p-const-i32-equal
  (equal (w3t::val-p (list :const (list :i32) v))
         (w3t::un-p v 32))
  :hints (("Goal" :in-theory (enable w3t::val-p w3t::in-p w3t::un-p
                                     w3t::num_-p w3t::inn-p))))

(defthm match135-const
  (equal (w3t::step_pure/match135
          (list (list :const (list :i32) v)))
         (if (w3t::un-p v 32)
             (list (list (list (list :const (list :i32) v))))
           nil))
  :hints (("Goal" :in-theory (e/d (w3t::step_pure/match135
                                    w3t::val-p w3t::in-p)
                                   (w3t::un-p))
                  :cases ((w3t::un-p v 32)))))

(defthm match135-const-ubp
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v))))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/match135
                                     val-p-const-i32-equal
                                     w3t::un-p w3t::in-p))))

;; The label's body has a return, so MATCH30 (all values) fails at once.
(defthm match30-const-return-nil
  (equal (w3t::step_pure/match30
          (list (list :const (list :i32) v) (list :return)))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/match30))))

(defthm r-label-vals-const-return-nil
  (equal (w3t::step_pure/r-label-vals
          (list (list :label_%{%}% 0 nil
                      (list (list :const (list :i32) v)
                            (list :return)))))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-label-vals))))

;; The body has no BR, so the two BR-LABEL rules find a tag past the end.
(defthm search51-3-3-2-nil
  (equal (w3t::step_pure/search51
          3 3 2
          (list (list :const (list :i32) v) (list :return))
          0 nil)
         nil)
  :hints (("Goal" :expand ((w3t::step_pure/search51
                            3 3 2
                            (list (list :const (list :i32) v) (list :return))
                            0 nil)))))

(defthm search65-3-3-2-nil
  (equal (w3t::step_pure/search65
          3 3 2
          (list (list :const (list :i32) v) (list :return)))
         nil)
  :hints (("Goal" :expand ((w3t::step_pure/search65
                            3 3 2
                            (list (list :const (list :i32) v) (list :return)))))))

(defthm br-label-zero-const-return-nil
  (not (w3t::step_pure/r-br-label-zero
        (list (list :label_%{%}% 0 nil
                    (list (list :const (list :i32) v) (list :return))))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-br-label-zero
                                     wrt::%tag-lo wrt::%tag-lo1))))

(defthm br-label-succ-const-return-nil
  (not (w3t::step_pure/r-br-label-succ
        (list (list :label_%{%}% 0 nil
                    (list (list :const (list :i32) v) (list :return))))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-br-label-succ
                                     wrt::%tag-lo wrt::%tag-lo1))))

;; ---------------------------------------------------------------------------
;; SEARCH141 on  (const v) (return):  the value of MATCH135 of the prefix.
;; ---------------------------------------------------------------------------

(defthm search141-const-return-open
  (equal (w3t::step_pure/search141
          2 2 2
          (list (list :const (list :i32) v) (list :return)))
         (let ((m (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))))
           (and m
                (list (append (w3t::step_pure/iter140 (car (car m)))
                              (list (list :return)))))))
  :hints (("Goal"
           :expand ((w3t::step_pure/search141
                     2 2 2
                     (list (list :const (list :i32) v) (list :return)))
                    (w3t::step_pure/search141
                     3 2 2
                     (list (list :const (list :i32) v) (list :return))))
           :cases ((w3t::step_pure/match135
                    (list (list :const (list :i32) v))))
           :in-theory (e/d (w3t::step_pure/iter140)
                           (w3t::step_pure/match135 w3t::val-p))
           :do-not-induct t)))

(defthm search141-const-return
  (implies (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v)))))
           (equal (w3t::step_pure/search141
                   2 2 2
                   (list (list :const (list :i32) v) (list :return)))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :in-theory (e/d (search141-const-return-open
                            w3t::step_pure/iter140)
                           (w3t::step_pure/search141
                            w3t::step_pure/match135))
           :do-not-induct t)))

(defthm r-return-label-const-return
  (implies (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v)))))
           (equal (w3t::step_pure/r-return-label
                   (list (list :label_%{%}% 0 nil
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :in-theory (e/d (w3t::step_pure/r-return-label
                            search141-const-return
                            wrt::%tag-lo
                            wrt::%tag-lo1)
                           (w3t::step_pure/search141
                            w3t::step_pure/match135))
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; STEP-PURE and TRY-RULES at the label.
;;
;; The rules tried before RETURN-LABEL cannot fire on this body: LABEL-VALS
;; fails because the body has a RETURN, and the two BR-LABEL rules because
;; there is no BR.  Their nil lemmas above keep STEP-PURE's rule chain from
;; splitting on them.
;; ---------------------------------------------------------------------------

(defthm match135-const-fact
  (implies (w3t::un-p v 32)
           (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v))))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/match135
                                     val-p-const-i32-equal))))


(defthm step-pure-const-return
  (implies (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v)))))
           (equal (w3t::step_pure
                   (list (list :label_%{%}% 0 nil
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :expand ((w3t::step_pure
                     (list (list :label_%{%}% 0 nil
                                 (list (list :const (list :i32) v)
                                       (list :return))))))
           :in-theory (enable w3t::step_pure/r-if-true
                              w3t::step_pure/r-if-false
                              r-label-vals-const-return-nil
                              r-return-label-const-return)
           :do-not-induct t)))

(defthm try-rules-const-return-literal
  (implies (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v)))))
           (equal (we::try-rules
                   '(W3T::STEP_PURE/R-LABEL-VALS
                     W3T::STEP_PURE/R-BR-LABEL-ZERO
                     W3T::STEP_PURE/R-BR-LABEL-SUCC
                     W3T::STEP_PURE/R-RETURN-LABEL
                     W3T::STEP_PURE/R-TRAP-LABEL
                     W3T::STEP_READ/SPLIT/R-RETURN_CALL_REF-LABEL
                     W3T::STEP_READ/SPLIT/R-THROW_REF-LABEL)
                   z
                   (list (list :label_%{%}% 0 nil
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (mv t z (list (list :const (list :i32) v)
                                (list :return)))))
  :hints (("Goal"
           :use ((:instance we::try-rules-on-admin-term
                            (kw :label_%{%}%) (n 0) (x nil) (z z)
                            (b (list (list :const (list :i32) v)
                                     (list :return)))))
           :in-theory (e/d (step-pure-const-return
                            r-label-vals-const-return-nil)
                           (we::try-rules
                            we::try-rules-on-admin-term
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; The label's STEP, bare and with values before and a rest after.
;; ---------------------------------------------------------------------------

(defthm step-const-return
  (implies (equal (w3t::step_pure/match135
                   (list (list :const (list :i32) v)))
                  (list (list (list (list :const (list :i32) v)))))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 0 nil
                                     (list (list :const (list :i32) v)
                                           (list :return))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v)
                                    (list :return))))))
  :hints (("Goal"
           :use ((:instance we::step-of-admin-term-when-rule-fires
                            (kw :label_%{%}%) (n 0) (x nil) (z z)
                            (b (list (list :const (list :i32) v)
                                     (list :return)))
                            (tr (we::try-rules
                                 (we::rules-for (we::head-place :label_%{%}%))
                                 z
                                 (list (list :label_%{%}% 0 nil
                                             (list (list :const (list :i32) v)
                                                   (list :return))))))))
           :in-theory (e/d (try-rules-const-return-literal)
                           (we::try-rules
                            we::try-rules-on-admin-term
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

(defthm step-const-return-ubp
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 0 nil
                                     (list (list :const (list :i32) v)
                                           (list :return))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v)
                                    (list :return))))))
  :hints (("Goal"
           :use ((:instance step-const-return))
           :in-theory (e/d (match135-const-ubp)
                           (we::try-rules
                            we::try-rules-on-admin-term
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

(defthm step-const-return-rest
  (implies (and (equal (w3t::step_pure/match135
                        (list (list :const (list :i32) v)))
                       (list (list (list (list :const (list :i32) v)))))
                (we::vals-p vals)
                (true-listp r))
           (equal (w3t::step
                   (list :|%;%| z
                         (append vals
                                 (cons (list :label_%{%}% 0 nil
                                             (list (list :const (list :i32) v)
                                                   (list :return)))
                                       r))))
                  (list (list :|%;%| z
                              (append vals
                                      (append (list (list :const (list :i32) v)
                                                    (list :return))
                                              r))))))
  :hints (("Goal"
           :use ((:instance we::step-of-admin-term-in-block-when-rule-fires
                            (kw :label_%{%}%) (n 0) (x nil) (z z)
                            (v vals) (r r)
                            (b (list (list :const (list :i32) v)
                                     (list :return)))
                            (tr (we::try-rules
                                 (we::rules-for (we::head-place :label_%{%}%))
                                 z
                                 (list (list :label_%{%}% 0 nil
                                             (list (list :const (list :i32) v)
                                                   (list :return))))))))
           :in-theory (e/d (try-rules-const-return-literal)
                           (we::try-rules
                            we::try-rules-on-admin-term
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

(defthm step-const-return-rest-ubp
  (implies (and (unsigned-byte-p 32 v)
                (we::vals-p vals)
                (true-listp r))
           (equal (w3t::step
                   (list :|%;%| z
                         (append vals
                                 (cons (list :label_%{%}% 0 nil
                                             (list (list :const (list :i32) v)
                                                   (list :return)))
                                       r))))
                  (list (list :|%;%| z
                              (append vals
                                      (append (list (list :const (list :i32) v)
                                                    (list :return))
                                              r))))))
  :hints (("Goal"
           :use ((:instance step-const-return-rest))
           :in-theory (e/d (match135-const-ubp)
                           (we::try-rules
                            we::try-rules-on-admin-term
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

