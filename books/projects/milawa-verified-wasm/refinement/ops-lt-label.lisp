; op_lt's conditional label/frame admin lifts.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-lt-body")
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
   (defthm lt-not-exit-body
     (not (we::exit-body-p (lt-body)))
     :hints (("Goal" :in-theory (enable we::exit-body-p)))))

  (local
   (defthm lt-not-exit-body1
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :local.get 1)
                 (list :relop (list :i32) (list :lt (list :s))))))
     :hints (("Goal" :in-theory (enable we::exit-body-p
                                     we::vals-p
                                     we::exit-block-p
                                     we::exn-throw-p
                                     we::first-nonval
                                     we::exit-head-p)))))

  (local
   (defthm lt-not-exit-body2
     (not (we::exit-body-p
           (list (list :const (list :i32) v1)
                 (list :const (list :i32) v2)
                 (list :relop (list :i32) (list :lt (list :s))))))
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

  (defthm lt-label-step1-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (lt-body))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (lt-body)))))
                    (list (list :|%;%|
                                (cadr (car inner))
                                (list (list :label_%{%}% 1 nil
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :l) (n 1) (x nil)
                              (b (lt-body)) (r nil)
                              (s *ir-store*)
                              (f (lt-frame v1 v2))
                              (inner inner))))))

  (defthm lt-label-step2-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :local.get 1)
                                      (list :relop (list :i32) (list :lt (list :s)))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :local.get 1)
                                             (list :relop (list :i32) (list :lt (list :s))))))))
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
                                       (list :relop (list :i32) (list :lt (list :s)))))
                              (r nil)
                              (s *ir-store*)
                              (f (lt-frame v1 v2))
                              (inner inner))))))

  (defthm lt-label-step3-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)
                                      (list :relop (list :i32) (list :lt (list :s)))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32) v1)
                                             (list :const (list :i32) v2)
                                             (list :relop (list :i32) (list :lt (list :s))))))))
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
                                       (list :relop (list :i32) (list :lt (list :s)))))
                              (r nil)
                              (s *ir-store*)
                              (f (lt-frame v1 v2))
                              (inner inner))))))

  (defthm lt-frame-step1-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (lt-body))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (lt-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (lt-body)))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (lt-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (lt-body))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm lt-frame-step2-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :local.get 1)
                                                  (list :relop (list :i32) (list :lt (list :s)))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (lt-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :local.get 1)
                                                         (list :relop (list :i32) (list :lt (list :s))))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (lt-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :local.get 1)
                                                   (list :relop (list :i32) (list :lt (list :s)))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner))))))

  (defthm lt-frame-step3-cond
    (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :label_%{%}% 1 nil
                                            (list (list :const (list :i32) v1)
                                                  (list :const (list :i32) v2)
                                                  (list :relop (list :i32) (list :lt (list :s)))))))))
                  inner
                  (milawa-state-pair-p (cadr (car inner))))
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :frame_%{%}% 1
                                       (lt-frame v1 v2)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) v1)
                                                         (list :const (list :i32) v2)
                                                         (list :relop (list :i32) (list :lt (list :s))))))))))
                    (list (list :|%;%|
                                (list :|%;%| (cadr (cadr (car inner)))
                                      *ir-call-frame*)
                                (list (list :frame_%{%}% 1
                                            (caddr (cadr (car inner)))
                                            (caddr (car inner))))))))
    :hints (("Goal"
             :in-theory (enable we::admin-term)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (lt-frame v1 v2))
                              (b (list (list :label_%{%}% 1 nil
                                             (list (list :const (list :i32) v1)
                                                   (list :const (list :i32) v2)
                                                   (list :relop (list :i32) (list :lt (list :s)))))))
                              (r nil)
                              (s *ir-store*)
                              (f *ir-call-frame*)
                              (inner inner)))))))
  

(defthm lt-state-pair-z
  (milawa-state-pair-p
   (list :|%;%| *ir-store* (lt-frame v1 v2)))
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

(defthm lt-label-step1
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :label_%{%}% 1 nil (lt-body)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :local.get 1)
                                                (list :relop (list :i32) (list :lt (list :s))))))))))
  :hints (("Goal"
           :use ((:instance lt-label-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :local.get 1)
                                               (list :relop (list :i32) (list :lt (list :s))))))))
                 lt-body-step1-specific
                 lt-state-pair-z)
           :in-theory (e/d (lt-body-step1-specific
                            lt-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (lt-frame)))))


(defthm lt-label-step2
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :local.get 1)
                                           (list :relop (list :i32) (list :lt (list :s))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32) v1)
                                                (list :const (list :i32) v2)
                                                (list :relop (list :i32) (list :lt (list :s))))))))))
  :hints (("Goal"
           :use ((:instance lt-label-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :const (list :i32) v1)
                                               (list :const (list :i32) v2)
                                               (list :relop (list :i32) (list :lt (list :s))))))))
                 lt-body-step2
                 lt-state-pair-z)
           :in-theory (e/d (lt-body-step2
                            lt-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (lt-frame)))))

(defthm lt-label-step3
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :label_%{%}% 1 nil
                                     (list (list :const (list :i32) v1)
                                           (list :const (list :i32) v2)
                                           (list :relop (list :i32) (list :lt (list :s))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :label_%{%}% 1 nil
                                          (list (list :const (list :i32)
                                                      (if (< v1 v2) 1 0)))))))))
  :hints (("Goal"
           :use ((:instance lt-label-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :const (list :i32)
                                                     (if (< v1 v2) 1 0)))))))
                 lt-innerbin-explicit
                 lt-state-pair-z)
           :in-theory (e/d (lt-innerbin-explicit
                            lt-state-pair-z
                            z-of-inner-list
                            body-of-inner-list
                            label-result-extract)
                           (lt-frame)))))

(defthm lt-frame-step1
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (lt-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (lt-body)))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (lt-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :local.get 1)
                                                            (list :relop (list :i32) (list :lt (list :s))))))))))))
  :hints (("Goal"
           :use ((:instance lt-frame-step1-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :local.get 1)
                                                           (list :relop (list :i32) (list :lt (list :s))))))))))
                 lt-label-step1
                 lt-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (lt-frame)))))

(defthm lt-frame-step2
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (lt-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :local.get 1)
                                                       (list :relop (list :i32) (list :lt (list :s))))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (lt-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32) v1)
                                                            (list :const (list :i32) v2)
                                                            (list :relop (list :i32) (list :lt (list :s))))))))))))
  :hints (("Goal"
           :use ((:instance lt-frame-step2-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32) v1)
                                                           (list :const (list :i32) v2)
                                                           (list :relop (list :i32) (list :lt (list :s))))))))))
                 lt-label-step2
                 lt-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (lt-frame)))))

(defthm lt-frame-step3
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :frame_%{%}% 1
                                     (lt-frame v1 v2)
                                     (list (list :label_%{%}% 1 nil
                                                 (list (list :const (list :i32) v1)
                                                       (list :const (list :i32) v2)
                                                       (list :relop (list :i32) (list :lt (list :s))))))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :frame_%{%}% 1
                                          (lt-frame v1 v2)
                                          (list (list :label_%{%}% 1 nil
                                                      (list (list :const (list :i32)
                                                                  (if (< v1 v2) 1 0)))))))))))
  :hints (("Goal"
           :use ((:instance lt-frame-step3-cond
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :label_%{%}% 1 nil
                                                     (list (list :const (list :i32)
                                                                 (if (< v1 v2) 1 0)))))))))
                 lt-label-step3
                 lt-state-pair-z)
           :in-theory (e/d (z-of-label-result
                            f-of-label-result
                            body-of-label-result)
                           (lt-frame)))))

(defthm lt-frame3-bridge
  (equal (list :|%;%|
               (list :|%;%| *ir-store* *ir-call-frame*)
               (list (list :frame_%{%}% 1
                           (lt-frame v1 v2)
                           (list (list :label_%{%}% 1 nil
                                       (list (list :const (list :i32)
                                                   (if (< v1 v2) 1 0))))))))
         (ir-label-vals-in-frame-cfg
          *ir-store* *ir-call-frame*
          (lt-frame v1 v2)
          (if (< v1 v2) 1 0)))
  :hints (("Goal" :in-theory (enable ir-label-vals-in-frame-cfg))))

(defthm lt-label-dissolve
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (ir-label-vals-in-frame-cfg
                         *ir-store* *ir-call-frame*
                         (lt-frame v1 v2)
                         (if (< v1 v2) 1 0))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (lt-frame v1 v2)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm lt-frame-dissolve
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (ir-frame-vals-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         (lt-frame v1 v2)
                         (if (< v1 v2) 1 0))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal" :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg))))

(defthm lt-value2
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (car (w3t::step
                              (ir-label-vals-in-frame-cfg
                               *ir-store* *ir-call-frame*
                               (lt-frame v1 v2)
                               (if (< v1 v2) 1 0))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (lt-label-dissolve lt-frame-dissolve))))

(defthm lt-body-outer3
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (ir-frame-lt-cfg v1 v2)))))))
                  (ir-label-vals-in-frame-cfg
                   *ir-store* *ir-call-frame*
                   (lt-frame v1 v2)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal"
           :in-theory (e/d (ir-frame-lt-cfg lt-frame lt-body)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (lt-frame-step1 lt-frame-step2 lt-frame-step3
                 lt-frame3-bridge))))

(defthm ir-op-lt-body
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (ir-frame-lt-cfg v1 v2)))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal"
           :in-theory (disable w3t::step ir-label-vals-in-frame-cfg ir-frame-vals-cfg ir-value-cfg)
           :use (lt-body-outer3 lt-value2))))

(defthm ir-op-lt-call-result
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2)
                (unsigned-byte-p 32 (if (< v1 v2) 1 0)))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (car (w3t::step
                                                (car (w3t::step
                                                      (w3t::$invoke
                                                       *ir-store* 3
                                                       (list
                                                        (list :const (list :i32) v1)
                                                        (list :const (list :i32) v2)))))))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (if (< v1 v2) 1 0))))
  :hints (("Goal"
           :in-theory (e/d (ir-op-lt-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-lt-invoke
                 ir-op-lt-call-entry
                 ir-op-lt-body))))
