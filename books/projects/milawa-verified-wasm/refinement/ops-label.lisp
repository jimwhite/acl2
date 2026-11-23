; op_jmp's W3T entry and body.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-add")

(defun label-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun label-body () '((:local.get 0)))

;; op_ifz (function 4): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-label-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-label-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 6)
              (list :call_ref *op-label-type*))))

(defthm ir-op-label-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 6
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-label-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-label-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 6)
                         (list :call_ref *op-label-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro label-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 6)
               (list :call_ref *op-label-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 6)
                      (list :call_ref *op-label-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 6)
                                 (list :call_ref *op-label-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone-label
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-label-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-label-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-label
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-label-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-label-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone-label))))

(defthm step-ref-func-call-ref-nil-label
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 6)
                      (list :call_ref *op-label-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 6)
                                 (list :call_ref *op-label-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref2))))

(defthm search21-label-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (label-suffix-cfg v2))
          2
          (cadr (label-suffix-cfg v2))
          (label-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-label-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (label-suffix-cfg v2))
          2
          (cadr (label-suffix-cfg v2))
          (label-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-label))))

(defthm search21-label-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (label-suffix-cfg v2))
          2
          (cadr (label-suffix-cfg v2))
          (label-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-label
                              step-ref-func-call-ref-nil-label))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-label
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (label-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (label-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-label
                              step-ref-func-call-ref-nil-label))))

(defthm step-const-ref-func-call-ref-nil-label
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (label-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (label-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-label))))

(defmacro label-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 6)
               (list :call_ref *op-label-type*))))

(defthm no-ctxt-instrs-on-op-label-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (label-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (label-call-cfg v1 v2))
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
                              step-call-ref-alone-nil-label
                              step-const-ref-func-call-ref-nil-label
                              step-ref-func-call-ref-nil-label))))

(defun ir-frame-label-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (label-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (label-body)))))))

(defthm ir-op-label-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (label-call-cfg v1 v2)))
                  (ir-frame-label-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (label-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-label-call
                              ir-frame-label-cfg
                              label-frame label-body
                              ir-frame-with-locals)
           :do-not-induct t)))


;; ---------------------------------------------------------------------------
;; The body and call result
;; ---------------------------------------------------------------------------

(defun label-callee-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (label-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (label-body)))))))

(defun label-after-local-get-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (label-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (list (list :const (list :i32) v1))))))))

(defthm label-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (label-callee-cfg v1 v2))
                  (list (label-after-local-get-cfg v1 v2))))
  :hints (("Goal"
           :in-theory (enable label-callee-cfg label-after-local-get-cfg
                              label-frame label-body)
           :expand ((w3t::step (label-callee-cfg v1 v2)))
           :do-not-induct t)))

(defun label-after-label-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (label-frame v1 v2)
                    (list (list :const (list :i32) v1))))))

(defthm label-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (label-after-local-get-cfg v1 v2))
                  (list (label-after-label-cfg v1 v2))))
  :hints (("Goal"
           :in-theory (e/d (label-after-local-get-cfg label-after-label-cfg)
                           (w3t::step ir-step-label-vals-in-frame))
           :use ((:instance ir-step-label-vals-in-frame
                            (store *ir-store*)
                            (outer *ir-call-frame*)
                            (f (label-frame v1 v2))
                            (v v1)))
           :do-not-induct t)))

(defthm label-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (label-after-label-cfg v1 v2))
                  (list (ir-value-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         v1))))
  :hints (("Goal"
           :in-theory (e/d (label-after-label-cfg)
                           (w3t::step ir-step-frame-vals))
           :use ((:instance ir-step-frame-vals
                            (z (list :|%;%| *ir-store* *ir-call-frame*))
                            (f (label-frame v1 v2))
                            (v v1)))
           :do-not-induct t)))

(defthm ir-op-label-body
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (label-callee-cfg v1 v2)))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   v1)))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (label-step1 label-step2 label-step3))))

(defthm ir-op-label-call-result
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (w3t::$invoke
                                           *ir-store* 6
                                           (list
                                            (list :const (list :i32) v1)
                                            (list :const (list :i32) v2)))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   v1)))
  :hints (("Goal"
           :in-theory (e/d (ir-op-label-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-label-invoke
                 ir-op-label-call-entry
                 ir-op-label-body))))

