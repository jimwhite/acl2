; L1, the CONST path: the callee's first four positions at the run's state.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The tail books prove each callee position as a step of a label-1 body whose
; label 0 contains frame 3 around the callee's body (const-callee.lisp).  This
; book re-states those four steps at one generic run-level state:
;
;   CONST-TAIL-CALLEE-STATE  the outer frame 6, label 1, label 0, frame 3
;                            around an arbitrary callee body
;
; and the body progresses exactly as the dispatcher's abbreviations say:
;
;   (milawa-func-body 3)      -- the read of global 1
;   (dbody0 (dadd pc))        -- after it
;   (dbody1 (dadd pc))        -- after the sub
;   (dbody2 (dadd pc) clen)   -- after the read of global 2
;   (dbody3 (dadd pc) clen)   -- after the mul
;
; Each step is the corresponding TAIL-CL-*-FRAME fact, instantiated at this
; state.  The four cost about 120M prover steps together; they are kept in
; their own book so the cheap front composition (const-join) does not pay for
; them on every recertification.
;
; Measured: 4 events, 119,671,938 prover steps, 383 s.

(in-package "MILAWA-WASM")

(include-book "const-join")
(include-book "const-callee")

(defun const-tail-callee-state (bytes sp pc clen result w body)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%|
        (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w))
              *frozen-entry-frame*)
        (list
         (list :frame_%{%}% 1
               (w3t::$fof (gset bytes sp pc clen result w))
               (list
                (list :label_%{%}% 1 nil
                      (cons (list :label_%{%}% 0 nil
                                  (cons (list :frame_%{%}% 1 (milawa-callee-frame 3)
                                              (list (list :label_%{%}% 1 nil body)))
                                        (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                            (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

(defthm const-tail-read1-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step
                   (const-tail-callee-state bytes sp pc clen result w
                                            (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))
                  (list
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody0 (dadd pc))))))
  :hints (("Goal" :in-theory (enable const-tail-callee-state dbody0 ibody3-after-1 milawa-func-body)
                  :use (tail-cl-read1-frame))))

(defthm const-tail-sub-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody0 (dadd pc))))
                  (list
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody1 (dadd pc))))))
  :hints (("Goal" :in-theory (enable const-tail-callee-state dbody0 dbody1 ibody3-after-1 milawa-func-body)
                  :use (tail-cl-sub-frame))))

(defthm const-tail-read2-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody1 (dadd pc))))
                  (list
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody2 (dadd pc) clen)))))
  :hints (("Goal" :in-theory (enable const-tail-callee-state dbody1 dbody2 ibody3-after-1 milawa-func-body)
                  :use (tail-cl-read2-frame))))

(defthm const-tail-mul-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody2 (dadd pc) clen)))
                  (list
                   (const-tail-callee-state bytes sp pc clen result w
                                            (dbody3 (dadd pc) clen)))))
  :hints (("Goal" :in-theory (enable const-tail-callee-state dbody2 dbody3 ibody3-after-1 milawa-func-body)
                  :use (tail-cl-mul-frame))))
