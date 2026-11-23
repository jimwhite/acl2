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
; (ir-op-const-body), by taking CAR after each STEP.  The remaining J2b-2
; pieces are the call entry from $INVOKE and the other opcodes/dispatcher.

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

;; The remaining J2b-2 pieces are the call entry from $INVOKE (one STEP from
;; ir-op-const-invoke-cfg, blocked on STEP/R-CTXT-INSTRS for the value
;; prefix) and the other opcode bodies/dispatcher.
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
