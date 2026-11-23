; op_ifz's W3T entry and the one-step body lemmas.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-add")

;; op_ifz (function 4) uses the same two-local frame as the other binary
;; opcodes, so its frame and state pair are named here for the entry and body
;; lemmas.

(defun ifz-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun ifz-z (v1 v2)
  (list :|%;%| *ir-store* (ifz-frame v1 v2)))

(defun ifz-body ()
  '((:local.get 0)
    (:testop (:i32) (:eqz))
    (:ifelse (:_result ((:i32)))
             ((:local.get 1))
             ((:const (:i32) 0)))))

; The i32.eqz test returns 1 exactly when its operand is zero.
(defthm ieqz-value
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::$ieqz_ 32 v)
                  (if (equal v 0) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ieqz_ w3t::$bool))))

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
;; The one-step body lemmas
;; ---------------------------------------------------------------------------

(defthm ifz-inner0
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

(defthm ifz-inner1
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

; The i32.ifelse step picks the branch on a literal 1/0 condition and wraps
; the chosen branch in a block.

(defthm ifz-inner2-true
  (equal (w3t::step
          (list :|%;%| z
                (list (list :const (list :i32) 1)
                      '(:ifelse (:_result ((:i32)))
                                ((:local.get 1))
                                ((:const (:i32) 0))))))
         (list (list :|%;%| z
                     (list '(:block (:_result ((:i32)))
                                    ((:local.get 1)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) 1)
                                 '(:ifelse (:_result ((:i32)))
                                           ((:local.get 1))
                                           ((:const (:i32) 0)))))))
           :do-not-induct t)))

(defthm ifz-inner2-false
  (equal (w3t::step
          (list :|%;%| z
                (list (list :const (list :i32) 0)
                      '(:ifelse (:_result ((:i32)))
                                ((:local.get 1))
                                ((:const (:i32) 0))))))
         (list (list :|%;%| z
                     (list '(:block (:_result ((:i32)))
                                    ((:const (:i32) 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list (list :const (list :i32) 0)
                                 '(:ifelse (:_result ((:i32)))
                                           ((:local.get 1))
                                           ((:const (:i32) 0)))))))
           :do-not-induct t)))

; A block step pushes a label around the block body.

(defthm ifz-block-true
  (equal (w3t::step
          (list :|%;%| z
                (list '(:block (:_result ((:i32)))
                               ((:local.get 1))))))
         (list (list :|%;%| z
                     (list '(:label_%{%}% 1 nil ((:local.get 1)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list '(:block (:_result ((:i32)))
                                          ((:local.get 1)))))))
           :do-not-induct t)))

(defthm ifz-block-false
  (equal (w3t::step
          (list :|%;%| z
                (list '(:block (:_result ((:i32)))
                               ((:const (:i32) 0))))))
         (list (list :|%;%| z
                     (list '(:label_%{%}% 1 nil
                                          ((:const (:i32) 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (list '(:block (:_result ((:i32)))
                                          ((:const (:i32) 0)))))))
           :do-not-induct t)))

; The then branch's local.get 1 runs inside the label the block created.

(defun ifz-label-local-get-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* (ifz-frame v1 v2))
        (list (list :label_%{%}% 1 nil
                    (list (list :local.get 1))))))

(defun ifz-label-value-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* (ifz-frame v1 v2))
        (list (list :label_%{%}% 1 nil
                    (list (list :const (list :i32) v2))))))

(defthm ifz-label-local-get
  (equal (w3t::step (ifz-label-local-get-cfg v1 v2))
         (list (ifz-label-value-cfg v1 v2)))
  :hints (("Goal"
           :in-theory (enable ifz-label-local-get-cfg
                              ifz-label-value-cfg
                              ifz-frame)
           :expand ((w3t::step (ifz-label-local-get-cfg v1 v2))))))

