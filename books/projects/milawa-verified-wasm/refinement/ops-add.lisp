; op_add's body through the engine's context lifts.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-w3t")
(include-book "../wasm3/engine-flat")

(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm add-body-step1
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (add-frame v1 v2))
                                (list (list :local.get 0)))))
                  inner)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (add-frame v1 v2))
                           (add-body)))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner))
                                        (list (list :local.get 1)
                                              (list :binop (list :i32)
                                                    (list :add))))))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity
                                we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p
                                add-frame)
                             ())
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*)
                              (we::f (add-frame v1 v2))
                              (we::vals nil)
                              (we::i (list :local.get 0))
                              (we::r (list (list :local.get 1)
                                           (list :binop (list :i32) (list :add))))
                              (we::a 0)
                              (we::inner inner))))))
  )

(defthm add-body-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (add-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :local.get 1)
                               (list :binop (list :i32) (list :add)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (add-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :const (list :i32) v2)
                                    (list :binop (list :i32) (list :add)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (add-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :local.get 1)
                                 (list :binop (list :i32) (list :add))))))
           :use ((:instance engine-ctxt-from-values-instr-step
                            (z (list :|%;%| *ir-store* (add-frame v1 v2)))
                            (x (list (list :const (list :i32) v1)))
                            (i (list :local.get 1))
                            (r (list (list :binop (list :i32) (list :add))))
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :const (list :i32) v2)))))))
           :in-theory (enable milawa-values-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              add-frame)
           :do-not-induct t)))

(defthm add-body-step1-specific
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (add-frame v1 v2))
                         (add-body)))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (add-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :local.get 1)
                                    (list :binop (list :i32)
                                          (list :add)))))))
  :hints (("Goal"
           :use ((:instance add-body-step1
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (add-frame v1 v2))
                                         (list (list :const (list :i32) v1)))))))
           :in-theory (enable add-inner0-explicit))))

(defthm add-body-inner3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (list :|%;%|
                                          (list :|%;%| *ir-store*
                                                (add-frame v1 v2))
                                          (add-body))))))))
                  (list :|%;%|
                        (list :|%;%| *ir-store* (add-frame v1 v2))
                        (list (list :const (list :i32)
                                    (loghead 32 (+ v1 v2)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (add-body-step1-specific
                 add-body-step2
                 add-innerbin-explicit))))

