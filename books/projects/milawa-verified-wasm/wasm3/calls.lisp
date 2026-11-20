; L1, layer 6: entering a call.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The last piece before the opcode theorems: a call pushes a frame and hands
; control to the callee's body.  Measured shape (see context.lisp):
;
;   (step <call to function i>) = ((:FRAME_ 1 F ((:LABEL_ 1 nil BODY))))
;
; with the store and the outer frame unchanged, F the callee's frame with its
; locals zero-initialised, and BODY the callee's code straight out of the store's
; :CODE field -- a constant of the artifact.
;
; The helpers below build exactly that, and they are helpers rather than literals
; for a reason: the body of `step` is two hundred lines and a lemma quoting it
; would be unreadable and would need regenerating whenever the module changed.
; The definition is verified against the artifact by evaluation first (each of the
; three matched), because a right-hand side that merely looks right costs a proof
; attempt to refute.
;
; ONE MORE RULE-ORDERING FACT.  With `(:REF.FUNC_ADDR 6)` counting as a VALUE
; (prefix7 = 1), the ctxt-instrs rule still does not apply to a call -- measured,
; and it is the fact that lets the chain above the call rule be walked:
;
;   (step/prefix7 instrs) = 1     (step/r-ctxt-instrs cfg) = NIL
;   (step/r-call_ref-func cfg) = T (step cfg) has length 1

(in-package "MILAWA-WASM")

(include-book "context")

;; ---------------------------------------------------------------------------
;; The callee's frame and body, as terms
;; ---------------------------------------------------------------------------

; What a local looks like when a frame is created: a singleton list holding the
; zero value, which is the representation frames.lisp records.
(defun zero-local (decl)
  (declare (ignore decl))
  '((:const (:i32) 0)))

(defun zero-locals (decls)
  (if (consp decls)
      (cons (zero-local (car decls)) (zero-locals (cdr decls)))
    nil))

(defun milawa-callee-locals (i)
  (zero-locals (caddr (milawa-func-code i))))

(defun milawa-callee-frame (i)
  (cons :%rec (cons (cons :locals (milawa-callee-locals i))
                    (list (cons :module (milawa-func-module i))))))

; The whole instruction list the call produces: frame, then label, then body.
(defun milawa-callee-admin (i)
  (list (list :frame_%{%}% 1 (milawa-callee-frame i)
              (list (list :label_%{%}% 1 nil (milawa-func-body i))))))

;; ---------------------------------------------------------------------------
;; The rule-ordering fact
;; ---------------------------------------------------------------------------

(defthm no-ctxt-instrs-on-a-call
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list '(:ref.func_addr 6)
                      '(:call_ref (:_def (:rec ((:sub ((:final)) nil
                                                      (:func%->% nil ((:i32))))))
                                        0)))))
         nil)
  :hints (("Goal" :expand ((w3t::step/r-ctxt-instrs
                            (list :|%;%| z
                                  (list '(:ref.func_addr 6)
                                        '(:call_ref (:_def (:rec ((:sub ((:final)) nil
                                                                        (:func%->% nil ((:i32))))))
                                                          0)))))
                           (:free (k lo hi i t9 zz a0)
                                  (w3t::step/search21 k lo hi i t9 zz a0))))))

;; ---------------------------------------------------------------------------
;; The call lemma
;; ---------------------------------------------------------------------------

(defthm step-call-enters-frame
  (equal (w3t::step (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result) (list '(:ref.func_addr 6) '(:call_ref (:_def (:rec ((:sub ((:final)) nil (:func%->% nil ((:i32)))))) 0)))))
         (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result) (milawa-callee-admin 6))))
  :hints (("Goal" :expand ((w3t::step (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result) (list '(:ref.func_addr 6) '(:call_ref (:_def (:rec ((:sub ((:final)) nil (:func%->% nil ((:i32)))))) 0)))))))))
