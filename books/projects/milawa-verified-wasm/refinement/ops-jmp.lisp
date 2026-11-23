; op_jmp's W3T entry and body.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-add")

(defun jmp-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun jmp-body () '((:local.get 1)))

;; op_ifz (function 4): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-jmp-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-jmp-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 5)
              (list :call_ref *op-jmp-type*))))

(defthm ir-op-jmp-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 5
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-jmp-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-jmp-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 5)
                         (list :call_ref *op-jmp-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro jmp-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 5)
               (list :call_ref *op-jmp-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 5)
                      (list :call_ref *op-jmp-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 5)
                                 (list :call_ref *op-jmp-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone-jmp
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-jmp-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-jmp-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-jmp
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-jmp-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-jmp-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone-jmp))))

(defthm step-ref-func-call-ref-nil-jmp
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 5)
                      (list :call_ref *op-jmp-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 5)
                                 (list :call_ref *op-jmp-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref2))))

(defthm search21-jmp-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (jmp-suffix-cfg v2))
          2
          (cadr (jmp-suffix-cfg v2))
          (jmp-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-jmp-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (jmp-suffix-cfg v2))
          2
          (cadr (jmp-suffix-cfg v2))
          (jmp-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-jmp))))

(defthm search21-jmp-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (jmp-suffix-cfg v2))
          2
          (cadr (jmp-suffix-cfg v2))
          (jmp-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-jmp
                              step-ref-func-call-ref-nil-jmp))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-jmp
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (jmp-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (jmp-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-jmp
                              step-ref-func-call-ref-nil-jmp))))

(defthm step-const-ref-func-call-ref-nil-jmp
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (jmp-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (jmp-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-jmp))))

(defmacro jmp-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 5)
               (list :call_ref *op-jmp-type*))))

(defthm no-ctxt-instrs-on-op-jmp-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (jmp-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (jmp-call-cfg v1 v2))
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
                              step-call-ref-alone-nil-jmp
                              step-const-ref-func-call-ref-nil-jmp
                              step-ref-func-call-ref-nil-jmp))))

(defun ir-frame-jmp-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (jmp-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (jmp-body)))))))

(defthm ir-op-jmp-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (jmp-call-cfg v1 v2)))
                  (ir-frame-jmp-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (jmp-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-jmp-call
                              ir-frame-jmp-cfg
                              jmp-frame jmp-body
                              ir-frame-with-locals)
           :do-not-induct t)))


;; ---------------------------------------------------------------------------
;; The body and call result
;; ---------------------------------------------------------------------------

(defun jmp-callee-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (jmp-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (jmp-body)))))))

(defun jmp-after-local-get-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (jmp-frame v1 v2)
                    (list (list :label_%{%}% 1 nil
                                (list (list :const (list :i32) v2))))))))

(defthm jmp-step1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (jmp-callee-cfg v1 v2))
                  (list (jmp-after-local-get-cfg v1 v2))))
  :hints (("Goal"
           :in-theory (enable jmp-callee-cfg jmp-after-local-get-cfg
                              jmp-frame jmp-body)
           :expand ((w3t::step (jmp-callee-cfg v1 v2)))
           :do-not-induct t)))

(defun jmp-after-label-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (jmp-frame v1 v2)
                    (list (list :const (list :i32) v2))))))

(defthm jmp-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (jmp-after-local-get-cfg v1 v2))
                  (list (jmp-after-label-cfg v1 v2))))
  :hints (("Goal"
           :in-theory (e/d (jmp-after-local-get-cfg jmp-after-label-cfg)
                           (w3t::step ir-step-label-vals-in-frame))
           :use ((:instance ir-step-label-vals-in-frame
                            (store *ir-store*)
                            (outer *ir-call-frame*)
                            (f (jmp-frame v1 v2))
                            (v v2)))
           :do-not-induct t)))

(defthm jmp-step3
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (jmp-after-label-cfg v1 v2))
                  (list (ir-value-cfg
                         (list :|%;%| *ir-store* *ir-call-frame*)
                         v2))))
  :hints (("Goal"
           :in-theory (e/d (jmp-after-label-cfg)
                           (w3t::step ir-step-frame-vals))
           :use ((:instance ir-step-frame-vals
                            (z (list :|%;%| *ir-store* *ir-call-frame*))
                            (f (jmp-frame v1 v2))
                            (v v2)))
           :do-not-induct t)))

(defthm ir-op-jmp-body
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (jmp-callee-cfg v1 v2)))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   v2)))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (jmp-step1 jmp-step2 jmp-step3))))

(defthm ir-op-jmp-call-result
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (w3t::$invoke
                                           *ir-store* 5
                                           (list
                                            (list :const (list :i32) v1)
                                            (list :const (list :i32) v2)))))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   v2)))
  :hints (("Goal"
           :in-theory (e/d (ir-op-jmp-invoke-cfg)
                           (w3t::step ir-label-vals-in-frame-cfg
                            ir-frame-vals-cfg ir-value-cfg))
           :use (ir-op-jmp-invoke
                 ir-op-jmp-call-entry
                 ir-op-jmp-body))))

