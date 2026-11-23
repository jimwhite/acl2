; op_ifz's W3T entry and body.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)
;
; op_ifz is implemented as target * (test == 0 ? 1 : 0) in i32, which is
; the same value as the control-flow implementation and has a straight-line
; four-instruction body (matching the add/sub/lt composition pattern).

(in-package "MILAWA-WASM")

(include-book "ihs/quotient-remainder-lemmas" :dir :system)
(include-book "ops-add")

(defun ifz-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun ifz-z (v1 v2)
  (list :|%;%| *ir-store* (ifz-frame v1 v2)))

(defun ifz-body ()
  '((:local.get 1)
    (:local.get 0)
    (:testop (:i32) (:eqz))
    (:binop (:i32) (:mul))))

; The i32.eqz test returns 1 exactly when its operand is zero.
(defthm ieqz-value
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::$ieqz_ 32 v)
                  (if (equal v 0) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ieqz_ w3t::$bool))))

; Multiplying an i32 by the 0/1 eqz result selects the value or 0.
(defthm rem-positive-as-mod
  (implies (and (integerp x) (<= 0 x) (integerp y) (< 0 y))
           (equal (rem x y) (mod x y)))
  :hints (("Goal" :in-theory (enable rem mod))))

(defthm loghead-32-as-mod
  (implies (integerp x)
           (equal (loghead 32 x) (mod x 4294967296)))
  :hints (("Goal" :in-theory (enable loghead))))

(defthm loghead-32-id
  (implies (unsigned-byte-p 32 v)
           (equal (loghead 32 v) v))
  :hints (("Goal" :in-theory (enable loghead-32-as-mod))))

(defthm imul-01
  (implies (and (unsigned-byte-p 32 v)
                (or (equal c 0) (equal c 1)))
           (equal (w3t::$imul_ 32 v c)
                  (if (equal c 1) v 0)))
  :hints (("Goal"
           :in-theory (enable w3t::$imul_ rem-positive-as-mod
                              loghead-32-as-mod)
           :cases ((equal c 0) (equal c 1)))))

;; op_ifz (function 4): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-ifz-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-ifz-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 4)
              (list :call_ref *op-ifz-type*))))

(defthm ir-op-ifz-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 4
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-ifz-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-ifz-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 4)
                         (list :call_ref *op-ifz-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro ifz-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 4)
               (list :call_ref *op-ifz-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 4)
                      (list :call_ref *op-ifz-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 4)
                                 (list :call_ref *op-ifz-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone-ifz
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-ifz-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-ifz-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-ifz
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-ifz-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-ifz-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone-ifz))))

(defthm step-ref-func-call-ref-nil-ifz
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 4)
                      (list :call_ref *op-ifz-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 4)
                                 (list :call_ref *op-ifz-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref2))))

(defthm search21-ifz-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (ifz-suffix-cfg v2))
          2
          (cadr (ifz-suffix-cfg v2))
          (ifz-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-ifz-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (ifz-suffix-cfg v2))
          2
          (cadr (ifz-suffix-cfg v2))
          (ifz-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-ifz))))

(defthm search21-ifz-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (ifz-suffix-cfg v2))
          2
          (cadr (ifz-suffix-cfg v2))
          (ifz-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-ifz
                              step-ref-func-call-ref-nil-ifz))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-ifz
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (ifz-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (ifz-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-ifz
                              step-ref-func-call-ref-nil-ifz))))

(defthm step-const-ref-func-call-ref-nil-ifz
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (ifz-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (ifz-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-ifz))))

(defmacro ifz-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 4)
               (list :call_ref *op-ifz-type*))))

(defthm no-ctxt-instrs-on-op-ifz-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (ifz-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (ifz-call-cfg v1 v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 3 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-ifz
                              step-const-ref-func-call-ref-nil-ifz
                              step-ref-func-call-ref-nil-ifz))))

(defun ir-frame-ifz-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (ifz-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (ifz-body)))))))

(defthm ir-op-ifz-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (ifz-call-cfg v1 v2)))
                  (ir-frame-ifz-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (ifz-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-ifz-call
                              ir-frame-ifz-cfg
                              ifz-frame ifz-body
                              ir-frame-with-locals)
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; The op_ifz redex steps
;; ---------------------------------------------------------------------------

(defthm ifz-inner0
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step
                   (list :|%;%| (ifz-z v1 v2)
                         (list (list :local.get 1))))
                  (list (list :|%;%| (ifz-z v1 v2)
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (ifz-z v1 v2)
                           (list (list :local.get 1)))))
           :in-theory (enable ifz-z ifz-frame)
           :do-not-induct t)))

(defthm ifz-inner1
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step
                   (list :|%;%| (ifz-z v1 v2)
                         (list (list :local.get 0))))
                  (list (list :|%;%| (ifz-z v1 v2)
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (ifz-z v1 v2)
                           (list (list :local.get 0)))))
           :in-theory (enable ifz-z ifz-frame)
           :do-not-induct t)))

(defthm ifz-inner2
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step
                   (list :|%;%| (ifz-z v1 v2)
                         (list (list :const (list :i32) v1)
                               (list :testop (list :i32) (list :eqz)))))
                  (list (list :|%;%| (ifz-z v1 v2)
                              (list (list :const (list :i32)
                                          (if (equal v1 0) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (ifz-z v1 v2)
                           (list (list :const (list :i32) v1)
                                 (list :testop (list :i32) (list :eqz))))))
           :in-theory (enable ifz-z ifz-frame ieqz-value
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :do-not-induct t)))

(defthm ifz-innerbin
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%| (ifz-z v1 v2)
                         (list (list :const (list :i32) v2)
                               (list :const (list :i32)
                                     (if (equal v1 0) 1 0))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%| (ifz-z v1 v2)
                              (list (list :const (list :i32)
                                          (if (equal v1 0) v2 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (ifz-z v1 v2)
                           (list (list :const (list :i32) v2)
                                 (list :const (list :i32)
                                       (if (equal v1 0) 1 0))
                                 (list :binop (list :i32) (list :mul))))))
           :in-theory (enable ifz-z ifz-frame imul-01
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :do-not-induct t)))

; The same redex steps with the state pair written out.
(defthm ifz-inner0-explicit
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :local.get 1))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (list (list :local.get 1)))))
           :in-theory (enable ifz-frame)
           :do-not-induct t)))

(defthm ifz-inner1-explicit
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :local.get 0))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (list (list :local.get 0)))))
           :in-theory (enable ifz-frame)
           :do-not-induct t)))

(defthm ifz-inner2-explicit
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :testop (list :i32) (list :eqz)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32)
                                          (if (equal v1 0) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :testop (list :i32) (list :eqz))))))
           :in-theory (enable ifz-frame ieqz-value
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :do-not-induct t)))

(defthm ifz-innerbin-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :const (list :i32) v2)
                               (list :const (list :i32)
                                     (if (equal v1 0) 1 0))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32)
                                          (if (equal v1 0) v2 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (list (list :const (list :i32) v2)
                                 (list :const (list :i32)
                                       (if (equal v1 0) 1 0))
                                 (list :binop (list :i32) (list :mul))))))
           :in-theory (enable ifz-frame imul-01
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :do-not-induct t)))

(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm ifz-body-step1
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (ifz-frame v1 v2))
                                (list (list :local.get 1)))))
                  inner)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (ifz-body)))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner))
                                        (list (list :local.get 0)
                                              (list :testop (list :i32)
                                                    (list :eqz))
                                              (list :binop (list :i32)
                                                    (list :mul))))))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity
                                we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p
                                ifz-frame)
                             ())
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*)
                              (we::f (ifz-frame v1 v2))
                              (we::vals nil)
                              (we::i (list :local.get 1))
                              (we::r (list (list :local.get 0)
                                           (list :testop (list :i32)
                                                 (list :eqz))
                                           (list :binop (list :i32)
                                                 (list :mul))))
                              (we::a 0)
                              (we::inner inner)))))))
  

(defthm ifz-body-step1-specific
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (ifz-body)))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32) v2)
                                    (list :local.get 0)
                                    (list :testop (list :i32) (list :eqz))
                                    (list :binop (list :i32) (list :mul)))))))
  :hints (("Goal"
           :use ((:instance ifz-body-step1
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (ifz-frame v1 v2))
                                         (list (list :const (list :i32) v2)))))))
           :in-theory (enable ifz-inner0))))

(defthm ifz-body-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :const (list :i32) v2)
                               (list :local.get 0)
                               (list :testop (list :i32) (list :eqz))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32) v2)
                                    (list :const (list :i32) v1)
                                    (list :testop (list :i32) (list :eqz))
                                    (list :binop (list :i32) (list :mul)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (ifz-frame v1 v2))
                           (list (list :const (list :i32) v2)
                                 (list :local.get 0)
                                 (list :testop (list :i32) (list :eqz))
                                 (list :binop (list :i32) (list :mul))))))
           :use ((:instance engine-ctxt-from-values-instr-step
                            (z (list :|%;%| *ir-store* (ifz-frame v1 v2)))
                            (x (list (list :const (list :i32) v2)))
                            (i (list :local.get 0))
                            (r (list (list :testop (list :i32) (list :eqz))
                                     (list :binop (list :i32) (list :mul))))
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (ifz-frame v1 v2))
                                         (list (list :const (list :i32) v1)))))))
           :in-theory (enable milawa-values-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              ifz-frame)
           :do-not-induct t)))

(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm ifz-testop-flat-generic
    (implies
     (and (unsigned-byte-p 32 v1)
          (unsigned-byte-p 32 v2)
          (equal inner
                 (w3t::step
                  (list :|%;%| (list :|%;%| s f)
                        (list (list :const (list :i32) v1)
                              (list :testop (list :i32) (list :eqz))))))
          inner)
     (equal
      (w3t::step
       (list :|%;%| (list :|%;%| s f)
             (list (list :const (list :i32) v2)
                   (list :const (list :i32) v1)
                   (list :testop (list :i32) (list :eqz))
                   (list :binop (list :i32) (list :mul)))))
      (list
       (list :|%;%| (cadr (car inner))
             (cons (list :const (list :i32) v2)
                   (append (caddr (car inner))
                           (list (list :binop (list :i32) (list :mul)))))))))
    :hints
    (("Goal"
      :in-theory (e/d (we::op-instr-p we::redex-arity
                        we::vals-p
                        w3t::val-p w3t::num_-p w3t::inn-p
                        w3t::in-p w3t::un-p)
                      (we::revappend-of-take-becomes-operands))
      :expand ((we::operands
                1
                (list (list :const (list :i32) v1)
                      (list :const (list :i32) v2))))
      :use
      ((:instance we::step-of-flat-block
                  (we::s s)
                  (we::f f)
                  (we::vals (list (list :const (list :i32) v1)
                                  (list :const (list :i32) v2)))
                  (we::i (list :testop (list :i32) (list :eqz)))
                  (we::r (list (list :binop (list :i32) (list :mul))))
                  (we::a 1)
                  (we::inner inner))))))

  (defthm ifz-binop-flat-generic
    (implies
     (and (unsigned-byte-p 32 v1)
          (unsigned-byte-p 32 v2)
          (equal inner
                 (w3t::step
                  (list :|%;%| (list :|%;%| s f)
                        (list (list :const (list :i32) v2)
                              (list :const (list :i32)
                                    (if (equal v1 0) 1 0))
                              (list :binop (list :i32) (list :mul))))))
          inner)
     (equal
      (w3t::step
       (list :|%;%| (list :|%;%| s f)
             (list (list :const (list :i32) v2)
                   (list :const (list :i32)
                         (if (equal v1 0) 1 0))
                   (list :binop (list :i32) (list :mul)))))
      (list (list :|%;%| (cadr (car inner))
                  (caddr (car inner))))))
    :hints
    (("Goal"
      :in-theory (e/d (we::op-instr-p we::redex-arity
                        we::vals-p
                        w3t::val-p w3t::num_-p w3t::inn-p
                        w3t::in-p w3t::un-p)
                      (we::revappend-of-take-becomes-operands))
      :expand ((we::operands
                2
                (list (list :const (list :i32)
                            (if (equal v1 0) 1 0))
                      (list :const (list :i32) v2))))
      :use
      ((:instance we::step-of-flat-block
                  (we::s s)
                  (we::f f)
                  (we::vals (list (list :const (list :i32)
                                       (if (equal v1 0) 1 0))
                                  (list :const (list :i32) v2)))
                  (we::i (list :binop (list :i32) (list :mul)))
                  (we::r nil)
                  (we::a 2)
                  (we::inner inner)))))))

(defthm ifz-body-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :const (list :i32) v2)
                               (list :const (list :i32) v1)
                               (list :testop (list :i32) (list :eqz))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32) v2)
                                    (list :const (list :i32)
                                          (if (equal v1 0) 1 0))
                                    (list :binop (list :i32) (list :mul)))))))
  :hints (("Goal"
           :use ((:instance ifz-testop-flat-generic
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store*
                                          (ifz-frame v1 v2))
                                    (list (list :const (list :i32)
                                                (if (equal v1 0) 1 0)))))))
                 ifz-inner2)
           :in-theory (enable ifz-z))))

(defthm ifz-body-step4
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (ifz-frame v1 v2))
                         (list (list :const (list :i32) v2)
                               (list :const (list :i32)
                                     (if (equal v1 0) 1 0))
                               (list :binop (list :i32) (list :mul)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (ifz-frame v1 v2))
                              (list (list :const (list :i32)
                                          (if (equal v1 0) v2 0)))))))
  :hints (("Goal"
           :use ((:instance ifz-binop-flat-generic
                            (s *ir-store*)
                            (f (ifz-frame v1 v2))
                            (inner
                             (list
                              (list :|%;%|
                                    (list :|%;%| *ir-store*
                                          (ifz-frame v1 v2))
                                    (list (list :const (list :i32)
                                                (if (equal v1 0)
                                                    v2 0)))))))
                 ifz-innerbin)
           :in-theory (enable ifz-z))))


(defthm ifz-body-inner4
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (list :|%;%|
                                                (list :|%;%| *ir-store*
                                                      (ifz-frame v1 v2))
                                                (ifz-body))))))))))
                  (list :|%;%|
                        (list :|%;%| *ir-store* (ifz-frame v1 v2))
                        (list (list :const (list :i32)
                                    (if (equal v1 0) v2 0))))))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (ifz-body-step1-specific
                 ifz-body-step2
                 ifz-body-step3
                 ifz-body-step4))))
