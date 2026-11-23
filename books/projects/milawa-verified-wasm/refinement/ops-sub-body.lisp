(in-package "MILAWA-WASM")

(include-book "ihs/quotient-remainder-lemmas" :dir :system)
(include-book "ops-add")

(defthm rem-positive-as-mod
  (implies (and (integerp x) (<= 0 x) (integerp y) (< 0 y))
           (equal (rem x y) (mod x y)))
  :hints (("Goal" :in-theory (enable rem mod))))

(defthm isub-rem-loghead
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (rem (- (+ (expt 2 32) v1) v2) (expt 2 32))
                  (loghead 32 (- v1 v2))))
  :hints (("Goal"
           :in-theory (e/d (loghead rem-positive-as-mod)
                           (rem mod)))))

(defthm loghead-32-as-mod
  (implies (integerp x)
           (equal (loghead 32 x) (mod x 4294967296)))
  :hints (("Goal" :in-theory (enable loghead))))

;; op_sub (function 2): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-sub-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-sub-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 2)
              (list :call_ref *op-sub-type*))))

(defthm ir-op-sub-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 2
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-sub-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-sub-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 2)
                         (list :call_ref *op-sub-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro sub-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 2)
               (list :call_ref *op-sub-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 2)
                      (list :call_ref *op-sub-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 2)
                                 (list :call_ref *op-sub-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone-sub
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-sub-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-sub-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-sub
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-sub-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-sub-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone-sub))))

(defthm step-ref-func-call-ref-nil-sub
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 2)
                      (list :call_ref *op-sub-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 2)
                                 (list :call_ref *op-sub-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref2))))

(defthm search21-sub-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (sub-suffix-cfg v2))
          2
          (cadr (sub-suffix-cfg v2))
          (sub-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-sub-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (sub-suffix-cfg v2))
          2
          (cadr (sub-suffix-cfg v2))
          (sub-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-sub))))

(defthm search21-sub-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (sub-suffix-cfg v2))
          2
          (cadr (sub-suffix-cfg v2))
          (sub-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-sub
                              step-ref-func-call-ref-nil-sub))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-sub
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (sub-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (sub-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-sub
                              step-ref-func-call-ref-nil-sub))))

(defthm step-const-ref-func-call-ref-nil-sub
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (sub-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (sub-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-sub))))

(defmacro sub-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 2)
               (list :call_ref *op-sub-type*))))

(defthm no-ctxt-instrs-on-op-sub-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (sub-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (sub-call-cfg v1 v2))
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
                              step-call-ref-alone-nil-sub
                              step-const-ref-func-call-ref-nil-sub
                              step-ref-func-call-ref-nil-sub))))

(defun ir-frame-sub-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals
                     (list (list (list :const (list :i32) v1))
                           (list (list :const (list :i32) v2))))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0)
                                      (list :local.get 1)
                                      (list :binop (list :i32) (list :sub)))))))))

(defthm ir-op-sub-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (sub-call-cfg v1 v2)))
                  (ir-frame-sub-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (sub-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-sub-call
                              ir-frame-sub-cfg
                              ir-frame-with-locals)
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; The op_sub redex steps (the inner instructions, before the context lift)
;; ---------------------------------------------------------------------------

(defun sub-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun sub-z (v1 v2)
  (list :|%;%| *ir-store* (sub-frame v1 v2)))

(defun sub-body () '((:local.get 0) (:local.get 1) (:binop (:i32) (:sub))))

(defthm sub-inner0
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (list :|%;%| (sub-z v1 v2)
                                   (list (list :local.get 0))))
                  (list (list :|%;%| (sub-z v1 v2)
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (sub-z v1 v2)
                                     (list (list :local.get 0)))))
           :in-theory (e/d (sub-z sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))

(defthm sub-inner1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (list :|%;%| (sub-z v1 v2)
                                   (list (list :local.get 1))))
                  (list (list :|%;%| (sub-z v1 v2)
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (sub-z v1 v2)
                                     (list (list :local.get 1)))))
           :in-theory (e/d (sub-z sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))

(defthm sub-innerbin
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%| (sub-z v1 v2)
                         (list (list :const (list :i32) v1)
                               (list :const (list :i32) v2)
                               (list :binop (list :i32) (list :sub)))))
                  (list (list :|%;%| (sub-z v1 v2)
                              (list (list :const (list :i32)
                                          (loghead 32 (- v1 v2))))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (sub-z v1 v2)
                           (list (list :const (list :i32) v1)
                                 (list :const (list :i32) v2)
                                 (list :binop (list :i32) (list :sub))))))
           :in-theory (e/d (sub-z sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))

; The same three redex steps with the state pair written out, which is the
; form the engine's flat-block lift produces.
(defthm sub-inner0-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :local.get 0))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :local.get 0)))))
           :in-theory (e/d (sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))

(defthm sub-inner1-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :local.get 1))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :local.get 1)))))
           :in-theory (e/d (sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))

(defthm sub-innerbin-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :const (list :i32) v2)
                               (list :binop (list :i32) (list :sub)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :const (list :i32)
                                          (loghead 32 (- v1 v2))))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :const (list :i32) v2)
                                 (list :binop (list :i32) (list :sub))))))
           :in-theory (e/d (sub-frame isub-rem-loghead loghead-32-as-mod) (rem mod loghead))
           :do-not-induct t)))


(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm sub-body-step1
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (sub-frame v1 v2))
                                (list (list :local.get 0)))))
                  inner)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (sub-body)))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner))
                                        (list (list :local.get 1)
                                              (list :binop (list :i32)
                                                    (list :sub))))))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity
                                we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p
                                sub-frame)
                             ())
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*)
                              (we::f (sub-frame v1 v2))
                              (we::vals nil)
                              (we::i (list :local.get 0))
                              (we::r (list (list :local.get 1)
                                           (list :binop (list :i32) (list :sub))))
                              (we::a 0)
                              (we::inner inner))))))
  )

(defthm sub-body-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :local.get 1)
                               (list :binop (list :i32) (list :sub)))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :const (list :i32) v2)
                                    (list :binop (list :i32) (list :sub)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (sub-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :local.get 1)
                                 (list :binop (list :i32) (list :sub))))))
           :use ((:instance engine-ctxt-from-values-instr-step
                            (z (list :|%;%| *ir-store* (sub-frame v1 v2)))
                            (x (list (list :const (list :i32) v1)))
                            (i (list :local.get 1))
                            (r (list (list :binop (list :i32) (list :sub))))
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :const (list :i32) v2)))))))
           :in-theory (enable milawa-values-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              sub-frame)
           :do-not-induct t)))

(defthm sub-body-step1-specific
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (sub-frame v1 v2))
                         (sub-body)))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (sub-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :local.get 1)
                                    (list :binop (list :i32)
                                          (list :sub)))))))
  :hints (("Goal"
           :use ((:instance sub-body-step1
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (sub-frame v1 v2))
                                         (list (list :const (list :i32) v1)))))))
           :in-theory (enable sub-inner0-explicit))))

(defthm sub-body-inner3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (list :|%;%|
                                          (list :|%;%| *ir-store*
                                                (sub-frame v1 v2))
                                          (sub-body))))))))
                  (list :|%;%|
                        (list :|%;%| *ir-store* (sub-frame v1 v2))
                        (list (list :const (list :i32)
                                    (loghead 32 (- v1 v2)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (sub-body-step1-specific
                 sub-body-step2
                 sub-innerbin-explicit))))

