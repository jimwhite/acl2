; op_sub's conditional label/frame admin lifts.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-sub-body")
(include-book "../wasm3/engine")

(defun milawa-state-pair-p (z)
  (and (consp z) (equal (car z) :|%;%|)
       (consp (cdr z)) (consp (cddr z)) (null (cdddr z))))

(encapsulate ()
  (local
   (defthm milawa-state-pair-p-is-we
     (equal (milawa-state-pair-p z) (we::state-shape-p z))
     :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                       we::state-shape-p)))))

  (local
   (defthm sub-not-exit-body
     (not (we::exit-body-p (sub-body)))
     :hints (("Goal" :in-theory (enable we::exit-body-p)))))

  (local
   (defthm sub-not-exit-body1
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :local.get 1)
                 (list :binop (list :i32) (list :sub)))))
     :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::vals-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::first-nonval
                                     we::exit-head-p)))))

  (local
   (defthm sub-not-exit-body2
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :const (list :i32) v2)
                 (list :binop (list :i32) (list :sub)))))
     :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::vals-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::first-nonval
                                     we::exit-head-p)))))

  (local
   (defthm label-not-exit-body
     (not (we::exit-body-p (list (list :label_%{%}% n x b))))
     :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::vals-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::first-nonval
                                     we::exit-head-p)))))

  (defthm sub-label-step1-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (sub-body))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (sub-body)))))
                    (list (list :|%;%|
                                (cadr (car inner))
                                (list (list :label_%{%}% 1 nil
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil)
                              (b (sub-body)) (r nil)
                              (s *ir-store*)
                              (f (sub-frame v1 v2))
                              (inner inner))))))

  (defthm sub-label-step2-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :local.get 1)
                                      (list :binop (list :i32)
                                            (list :sub))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :local.get 1)
                                             (list :binop (list :i32)
                                                   (list :sub)))))))
                    (list (list :|%;%|
                                (cadr (car inner))
                                (list (list :label_%{%}% 1 nil
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil)
                              (b (list (list :const (list :i32) v1)
                                       (list :local.get 1)
                                       (list :binop (list :i32)
                                             (list :sub))))
                              (r nil)
                              (s *ir-store*)
                              (f (sub-frame v1 v2))
                              (inner inner))))))

  (defthm sub-label-step3-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)
                                      (list :binop (list :i32)
                                            (list :sub))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :const (list :i32) v2)
                                             (list :binop (list :i32)
                                                   (list :sub)))))))
                    (list (list :|%;%|
                                (cadr (car inner))
                                (list (list :label_%{%}% 1 nil
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil)
                              (b (list (list :const (list :i32) v1)
                                       (list :const (list :i32) v2)
                                       (list :binop (list :i32)
                                             (list :sub))))
                              (r nil)
                              (s *ir-store*)
                              (f (sub-frame v1 v2))
                              (inner inner))))))

  (defthm sub-frame-step1-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (sub-body))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (sub-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (sub-body)))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (sub-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (sub-body))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm sub-frame-step2-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :local.get 1)
                                                  (list :binop (list :i32)
                                                        (list :sub))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (sub-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :local.get 1)
                                                         (list :binop (list :i32)
                                                               (list :sub)))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (sub-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :local.get 1)
                                                   (list :binop (list :i32)
                                                         (list :sub))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm sub-frame-step3-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :const (list :i32) v2)
                                                  (list :binop (list :i32)
                                                        (list :sub))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (sub-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :const (list :i32) v2)
                                                         (list :binop (list :i32)
                                                               (list :sub)))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (sub-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :const (list :i32) v2)
                                                   (list :binop (list :i32)
                                                         (list :sub))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner)))))))
  

(defthm sub-state-pair-z
  (milawa-state-pair-p
   (list :|%;%| *ir-store* (sub-frame v1 v2)))
  :hints (("Goal" :in-theory (enable milawa-state-pair-p))))

(defthm z-of-inner-list
  (equal (cadr (car (list (list :|%;%| z b)))) z))

(defthm body-of-inner-list
  (equal (caddr (car (list (list :|%;%| z b)))) b))

(defthm z-of-label-result
  (equal (cadr (cadr (car (list (list :|%;%|
                                           (list :|%;%| s f) b)))))
         s))

(defthm f-of-label-result
  (equal (caddr (cadr (car (list (list :|%;%|
                                            (list :|%;%| s f) b)))))
         f))

(defthm body-of-label-result
  (equal (caddr (car (list (list :|%;%|
                                        (list :|%;%| s f) b))))
         b))

(defthm label-result-extract
  (equal (list
          (list :|%;%|
                (cadr (car (list (list :|%;%| z b))))
                (list (list :label_%{%}% 1 nil
                            (caddr (car (list (list :|%;%| z b))))))))
         (list
          (list :|%;%| z
                (list (list :label_%{%}% 1 nil b))))))

(defthm sub-label-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :label_%{%}% 1 nil (sub-body)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :local.get 1)
                                                (list :binop (list :i32)
                                                      (list :sub)))))))))
  :hints (("Goal"
           :use ((:instance sub-label-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :local.get 1)
                                               (list :binop (list :i32)
                                                     (list :sub)))))))
                 sub-body-step1-specific
                 sub-state-pair-z)
           :in-theory (e/d (sub-body-step1-specific
                            sub-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (sub-frame)))))


(defthm sub-label-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :local.get 1)
                                           (list :binop (list :i32)
                                                 (list :sub)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :const (list :i32) v2)
                                                (list :binop (list :i32)
                                                      (list :sub)))))))))
  :hints (("Goal"
           :use ((:instance sub-label-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :const (list :i32) v2)
                                               (list :binop (list :i32)
                                                     (list :sub)))))))
                 sub-body-step2
                 sub-state-pair-z)
           :in-theory (e/d (sub-body-step2
                            sub-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (sub-frame)))))

(defthm sub-label-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :const (list :i32) v2)
                                           (list :binop (list :i32)
                                                 (list :sub)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32)
                                                      (loghead 32 (- v1 v2))))))))))
  :hints (("Goal"
           :use ((:instance sub-label-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :const (list :i32)
                                                     (loghead 32 (- v1 v2))))))))
                 sub-innerbin-explicit
                 sub-state-pair-z)
           :in-theory (e/d (sub-innerbin-explicit
                            sub-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (sub-frame)))))

(defthm sub-frame-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (sub-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (sub-body)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (sub-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :local.get 1)
                                                            (list :binop (list :i32)
                                                                  (list :sub)))))))))))
  :hints (("Goal"
           :use ((:instance sub-frame-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :local.get 1)
                                                           (list :binop (list :i32)
                                                                 (list :sub)))))))))
                 sub-label-step1
                 sub-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (sub-frame)))))

(defthm sub-frame-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (sub-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :local.get 1)
                                                       (list :binop (list :i32)
                                                             (list :sub)))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (sub-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :const (list :i32) v2)
                                                            (list :binop (list :i32)
                                                                  (list :sub)))))))))))
  :hints (("Goal"
           :use ((:instance sub-frame-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :const (list :i32) v2)
                                                           (list :binop (list :i32)
                                                                 (list :sub)))))))))
                 sub-label-step2
                 sub-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (sub-frame)))))

(defthm sub-frame-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (sub-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :const (list :i32) v2)
                                                       (list :binop (list :i32)
                                                             (list :sub)))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (sub-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32)
                                                                  (loghead 32 (- v1 v2))))))))))))
  :hints (("Goal"
           :use ((:instance sub-frame-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32)
                                                                 (loghead 32 (- v1 v2))))))))))
                 sub-label-step3
                 sub-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (sub-frame)))))

(defthm sub-frame3-bridge
  (equal (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :frame_%{%}% 1
                           (sub-frame v1 v2)
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32)
                                                   (loghead 32 (- v1 v2)))))))))
         (ir-label-vals-in-frame-cfg
          *ir-store* *ir-call-frame*
          (sub-frame v1 v2)
          (loghead 32 (- v1 v2))))
  :hints (("Goal" :in-theory (enable ir-label-vals-in-frame-cfg))))

(defthm sub-label-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (ir-label-vals-in-frame-cfg
                         *ir-store* *ir-call-frame*
                         (sub-frame v1 v2)
                         (loghead 32 (- v1 v2)))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (sub-frame v1 v2)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm sub-frame-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (ir-frame-vals-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (sub-frame v1 v2)
                         (loghead 32 (- v1 v2)))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm sub-value2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (ir-label-vals-in-frame-cfg
                               *ir-store* *ir-call-frame*
                               (sub-frame v1 v2)
                               (loghead 32 (- v1 v2)))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (sub-label-dissolve sub-frame-dissolve))))

(defthm sub-body-outer3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (ir-frame-sub-cfg v1 v2)))))))
                  (ir-label-vals-in-frame-cfg
                   *ir-store* *ir-call-frame*
                   (sub-frame v1 v2)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal"
           :in-theory (e/d (ir-frame-sub-cfg sub-frame sub-body)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (sub-frame-step1 sub-frame-step2 sub-frame-step3
                 sub-frame3-bridge))))

(defthm ir-op-sub-body
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (ir-frame-sub-cfg v1 v2)))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (sub-body-outer3 sub-value2))))

(defthm ir-op-sub-call-result
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (- v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (car (w3t::step
                                                      (w3t::$invoke
                                                       *ir-store* 2
                                                       (list
                                                        (list :const (list :i32) v1)
                                                        (list :const (list :i32) v2)))))))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (- v1 v2)))))
  :hints (("Goal"
           :in-theory (e/d (ir-op-sub-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-sub-invoke
                 ir-op-sub-call-entry
                 ir-op-sub-body))))
