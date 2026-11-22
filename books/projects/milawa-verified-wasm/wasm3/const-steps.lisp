; L1, the CONST path: the callee's first five positions at the run's state.
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
;   (dbody4 (dadd pc) clen)   -- after the ltu
;
; Each step is the corresponding TAIL-CL-*-FRAME fact, instantiated at this
; state.  The ltu step is the exception: its frame fact is stated with the
; body's literal spelling, so it gets a literal-spelling state and macros
; (see the comment at that step).  The five cost about 125M prover steps
; together; they are kept in their own book so the cheap front composition
; (const-join) does not pay for them on every recertification.
;
; Measured: 6 events, 125,080,472 prover steps, 401.6 s.

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

; The ltu step is the one whose frame fact is stated with the body's literal
; spelling (the two constants and the relop).  Unfolding DBODY3/DBODY4 inside
; the generic state made the :use instance miss and the prover re-derive the
; frame step (it ran past 10 minutes).  Stating the input and output states
; with the same literal body, as macros, and expanding only the state function
; makes the instance match: 5.4M steps, 21 s.
(defun const-tail-ltu-state (bytes sp pc clen result w body)
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

(defmacro const-tail-ltu-input-body (pc clen)
  `(cons (list :const (quote (:i32))
               (car (w3t::$binop_ (quote (:i32)) (quote (:sub)) (dadd ,pc) 4096)))
         (cons (list :const (quote (:i32))
                     (car (w3t::$binop_ (quote (:i32)) (quote (:mul)) ,clen 4)))
               (quote ((:relop (:i32) (:lt (:u))))))))

(defmacro const-tail-ltu-output-body (pc clen)
  `(list (list :const (quote (:i32))
               (w3t::$relop_ (quote (:i32)) (quote (:lt (:u)))
                             (car (w3t::$binop_ (quote (:i32)) (quote (:sub)) (dadd ,pc) 4096))
                             (car (w3t::$binop_ (quote (:i32)) (quote (:mul)) ,clen 4))))))

(defthm const-tail-ltu-bridge
  (equal (const-tail-callee-state bytes sp pc clen result w
                                  (dbody3 (dadd pc) clen))
         (const-tail-ltu-state bytes sp pc clen result w
                               (const-tail-ltu-input-body pc clen)))
  :hints (("Goal" :in-theory (enable const-tail-callee-state const-tail-ltu-state
                                     dbody2 dbody3 dconst dsub dmul))))

(defthm const-tail-ltu-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step
                   (const-tail-ltu-state bytes sp pc clen result w
                                         (const-tail-ltu-input-body pc clen)))
                  (list
                   (const-tail-ltu-state bytes sp pc clen result w
                                         (const-tail-ltu-output-body pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step)
                  :expand ((const-tail-ltu-state bytes sp pc clen result w
                                                 (const-tail-ltu-input-body pc clen))
                           (const-tail-ltu-state bytes sp pc clen result w
                                                 (const-tail-ltu-output-body pc clen)))
                  :use (tail-cl-ltu-frame))))
