; op_add's conditional label/frame admin lifts.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-add")
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
   (defthm add-not-exit-body
     (not (we::exit-body-p (add-body)))
     :hints (("Goal" :in-theory (enable we::exit-body-p)))))

  (local
   (defthm add-not-exit-body1
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :local.get 1)
                 (list :binop (list :i32) (list :add)))))
     :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::vals-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::first-nonval
                                     we::exit-head-p)))))

  (local
   (defthm add-not-exit-body2
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :const (list :i32) v2)
                 (list :binop (list :i32) (list :add)))))
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

  (defthm add-label-step1-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (add-body))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (add-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (add-body)))))
                    (list (list :|%;%|
                                (cadr (car inner))
                                (list (list :label_%{%}% 1 nil
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil)
                              (b (add-body)) (r nil)
                              (s *ir-store*)
                              (f (add-frame v1 v2))
                              (inner inner))))))

  (defthm add-label-step2-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :local.get 1)
                                      (list :binop (list :i32)
                                            (list :add))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (add-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :local.get 1)
                                             (list :binop (list :i32)
                                                   (list :add)))))))
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
                                             (list :add))))
                              (r nil)
                              (s *ir-store*)
                              (f (add-frame v1 v2))
                              (inner inner))))))

  (defthm add-label-step3-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)
                                      (list :binop (list :i32)
                                            (list :add))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (add-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :const (list :i32) v2)
                                             (list :binop (list :i32)
                                                   (list :add)))))))
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
                                             (list :add))))
                              (r nil)
                              (s *ir-store*)
                              (f (add-frame v1 v2))
                              (inner inner))))))

  (defthm add-frame-step1-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (add-body))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (add-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (add-body)))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (add-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (add-body))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm add-frame-step2-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :local.get 1)
                                                  (list :binop (list :i32)
                                                        (list :add))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (add-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :local.get 1)
                                                         (list :binop (list :i32)
                                                               (list :add)))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (add-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :local.get 1)
                                                   (list :binop (list :i32)
                                                         (list :add))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm add-frame-step3-cond
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :const (list :i32) v2)
                                                  (list :binop (list :i32)
                                                        (list :add))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (add-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :const (list :i32) v2)
                                                         (list :binop (list :i32)
                                                               (list :add)))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (add-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :const (list :i32) v2)
                                                   (list :binop (list :i32)
                                                         (list :add))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner)))))))
  

(defthm add-state-pair-z
  (milawa-state-pair-p
   (list :|%;%| *ir-store* (add-frame v1 v2)))
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

(defthm add-label-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (add-frame v1 v2))
                         (list (list :label_%{%}% 1 nil (add-body)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (add-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :local.get 1)
                                                (list :binop (list :i32)
                                                      (list :add)))))))))
  :hints (("Goal"
           :use ((:instance add-label-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :local.get 1)
                                               (list :binop (list :i32)
                                                     (list :add)))))))
                 add-body-step1-specific
                 add-state-pair-z)
           :in-theory (e/d (add-body-step1-specific
                            add-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (add-frame)))))


(defthm add-label-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (add-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :local.get 1)
                                           (list :binop (list :i32)
                                                 (list :add)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (add-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :const (list :i32) v2)
                                                (list :binop (list :i32)
                                                      (list :add)))))))))
  :hints (("Goal"
           :use ((:instance add-label-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :const (list :i32) v2)
                                               (list :binop (list :i32)
                                                     (list :add)))))))
                 add-body-step2
                 add-state-pair-z)
           :in-theory (e/d (add-body-step2
                            add-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (add-frame)))))

(defthm add-label-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (add-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :const (list :i32) v2)
                                           (list :binop (list :i32)
                                                 (list :add)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (add-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32)
                                                      (loghead 32 (+ v1 v2))))))))))
  :hints (("Goal"
           :use ((:instance add-label-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :const (list :i32)
                                                     (loghead 32 (+ v1 v2))))))))
                 add-innerbin-explicit
                 add-state-pair-z)
           :in-theory (e/d (add-innerbin-explicit
                            add-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (add-frame)))))

(defthm add-frame-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (add-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (add-body)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (add-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :local.get 1)
                                                            (list :binop (list :i32)
                                                                  (list :add)))))))))))
  :hints (("Goal"
           :use ((:instance add-frame-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :local.get 1)
                                                           (list :binop (list :i32)
                                                                 (list :add)))))))))
                 add-label-step1
                 add-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (add-frame)))))

(defthm add-frame-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (add-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :local.get 1)
                                                       (list :binop (list :i32)
                                                             (list :add)))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (add-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :const (list :i32) v2)
                                                            (list :binop (list :i32)
                                                                  (list :add)))))))))))
  :hints (("Goal"
           :use ((:instance add-frame-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :const (list :i32) v2)
                                                           (list :binop (list :i32)
                                                                 (list :add)))))))))
                 add-label-step2
                 add-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (add-frame)))))

(defthm add-frame-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (add-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :const (list :i32) v2)
                                                       (list :binop (list :i32)
                                                             (list :add)))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (add-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32)
                                                                  (loghead 32 (+ v1 v2))))))))))))
  :hints (("Goal"
           :use ((:instance add-frame-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32)
                                                                 (loghead 32 (+ v1 v2))))))))))
                 add-label-step3
                 add-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (add-frame)))))

(defthm add-frame3-bridge
  (equal (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :frame_%{%}% 1
                           (add-frame v1 v2)
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32)
                                                   (loghead 32 (+ v1 v2)))))))))
         (ir-label-vals-in-frame-cfg
          *ir-store* *ir-call-frame*
          (add-frame v1 v2)
          (loghead 32 (+ v1 v2))))
  :hints (("Goal" :in-theory (enable ir-label-vals-in-frame-cfg))))

(defthm add-label-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (ir-label-vals-in-frame-cfg
                         *ir-store* *ir-call-frame*
                         (add-frame v1 v2)
                         (loghead 32 (+ v1 v2)))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (add-frame v1 v2)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm add-frame-dissolve
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (ir-frame-vals-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (add-frame v1 v2)
                         (loghead 32 (+ v1 v2)))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm add-value2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (ir-label-vals-in-frame-cfg
                               *ir-store* *ir-call-frame*
                               (add-frame v1 v2)
                               (loghead 32 (+ v1 v2)))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (add-label-dissolve add-frame-dissolve))))

(defthm add-body-outer3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (ir-frame-add-cfg v1 v2)))))))
                  (ir-label-vals-in-frame-cfg
                   *ir-store* *ir-call-frame*
                   (add-frame v1 v2)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal"
           :in-theory (e/d (ir-frame-add-cfg add-frame add-body)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (add-frame-step1 add-frame-step2 add-frame-step3
                 add-frame3-bridge))))

(defthm ir-op-add-body
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (ir-frame-add-cfg v1 v2)))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (add-body-outer3 add-value2))))

(defthm ir-op-add-call-result
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                (unsigned-byte-p 32 (loghead 32 (+ v1 v2))))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (car (w3t::step
                                                      (w3t::$invoke
                                                       *ir-store* 1
                                                       (list
                                                        (list :const (list :i32) v1)
                                                        (list :const (list :i32) v2)))))))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (loghead 32 (+ v1 v2)))))
  :hints (("Goal"
           :in-theory (e/d (ir-op-add-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-add-invoke
                 ir-op-add-call-entry
                 ir-op-add-body))))
