; J2b-2, first W3T steps: the op_const body's frame/label/return rules.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The old context library's generic no-ctxt-instrs facts (wasm3/context.lisp)
; apply to the new store as well.  With them, the frame/label local.get steps,
; the two value-return steps, and the frame-around-label-around-value step are
; proved for the op_const body:
;
;   local.get 0 inside frame 1 / label 1       -> the value is pushed
;   label around a value                        -> label dissolves
;   frame around a value                        -> frame dissolves
;   frame around a label around a value         -> the label dissolves
;
; This file now also proves the three-step op_const body composition
; (ir-op-const-body), the value-prefixed no-ctxt fact, the one-step call
; entry, and the four-step ir-op-const-call-result from $INVOKE to the value.
; The remaining J2b-2 pieces are the other opcodes/dispatcher.

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/translate/gen/wasm-3.0/wasm3")
(include-book "../wasm3/context")
(include-book "ops")

(defun ir-frame-with-locals (locals)
  (w3t::%put-field *ir-frame* :locals locals))

(defun ir-z (frame) (list :|%;%| *ir-store* frame))

;; ---------------------------------------------------------------------------
;; Frame / label local.get
;; ---------------------------------------------------------------------------

(defun ir-label-local-get-cfg (frame)
  (list :|%;%| (ir-z frame)
        (list (list :label_%{%}% 1 nil (list (list :local.get 0))))))

(defun ir-label-value-cfg (frame l0)
  (list :|%;%| (ir-z frame)
        (list (list :label_%{%}% 1 nil (list l0)))))

(defthm ir-step-in-label-local-get
  (equal (w3t::step (ir-label-local-get-cfg
                     (ir-frame-with-locals (list (list l0)))))
         (list (ir-label-value-cfg
                (ir-frame-with-locals (list (list l0))) l0)))
  :hints (("Goal" :in-theory (enable ir-label-local-get-cfg
                                     ir-label-value-cfg ir-z
                                     ir-frame-with-locals)
                  :expand ((w3t::step
                            (ir-label-local-get-cfg
                             (ir-frame-with-locals (list (list l0)))))))))

(defun ir-frame-local-get-cfg (l0)
  (list :|%;%| (list :|%;%| *ir-store* *ir-frame*)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals (list (list l0)))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0))))))))

(defun ir-frame-value-cfg (l0)
  (list :|%;%| (list :|%;%| *ir-store* *ir-frame*)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals (list (list l0)))
                    (list (list :label_%{%}% 1 nil (list l0)))))))

(defthm ir-step-in-frame-local-get
  (equal (w3t::step (ir-frame-local-get-cfg l0))
         (list (ir-frame-value-cfg l0)))
  :hints (("Goal" :in-theory (enable ir-frame-local-get-cfg
                                     ir-frame-value-cfg ir-frame-with-locals)
                  :use (ir-step-in-label-local-get)
                  :expand ((w3t::step (ir-frame-local-get-cfg l0))))))

;; ---------------------------------------------------------------------------
;; Value returns
;; ---------------------------------------------------------------------------

(defun ir-label-vals-cfg (z v)
  (list :|%;%| z
        (list (list :label_%{%}% 1 nil
                    (list (list :const (list :i32) v))))))

(defthm ir-step-label-vals
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step (ir-label-vals-cfg z v))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) v))))))
  :hints (("Goal" :in-theory (enable ir-label-vals-cfg)
                  :expand ((w3t::step (ir-label-vals-cfg z v))))))

(defun ir-frame-vals-cfg (z f v)
  (list :|%;%| z
        (list (list :frame_%{%}% 1 f
                    (list (list :const (list :i32) v))))))

(defun ir-value-cfg (z v)
  (list :|%;%| z (list (list :const (list :i32) v))))

(defthm ir-step-frame-vals
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step (ir-frame-vals-cfg z f v))
                  (list (ir-value-cfg z v))))
  :hints (("Goal" :in-theory (enable ir-frame-vals-cfg ir-value-cfg)
                  :expand ((w3t::step (ir-frame-vals-cfg z f v))))))

;; ---------------------------------------------------------------------------
;; Frame around label around value, and the op_const body
;; ---------------------------------------------------------------------------

(defun ir-label-vals-in-frame-cfg (store outer f v)
  (list :|%;%| (list :|%;%| store outer)
        (list (list :frame_%{%}% 1 f
                    (list (list :label_%{%}% 1 nil
                                (list (list :const (list :i32) v))))))))

(defthm ir-step-label-vals-in-frame
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step (ir-label-vals-in-frame-cfg store outer f v))
                  (list (ir-frame-vals-cfg
                         (list :|%;%| store outer) f v))))
  :hints (("Goal" :in-theory (enable w3t::step) :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; Composing the three steps: the op_const body
;; ---------------------------------------------------------------------------
;;
;; The three lemmas above are stated for a whole STEP result, a trace of one
;; configuration.  The body of op_const drives the machine by taking CAR after
;; each STEP, so the composition uses the CAR forms below.

(defthm ir-step1-in-frame-local-get
  (equal (car (w3t::step (ir-frame-local-get-cfg l0)))
         (ir-frame-value-cfg l0))
  :hints (("Goal" :use (ir-step-in-frame-local-get)
                  :in-theory (enable ir-frame-local-get-cfg
                                     ir-frame-value-cfg
                                     ir-frame-with-locals))))

;; Rewrite IR-FRAME-VALUE-CFG at the op_const argument to the generic
;; frame-around-label-around-value shape, so IR-STEP-LABEL-VALS-IN-FRAME
;; applies without unfolding either helper.
(defthm ir-frame-value-cfg-is-in-frame
  (equal (ir-frame-value-cfg (list :const (list :i32) v))
         (ir-label-vals-in-frame-cfg
          *ir-store* *ir-frame*
          (ir-frame-with-locals (list (list (list :const (list :i32) v))))
          v))
  :hints (("Goal" :in-theory (enable ir-frame-value-cfg
                                     ir-label-vals-in-frame-cfg
                                     ir-frame-with-locals))))

(defthm ir-step1-frame-value
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (ir-frame-value-cfg (list :const (list :i32) v))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* *ir-frame*)
                   (ir-frame-with-locals
                    (list (list (list :const (list :i32) v))))
                   v)))
  :hints (("Goal" :in-theory (e/d (ir-frame-value-cfg-is-in-frame)
                                  (ir-frame-value-cfg
                                   ir-label-vals-in-frame-cfg
                                   ir-frame-with-locals
                                   w3t::step)))))

(defthm ir-step1-frame-vals
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step (ir-frame-vals-cfg z f v)))
                  (ir-value-cfg z v)))
  :hints (("Goal" :in-theory (disable w3t::step
                                     ir-frame-vals-cfg
                                     ir-value-cfg))))

;; The op_const body: from the callee frame with local v, three spec steps
;; leave the value ((:CONST (:I32) v)).  This is the local.get -> label
;; dissolve -> frame dissolve chain, composed by the three CAR step lemmas.
(defthm ir-op-const-body
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (ir-frame-local-get-cfg
                                     (list :const (list :i32) v))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-frame*)
                   v)))
  :hints (("Goal"
           :in-theory (disable w3t::step
                               ir-frame-local-get-cfg
                               ir-frame-value-cfg
                               ir-label-vals-in-frame-cfg
                               ir-frame-vals-cfg
                               ir-value-cfg
                               ir-frame-with-locals
                               ir-frame-value-cfg-is-in-frame)
           :use ((:instance ir-step1-in-frame-local-get
                            (l0 (list :const (list :i32) v)))
                 (:instance ir-step1-frame-value (v v))
                 (:instance ir-step1-frame-vals
                            (z (list :|%;%| *ir-store* *ir-frame*))
                            (f (ir-frame-with-locals
                                (list (list (list :const (list :i32) v)))))
                            (v v))))))

;; ---------------------------------------------------------------------------
;; The $INVOKE entry configuration
;; ---------------------------------------------------------------------------

;; $INVOKE builds an empty call frame (an empty module), not *ir-frame*.
(defconst *ir-call-frame*
  '(:%rec (:locals)
          (:module :%rec (:types) (:tags) (:globals) (:mems) (:tables)
                   (:funcs) (:datas) (:elems) (:exports))))

(defun ir-op-const-invoke-cfg (v)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v)
              '(:ref.func_addr 0)
              '(:call_ref
                (:_def
                 (:rec ((:sub ((:final)) nil
                              (:func%->% ((:i32)) ((:i32))))))
                 0)))))

(defthm ir-op-const-invoke
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::$invoke *ir-store* 0
                                (list (list :const (list :i32) v)))
                  (ir-op-const-invoke-cfg v)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

;; ---------------------------------------------------------------------------
;; The value-prefixed no-ctxt fact and the one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-const-type*
  '(:_def (:rec ((:sub ((:final)) nil (:func%->% ((:i32)) ((:i32)))))) 0))

;; STEP/PREFIX7 sees the value (:CONST (:I32) v) and the (:REF.FUNC_ADDR 0)
;; as the two leading values; the call_ref is not a value.
(defthm prefix7-op-const-call
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v)
                         (list :ref.func_addr 0)
                         (list :call_ref *op-const-type*)))
                  2))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

;; The old calls.lisp fact, at function 0/type 0.
(defthm no-ctxt-instrs-on-ref-func-call-ref0
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 0)
                      (list :call_ref *op-const-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 0)
                                 (list :call_ref *op-const-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone0
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-const-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-const-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

;; The two suffixes the search tries are stuck: the call_ref has no
;; function reference, and the (ref.func, call_ref) pair has no argument.
(defthm step-call-ref-alone-nil
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-const-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-const-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone0))))

(defthm step-ref-func-call-ref-nil
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 0)
                      (list :call_ref *op-const-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 0)
                                 (list :call_ref *op-const-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref0))))

(defthm no-ctxt-instrs-on-op-const-call
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                         (list (list :const (list :i32) v)
                               (list :ref.func_addr 0)
                               (list :call_ref *op-const-type*))))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :const (list :i32) v)
                                 (list :ref.func_addr 0)
                                 (list :call_ref *op-const-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p))))

;; The callee-frame configuration the body lemmas use, at an arbitrary z.
(defun ir-frame-local-get-cfg-z (z l0)
  (list :|%;%| z
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals (list (list l0)))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0))))))))

;; One STEP from $INVOKE enters the callee frame.
(defthm ir-op-const-call-entry
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                              (list (list :const (list :i32) v)
                                    (list :ref.func_addr 0)
                                    (list :call_ref *op-const-type*)))))
                  (ir-frame-local-get-cfg-z
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   (list :const (list :i32) v))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :const (list :i32) v)
                                 (list :ref.func_addr 0)
                                 (list :call_ref *op-const-type*)))))
           :in-theory (enable no-ctxt-instrs-on-op-const-call
                              ir-frame-local-get-cfg-z
                              ir-frame-with-locals)
           :do-not-induct t)))

;; ---------------------------------------------------------------------------
;; The generalized body: arbitrary outer frame
;; ---------------------------------------------------------------------------

(defun ir-frame-local-get-cfg-o (outer l0)
  (list :|%;%| (list :|%;%| *ir-store* outer)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals (list (list l0)))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0))))))))

(defun ir-frame-value-cfg-o (outer l0)
  (list :|%;%| (list :|%;%| *ir-store* outer)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals (list (list l0)))
                    (list (list :label_%{%}% 1 nil (list l0)))))))

(defthm ir-step-in-frame-local-get-o
  (equal (w3t::step (ir-frame-local-get-cfg-o outer l0))
         (list (ir-frame-value-cfg-o outer l0)))
  :hints (("Goal" :in-theory (enable ir-frame-local-get-cfg-o
                                     ir-frame-value-cfg-o
                                     ir-frame-with-locals)
                  :use (ir-step-in-label-local-get)
                  :expand ((w3t::step (ir-frame-local-get-cfg-o outer l0))))))

(defthm ir-step1-in-frame-local-get-o
  (equal (car (w3t::step (ir-frame-local-get-cfg-o outer l0)))
         (ir-frame-value-cfg-o outer l0))
  :hints (("Goal" :use (ir-step-in-frame-local-get-o)
                  :in-theory (enable ir-frame-local-get-cfg-o
                                     ir-frame-value-cfg-o
                                     ir-frame-with-locals))))

(defthm ir-frame-value-cfg-o-is-in-frame
  (equal (ir-frame-value-cfg-o outer (list :const (list :i32) v))
         (ir-label-vals-in-frame-cfg
          *ir-store* outer
          (ir-frame-with-locals (list (list (list :const (list :i32) v))))
          v))
  :hints (("Goal" :in-theory (enable ir-frame-value-cfg-o
                                     ir-label-vals-in-frame-cfg
                                     ir-frame-with-locals))))

(defthm ir-step1-frame-value-o
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (ir-frame-value-cfg-o outer (list :const (list :i32) v))))
                  (ir-frame-vals-cfg
                   (list :|%;%| *ir-store* outer)
                   (ir-frame-with-locals
                    (list (list (list :const (list :i32) v))))
                   v)))
  :hints (("Goal" :in-theory (e/d (ir-frame-value-cfg-o-is-in-frame)
                                  (ir-frame-value-cfg-o
                                   ir-label-vals-in-frame-cfg
                                   ir-frame-with-locals
                                   w3t::step)))))

(defthm ir-op-const-body-o
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (ir-frame-local-get-cfg-o
                                     outer
                                     (list :const (list :i32) v))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* outer)
                   v)))
  :hints (("Goal"
           :in-theory (disable w3t::step
                               ir-frame-local-get-cfg-o
                               ir-frame-value-cfg-o
                               ir-label-vals-in-frame-cfg
                               ir-frame-vals-cfg
                               ir-value-cfg
                               ir-frame-with-locals
                               ir-frame-value-cfg-o-is-in-frame)
           :use ((:instance ir-step1-in-frame-local-get-o
                            (l0 (list :const (list :i32) v))
                            (outer outer))
                 (:instance ir-step1-frame-value-o
                            (v v) (outer outer))
                 (:instance ir-step1-frame-vals
                            (z (list :|%;%| *ir-store* outer))
                            (f (ir-frame-with-locals
                                (list (list (list :const (list :i32) v)))))
                            (v v))))))

(defthm ir-op-const-call-entry-invoke
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step (ir-op-const-invoke-cfg v)))
                  (ir-frame-local-get-cfg-o
                   *ir-call-frame*
                   (list :const (list :i32) v))))
  :hints (("Goal" :in-theory (enable ir-op-const-invoke-cfg
                                     ir-frame-local-get-cfg-o
                                     ir-frame-local-get-cfg-z
                                     ir-frame-with-locals)
                  :use (ir-op-const-call-entry))))

;; $INVOKE, one call step, and the three body steps, in one composition.
(defthm ir-op-const-call-result
  (implies (unsigned-byte-p 32 v)
           (equal (car (w3t::step
                        (car (w3t::step
                              (car (w3t::step
                                    (car (w3t::step
                                          (ir-op-const-invoke-cfg v)))))))))
                  (ir-value-cfg
                   (list :|%;%| *ir-store* *ir-call-frame*)
                   v)))
  :hints (("Goal"
           :in-theory (disable w3t::step
                               ir-op-const-invoke-cfg
                               ir-frame-local-get-cfg-o
                               ir-frame-value-cfg-o
                               ir-label-vals-in-frame-cfg
                               ir-frame-vals-cfg
                               ir-value-cfg
                               ir-frame-with-locals)
           :use (ir-op-const-call-entry-invoke
                 (:instance ir-op-const-body-o
                            (outer *ir-call-frame*))))))

;; ---------------------------------------------------------------------------
;; op_add (function 1): entry and one-step call entry
;; ---------------------------------------------------------------------------

(defconst *op-add-type*
  '(:_def (:rec ((:sub ((:final)) nil
                        (:func%->% ((:i32) (:i32)) ((:i32)))))) 0))

(defun ir-op-add-invoke-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :const (list :i32) v1)
              (list :const (list :i32) v2)
              (list :ref.func_addr 1)
              (list :call_ref *op-add-type*))))

(defthm ir-op-add-invoke
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::$invoke *ir-store* 1
                                (list (list :const (list :i32) v1)
                                      (list :const (list :i32) v2)))
                  (ir-op-add-invoke-cfg v1 v2)))
  :hints (("Goal" :in-theory (enable w3t::$invoke))))

(defthm prefix7-op-add-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/prefix7
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :ref.func_addr 1)
                         (list :call_ref *op-add-type*)))
                  3))
  :hints (("Goal" :in-theory (enable w3t::step/prefix7
                                     w3t::val-p))))

(defmacro add-suffix-cfg (v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v2)
               (list :ref.func_addr 1)
               (list :call_ref *op-add-type*))))

(defthm no-ctxt-instrs-on-ref-func-call-ref1
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :ref.func_addr 1)
                      (list :call_ref *op-add-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z
                           (list (list :ref.func_addr 1)
                                 (list :call_ref *op-add-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm no-ctxt-instrs-on-call-ref-alone1
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :call_ref *op-add-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%| z (list (list :call_ref *op-add-type*))))
                    (:free (k lo hi i t9 zz a0)
                     (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm step-call-ref-alone-nil-add
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :call_ref *op-add-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :call_ref *op-add-type*)))))
           :in-theory (enable no-ctxt-instrs-on-call-ref-alone1))))

(defthm step-ref-func-call-ref-nil-add
  (equal (w3t::step
          (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                (list (list :ref.func_addr 1)
                      (list :call_ref *op-add-type*))))
         nil)
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| (list :|%;%| *ir-store* *ir-call-frame*)
                           (list (list :ref.func_addr 1)
                                 (list :call_ref *op-add-type*)))))
           :in-theory (enable no-ctxt-instrs-on-ref-func-call-ref1))))

(defthm search21-add-suffix-k0
  (equal (w3t::step/search21
          0 0 2
          (caddr (add-suffix-cfg v2))
          2
          (cadr (add-suffix-cfg v2))
          (add-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0))))))

(defthm search21-add-suffix-k1
  (equal (w3t::step/search21
          1 0 2
          (caddr (add-suffix-cfg v2))
          2
          (cadr (add-suffix-cfg v2))
          (add-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-ref-func-call-ref-nil-add))))

(defthm search21-add-suffix-k2
  (equal (w3t::step/search21
          2 0 2
          (caddr (add-suffix-cfg v2))
          2
          (cadr (add-suffix-cfg v2))
          (add-suffix-cfg v2))
         nil)
  :hints (("Goal"
           :expand ((:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable step-call-ref-alone-nil-add
                              step-ref-func-call-ref-nil-add))))

(defthm no-ctxt-instrs-on-const-ref-func-call-ref-add
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step/r-ctxt-instrs (add-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (add-suffix-cfg v2))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 2 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 1 lo hi i t9 zz a0))
                    (:free (lo hi i t9 zz a0)
                     (w3t::step/search21 0 lo hi i t9 zz a0)))
           :in-theory (enable w3t::step/prefix7
                              w3t::val-p
                              step-call-ref-alone-nil-add
                              step-ref-func-call-ref-nil-add))))

(defthm step-const-ref-func-call-ref-nil-add
  (implies (unsigned-byte-p 32 v2)
           (equal (w3t::step (add-suffix-cfg v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step (add-suffix-cfg v2)))
           :in-theory (enable no-ctxt-instrs-on-const-ref-func-call-ref-add))))

(defmacro add-call-cfg (v1 v2)
  `(list :|%;%|
         (list :|%;%| *ir-store* *ir-call-frame*)
         (list (list :const (list :i32) ,v1)
               (list :const (list :i32) ,v2)
               (list :ref.func_addr 1)
               (list :call_ref *op-add-type*))))

(defthm no-ctxt-instrs-on-op-add-call
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (w3t::step/r-ctxt-instrs (add-call-cfg v1 v2))
                  nil))
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (add-call-cfg v1 v2))
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
                              step-call-ref-alone-nil-add
                              step-const-ref-func-call-ref-nil-add
                              step-ref-func-call-ref-nil-add))))

(defun ir-frame-add-cfg (v1 v2)
  (list :|%;%|
        (list :|%;%| *ir-store* *ir-call-frame*)
        (list (list :frame_%{%}% 1
                    (ir-frame-with-locals
                     (list (list (list :const (list :i32) v1))
                           (list (list :const (list :i32) v2))))
                    (list (list :label_%{%}% 1 nil
                                (list (list :local.get 0)
                                      (list :local.get 1)
                                      (list :binop (list :i32) (list :add)))))))))

(defthm ir-op-add-call-entry
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (car (w3t::step (add-call-cfg v1 v2)))
                  (ir-frame-add-cfg v1 v2)))
  :hints (("Goal"
           :expand ((w3t::step (add-call-cfg v1 v2)))
           :in-theory (enable no-ctxt-instrs-on-op-add-call
                              ir-frame-add-cfg
                              ir-frame-with-locals)
           :do-not-induct t)))

;; The remaining J2b-2 pieces are the op_add body (the two local.gets and
;; binop through the frame), the other opcode bodies, and the dispatcher.
;;
;; Call-entry finding (checked by evaluation).  Calling function 0 with the
;; value (:CONST (:I32) v) is
;;
;;   ($INVOKE *ir-store* 0 (list (list :const (list :i32) v)))
;;     = (:%;% (:% *ir-store* <empty-call-frame>)
;;             ((:const (:i32) v) (:ref.func_addr 0) (:call_ref <type>)))
;;
;; where <empty-call-frame> is (:locals)/(:module (:types)(:tags)...(:exports)),
;; NOT *ir-frame* (whose :module is the full module).  One STEP enters the
;; callee frame, i.e. this body's ir-frame-local-get-cfg at that outer frame.
;; The symbolic proof has to discharge STEP/R-CTXT-INSTRS for the value
;; prefix; calls.lisp's no-ctxt-instrs-on-a-call is the no-prefix fact, and
;; the prefixed version is the open piece.
;; ---------------------------------------------------------------------------
