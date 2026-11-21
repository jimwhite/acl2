(in-package "MILAWA-WASM")

(include-book "const")

; L1, the CONST path's tail: the run's steps inside the frame after the front.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The front (const.lisp) leaves the run at
;
;   (:%;% (:%;% ($sof gset) *frozen-entry-frame*)
;         ((:frame 1 ($fof gset) ((:label 1 nil ((:label 0 nil TAIL13) :: rest13))))))
;
; where gset is the store after the front's two writes (global 1 := pc+4) and
; the callee frame has local 0 = the opcode.  The run's tail is NOT the const
; book's chain: the chain's facts are at iz6 (the frozen store, the zero-local
; callee frame) and wrap the body in a label 1 with no label 0 and no rest.
; This book builds the tail at the run's own states.
;
; The first step, end to end, is the template the rest follow:
;
;   tail-call-split      the lone (:CALL 3) at the run's state (plain
;                        evaluation: the dispatcher must be ENABLED, unlike
;                        the front's facts)
;   tail-ctxt            the TAIL13 ctxt-instrs step, the book's recipe with
;                        the lone-call slice supplied by tail-call-split
;   tail-step            the step from the ctxt step
;   tail-label0          the lone label 0 around TAIL13 (the book's dlabel6
;                        hint shape: step enabled, only ctxt-instrs disabled,
;                        the ctxt-label definition instance + the inner step)
;   tail-label0-rest     the ctxt-instrs slice of the label 0 with rest13 after
;   tail1-*              the label-1 lift's premises (the two step_pure and the
;                        two step_read refusals and the size check)
;   tail-label1          the label-1 lift (LABEL-LIFT-GENERAL at the run's
;                        states, the premises handed in)
;   tail-frame1          the frame rule at the run's outer configuration --
;                        the run's first tail step, at the config the front
;                        leaves off
;
; The z's: the run's inner state is (:%;% ($sof (gset ...)) ($fof (gset ...)))
; (the frame rule's inner pair); the outer frame is *frozen-entry-frame*.

(defun gset (bytes sp pc clen result w)
  (w3t::$with_global
   (list :|%;%| (frozen-store bytes sp pc clen 1 result)
         (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))))
   1 (list :const (list :i32) (dadd pc))))
(defthm tail-call-split
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))
                          (list (list :call 3))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))
                     (list (list :ref.func_addr 3) *t3*)))))

(defthm tail-ctxt
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
                 (:instance (:definition w3t::step/prefix7) (w3t::%s (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (w3t::%t9 0)
                            (w3t::z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
                 tail-call-split))))
(defthm tail-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
           :use (tail-ctxt))))
(defthm tail-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
                 tail-step))))

; ---- the label-0-with-rest ctxt step -------------------------------------
(defthm tail-label0-rest
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                 (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%t9 0)
                            (w3t::z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                 tail-label0))))

; ---- the label-1 lift's premises ------------------------------------------
(defthm tail1-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))
(defthm tail1-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))
(defthm tail1-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))
(defthm tail1-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))
(defthm tail1-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

; ---- the label-1 lift -----------------------------------------------------
(defthm tail-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-label0-rest tail1-spure-body tail1-sread-body
                 tail1-spure-label tail1-sread-label tail1-size))))

; ---- the frame lift: the run-level step ------------------------------------
(defthm tail-frame1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (gset bytes sp pc clen result w)) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (gset bytes sp pc clen result w)) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (gset bytes sp pc clen result w))) (fp (w3t::$fof (gset bytes sp pc clen result w))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (z1 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (b (cons (list :label_%{%}% 0 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-label1))))
; the run's first tail step, at the config the front leaves off:


; ---------------------------------------------------------------------------
; THE SECOND TAIL STEP: the call entry, end to end
; ---------------------------------------------------------------------------
;
; The second step's label-0 body is a CONS term (the (:REF.FUNC_ADDR 3)
; (*t3*) pair followed by rest12), not a quoted literal, and the frame
; rung's premise then has to match at the explicit-pair z spelling
; (:%;% ($sof (gset ...)) ($fof (gset ...))).  The recipe, proven here:
;
;   * all the state's constructors AND the W3T projections ($sof/$fof/$s/$f/
;     $store/$frame) and gset stay OPAQUE -- an opaque (gset ...) cannot
;     answer the projections' own (CONSP (GSET ...)) checks, and an unfolded
;     store poisons the acl2-count measure checks with rationals;
;   * two generic projection facts, sof-of-a-pair/fof-of-a-pair, project the
;     explicit z pair; two field bridges, funcs-of-zl/frame-module-of-zl,
;     give the call rule the store's :funcs and the frame's module :funcs at
;     the projection spellings;
;   * no-ctxt-instrs-on-call-3-zl (the book's :expand recipe), the ZL slice
;     (the call_ref-func rule at the opaque state), and the ZL ctxt (the
;     book's prefix7/search21 instances) carry the body step;
;   * then the template's rungs at ZL: the lone label 0, the label-0/rest
;     slice, the five premises, the label-1 lift -- and the FRAME RULE,
;     whose premise now matches the label-1 fact syntactically (both at the
;     explicit-pair z), so its size and shape premises evaluate with the
;     state opaque.
;
; The result, TAIL-ENTRY-ZL-FRAME, is the run's second tail step at the
; config the first step leaves: the label-0's body goes from the pair to
; milawa-callee-admin 3 appended to rest12.
(defun zrun (bytes sp pc clen result w)
  (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
(defthm sof-of-a-pair (equal (w3t::$sof (list :|%;%| x y)) x))
(defthm fof-of-a-pair (equal (w3t::$fof (list :|%;%| x y)) y))
(defthm funcs-of-zl
  (equal (w3t::%get-field (w3t::$s (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) :funcs)
         (w3t::%get-field *milawa-verified-store* :funcs)))
(defthm frame-module-of-zl
  (equal (w3t::%get-field (w3t::%get-field (w3t::$f (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) :module) :funcs)
         '(0 1 2 3 4 5 6 7 8 9 10 11)))
(defthm no-ctxt-instrs-on-call-3-zl
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :ref.func_addr 3) *t3*)))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :ref.func_addr 3) *t3*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))
(defthm tail-entry-slice-zl
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :ref.func_addr 3) *t3*)))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (milawa-callee-admin 3))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use (funcs-of-zl frame-module-of-zl no-ctxt-instrs-on-call-3-zl)
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :ref.func_addr 3) *t3*)))))))
(defthm tail-entry-ctxt-zl
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs w3t::step gset w3t::$with_global w3t::$with_local w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
                 (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (w3t::%t9 1)
                            (w3t::z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
                 tail-entry-slice-zl))))

; ---------- tail-entry-zl: the body step at the run's state ----------
(defthm tail-entry-zl-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
           :use (tail-entry-ctxt-zl))))
(defthm tail-entry-zl-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))
                 tail-entry-zl-step))))
(defthm tail-entry-zl-label0-rest
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                 (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%t9 0)
                            (w3t::z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                 tail-entry-zl-label0))))
(defthm tail-entry-zl-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))
(defthm tail-entry-zl-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))
(defthm tail-entry-zl-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))
(defthm tail-entry-zl-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))
(defthm tail-entry-zl-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
(defthm tail-entry-zl-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-entry-zl-label0-rest tail-entry-zl-spure-body tail-entry-zl-sread-body
                 tail-entry-zl-spure-label tail-entry-zl-sread-label tail-entry-zl-size))))
(defthm tail-entry-zl-frame
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (gset bytes sp pc clen result w)) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (gset bytes sp pc clen result w)) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (gset bytes sp pc clen result w))) (fp (w3t::$fof (gset bytes sp pc clen result w))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (z1 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                            (b (cons (list :label_%{%}% 0 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-entry-zl-label1))))

