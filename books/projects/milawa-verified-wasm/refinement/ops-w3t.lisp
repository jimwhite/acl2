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
; The remaining J2b-2 pieces are the three-step body composition (the helper
; terms do not normalize across the three facts yet), the call entry from
; $INVOKE, and the remaining opcodes/dispatcher.

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

;; The op_const body is the three-step chain
;;   ir-step-in-frame-local-get  ->  ir-step-label-vals-in-frame  ->
;;   ir-step-frame-vals
;; at l0 = (:CONST (:I32) v).  Each step is proved above; composing them in
;; one defthm with :use still does not close (the config helper terms do not
;; normalize across the three facts yet).  That composition is the next
;; J2b-2 piece.  The call entry from $INVOKE and the remaining opcodes follow.
;; ---------------------------------------------------------------------------

;; The body theorem is the op_const W3T body: from the callee frame with local
;; v, three spec steps leave ((:CONST (:I32) v)).  The call entry from
;; $INVOKE and the remaining opcodes are the next J2b-2 pieces.
;; ---------------------------------------------------------------------------
