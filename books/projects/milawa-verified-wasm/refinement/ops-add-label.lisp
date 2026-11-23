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

