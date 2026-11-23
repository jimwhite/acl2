(in-package "MILAWA-WASM")
(include-book "ops-return-label")
(include-book "ops-dispatch-tail")
(include-book "../wasm3/engine")

(defun no-tag-p (tag s)
  (if (atom s)
      t
    (and (not (and (consp (car s)) (eq (car (car s)) tag)))
         (no-tag-p tag (cdr s)))))

(defun no-br-p (s) (no-tag-p :br s))

(defthm %tag-lo1-when-no-tag
  (implies (no-tag-p tag s)
           (equal (wrt::%tag-lo1 tag off s i)
                  (+ 1 i (len s))))
  :hints (("Goal" :induct (wrt::%tag-lo1 tag off s i)
                  :in-theory (enable no-tag-p wrt::%tag-lo1))))

(defthm %tag-lo-when-no-tag
  (implies (no-tag-p tag s)
           (equal (wrt::%tag-lo tag off s)
                  (+ 1 (len s))))
  :hints (("Goal" :in-theory (enable wrt::%tag-lo))))

(defthm search51-k-gt-hi-nil
  (implies (< hi k)
           (equal (w3t::step_pure/search51 k lo hi l n instrs)
                  nil))
  :hints (("Goal" :expand ((w3t::step_pure/search51 k lo hi l n instrs))
                  :do-not-induct t)))

(defthm search65-k-gt-hi-nil
  (implies (< hi k)
           (equal (w3t::step_pure/search65 k lo hi l)
                  nil))
  :hints (("Goal" :expand ((w3t::step_pure/search65 k lo hi l))
                  :do-not-induct t)))

(defthm br-label-zero-nil-when-no-br
  (implies (no-br-p body)
           (not (w3t::step_pure/r-br-label-zero
                 (list (list :label_%{%}% n nil body)))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-br-label-zero
                                     wrt::%tag-lo)
                  :do-not-induct t)))

(defthm br-label-succ-nil-when-no-br
  (implies (no-br-p body)
           (not (w3t::step_pure/r-br-label-succ
                 (list (list :label_%{%}% n nil body)))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-br-label-succ
                                     wrt::%tag-lo)
                  :do-not-induct t)))

(defthm un-p-implies-ubp
  (implies (w3t::un-p v 32)
           (unsigned-byte-p 32 v))
  :hints (("Goal" :in-theory (enable w3t::un-p))))

(defthm search141-const-return-suffix
  (implies (and (unsigned-byte-p 32 v) (true-listp suffix))
           (equal (w3t::step_pure/search141
                   2 2
                   (+ 2 (len suffix))
                   (cons (list :const (list :i32) v)
                         (cons (list :return) suffix)))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :expand ((w3t::step_pure/search141
                     2 2
                     (+ 2 (len suffix))
                     (cons (list :const (list :i32) v)
                           (cons (list :return) suffix))))
           :in-theory (e/d (w3t::step_pure/iter140
                            match135-const-ubp)
                           (w3t::step_pure/search141
                            w3t::step_pure/match135))
           :do-not-induct t)))

(defthm return-label-const-return-suffix
  (implies (and (unsigned-byte-p 32 v) (true-listp suffix))
           (equal (w3t::step_pure/r-return-label
                   (list (list :label_%{%}% n nil
                               (cons (list :const (list :i32) v)
                                     (cons (list :return) suffix)))))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :in-theory (e/d (w3t::step_pure/r-return-label
                            wrt::%tag-lo wrt::%tag-lo1
                            search141-const-return-suffix)
                           (w3t::step_pure/search141
                            w3t::step_pure/match135))
           :do-not-induct t)))

(defthm match30-return-cons-nil
  (equal (w3t::step_pure/match30 (cons (list :return) suffix))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/match30))))

(defthm match30-const-return-suffix-nil
  (equal (w3t::step_pure/match30
          (cons (list :const (list :i32) v)
                (cons (list :return) suffix)))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/match30))))

(defthm r-label-vals-const-return-suffix-nil
  (equal (w3t::step_pure/r-label-vals
          (list (list :label_%{%}% n nil
                      (cons (list :const (list :i32) v)
                            (cons (list :return) suffix)))))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-label-vals))))

(defthm step-pure-label-suffix
  (implies (and (unsigned-byte-p 32 v)
                (true-listp suffix)
                (no-br-p suffix))
           (equal (w3t::step_pure
                   (list (list :label_%{%}% n nil
                               (cons (list :const (list :i32) v)
                                     (cons (list :return) suffix)))))
                  (list (list (list :const (list :i32) v)
                              (list :return)))))
  :hints (("Goal"
           :in-theory (e/d (w3t::step_pure
                            w3t::step_pure/r-if-true
                            w3t::step_pure/r-if-false
                            r-label-vals-const-return-suffix-nil
                            return-label-const-return-suffix
                            wrt::%tag-lo wrt::%tag-lo1)
                           (we::step_pure-of-redex-label_%{%}%
                            we::redex-shape-p-of-one-term))
           :do-not-induct t)))

(defthm try-rules-label-when-step-pure
  (implies (equal (w3t::step_pure
                   (list (list :label_%{%}% n nil b)))
                  (list body0))
           (equal (we::try-rules
                   (we::rules-for (we::head-place :label_%{%}%)) z
                   (list (list :label_%{%}% n nil b)))
                  (mv t z body0)))
  :hints (("Goal"
           :in-theory (e/d (we::try-rules-on-admin-term)
                           (we::try-rules
                            (:e we::rules-for)
                            (:e we::head-place)
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

(defthm try-rules-label-suffix
  (implies (and (unsigned-byte-p 32 v)
                (true-listp suffix)
                (no-br-p suffix))
           (equal (we::try-rules
                   (we::rules-for (we::head-place :label_%{%}%)) z
                   (list (list :label_%{%}% n nil
                               (cons (list :const (list :i32) v)
                                     (cons (list :return) suffix)))))
                  (mv t z (list (list :const (list :i32) v)
                                (list :return)))))
  :hints (("Goal"
           :cases ((equal (w3t::step_pure
                           (list (list :label_%{%}% n nil
                                       (cons (list :const (list :i32) v)
                                             (cons (list :return) suffix)))))
                          (list (list (list :const (list :i32) v)
                                      (list :return)))))
           :use ((:instance step-pure-label-suffix)
                 (:instance try-rules-label-when-step-pure
                            (b (cons (list :const (list :i32) v)
                                     (cons (list :return) suffix)))
                            (body0 (list (list :const (list :i32) v)
                                         (list :return)))))
           :in-theory (disable we::try-rules
                               (:e we::rules-for)
                               (:e we::head-place)
                               we::step_pure-of-redex-label_%{%}%)
           :do-not-induct t)))

(defthm step-label-suffix
  (implies (and (unsigned-byte-p 32 v)
                (true-listp suffix)
                (no-br-p suffix))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% n nil
                                     (cons (list :const (list :i32) v)
                                           (cons (list :return) suffix))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v)
                                    (list :return))))))
  :hints (("Goal"
           :cases ((equal (we::try-rules
                           (we::rules-for (we::head-place :label_%{%}%))
                           z
                           (list (list :label_%{%}% n nil
                                       (cons (list :const (list :i32) v)
                                             (cons (list :return) suffix)))))
                          (mv t z (list (list :const (list :i32) v)
                                        (list :return)))))
           :use ((:instance we::step-of-admin-term-when-rule-fires
                            (kw :label_%{%}%) (n n) (x nil) (z z)
                            (b (cons (list :const (list :i32) v)
                                     (cons (list :return) suffix)))
                            (tr (we::try-rules
                                 (we::rules-for (we::head-place :label_%{%}%))
                                 z
                                 (list (list :label_%{%}% n nil
                                             (cons (list :const (list :i32) v)
                                                   (cons (list :return) suffix)))))))
                 (:instance try-rules-label-suffix))
           :in-theory (disable we::try-rules
                               (:e we::rules-for)
                               (:e we::head-place)
                               we::step_pure-of-redex-label_%{%}%)
           :do-not-induct t)))

(defthm no-br-p-append
  (implies (and (no-br-p a) (no-br-p b))
           (no-br-p (append a b)))
  :hints (("Goal" :induct (append a b)
                  :in-theory (enable no-br-p append))))

(defthm no-br-p-dispatch-branch
  (no-br-p (dispatch-branch j))
  :hints (("Goal" :in-theory (enable dispatch-branch no-br-p))))

(defthm no-br-p-dispatch-cmp
  (no-br-p (dispatch-cmp j))
  :hints (("Goal" :in-theory (enable dispatch-cmp no-br-p))))

(defthm no-br-p-dispatch-body-from
  (no-br-p (dispatch-body-from j))
  :hints (("Goal" :induct (dispatch-body-from j)
                  :in-theory (enable dispatch-body-from no-br-p-append))))

(defthm no-br-p-dispatch-tail
  (no-br-p (dispatch-tail j))
  :hints (("Goal" :in-theory (enable dispatch-tail))))

(defthm step-function-label-tail
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 1 nil
                                     (cons (list :const (list :i32) v)
                                           (cons (list :return)
                                                 (dispatch-tail j)))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v)
                                    (list :return))))))
  :hints (("Goal"
           :use ((:instance step-label-suffix
                            (n 1) (suffix (dispatch-tail j))))
           :in-theory (enable no-br-p-dispatch-tail
                              true-listp-dispatch-tail)
           :do-not-induct t)))

(defthm match107-const-return-nil
  (equal (w3t::step_pure/match107
          (list (list :const (list :i32) v) (list :return)))
         nil)
  :hints (("Goal" :in-theory (enable w3t::step_pure/match107))))

(defthm r-frame-vals-const-return-nil
  (not (w3t::step_pure/r-frame-vals
        (list (list :frame_%{%}% 1 f
                    (list (list :const (list :i32) v)
                          (list :return))))))
  :hints (("Goal" :in-theory (enable w3t::step_pure/r-frame-vals))))

(defthm search127-const-return
  (implies (w3t::un-p v 32)
           (equal (w3t::step_pure/search127
                   2 2 2
                   (list (list :const (list :i32) v) (list :return))
                   1)
                  (list (list (list :const (list :i32) v)))))
  :hints (("Goal"
           :expand ((w3t::step_pure/search127
                     2 2 2
                     (list (list :const (list :i32) v) (list :return))
                     1))
           :in-theory (enable w3t::step_pure/match117
                              w3t::step_pure/match121
                              w3t::step_pure/iter126
                              val-p-const-i32-equal)
           :do-not-induct t)))

(defthm return-frame-const-return
  (implies (w3t::un-p v 32)
           (equal (w3t::step_pure/r-return-frame
                   (list (list :frame_%{%}% 1 f
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (list (list (list :const (list :i32) v)))))
  :hints (("Goal"
           :in-theory (e/d (w3t::step_pure/r-return-frame
                            wrt::%tag-lo wrt::%tag-lo1
                            search127-const-return)
                           (w3t::step_pure/search127))
           :do-not-induct t)))

(defthm step-pure-frame-return
  (implies (w3t::un-p v 32)
           (equal (w3t::step_pure
                   (list (list :frame_%{%}% 1 f
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (list (list (list :const (list :i32) v)))))
  :hints (("Goal"
           :in-theory (e/d (w3t::step_pure
                            r-frame-vals-const-return-nil
                            return-frame-const-return)
                           (we::step_pure-of-redex-label_%{%}%
                            we::redex-shape-p-of-one-term))
           :do-not-induct t)))

(defthm try-rules-frame-when-step-pure
  (implies (equal (w3t::step_pure
                   (list (list :frame_%{%}% 1 f b)))
                  (list body0))
           (equal (we::try-rules
                   (we::rules-for (we::head-place :frame_%{%}%)) z
                   (list (list :frame_%{%}% 1 f b)))
                  (mv t z body0)))
  :hints (("Goal"
           :in-theory (e/d (we::try-rules-on-admin-term)
                           (we::try-rules
                            (:e we::rules-for)
                            (:e we::head-place)
                            we::step_pure-of-redex-label_%{%}%))
           :do-not-induct t)))

(defthm try-rules-frame-return
  (implies (w3t::un-p v 32)
           (equal (we::try-rules
                   (we::rules-for (we::head-place :frame_%{%}%)) z
                   (list (list :frame_%{%}% 1 f
                               (list (list :const (list :i32) v)
                                     (list :return)))))
                  (mv t z (list (list :const (list :i32) v)))))
  :hints (("Goal"
           :cases ((equal (w3t::step_pure
                           (list (list :frame_%{%}% 1 f
                                       (list (list :const (list :i32) v)
                                             (list :return)))))
                          (list (list (list :const (list :i32) v)))))
           :use ((:instance step-pure-frame-return)
                 (:instance try-rules-frame-when-step-pure
                            (b (list (list :const (list :i32) v)
                                     (list :return)))
                            (body0 (list (list :const (list :i32) v)))))
           :in-theory (disable we::try-rules
                               (:e we::rules-for)
                               (:e we::head-place)
                               we::step_pure-of-redex-label_%{%}%)
           :do-not-induct t)))

(defthm step-frame-return
  (implies (w3t::un-p v 32)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :frame_%{%}% 1 f
                                     (list (list :const (list :i32) v)
                                           (list :return))))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v))))))
  :hints (("Goal"
           :cases ((equal (we::try-rules
                           (we::rules-for (we::head-place :frame_%{%}%)) z
                           (list (list :frame_%{%}% 1 f
                                       (list (list :const (list :i32) v)
                                             (list :return)))))
                          (mv t z (list (list :const (list :i32) v)))))
           :use ((:instance we::step-of-admin-term-when-rule-fires
                            (kw :frame_%{%}%) (n 1) (x f) (z z)
                            (b (list (list :const (list :i32) v)
                                     (list :return)))
                            (tr (we::try-rules
                                 (we::rules-for (we::head-place :frame_%{%}%))
                                 z
                                 (list (list :frame_%{%}% 1 f
                                             (list (list :const (list :i32) v)
                                                   (list :return)))))))
                 (:instance try-rules-frame-return))
           :in-theory (disable we::try-rules
                               (:e we::rules-for)
                               (:e we::head-place)
                               we::step_pure-of-redex-label_%{%}%)
           :do-not-induct t)))

(defthm not-exit-body-p-label
  (not (we::exit-body-p (list (list :label_%{%}% n x b))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::exit-head-p
                                     we::first-nonval))))

(defthm frame-label-step-of-body
  (implies (and (true-listp body)
                (not (we::exit-body-p body))
                (equal inner (w3t::step (list :|%;%| (list :|%;%| s f) body)))
                inner
                (equal (cadr (car inner)) (list :|%;%| s f))
                (we::state-shape-p (cadr (car inner))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (list (list :frame_%{%}% 1 f
                                     (list (list :label_%{%}% 1 nil body))))))
                  (list (list :|%;%|
                              (list :|%;%| s f)
                              (list (list :frame_%{%}% 1 f
                                          (list (list :label_%{%}% 1 nil
                                                      (caddr (car inner))))))))))
  :hints (("Goal"
           :use ((:instance engine-admin-term-in-block
                            (k :l) (n 1) (x nil) (b body) (r nil)
                            (s s) (f f) (inner inner))
                 (:instance engine-admin-term-in-block
                            (k :f) (n 1) (x f)
                            (b (list (list :label_%{%}% 1 nil body)))
                            (r nil) (s s) (f f)
                            (inner (list (list :|%;%|
                                               (cadr (car inner))
                                               (list (list :label_%{%}% 1 nil
                                                           (caddr (car inner)))))))))
           :in-theory (disable w3t::step)
           :do-not-induct t)))

(defthm frame-label-step-of-body-x
  (implies (and (true-listp body)
                (not (we::exit-body-p body))
                (equal inner
                       (w3t::step
                        (list :|%;%| (list :|%;%| s x) body)))
                inner
                (equal (cadr (car inner)) (list :|%;%| s x))
                (we::state-shape-p (cadr (car inner))))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| s f)
                   (list (list :frame_%{%}% 1 x
                               (list (list :label_%{%}% 1 nil body))))))
            (list
             (list :|%;%| (list :|%;%| s f)
                   (list (list :frame_%{%}% 1 x
                               (list (list :label_%{%}% 1 nil
                                           (caddr (car inner))))))))))
  :hints (("Goal"
           :use ((:instance engine-admin-term-in-block
                            (k :l) (n 1) (x nil) (b body) (r nil)
                            (s s) (f x) (inner inner))
                 (:instance engine-admin-term-in-block
                            (k :f) (n 1) (x x)
                            (b (list (list :label_%{%}% 1 nil body)))
                            (r nil) (s s) (f f)
                            (inner (list (list :|%;%|
                                               (cadr (car inner))
                                               (list (list :label_%{%}% 1 nil
                                                           (caddr (car inner)))))))))
           :in-theory (disable w3t::step)
           :do-not-induct t)))
