(in-package "MILAWA-WASM")

(include-book "ops-add")

(defthm lt-signed-value
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2))
           (equal (w3t::$ilt_ 32 (list :s) v1 v2)
                  (if (< v1 v2) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ilt_ w3t::$signed_ w3t::$bool))))

;; The signed comparison's bridge needs 31-bit operands, but the body
;; composition lemmas carry the (weaker) 32-bit bounds.
(defthm unsigned-byte-p-31-implies-32
  (implies (unsigned-byte-p 31 x)
           (unsigned-byte-p 32 x))
  :hints (("Goal" :in-theory (enable unsigned-byte-p))))

;; op_lt (function 2): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-lt-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-lt-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 3)
              (list :call_ref *op-lt-type*))))

(defthm ir-op-lt-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 3
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-lt-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-lt-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 3)
                         (list :call_ref *op-lt-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro lt-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 3)
               (list :call_ref *op-lt-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 3)
                      (list :call_ref *op-lt-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 3)
                                 (list :call_ref *op-lt-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone-lt
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-lt-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-lt-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-lt
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-lt-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-lt-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone-lt))))

(defthm step-ref-func-call-ref-nil-lt
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 3)
                      (list :call_ref *op-lt-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 3)
                                 (list :call_ref *op-lt-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref2))))

(defthm search21-lt-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (lt-suffix-cfg v2))
          2
          (cadr (lt-suffix-cfg v2))
          (lt-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-lt-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (lt-suffix-cfg v2))
          2
          (cadr (lt-suffix-cfg v2))
          (lt-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-lt))))

(defthm search21-lt-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (lt-suffix-cfg v2))
          2
          (cadr (lt-suffix-cfg v2))
          (lt-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-lt
                              step-ref-func-call-ref-nil-lt))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-lt
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (lt-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (lt-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-lt
                              step-ref-func-call-ref-nil-lt))))

(defthm step-const-ref-func-call-ref-nil-lt
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (lt-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (lt-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-lt))))

(defmacro lt-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 3)
               (list :call_ref *op-lt-type*))))

(defthm no-ctxt-instrs-on-op-lt-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (lt-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (lt-call-cfg v1 v2))
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
                              step-call-ref-alone-nil-lt
                              step-const-ref-func-call-ref-nil-lt
                              step-ref-func-call-ref-nil-lt))))

(defun ir-frame-lt-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals
                     (list (list (list :const (list :i32) v1))
                           (list (list :const (list :i32) v2))))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0)
                                      (list :local.get 1)
                                      (list :relop (list :i32) (list :lt (list :s))))))))))

(defthm ir-op-lt-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (lt-call-cfg v1 v2)))
                  (ir-frame-lt-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (lt-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-lt-call
                              ir-frame-lt-cfg
                              ir-frame-with-locals)
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; The op_lt redex steps (the inner instructions, before the context lift)
;; ---------------------------------------------------------------------------

(defun lt-frame (v1 v2)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) v1))
         (list (list :const (list :i32) v2)))))

(defun lt-z (v1 v2)
  (list :|%;%| *ir-store* (lt-frame v1 v2)))

(defun lt-body () '((:local.get 0) (:local.get 1) (:relop (:i32) (:lt (:s)))))

(defthm lt-inner0
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (list :|%;%| (lt-z v1 v2)
                                   (list (list :local.get 0))))
                  (list (list :|%;%| (lt-z v1 v2)
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (lt-z v1 v2)
                                     (list (list :local.get 0)))))
           :in-theory (enable lt-z lt-frame)
           :do-not-induct t)))

(defthm lt-inner1
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step (list :|%;%| (lt-z v1 v2)
                                   (list (list :local.get 1))))
                  (list (list :|%;%| (lt-z v1 v2)
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (lt-z v1 v2)
                                     (list (list :local.get 1)))))
           :in-theory (enable lt-z lt-frame)
           :do-not-induct t)))

(defthm lt-innerbin
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2))
           (equal (w3t::step
                   (list :|%;%| (lt-z v1 v2)
                         (list (list :const (list :i32) v1)
                               (list :const (list :i32) v2)
                               (list :relop (list :i32) (list :lt (list :s))))))
                  (list (list :|%;%| (lt-z v1 v2)
                              (list (list :const (list :i32)
                                          (if (< v1 v2) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (lt-z v1 v2)
                           (list (list :const (list :i32) v1)
                                 (list :const (list :i32) v2)
                                 (list :relop (list :i32) (list :lt (list :s)))))))
           :in-theory (e/d (lt-z lt-frame lt-signed-value)
                           (w3t::$ilt_))
           :do-not-induct t)))

; The same three redex steps with the state pair written out, which is the
; form the engine's flat-block lift produces.
(defthm lt-inner0-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :local.get 0))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :const (list :i32) v1))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :local.get 0)))))
           :in-theory (enable lt-frame)
           :do-not-induct t)))

(defthm lt-inner1-explicit
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :local.get 1))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :const (list :i32) v2))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :local.get 1)))))
           :in-theory (enable lt-frame)
           :do-not-induct t)))

(defthm lt-innerbin-explicit
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :const (list :i32) v2)
                               (list :relop (list :i32) (list :lt (list :s))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :const (list :i32)
                                          (if (< v1 v2) 1 0)))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :const (list :i32) v2)
                                 (list :relop (list :i32) (list :lt (list :s)))))))
           :in-theory (e/d (lt-frame lt-signed-value)
                           (w3t::$ilt_))
           :do-not-induct t)))


(encapsulate ()
  (local (include-book "../wasm3/engine"))

  (defthm lt-body-step1
    (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2)
                  (equal inner
                         (w3t::step
                          (list :|%;%|
                                (list :|%;%| *ir-store* (lt-frame v1 v2))
                                (list (list :local.get 0)))))
                  inner)
             (equal (w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (lt-body)))
                    (list (list :|%;%| (cadr (car inner))
                                (append (caddr (car inner))
                                        (list (list :local.get 1)
                                              (list :relop (list :i32)
                                                    (list :lt (list :s)))))))))
    :hints (("Goal"
             :in-theory (e/d (we::op-instr-p we::redex-arity
                                we::vals-p
                                w3t::val-p w3t::num_-p w3t::inn-p
                                w3t::in-p w3t::un-p
                                lt-frame)
                             ())
             :use ((:instance we::step-of-flat-block
                              (we::s *ir-store*)
                              (we::f (lt-frame v1 v2))
                              (we::vals nil)
                              (we::i (list :local.get 0))
                              (we::r (list (list :local.get 1)
                                           (list :relop (list :i32) (list :lt (list :s)))))
                              (we::a 0)
                              (we::inner inner))))))
  )

(defthm lt-body-step2
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (list (list :const (list :i32) v1)
                               (list :local.get 1)
                               (list :relop (list :i32) (list :lt (list :s))))))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :const (list :i32) v2)
                                    (list :relop (list :i32) (list :lt (list :s))))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%|
                           (list :|%;%| *ir-store* (lt-frame v1 v2))
                           (list (list :const (list :i32) v1)
                                 (list :local.get 1)
                                 (list :relop (list :i32) (list :lt (list :s)))))))
           :use ((:instance engine-ctxt-from-values-instr-step
                            (z (list :|%;%| *ir-store* (lt-frame v1 v2)))
                            (x (list (list :const (list :i32) v1)))
                            (i (list :local.get 1))
                            (r (list (list :relop (list :i32) (list :lt (list :s)))))
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :const (list :i32) v2)))))))
           :in-theory (enable milawa-values-p
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p
                              lt-frame)
           :do-not-induct t)))

(defthm lt-body-step1-specific
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%|
                         (list :|%;%| *ir-store* (lt-frame v1 v2))
                         (lt-body)))
                  (list (list :|%;%|
                              (list :|%;%| *ir-store* (lt-frame v1 v2))
                              (list (list :const (list :i32) v1)
                                    (list :local.get 1)
                                    (list :relop (list :i32)
                                          (list :lt (list :s))))))))
  :hints (("Goal"
           :use ((:instance lt-body-step1
                            (inner
                             (list (list :|%;%|
                                         (list :|%;%| *ir-store*
                                               (lt-frame v1 v2))
                                         (list (list :const (list :i32) v1)))))))
           :in-theory (enable lt-inner0-explicit))))

(defthm lt-body-inner3
  (implies (and (unsigned-byte-p 31 v1) (unsigned-byte-p 31 v2))
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (list :|%;%|
                                          (list :|%;%| *ir-store*
                                                (lt-frame v1 v2))
                                          (lt-body))))))))
                  (list :|%;%|
                        (list :|%;%| *ir-store* (lt-frame v1 v2))
                        (list (list :const (list :i32)
                                    (if (< v1 v2) 1 0))))))
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use (lt-body-step1-specific
                 lt-body-step2
                 lt-innerbin-explicit))))

