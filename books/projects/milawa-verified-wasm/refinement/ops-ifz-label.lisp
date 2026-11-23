; op_ifz's conditional label/frame lifts and call result.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-ifz-body")
(include-book "../wasm3/engine")

(defun milawa-state-pair-p (z)
  (and (consp z) (equal (car z) :|%;%|)
       (consp (cdr z)) (consp (cddr z)) (null (cdddr z))))

(defthm milawa-state-pair-p-is-we
  (equal (milawa-state-pair-p z) (we::state-shape-p z))
  :hints (("Goal" :in-theory (enable milawa-state-pair-p
                                    we::state-shape-p))))

(defthm ifz-not-exit-body
  (not (we::exit-body-p (ifz-body)))
  :hints (("Goal" :in-theory (enable we::exit-body-p))))

(defthm ifz-not-exit-body1
  (not (we::exit-body-p
        (list (list :const (list :i32) v2)
              (list :local.get 0)
              (list :testop (list :i32) (list :eqz))
              (list :binop (list :i32) (list :mul)))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                    we::vals-p
                                    we::exit-block-p
                                    we::exn-throw-p
                                    we::first-nonval
                                    we::exit-head-p))))

(defthm ifz-not-exit-body2
  (not (we::exit-body-p
        (list (list :const (list :i32) v2)
              (list :const (list :i32) v1)
              (list :testop (list :i32) (list :eqz))
              (list :binop (list :i32) (list :mul)))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                    we::vals-p
                                    we::exit-block-p
                                    we::exn-throw-p
                                    we::first-nonval
                                    we::exit-head-p))))

(defthm ifz-not-exit-body3
  (not (we::exit-body-p
        (list (list :const (list :i32) v2)
              (list :const (list :i32)
                    (if (equal v1 0) 1 0))
              (list :binop (list :i32) (list :mul)))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                    we::vals-p
                                    we::exit-block-p
                                    we::exn-throw-p
                                    we::first-nonval
                                    we::exit-head-p))))

(defthm label-not-exit-body
  (not (we::exit-body-p (list (list :label_%{%}% n x b))))
  :hints (("Goal" :in-theory (enable we::exit-body-p
                                    we::vals-p
                                    we::exit-block-p
                                    we::exn-throw-p
                                    we::first-nonval
                                    we::exit-head-p))))

(defthm ifz-label-step-cond
  (implies (and (true-listp b)
                (not (we::exit-body-p b))
                (equal inner
                       (w3t::step (list :|%;%| (list :|%;%| s f) b)))
                inner
                (milawa-state-pair-p (cadr (car inner))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (list (list :label_%{%}% 1 nil b))))
                  (list (list :|%;%| (cadr (car inner))
                              (list (list :label_%{%}% 1 nil
                                          (caddr (car inner))))))))
  :hints (("Goal"
           :in-theory (enable we::admin-term)
           :use ((:instance engine-admin-term-in-block
                            (k :l) (n 1) (x nil)
                            (b b) (r nil)
                            (s s) (f f)
                            (inner inner))))))

(defthm ifz-frame-step-cond
  (implies (and (not (we::exit-body-p (list (list :label_%{%}% 1 nil b))))
                (equal inner
                       (w3t::step
                        (list :|%;%| (list :|%;%| s f)
                              (list (list :label_%{%}% 1 nil b)))))
                inner
                (milawa-state-pair-p (cadr (car inner))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s outer)
                         (list (list :frame_%{%}% 1 f
                                     (list (list :label_%{%}% 1 nil b))))))
                  (list (list :|%;%|
                              (list :|%;%| (cadr (cadr (car inner))) outer)
                              (list (list :frame_%{%}% 1
                                          (caddr (cadr (car inner)))
                                          (caddr (car inner))))))))
  :hints (("Goal"
           :in-theory (enable we::admin-term)
           :use ((:instance engine-admin-term-in-block
                            (k :f) (n 1) (x f)
                            (b (list (list :label_%{%}% 1 nil b)))
                            (r nil)
                            (s s) (f outer)
                            (inner inner))
                 (:instance milawa-state-pair-p-is-we
                            (z (cadr (car inner))))))))

(defthm ifz-state-pair-z
  (milawa-state-pair-p (ifz-z v1 v2))
  :hints (("Goal" :in-theory (enable milawa-state-pair-p ifz-z))))

;; ---------------------------------------------------------------------------
;; The four body steps, lifted through the label and then the frame
;; ---------------------------------------------------------------------------

(defthm ifz-label-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil (ifz-body)))))
            (list
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list (list :const (list :i32) v2)
                                     (list :local.get 0)
                                     (list :testop (list :i32) (list :eqz))
                                     (list :binop (list :i32) (list :mul)))))))))
  :hints (("Goal"
           :use ((:instance ifz-label-step-cond
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (b (ifz-body))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :const (list :i32) v2)
                                     (list :local.get 0)
                                     (list :testop (list :i32) (list :eqz))
                                     (list :binop (list :i32)
                                           (list :mul)))))))
                 ifz-body-step1-specific
                 ifz-not-exit-body
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-frame-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (ifz-body)))))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :local.get 0)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))))
  :hints (("Goal"
           :use ((:instance ifz-frame-step-cond
                            (s *ir-store*)
                            (outer *ir-call-frame*)
                            (f (ifz-frame v1 v2))
                            (b (ifz-body))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :local.get 0)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
                 ifz-label-step1
                 label-not-exit-body
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-label-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32) v2)
                                (list :local.get 0)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul)))))))
            (list
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32) v1)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul)))))))))
  :hints (("Goal"
           :use ((:instance ifz-label-step-cond
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :local.get 0)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :const (list :i32) v2)
                                     (list :const (list :i32) v1)
                                     (list :testop (list :i32) (list :eqz))
                                     (list :binop (list :i32)
                                           (list :mul)))))))
                 ifz-body-step2
                 ifz-not-exit-body1
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-frame-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :local.get 0)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32) v1)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))))
  :hints (("Goal"
           :use ((:instance ifz-frame-step-cond
                            (s *ir-store*)
                            (outer *ir-call-frame*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :local.get 0)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32) v1)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
                 ifz-label-step2
                 label-not-exit-body
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-label-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32) v1)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul)))))))
            (list
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32)
                                      (if (equal v1 0) 1 0))
                                (list :binop (list :i32) (list :mul)))))))))
  :hints (("Goal"
           :use ((:instance ifz-label-step-cond
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32) v1)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :const (list :i32) v2)
                                     (list :const (list :i32)
                                           (if (equal v1 0) 1 0))
                                     (list :binop (list :i32)
                                           (list :mul)))))))
                 ifz-body-step3
                 ifz-not-exit-body2
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-frame-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32) v1)
                                            (list :testop (list :i32)
                                                  (list :eqz))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32)
                                                  (if (equal v1 0) 1 0))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))))
  :hints (("Goal"
           :use ((:instance ifz-frame-step-cond
                            (s *ir-store*)
                            (outer *ir-call-frame*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32) v1)
                                (list :testop (list :i32) (list :eqz))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32)
                                                  (if (equal v1 0) 1 0))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
                 ifz-label-step3
                 label-not-exit-body
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-label-step4
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32)
                                      (if (equal v1 0) 1 0))
                                (list :binop (list :i32) (list :mul)))))))
            (list
             (list :|%;%| (ifz-z v1 v2)
                   (list (list :label_%{%}% 1 nil
                               (list
                                (list :const (list :i32)
                                      (if (equal v1 0) v2 0)))))))))
  :hints (("Goal"
           :use ((:instance ifz-label-step-cond
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32)
                                      (if (equal v1 0) 1 0))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :const (list :i32)
                                           (if (equal v1 0) v2 0)))))))
                 ifz-body-step4
                 ifz-not-exit-body3
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-frame-step4
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32) v2)
                                            (list :const (list :i32)
                                                  (if (equal v1 0) 1 0))
                                            (list :binop (list :i32)
                                                  (list :mul)))))))))
            (list
             (list :|%;%|
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list (list :frame_%{%}% 1
                               (ifz-frame v1 v2)
                               (list (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32)
                                                  (if (equal v1 0)
                                                      v2 0)))))))))))
  :hints (("Goal"
           :use ((:instance ifz-frame-step-cond
                            (s *ir-store*)
                            (outer *ir-call-frame*)
                            (f (ifz-frame v1 v2))
                            (b (list
                                (list :const (list :i32) v2)
                                (list :const (list :i32)
                                      (if (equal v1 0) 1 0))
                                (list :binop (list :i32) (list :mul))))
                            (inner
                             (list
                              (list :|%;%| (ifz-z v1 v2)
                                    (list
                                     (list :label_%{%}% 1 nil
                                           (list
                                            (list :const (list :i32)
                                                  (if (equal v1 0)
                                                      v2 0)))))))))
                 ifz-label-step4
                 label-not-exit-body
                 ifz-state-pair-z)
           :in-theory (e/d (ifz-z) (ifz-frame)))))

(defthm ifz-value-ubp32
  (implies (unsigned-byte-p 32 v2)
           (unsigned-byte-p 32 (if (equal v1 0) v2 0)))
  :hints (("Goal" :in-theory (enable unsigned-byte-p)
                  :cases ((equal v1 0)))))

(defthm ifz-frame4-bridge
  (equal (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :frame_%{%}% 1
                           (ifz-frame v1 v2)
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32)
                                                   (if (equal v1 0)
                                                       v2 0))))))))
         (ir-label-vals-in-frame-cfg
          *ir-store* *ir-call-frame*
          (ifz-frame v1 v2)
          (if (equal v1 0) v2 0)))
  :hints (("Goal" :in-theory (enable ir-label-vals-in-frame-cfg))))

(defthm ifz-label-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (ir-label-vals-in-frame-cfg
                         *ir-store* *ir-call-frame*
                         (ifz-frame v1 v2)
                         (if (equal v1 0) v2 0))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (ifz-frame v1 v2)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg
                                      ir-frame-vals-cfg ir-value-cfg))))

(defthm ifz-frame-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (ir-frame-vals-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (ifz-frame v1 v2)
                         (if (equal v1 0) v2 0))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg
                                      ir-frame-vals-cfg ir-value-cfg))))

(defthm ifz-value2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (ir-label-vals-in-frame-cfg
                               *ir-store* *ir-call-frame*
                               (ifz-frame v1 v2)
                               (if (equal v1 0) v2 0))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg
                               ir-frame-vals-cfg ir-value-cfg)
           :use (ifz-label-dissolve ifz-frame-dissolve))))

(defthm ifz-body-outer4
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (ir-frame-ifz-cfg v1 v2)))))))))
                  (ir-label-vals-in-frame-cfg
                   *ir-store* *ir-call-frame*
                   (ifz-frame v1 v2)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal"
           :in-theory (e/d (ir-frame-ifz-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ifz-frame-step1 ifz-frame-step2 ifz-frame-step3
                 ifz-frame-step4 ifz-frame4-bridge))))

(defthm ir-op-ifz-body
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (car (w3t::step
                                                      (ir-frame-ifz-cfg v1 v2)))))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg
                               ir-frame-vals-cfg ir-value-cfg)
           :use (ifz-body-outer4 ifz-value2))))

(defthm ir-op-ifz-call-result
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (car (w3t::step
                                                      (car (w3t::step
                                                            (w3t::$invoke
                                                             *ir-store* 4
                                                             (list
                                                              (list :const (list :i32) v1)
                                                              (list :const (list :i32) v2)))))))))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (equal v1 0) v2 0))))
  :hints (("Goal"
           :in-theory (e/d (ir-op-ifz-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-ifz-invoke
                 ir-op-ifz-call-entry
                 ir-op-ifz-body))))
