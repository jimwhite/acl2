; Entering the STEP dispatcher (function 7) from $INVOKE.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-frame-traces")

(defconst *op-step-type*
  '(:_def
    (:rec ((:sub ((:final)) nil
                 (:func%->% ((:i32) (:i32) (:i32)) ((:i32))))))
    0))

(defun ir-op-step-invoke-cfg (op a b)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) op)
              (list :const (list :i32) a)
              (list :const (list :i32) b)
              (list :ref.func_addr 7)
              (list :call_ref *op-step-type*))))

(defthm ir-op-step-invoke
  (implies (and (unsigned-byte-p 32 op)
                (unsigned-byte-p 32 a)
                (unsigned-byte-p 32 b))
           (equal (w3t::$invoke
                   *ir-store* 7
                   (list (list :const (list :i32) op)
                         (list :const (list :i32) a)
                         (list :const (list :i32) b)))
                  (ir-op-step-invoke-cfg op a b)))
  :hints (("Goal" :in-theory (enable w3t::$invoke
                                     w3t::$invoke/all4
                                     w3t::$invoke/iter5
                                     w3t::val_ok
                                     w3t::val_ok/r-num
                                     w3t::val_ok/r-vec
                                     w3t::val_ok/r-ref
                                     w3t::num_ok
                                     w3t::num_ok/r0
                                     w3t::num-p
                                     w3t::num_-p
                                     w3t::ref-p
                                     w3t::vec-p
                                     w3t::expand
                                     w3t::expand/r0
                                     w3t::in-p
                                     ir-op-step-invoke-cfg))))

; The three arguments and the function reference are values; the call_ref is
; not.  So STEP/PREFIX7 skips four leading value instructions.

(defthm val-p-const-i32-ubp
  (implies (unsigned-byte-p 32 v)
           (w3t::val-p (list :const (list :i32) v)))
  :hints (("Goal" :in-theory (e/d (w3t::val-p w3t::num-p w3t::num_-p
                                            w3t::in-p w3t::inn-p w3t::un-p)
                                  ()))))

(defthm val-p-ref-func-7
  (w3t::val-p (list :ref.func_addr 7))
  :hints (("Goal" :in-theory (enable w3t::val-p))))

(defthm not-val-p-call-ref
  (not (w3t::val-p (list :call_ref *op-step-type*)))
  :hints (("Goal" :in-theory (enable w3t::val-p))))

(defthm prefix7-op-step-call
  (implies (and (unsigned-byte-p 32 op)
                (unsigned-byte-p 32 a)
                (unsigned-byte-p 32 b))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) op)
                         (list :const (list :i32) a)
                         (list :const (list :i32) b)
                         (list :ref.func_addr 7)
                         (list :call_ref *op-step-type*)))
                  4))
  :hints (("Goal" :in-theory (e/d (w3t::step/prefix7
                                   we::first-nonval
                                   val-p-const-i32-ubp
                                   val-p-ref-func-7
                                   not-val-p-call-ref)
                                  (w3t::val-p))
           :do-not-induct t)))

(defthm no-ctxt-instrs-call-alone
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :call_ref *op-step-type*))))
         nil)
  :hints (("Goal"
           :use ((:instance we::step/r-ctxt-instrs-of-one-instr
                            (we::z (list :|%;%| *ir-store* *ir-call-frame*))
                            (i (list :call_ref *op-step-type*))))
           :in-theory (disable we::step/r-ctxt-instrs-of-one-instr
                               w3t::val-p))))

(defthm step-call-alone-nil
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :call_ref *op-step-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :call_ref *op-step-type*)))))
           :in-theory (enable no-ctxt-instrs-call-alone
                              we::step-rule-defs))))

(defthm no-ctxt-instrs-ref-func-call
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
         nil)
  :hints (("Goal"
           :expand ((we::flat-search 1 (list (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 0 (list (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*)))
           :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                            (x (list (list :ref.func_addr 7)))
                            (i (list :call_ref *op-step-type*))
                            (r nil)
                            (we::z (list :|%;%| *ir-store* *ir-call-frame*))))
           :in-theory (e/d (val-p-ref-func-7
                              not-val-p-call-ref
                              step-call-alone-nil
                              we::vals-p)
                              (we::step/r-ctxt-instrs-becomes-flat-search)))))

(defthm step-ref-func-call-nil
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :ref.func_addr 7) (list :call_ref *op-step-type*)))))
           :in-theory (enable no-ctxt-instrs-ref-func-call
                              we::step-rule-defs))))

(defthm no-ctxt-instrs-const-ref-func-call
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) v1) (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
                  nil))
  :hints (("Goal"
           :expand ((we::flat-search 2 (list (list :const (list :i32) v1) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 1 (list (list :const (list :i32) v1) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 0 (list (list :const (list :i32) v1) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*)))
           :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                            (x (list (list :const (list :i32) v1) (list :ref.func_addr 7)))
                            (i (list :call_ref *op-step-type*))
                            (r nil)
                            (we::z (list :|%;%| *ir-store* *ir-call-frame*))))
           :in-theory (e/d (val-p-const-i32-ubp
                              val-p-ref-func-7
                              not-val-p-call-ref
                              step-call-alone-nil
                              step-ref-func-call-nil
                              we::vals-p)
                              (we::step/r-ctxt-instrs-becomes-flat-search)))))

(defthm step-const-ref-func-call-nil
  (implies (unsigned-byte-p 32 v1)
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) v1) (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*) (list (list :const (list :i32) v1) (list :ref.func_addr 7) (list :call_ref *op-step-type*)))))
           :in-theory (enable no-ctxt-instrs-const-ref-func-call
                              we::step-rule-defs))))

(defthm no-ctxt-instrs-2const-ref-func-call
  (implies (and (unsigned-byte-p 32 v1)
                (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
                  nil))
  :hints (("Goal"
           :expand ((we::flat-search 3 (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 2 (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 1 (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 0 (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*)))
           :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                            (x (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7)))
                            (i (list :call_ref *op-step-type*))
                            (r nil)
                            (we::z (list :|%;%| *ir-store* *ir-call-frame*))))
           :in-theory (e/d (val-p-const-i32-ubp
                              val-p-ref-func-7
                              not-val-p-call-ref
                              step-call-alone-nil
                              step-ref-func-call-nil
                              step-const-ref-func-call-nil
                              we::vals-p)
                              (we::step/r-ctxt-instrs-becomes-flat-search)))))

(defthm step-2const-ref-func-call-nil
  (implies (and (unsigned-byte-p 32 v1)
                (unsigned-byte-p 32 v2))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :const (list :i32) v1) (list :const (list :i32) v2) (list :ref.func_addr 7) (list :call_ref *op-step-type*)))))
           :in-theory (enable no-ctxt-instrs-2const-ref-func-call
                              we::step-rule-defs))))

(defthm no-ctxt-instrs-on-op-step-call
  (implies (and (unsigned-byte-p 32 op)
                (unsigned-byte-p 32 a)
                (unsigned-byte-p 32 b))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7) (list :call_ref *op-step-type*))))
                  nil))
  :hints (("Goal"
           :expand ((we::flat-search 4 (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 3 (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 2 (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 1 (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*))
                    (we::flat-search 0 (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)) (list :call_ref *op-step-type*) nil (list :|%;%| *ir-store* *ir-call-frame*)))
           :use ((:instance we::step/r-ctxt-instrs-becomes-flat-search
                            (x (list (list :const (list :i32) op) (list :const (list :i32) a) (list :const (list :i32) b) (list :ref.func_addr 7)))
                            (i (list :call_ref *op-step-type*))
                            (r nil)
                            (we::z (list :|%;%| *ir-store* *ir-call-frame*))))
           :in-theory (e/d (val-p-const-i32-ubp
                              val-p-ref-func-7
                              not-val-p-call-ref
                              step-call-alone-nil
                              step-ref-func-call-nil
                              step-const-ref-func-call-nil
                              step-2const-ref-func-call-nil
                              we::vals-p)
                              (we::step/r-ctxt-instrs-becomes-flat-search)))))

