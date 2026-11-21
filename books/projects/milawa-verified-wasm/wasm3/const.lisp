(in-package "MILAWA-WASM")

(include-book "oob")

; L1, the running branch: the CONST (opcode 1) tail.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The CONST test's true branch leaves the tail
;
;   (:CALL 3) (:TESTOP eqz) (:IFELSE abort NIL) (:GLOBAL.GET 1) (:LOAD ...)
;   (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST 4) (:BINOP ADD) (:GLOBAL.SET 1)
;   (:LOCAL.GET 1) (:CALL 0) (:CONST 1) (:RETURN)
;
; at the head of function 6's label body.  This book starts its execution at
; the body level (z = iz6, the callee frame 6 record): the call to $in_code
; (function 3) is split by the ctxt search's lone-call slice (dcall3-lone,
; dconst-tail-spure/read/ctxt/step) and the (ref.func_addr 3) (call_ref ...)
; pair's entry pushes the callee admin (dconst-tail-entry-ctxt, using running's
; rstep-call-entry-3 at the same frozen-callee-z).  The callee's execution and
; the rest of the tail follow.



(defthm dcall3-lone (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :call 3)))) (list (icfg (iz6 bytes sp pc clen result) (list (list :ref.func_addr 3) *t3*)))))

(defthm dconst-tail-spure (equal (w3t::step_pure (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil) :hints (("Goal" :in-theory (disable w3t::step_pure) :use ((:instance (:definition w3t::step_pure) (w3t::%a0 (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm dconst-tail-read (equal (w3t::step_read/split (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil) :hints (("Goal" :in-theory (disable w3t::step_read/split) :use ((:instance (:definition w3t::step_read/split) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))

(defthm dconst-tail-ctxt (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) dcall3-lone))))

(defthm dconst-tail-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))) :hints (("Goal" :in-theory (disable w3t::step) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) :use (dconst-tail-spure dconst-tail-read dconst-tail-ctxt))))

(defthm dconst-tail-entry-ctxt (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (icfg (iz6 bytes sp pc clen result) (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))) (:instance rstep-call-entry-3 (status 1))))))

; ---------------------------------------------------------------------------
; The callee's execution at the CONST tail's call: four of the seven positions
; ---------------------------------------------------------------------------
;
; The callee (function 3, $in_code) runs inside the frame-3 admin; its steps are
; the dispatch book's positions, carried through the ctxt search's frame slice so
; the CONST tail's continuation (const-rest) stays after it.  The read of global
; 1 (the first position), the sub, the label-vals dissolve and the frame-vals
; dissolve are here.  The read of global 2, the mul and the lt_u (the positions
; whose bodies carry the symbolic intermediate values) need their own size
; facts and are next.


(defun const-rest () (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))

(defthm dconst-cal-read1-ctxt (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))))) iframe3-instance (:instance iframe3-instance)))))

(defthm dconst-cal-read1-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))))) :use (dconst-cal-read1-ctxt))))

(defthm dconst-cal-sub-ctxt (implies (unsigned-byte-p 32 pc) (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody1 pc)) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (dadmin (dbody0 pc)) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (dadmin (dbody0 pc)) (const-rest))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest))))) dframe-sub (:instance dframe-sub)))))

(defthm dconst-cal-sub-step (implies (unsigned-byte-p 32 pc) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody1 pc)) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest))))) :use (dconst-cal-sub-ctxt))))

(defthm dconst-cal-ldis-ctxt (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (dadmin (dbody4 pc clen)) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (dadmin (dbody4 pc clen)) (const-rest))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest))))) dframe3-dissolve-label (:instance dframe3-dissolve-label)))))

(defthm dconst-cal-ldis-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest))))) :use (dconst-cal-ldis-ctxt))))

(defthm dconst-cal-fdis-ctxt (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dbody4 pc clen) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (dframe3 (dbody4 pc clen)) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (dframe3 (dbody4 pc clen)) (const-rest))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))) dfv-generic (:instance dfv-generic)))))

(defthm dconst-cal-fdis-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (dbody4 pc clen) (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz w3t::$binop_ (:executable-counterpart w3t::$binop_)) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))) :use (dconst-cal-fdis-ctxt))))

; ---------------------------------------------------------------------------
; The callee's remaining three positions (read of global 2, mul, lt_u)
; ---------------------------------------------------------------------------
;
; The trick these three needed: the frame's slice step is taken as a HYPOTHESIS
; (the conditional ctxt-frame-* lemmas), because the automatic frame rewrite
; loses the (iz6 ...) spelling -- the store record's unfolding otherwise makes
; the inner fact's statement and the goal's term differ.  The application facts
; (dconst-cal-*-ctxt2) then discharge the hypothesis with the dispatch book's
; dframe-read/dframe-mul/dframe-ltu, and the steps follow from the ctxt facts.


(defthm ctxt-frame-read2 (implies (unsigned-byte-p 32 pc) (implies (and (equal (w3t::step (list :|%;%| zl (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))))) (list (list :|%;%| zr (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen)))))))) (< (w3t::%size (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc)))))) (w3t::%size (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest))))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest)))) (list (list :|%;%| zr (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest))) (w3t::%t9 0) (w3t::z zl) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest)))))))))

(defthm dconst-cal-read2-ctxt2 (implies (unsigned-byte-p 32 pc) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest)))) (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz ctxt-frame-read2) :use ((:instance ctxt-frame-read2 (zl (iz6 bytes sp pc clen result)) (zr (iz6 bytes sp pc clen result))) (:instance dframe-read)))))

(defthm ctxt-frame-mul (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (implies (and (equal (w3t::step (list :|%;%| zl (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))))) (list (list :|%;%| zr (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen)))))))) (< (w3t::%size (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen)))))) (w3t::%size (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))) (list (list :|%;%| zr (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))) (w3t::%t9 0) (w3t::z zl) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))))))))

(defthm dconst-cal-mul-ctxt2 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))) (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz ctxt-frame-mul) :use ((:instance ctxt-frame-mul (zl (iz6 bytes sp pc clen result)) (zr (iz6 bytes sp pc clen result))) (:instance dframe-mul)))))

(defthm ctxt-frame-ltu (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (implies (and (equal (w3t::step (list :|%;%| zl (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))))) (list (list :|%;%| zr (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody4 pc clen)))))))) (< (w3t::%size (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen)))))) (w3t::%size (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))) (list (list :|%;%| zr (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody4 pc clen))))) (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))) (w3t::%t9 0) (w3t::z zl) (w3t::%a0 (list :|%;%| zl (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))))))))

(defthm dconst-cal-ltu-ctxt2 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))) (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody4 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz ctxt-frame-ltu) :use ((:instance ctxt-frame-ltu (zl (iz6 bytes sp pc clen result)) (zr (iz6 bytes sp pc clen result))) (:instance dframe-ltu)))))

(defthm dconst-cal-read2-step2 (implies (unsigned-byte-p 32 pc) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest))))) :use (dconst-cal-read2-ctxt2))))

(defthm dconst-cal-mul-step2 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))) :use (dconst-cal-mul-ctxt2))))

(defthm dconst-cal-ltu-step2 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody4 pc clen))))) (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))) :use (dconst-cal-ltu-ctxt2))))

; ---------------------------------------------------------------------------
; The testop, the ifelse's else branch, and the empty block/label
; ---------------------------------------------------------------------------
;
; The $in_code callee returns the comparison (dltu (dsub pc) (dmul clen)) --
; symbolic, so the testop tier is case-split.  In the in-code case (value 1)
; the testop eqz pushes 0, the ifelse takes its ELSE branch (NIL), and the
; empty block and label dissolve to the rest of the tail -- the immediate read.
; The search results splice the tail AFTER the stepped slice: the searched
; result's instruction list is (const 0) :: (cdr of the tail), not the whole
; tail -- getting that one element wrong makes the search fact unprovable and
; was the blocker here.


(defthm dconst-search-eqz-1 (implies (equal (dltu (dsub pc) (dmul clen)) 1) (equal (w3t::step/search21 1 0 1 (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)) 1 (iz6 bytes sp pc clen result) (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))) (:instance fail-lone-testop-cons (z (iz6 bytes sp pc clen result))) (:instance testop-slice-one (z (iz6 bytes sp pc clen result)))))))

(defthm dconst-tail-eqz-1 (implies (equal (dltu (dsub pc) (dmul clen)) 1) (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))) dconst-search-eqz-1))))

(defthm dconst-tail-eqz-1-step (implies (equal (dltu (dsub pc) (dmul clen)) 1) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))) :use (dconst-tail-eqz-1))))



(defthm dconst-search-ifelse-0 (equal (w3t::step/search21 1 0 1 (cons (list :const (list :i32) 0) (cdr (const-rest))) 1 (iz6 bytes sp pc clen result) (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) 0) (cdr (const-rest)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) 0) (cdr (const-rest)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))) (:instance fail-lone-ifelse-cons (z (iz6 bytes sp pc clen result))) (:instance difelse-slice-0 (z (iz6 bytes sp pc clen result)))))))

(defthm dconst-tail-ifelse-0 (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :const (list :i32) 0) (cdr (const-rest))))) dconst-search-ifelse-0))))

(defthm dconst-tail-ifelse-0-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))) :use (dconst-tail-ifelse-0))))



(defthm dconst-block (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) (:instance rstep-empty-block (z (iz6 bytes sp pc clen result)))))))

(defthm dconst-block-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))) :use (dconst-block))))

(defthm dconst-elabel (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cddr (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (w3t::%t9 0) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))) (:instance rstep-empty-label (z (iz6 bytes sp pc clen result)))))))

(defthm dconst-elabel-step (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cddr (const-rest))))) :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))) :use (dconst-elabel))))

; ---------------------------------------------------------------------------
; The immediate read: (global.get 1) pushes pc
; ---------------------------------------------------------------------------
;
; With the empty block/label dissolved, the tail's head is (global.get 1):
; the runtime's global 1 is the pc (the absolute code address), so the read
; pushes (const pc).  The read's slice and its ctxt step at the tail's
; continuation are the first two facts; the load at pc is next.


(defthm dconst-read-slice
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :global.get 1))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :const (list :i32) pc))))))

(defthm dconst-read-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result)
                (cddr (const-rest))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (cons (list :const (list :i32) pc) (cdddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cddr (const-rest)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cddr (const-rest))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cddr (const-rest)))
                            (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cddr (const-rest)))))
                 dconst-read-slice))))

(defthm dconst-read-step
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (cddr (const-rest))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (cons (list :const (list :i32) pc) (cdddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (cddr (const-rest)))))
           :use (dconst-read-ctxt))))

; ---------------------------------------------------------------------------
; The load at pc: the instruction word
; ---------------------------------------------------------------------------
;
; The immediate is read from the code memory at the pc: the slice's step
; pushes the word W under the memory hypotheses (the same shape as the halt
; book's p2load-slice), the lone load has no step (the address is missing),
; and the ctxt step splices the continuation after the two-element slice.


(defthm dconst-load-slice
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W)))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :const (list :i32) pc)
                                         (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :const (list :i32) W))))))
  :hints (("Goal" :in-theory (disable w3t::$binop_ (:executable-counterpart w3t::$binop_)))))

(defthm dconst-fail-lone-load
  (equal (w3t::step (list :|%;%| z
                          (list (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z
                                            (list (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (list (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))))))



(defthm dconst-load-ctxt (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) W) (cddddr (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :const (list :i32) pc) (cdddr (const-rest))))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) pc) (cdddr (const-rest)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest)))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) pc) (cdddr (const-rest)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest)))))) (:instance dconst-fail-lone-load (z (iz6 bytes sp pc clen result))) (:instance dconst-load-slice)))))

(defthm dconst-load-step (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest))))) (list (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) W) (cddddr (const-rest))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::$binop_ (:executable-counterpart w3t::$binop_)) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest)))))) :use (dconst-load-ctxt))))


; ---------------------------------------------------------------------------
; The local write: local 1 gets the loaded word
; ---------------------------------------------------------------------------
;
; The load leaves the config ((const W), (local.set 1), (global.get 1),
; (const 4), (add), (global.set 1), (local.get 1), (call 0), (const 1),
; (return)): the value W is on top and the write consumes it.  The lone
; (local.set 1) has no step; the two-element slice's step is the local.set
; rule with the value W.  The slice's step is proved with the val-p
; hypothesis on the (const W) value, the same shape as load.lisp's index-0
; dlocal-set-slice-gen.
;
; The ctxt fact needs one more thing than its index-0 analogue: for index 1
; the updated frame's locals list is (update-nth 1 (list VAL) LOCALS), and
; if $with_local unfolds the prover normalizes that update two different
; ways (update-nth 1 on the alist representation gives (list* (cadr locals)
; VAL (cdddr locals)) on one path and (cons VAL (cddr locals)) on another),
; leaving an unprovable put-assoc-equal mismatch.  Keeping $with_local
; opaque makes the slice's rhs and the goal's rhs syntactically identical;
; the whole chain then proves (the ctxt fact in 372k steps).  The concrete
; frozen z is no obstacle either, since $with_local never unfolds.



(defthm dconst-fail-lone-lset1
  (equal (w3t::step (icfg z (list '(:local.set 1)))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list '(:local.set 1)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list '(:local.set 1)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list '(:local.set 1)))))))))

(defthm dconst-lset1-spure
  (equal (w3t::step_pure (list (list :const (list :i32) W) '(:local.set 1))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (list (list :const (list :i32) W) '(:local.set 1))))))))

(defthm dconst-lset1-split
  (equal (w3t::step_read/split (icfg z (list (list :const (list :i32) W) '(:local.set 1)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))))))

(defthm dconst-lset1-rctxti
  (implies (w3t::val-p (list :const (list :i32) W))
           (equal (w3t::step/r-ctxt-instrs (icfg z (list (list :const (list :i32) W) '(:local.set 1)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) W) '(:local.set 1))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) W) '(:local.set 1)))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) W) '(:local.set 1)))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))
                 (:instance dconst-fail-lone-lset1 (z z))))))

(defthm dconst-lset1-slice
  (implies (w3t::val-p (list :const (list :i32) W))
           (equal (w3t::step (icfg z (list (list :const (list :i32) W) '(:local.set 1))))
                  (list (icfg (w3t::$with_local z 1 (list :const (list :i32) W)) nil))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-local.set
                                      w3t::$with_local w3t::$frame w3t::$store w3t::%get-field w3t::%put-field)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))
                 (:instance (:definition w3t::step/r-local.set)
                            (w3t::%a0 (icfg z (list (list :const (list :i32) W) '(:local.set 1)))))
                 dconst-lset1-spure dconst-lset1-split dconst-lset1-rctxti))))

(defthm dconst-lset1-ctxt
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cons (list :const (list :i32) W)
                                        (cddddr (const-rest)))))
                  (list (list :|%;%| (w3t::$with_local z 1 (list :const (list :i32) W))
                              (cdr (cddddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                                      w3t::$with_local w3t::$frame w3t::$store
                                      w3t::%get-field w3t::%put-field)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) W)
                                                           (cddddr (const-rest))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) W)
                                           (cddddr (const-rest)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (cddddr (const-rest))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) W)
                                                           (cddddr (const-rest))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (cddddr (const-rest))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) W)
                                                           (cddddr (const-rest))))))
                 (:instance dconst-lset1-slice)
                 (:instance dconst-fail-lone-lset1 (z z))))))

(defthm dconst-lset1-step
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step
                   (list :|%;%| z (cons (list :const (list :i32) W)
                                        (cddddr (const-rest)))))
                  (list (list :|%;%| (w3t::$with_local z 1 (list :const (list :i32) W))
                              (cdr (cddddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::$with_local)
           :use (dconst-lset1-ctxt)
           :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) W)
                                                    (cddddr (const-rest)))))))))

; ---------------------------------------------------------------------------
; The pc write: pc = pc + 4, then the dispatcher's word
; ---------------------------------------------------------------------------
;
; After the local.set 1 the tail continues with the pc increment and the
; dispatcher hand-off:
;
;   (global.get 1) (const 4) (binop add) (global.set 1)
;   (local.get 1) (call 0) (const 1) (return)
;
; with the loaded word W saved in local 1.  The globals 1 and 0 are (mut i32)
; and the add is the fetch book's dadd (pc + 4, wrapped); the write's store
; rule rewrites store global 6 (the module maps global 1 to store global 6)
; through $with_global.  This tier is fetch.lisp's pc-increment chain at the
; CONST tail's continuation: the same slice/lone/failure facts (dadd-slice,
; fail-lone-add, fail-add-one, dglobal-set-slice-gen, fail-lone-global-set)
; are reused, and the context lifts are re-proved here at (const-tail2).
;
; One new lesson: the step-level global.set fact must keep $with_global (and
; the frame/store accessors) DISABLED -- enabled, the equality's two sides
; unfold the store record by different paths and the proof exceeds 8M steps;
; disabled, it is 13k.  The local.get 1 tier reads local 1 back (the word W)
; with the fetch book's variable-z recipe: the store is by now a $with_global
; term, so the slice and its ctxt fact take the $local equality as hypothesis
; and the concrete instance is discharged by local-of-gset1-concrete.

(defun const-tail2 () (cdr (cddddr (const-rest))))

; The state after the local.set 1.
(defun zlset1 (bytes sp pc clen result W)
  (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)))

(defthm const-read-pc-slice
  (equal (w3t::step (icfg (zlset1 bytes sp pc clen result W)
                          (list (list :global.get 1))))
         (list (icfg (zlset1 bytes sp pc clen result W)
                     (list (list :const (list :i32) pc))))))

(defthm dconst-get1-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (zlset1 bytes sp pc clen result W) (const-tail2)))
         (list (icfg (zlset1 bytes sp pc clen result W)
                     (cons (list :const (list :i32) pc) (cdr (const-tail2))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (const-tail2))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (const-tail2)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (const-tail2)) (w3t::%t9 0)
                            (w3t::z (zlset1 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (const-tail2))))
                 const-read-pc-slice))))

(defthm dconst-get1-step
  (equal (w3t::step (icfg (zlset1 bytes sp pc clen result W) (const-tail2)))
         (list (icfg (zlset1 bytes sp pc clen result W)
                     (cons (list :const (list :i32) pc) (cdr (const-tail2))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use (dconst-get1-ctxt)
           :expand ((w3t::step (icfg (zlset1 bytes sp pc clen result W)
                                     (const-tail2)))))))

; ---------------------------------------------------------------------------
; The add: pc + 4
; ---------------------------------------------------------------------------

(defthm dconst-add-ctxt
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (zlset1 bytes sp pc clen result W)
                         (cons (list :const (list :i32) pc) (cdr (const-tail2)))))
                  (list (icfg (zlset1 bytes sp pc clen result W)
                              (cons (list :const (list :i32) (dadd pc))
                                    (cdddr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) pc)
                                                  (cdr (const-tail2))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) pc)
                                           (cdr (const-tail2)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) pc)
                                            (cdr (const-tail2))))
                            (w3t::%t9 2)
                            (w3t::z (zlset1 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) pc)
                                                  (cdr (const-tail2))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) pc)
                                            (cdr (const-tail2))))
                            (w3t::%t9 2)
                            (w3t::z (zlset1 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) pc)
                                                  (cdr (const-tail2))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) pc)
                                            (cdr (const-tail2))))
                            (w3t::%t9 2)
                            (w3t::z (zlset1 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zlset1 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) pc)
                                                  (cdr (const-tail2))))))
                 dadd-slice
                 (:instance fail-lone-add
                            (z (zlset1 bytes sp pc clen result W)))
                 (:instance fail-add-one
                            (z (zlset1 bytes sp pc clen result W))
                            (c 4))))))

(defthm dconst-add-step
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step
                   (icfg (zlset1 bytes sp pc clen result W)
                         (cons (list :const (list :i32) pc) (cdr (const-tail2)))))
                  (list (icfg (zlset1 bytes sp pc clen result W)
                              (cons (list :const (list :i32) (dadd pc))
                                    (cdddr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use (dconst-add-ctxt)
           :expand ((w3t::step (icfg (zlset1 bytes sp pc clen result W)
                                     (cons (list :const (list :i32) pc)
                                           (cdr (const-tail2)))))))))

(defthm local-of-lset1-concrete
  (equal (w3t::$local (zlset1 bytes sp pc clen result W) 1)
         (list (list :const (list :i32) W))))

(defthm local-of-gset1-concrete
  (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1
                                          (list :const (list :i32) (dadd pc)))
                      1)
         (list (list :const (list :i32) W))))

(defthm dconst-gset-ctxt
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) (dadd pc))
                               (cdddr (const-tail2)))))
                  (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc)))
                              (cddddr (const-tail2))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) (dadd pc))
                                                  (cdddr (const-tail2))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) (dadd pc))
                                           (cdddr (const-tail2)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :const (list :i32) (dadd pc))
                                            (cdddr (const-tail2))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) (dadd pc))
                                                  (cdddr (const-tail2))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :const (list :i32) (dadd pc))
                                            (cdddr (const-tail2))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (cons (list :const (list :i32) (dadd pc))
                                                  (cdddr (const-tail2))))))
                 dglobal-set-slice-gen
                 (:instance fail-lone-global-set (z z))))))

(defthm dconst-gset-step
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step
                   (list :|%;%| z
                         (cons (list :const (list :i32) (dadd pc))
                               (cdddr (const-tail2)))))
                  (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc)))
                              (cddddr (const-tail2))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_
                                      w3t::$with_global w3t::$sof w3t::$fof
                                      w3t::$frame w3t::$store
                                      w3t::%get-field w3t::%put-field)
           :use (dconst-gset-ctxt)
           :expand ((w3t::step (list :|%;%| z
                                     (cons (list :const (list :i32) (dadd pc))
                                           (cdddr (const-tail2)))))))))

(defthm dconst-lget-slice-gen
  (implies (equal (w3t::$local z 1) (list (list :const (list :i32) W)))
           (equal (w3t::step (list :|%;%| z (list (list :local.get 1))))
                  (list (list :|%;%| z (list (list :const (list :i32) W)))))))

(defthm dconst-lget-ctxt
  (implies (equal (w3t::$local z 1) (list (list :const (list :i32) W)))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cddddr (const-tail2))))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32) W)
                                    (cdr (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (cddddr (const-tail2)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cddddr (const-tail2))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cddddr (const-tail2)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (cddddr (const-tail2)))))
                 dconst-lget-slice-gen))))

(defthm dconst-lget-step
  (implies (equal (w3t::$local z 1) (list (list :const (list :i32) W)))
           (equal (w3t::step (list :|%;%| z (cddddr (const-tail2))))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32) W)
                                    (cdr (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use (dconst-lget-ctxt)
           :expand ((w3t::step (list :|%;%| z (cddddr (const-tail2))))))))

(defthm dconst-lget-at-z2
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step
                   (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1
                                                   (list :const (list :i32) (dadd pc)))
                         (cddddr (const-tail2))))
                  (list (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1
                                                        (list :const (list :i32) (dadd pc)))
                              (cons (list :const (list :i32) W)
                                    (cdr (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance dconst-lget-step
                            (z (w3t::$with_global (zlset1 bytes sp pc clen result W) 1
                                                  (list :const (list :i32) (dadd pc)))))
                 local-of-gset1-concrete))))

; ---------------------------------------------------------------------------
; The $push callee (function 0): its body end to end
; ---------------------------------------------------------------------------
;
; The dispatcher's CONST branch ends by calling function 0, the seven-
; instruction $push: (global.get 0) reads the stack pointer, (local.get 0)
; the word W, the i32.store writes the word, and the sp write advances it.
; The callee's frame carries W in local 0; its label and frame have arity 0
; (no results), so its return is void.
;
; The chain is the dispatch book's seven layers per position -- the slice, the
; body's ctxt, the body step, the label step, the frame step (through the
; arity-0 wrapper), the ctxt lift with the caller's continuation, and the
; step-level fact -- at the explicit z spellings the frame rule builds.  Two
; lessons this tier cost: the phase facts (step_pure and step_read/split nil)
; must be stated at the CONCRETE instruction lists, because step_pure's trap
; search scans the list's length; and the concrete slice/failure facts must be
; in constructor form.  The store's slice is proved generically in z (the
; memory's byte length is symbolic), with its lone and one-value refusals.
;
; Positions 0-4 are closed here.  Position 5 (the global.set 0 write) and the
; two dissolves (the label-vals and frame-vals of the void return) are next.


(defun const-tail3 () (cdr (cddddr (const-tail2))))

(defun zlset1 (bytes sp pc clen result W) (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)))

(defun zw2 (bytes sp pc clen result W) (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))))

(defun sframe0 (bytes sp pc clen result W)
  (declare (ignore bytes sp pc clen result))
  (list :%rec (cons :locals (list (list (list :const (list :i32) W))))
        (cons :module (milawa-func-module 0))))

(defun sadmin (bytes sp pc clen result W)
  (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W)
              (list (list :label_%{%}% 0 nil (milawa-func-body 0))))))

(defun sz0 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (sframe0 bytes sp pc clen result W)))

(defun sz1 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz0 bytes sp pc clen result W)) (sframe0 bytes sp pc clen result W)))

(defun sz2 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz1 bytes sp pc clen result W)) (sframe0 bytes sp pc clen result W)))

(defun szm (bytes sp pc clen result W) (w3t::$with_mem (sz2 bytes sp pc clen result W) 0 (+ sp 0) 4 (w3t::$nbytes_ (list :i32) W)))

(defun sz3 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (szm bytes sp pc clen result W)) (sframe0 bytes sp pc clen result W)))

(defun sz5 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz3 bytes sp pc clen result W)) (sframe0 bytes sp pc clen result W)))

(defun szg (bytes sp pc clen result W) (w3t::$with_global (sz5 bytes sp pc clen result W) 0 (list :const (list :i32) (dadd sp))))

(defun zo1 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz0 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun zo2 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz1 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun zo3 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (szm bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun zo4 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz3 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun zo5 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (sz5 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun zo6 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun sbody0 () (milawa-func-body 0))

(defun sbody1 (sp) (cons (list :const (list :i32) sp) (cdr (milawa-func-body 0))))

(defun sbody2 (sp W)
  (cons (list :const (list :i32) sp)
        (cons (list :const (list :i32) W) (cddr (milawa-func-body 0)))))

(defun sbody3 () (cdddr (milawa-func-body 0)))

(defun sbody4 (sp) (cons (list :const (list :i32) sp) (cdr (sbody3))))

(defun sbody5 (sp) (cons (list :const (list :i32) (dadd sp)) (cdddr (sbody3))))

(defun zpair0 (bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))))

(defun sarg6 (bytes sp pc clen result W) (w3t::$sof (szg bytes sp pc clen result W)))

(defun store-instrs (sp W)
  (list (list :const (list :i32) sp) (list :const (list :i32) W)
        '(:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))

(defun store-hyps (z sp W)
  (and (unsigned-byte-p 32 sp) (unsigned-byte-p 32 W)
       (<= (+ sp 4) (len (w3t::%get-field (w3t::$mem z 0) :bytes)))))

(defthm gfail-lone-gset0
  (equal (w3t::step (list :|%;%| z (list (quote (:global.set 0))))) nil)
  :hints (("Goal" :in-theory (disable)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (quote (:global.set 0))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (quote (:global.set 0)))) (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (quote (:global.set 0))))))))))

(defthm dstep-frame-outer-gen-0
  (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s fp)
                                         (list (list :label_%{%}% 0 nil b))))
                        (list (list :|%;%| zp (list (list :label_%{%}% 0 nil b2)))))
                (< (w3t::%size (list (list :label_%{%}% 0 nil b)))
                   (w3t::%size (list (list :frame_%{%}% 0 fp (list (list :label_%{%}% 0 nil b))))))
                (consp zp) (equal (car zp) :|%;%|)
                (true-listp (cdr zp)) (equal (len (cdr zp)) 2))
           (equal (w3t::step (list :|%;%| (list :|%;%| s f)
                                   (list (list :frame_%{%}% 0 fp
                                               (list (list :label_%{%}% 0 nil b))))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof zp) f)
                              (list (list :frame_%{%}% 0 (w3t::$fof zp)
                                          (list (list :label_%{%}% 0 nil b2))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (list (list :frame_%{%}% 0 fp
                                                        (list (list :label_%{%}% 0 nil b)))))))
                 (:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (list (list :frame_%{%}% 0 fp
                                                        (list (list :label_%{%}% 0 nil b)))))))))))

(defthm s-lone-store
  (equal (w3t::step (list :|%;%| z (list (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
         nil)
  :hints (("Goal" :in-theory (disable)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))))))

(defthm s-store-one
  (implies (unsigned-byte-p 32 c)
           (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                  nil))
  :hints (("Goal" :in-theory (disable)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c) (quote (:store (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))))
                 s-lone-store))))

(defthm s-store-spure
  (equal (w3t::step_pure (store-instrs sp W)) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (store-instrs sp W)))))))

(defthm s-store-split
  (equal (w3t::step_read/split (list :|%;%| z (store-instrs sp W))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))))))

(defthm s-store-rctxti
  (implies (store-hyps z sp W)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (store-instrs sp W)))
                  nil))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (store-instrs sp W)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (store-instrs sp W)) (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (store-instrs sp W)) (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (store-instrs sp W)) (w3t::%t9 2) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 s-lone-store s-store-one))))

(defthm s-store-slice-gen
  (implies (store-hyps z sp W)
           (equal (w3t::step (list :|%;%| z (store-instrs sp W)))
                  (list (list :|%;%| (w3t::$with_mem z 0 (+ sp 0) 4 (w3t::$nbytes_ (list :i32) W))
                              nil))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-store-num-val)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 (:instance (:definition w3t::step/r-store-num-val)
                            (w3t::%a0 (list :|%;%| z (store-instrs sp W))))
                 s-store-spure s-store-split s-store-rctxti))))

(defthm s-ctxt-lift-gen
  (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s f)
                                         (list (list :frame_%{%}% 0 fp b))))
                        (list (list :|%;%| zp (list (list :frame_%{%}% 0 fp2 b2)))))
                (consp zp) (equal (car zp) :|%;%|)
                (true-listp (cdr zp)) (equal (len (cdr zp)) 2)
                (consp cont) (true-listp cont)
                (< (w3t::%size (list (list :frame_%{%}% 0 fp b)))
                   (w3t::%size (cons (list :frame_%{%}% 0 fp b) cont))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| s f)
                         (cons (list :frame_%{%}% 0 fp b) cont)))
                  (list (list :|%;%| zp
                              (cons (list :frame_%{%}% 0 fp2 b2) cont)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (cons (list :frame_%{%}% 0 fp b) cont))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :frame_%{%}% 0 fp b) cont)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :frame_%{%}% 0 fp b) cont))
                            (w3t::%t9 0) (w3t::z (list :|%;%| s f))
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (cons (list :frame_%{%}% 0 fp b) cont))))))))

(defthm s-respell0
  (equal (list :|%;%| (zw2 bytes sp pc clen result W) zz)
         (list :|%;%| (zpair0 bytes sp pc clen result W) zz))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-slice0
  (equal (w3t::step (list :|%;%| (sz0 bytes sp pc clen result W) (list (list :global.get 0))))
         (list (list :|%;%| (sz0 bytes sp pc clen result W) (list (list :const (list :i32) sp)))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-slice1
  (equal (w3t::step (list :|%;%| (sz1 bytes sp pc clen result W) (list (list :local.get 0))))
         (list (list :|%;%| (sz1 bytes sp pc clen result W) (list (list :const (list :i32) W)))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-mem-of-sz2
  (equal (w3t::%get-field (w3t::$mem (sz2 bytes sp pc clen result W) 0) :bytes)
         bytes)
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-slice2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step (list :|%;%| (sz2 bytes sp pc clen result W) (store-instrs sp W)))
                  (list (list :|%;%| (szm bytes sp pc clen result W) nil))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance s-store-slice-gen (z (sz2 bytes sp pc clen result W))) s-mem-of-sz2))))

(defthm s-slice3
  (equal (w3t::step (list :|%;%| (sz3 bytes sp pc clen result W) (list (list :global.get 0))))
         (list (list :|%;%| (sz3 bytes sp pc clen result W) (list (list :const (list :i32) sp)))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-ctxt0
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz0 bytes sp pc clen result W) (sbody0)))
         (list (list :|%;%| (sz0 bytes sp pc clen result W) (sbody1 sp))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (sz0 bytes sp pc clen result W) (sbody0)))) (:instance (:definition w3t::step/prefix7) (w3t::%s (sbody0))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (sbody0)) (w3t::%t9 0) (w3t::z (sz0 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz0 bytes sp pc clen result W) (sbody0)))) s-slice0 ))))

(defthm s-body0
  (equal (w3t::step (list :|%;%| (sz0 bytes sp pc clen result W) (sbody0)))
         (list (list :|%;%| (sz0 bytes sp pc clen result W) (sbody1 sp))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-ctxt0)
           :expand ((w3t::step (list :|%;%| (sz0 bytes sp pc clen result W) (sbody0)))))))

(defthm s-label0
  (equal (w3t::step (list :|%;%| (sz0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))))
         (list (list :|%;%| (sz0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (sz0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))))) s-body0))))

(defthm s-frame0
  (equal (w3t::step (list :|%;%| (zpair0 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))))))
         (list (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (zw2 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody0)) (b2 (sbody1 sp)) (zp (sz0 bytes sp pc clen result W))) s-label0))))

(defthm s-lift0
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zpair0 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (zw2 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody0)) (b2 (sbody1 sp)) (zp (zo1 bytes sp pc clen result W)) (fp2 (w3t::$fof (sz0 bytes sp pc clen result W))) (cont (cdr (const-tail3)))) s-frame0))))

(defthm s-spure0
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody0))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody0))))
                                            (cdr (const-tail3)))))))))

(defthm s-split0
  (equal (w3t::step_read/split (list :|%;%| (sz0 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody0))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz0 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody0))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-spure1
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody1 sp))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody1 sp))))
                                            (cdr (const-tail3)))))))))

(defthm s-split1
  (equal (w3t::step_read/split (list :|%;%| (sz1 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody1 sp))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz1 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody1 sp))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-spure2
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody2 sp W))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody2 sp W))))
                                            (cdr (const-tail3)))))))))

(defthm s-split2
  (equal (w3t::step_read/split (list :|%;%| (sz2 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody2 sp W))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody2 sp W))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-spure3
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody3))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody3))))
                                            (cdr (const-tail3)))))))))

(defthm s-split3
  (equal (w3t::step_read/split (list :|%;%| (sz3 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody3))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz3 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody3))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-spure4
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody4 sp))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody4 sp))))
                                            (cdr (const-tail3)))))))))

(defthm s-split4
  (equal (w3t::step_read/split (list :|%;%| (sz5 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody4 sp))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody4 sp))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-spure5
  (equal (w3t::step_pure (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody5 sp))))
                               (cdr (const-tail3))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody5 sp))))
                                            (cdr (const-tail3)))))))))

(defthm s-split5
  (equal (w3t::step_read/split (list :|%;%| (sz5 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody5 sp))))
                                                        (cdr (const-tail3)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (cons (list :frame_%{{%}}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{{%}}% 0 nil (sbody5 sp))))
                                                                 (cdr (const-tail3))))))))))

(defthm s-step0
  (equal (w3t::step (list :|%;%| (zpair0 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-lift0)
           :expand ((w3t::step (list :|%;%| (zpair0 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))))))))

(defthm s-ctxt1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz1 bytes sp pc clen result W) (sbody1 sp)))
                  (list (list :|%;%| (sz1 bytes sp pc clen result W) (sbody2 sp W)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (sz1 bytes sp pc clen result W) (sbody1 sp)))) (:instance (:definition w3t::step/prefix7) (w3t::%s (sbody1 sp))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (sbody1 sp)) (w3t::%t9 1) (w3t::z (sz1 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz1 bytes sp pc clen result W) (sbody1 sp)))) s-slice1))))

(defthm s-body1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (sz1 bytes sp pc clen result W) (sbody1 sp)))
                  (list (list :|%;%| (sz1 bytes sp pc clen result W) (sbody2 sp W)))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-ctxt1)
           :expand ((w3t::step (list :|%;%| (sz1 bytes sp pc clen result W) (sbody1 sp)))))))

(defthm s-label1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (sz1 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))))
                  (list (list :|%;%| (sz1 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (sz1 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))))) s-body1))))

(defthm s-frame1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))))))
                  (list (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (sz0 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody1 sp)) (b2 (sbody2 sp W)) (zp (sz1 bytes sp pc clen result W))) s-label1))))

(defthm s-lift1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (sz0 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody1 sp)) (b2 (sbody2 sp W)) (zp (zo2 bytes sp pc clen result W)) (fp2 (w3t::$fof (sz1 bytes sp pc clen result W))) (cont (cdr (const-tail3)))) s-frame1))))

(defthm s-step1
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-lift1)
           :expand ((w3t::step (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))))))

(defthm s-ctxt2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))
                  (list (list :|%;%| (szm bytes sp pc clen result W) (sbody3)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))) (:instance (:definition w3t::step/prefix7) (w3t::%s (sbody2 sp W))) (:instance (:definition w3t::step/search21) (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody2 sp W)) (w3t::%t9 2) (w3t::z (sz2 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody2 sp W)) (w3t::%t9 2) (w3t::z (sz2 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody2 sp W)) (w3t::%t9 2) (w3t::z (sz2 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))) s-slice2 ))))

(defthm s-body2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))
                  (list (list :|%;%| (szm bytes sp pc clen result W) (sbody3)))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-ctxt2)
           :expand ((w3t::step (list :|%;%| (sz2 bytes sp pc clen result W) (sbody2 sp W)))))))

(defthm s-label2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step (list :|%;%| (sz2 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))))
                  (list (list :|%;%| (szm bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (sz2 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))))) s-body2))))

(defthm s-frame2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))))))
                  (list (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (sz1 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody2 sp W)) (b2 (sbody3)) (zp (szm bytes sp pc clen result W))) s-label2))))

(defthm s-lift2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (sz1 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody2 sp W)) (b2 (sbody3)) (zp (zo3 bytes sp pc clen result W)) (fp2 (w3t::$fof (szm bytes sp pc clen result W))) (cont (cdr (const-tail3)))) s-frame2))))

(defthm s-step2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W)
           (equal (w3t::step (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-lift2)
           :expand ((w3t::step (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))))))

(defthm s-ctxt3
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz3 bytes sp pc clen result W) (sbody3)))
         (list (list :|%;%| (sz3 bytes sp pc clen result W) (sbody4 sp))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (sz3 bytes sp pc clen result W) (sbody3)))) (:instance (:definition w3t::step/prefix7) (w3t::%s (sbody3))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (sbody3)) (w3t::%t9 0) (w3t::z (sz3 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz3 bytes sp pc clen result W) (sbody3)))) s-slice3 ))))

(defthm s-body3
  (equal (w3t::step (list :|%;%| (sz3 bytes sp pc clen result W) (sbody3)))
         (list (list :|%;%| (sz3 bytes sp pc clen result W) (sbody4 sp))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-ctxt3)
           :expand ((w3t::step (list :|%;%| (sz3 bytes sp pc clen result W) (sbody3)))))))

(defthm s-label3
  (equal (w3t::step (list :|%;%| (sz3 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))))
         (list (list :|%;%| (sz3 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (sz3 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))))) s-body3))))

(defthm s-frame3
  (equal (w3t::step (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))))))
         (list (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (szm bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody3)) (b2 (sbody4 sp)) (zp (sz3 bytes sp pc clen result W))) s-label3))))

(defthm s-lift3
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (szm bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody3)) (b2 (sbody4 sp)) (zp (zo4 bytes sp pc clen result W)) (fp2 (w3t::$fof (sz3 bytes sp pc clen result W))) (cont (cdr (const-tail3)))) s-frame3))))

(defthm s-step3
  (equal (w3t::step (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))
                 s-spure3 s-split3 s-lift3))))

(defthm s-ctxt4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))
                  (list (list :|%;%| (sz5 bytes sp pc clen result W) (sbody5 sp)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))) (:instance (:definition w3t::step/prefix7) (w3t::%s (sbody4 sp))) (:instance (:definition w3t::step/search21) (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody4 sp)) (w3t::%t9 2) (w3t::z (sz5 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody4 sp)) (w3t::%t9 2) (w3t::z (sz5 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (sbody4 sp)) (w3t::%t9 2) (w3t::z (sz5 bytes sp pc clen result W)) (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))) (:instance dadd-slice (z (sz5 bytes sp pc clen result W)) (pc sp)) (:instance fail-lone-add (z (sz5 bytes sp pc clen result W))) (:instance fail-add-one (z (sz5 bytes sp pc clen result W)) (c 4))))))

(defthm s-body4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))
                  (list (list :|%;%| (sz5 bytes sp pc clen result W) (sbody5 sp)))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (s-ctxt4)
           :expand ((w3t::step (list :|%;%| (sz5 bytes sp pc clen result W) (sbody4 sp)))))))

(defthm s-label4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (sz5 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))))
                  (list (list :|%;%| (sz5 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody5 sp)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))))) s-body4))))

(defthm s-frame4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))))))
                  (list (list :|%;%| (zo5 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (sz3 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody4 sp)) (b2 (sbody5 sp)) (zp (sz5 bytes sp pc clen result W))) s-label4))))

(defthm s-lift4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo5 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (sz3 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (sbody4 sp)) (b2 (sbody5 sp)) (zp (zo5 bytes sp pc clen result W)) (fp2 (w3t::$fof (sz5 bytes sp pc clen result W))) (cont (cdr (const-tail3)))) s-frame4))))

(defthm s-step4
  (implies (unsigned-byte-p 32 sp)
           (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo5 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))
                 s-spure4 s-split4 s-lift4))))

(defthm s-label-vals
  (equal (w3t::step (list :|%;%| (szg bytes sp pc clen result W) (list (list :label_%{%}% 0 nil nil))))
         (list (list :|%;%| (szg bytes sp pc clen result W) nil)))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm s-frame-vals-gen
  (equal (w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 0 fp nil))))
         (list (list :|%;%| (list :|%;%| s f) nil))))

; ---------------------------------------------------------------------------
; The $push tail: the global.set 0 write (position 5)
; ---------------------------------------------------------------------------
;
; The callee's last instruction advances the stack pointer: the write's slice
; is the two-element ((const (dadd sp)) (global.set 0)); the ctxt rule does NOT
; fire on a slice that is the whole configuration (the search's measure ties),
; so the slice's step IS the global.set rule (gsGS0) and the ctxt is nil.  The
; stepped value (dadd sp) must be a value (the val-p hypothesis); the store's
; $with_global stays opaque so the module/global records never unfold.

(defun gset-instrs (sp)
  (list (list :const (list :i32) (dadd sp)) (quote (:global.set 0))))

(defthm gfail-lone-gset0
  (equal (w3t::step (list :|%;%| z (list (quote (:global.set 0))))) nil)
  :hints (("Goal" :in-theory (disable)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (quote (:global.set 0))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (quote (:global.set 0)))) (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (quote (:global.set 0))))))))))

(defthm g-gset-spure
  (equal (w3t::step_pure (gset-instrs sp)) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure) (w3t::%a0 (gset-instrs sp)))))))

(defthm g-gset-split
  (equal (w3t::step_read/split (list :|%;%| z (gset-instrs sp))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split) (w3t::%a0 (list :|%;%| z (gset-instrs sp))))))))

(defthm g-gset-rctxti
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (gset-instrs sp))) nil))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (gset-instrs sp))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (gset-instrs sp)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (gset-instrs sp)) (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (gset-instrs sp))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (gset-instrs sp)) (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (gset-instrs sp))))
                 gfail-lone-gset0))))

(defthm gsGS0
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step (list :|%;%| z (gset-instrs sp)))
                  (list (list :|%;%| (w3t::$with_global z 0 (list :const (list :i32) (dadd sp))) nil))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_ w3t::$with_global)
           :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| z (gset-instrs sp))))
                 (:instance (:definition w3t::step/r-global.set) (w3t::%a0 (list :|%;%| z (gset-instrs sp))))
                 g-gset-spure g-gset-split g-gset-rctxti))))

(defthm s-ctxt5-nil
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (sz5 bytes sp pc clen result W) (gset-instrs sp))) nil))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance g-gset-rctxti (z (sz5 bytes sp pc clen result W)))))))

(defthm s-body5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step (list :|%;%| (sz5 bytes sp pc clen result W) (gset-instrs sp)))
                  (list (list :|%;%| (szg bytes sp pc clen result W) nil))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::$with_global)
           :use ((:instance gsGS0 (z (sz5 bytes sp pc clen result W)))))))

(defthm s-label5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step (list :|%;%| (sz5 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))))
                  (list (list :|%;%| (szg bytes sp pc clen result W) (list (list :label_%{%}% 0 nil nil))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u w3t::$sof w3t::$fof w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store w3t::%get-field w3t::%put-field frozen-store iz6 zlset1 zw2 sframe0 milawa-func-module milawa-callee-frame milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (sz5 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp))))))
                 s-body5))))

(defthm s-zg-shape-p5
  (and (consp (szg bytes sp pc clen result W))
       (equal (car (szg bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (szg bytes sp pc clen result W)))
       (equal (len (cdr (szg bytes sp pc clen result W))) 2))
  :hints (("Goal" :in-theory (disable w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$sof w3t::$fof w3t::$frame w3t::$store w3t::%get-field w3t::%put-field frozen-store iz6 zlset1 zw2 sframe0 milawa-func-module milawa-callee-frame milawa-func-body dadd w3t::$binop_))))

(defthm s-frame5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))))))
                  (list (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))))))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u w3t::$sof w3t::$fof w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store w3t::%get-field w3t::%put-field frozen-store iz6 zlset1 zw2 sframe0 milawa-func-module milawa-callee-frame milawa-func-body)
           :use ((:instance dstep-frame-outer-gen-0 (s (w3t::$sof (sz3 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W)) (b (gset-instrs sp)) (b2 nil) (zp (szg bytes sp pc clen result W)))
                 s-label5 s-zg-shape-p5))))

(defthm s-lift5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u w3t::$sof w3t::$fof w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store w3t::%get-field w3t::%put-field frozen-store iz6 zlset1 zw2 sframe0 milawa-func-module milawa-callee-frame milawa-func-body)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (sz3 bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (sframe0 bytes sp pc clen result W))
                            (b (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (b2 (list (list :label_%{%}% 0 nil nil)))
                            (zp (zo6 bytes sp pc clen result W)) (fp2 (w3t::$fof (szg bytes sp pc clen result W))) (cont (cdr (const-tail3))))
                 s-frame5))))

(defthm s-step5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp)))
           (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))))
                  (list (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u w3t::$sof w3t::$fof w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store w3t::%get-field w3t::%put-field frozen-store iz6 zlset1 zw2 sframe0 milawa-func-module milawa-callee-frame milawa-func-body)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))
                 s-spure5 s-split5 s-lift5))))

; ---------------------------------------------------------------------------
; The $push callee's void return: the label and frame dissolves
; ---------------------------------------------------------------------------
;
; The callee's label and frame have arity 0, so its return is void: the label
; whose body is all values is removed by the pure label-vals rule, and the
; frame whose body is all values by frame-vals.  Both are stated at the
; ACCESSOR-PAIR spellings the frame rule builds -- the frame rule's result z
; is the SYNTAX of the inner result's z (its cadr/caddr), while the wrappers
; state ($sof zp)/($fof zp); with the pair accessors ENABLED (they only
; destructure literal pairs) the two spellings bridge, while the store
; constructors stay opaque.  Two generic wrappers are proved: the frame
; dissolve (the label-vals step inside the frame) and the final lift (the
; frame-vals dissolve spliced before the continuation).

(defthm e-label-vals
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W))) (list (list :label_%{%}% 0 nil nil))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W))) nil))))

(defthm e-zpair-shape
  (and (consp (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W)))) (equal (car (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W)))) :|%;%|)
       (true-listp (cdr (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W))))) (equal (len (cdr (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W))))) 2)))

(defthm e-dissolve-gen
  (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s fp)
                                         (list (list :label_%{%}% 0 nil nil))))
                        (list (list :|%;%| zp nil)))
                (< (w3t::%size (list (list :label_%{%}% 0 nil nil)))
                   (w3t::%size (list (list :frame_%{%}% 0 fp (list (list :label_%{%}% 0 nil nil))))))
                (consp zp) (equal (car zp) :|%;%|)
                (true-listp (cdr zp)) (equal (len (cdr zp)) 2))
           (equal (w3t::step (list :|%;%| (list :|%;%| s f)
                                   (list (list :frame_%{%}% 0 fp
                                               (list (list :label_%{%}% 0 nil nil))))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof zp) f)
                              (list (list :frame_%{%}% 0 (w3t::$fof zp) nil))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 0 fp (list (list :label_%{%}% 0 nil nil)))))))
                 (:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 0 fp (list (list :label_%{%}% 0 nil nil)))))))))))

(defthm e-frame-nil
  (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))))))
         (list (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil)))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u sframe0 milawa-func-module milawa-callee-frame milawa-func-body sz0 sz1 sz2 szm sz3 sz5 szg zlset1 zw2 w3t::$with_global w3t::$with_mem w3t::$with_local w3t::%get-field w3t::%put-field frozen-store iz6)
           :use ((:instance e-dissolve-gen (s (w3t::$sof (szg bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (szg bytes sp pc clen result W))) (zp (list :|%;%| (w3t::$sof (szg bytes sp pc clen result W)) (w3t::$fof (szg bytes sp pc clen result W)))))
                 e-zpair-shape e-label-vals))))

(defthm e-lift-nil
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u sframe0 milawa-func-module milawa-callee-frame milawa-func-body sz0 sz1 sz2 szm sz3 sz5 szg zlset1 zw2 w3t::$with_global w3t::$with_mem w3t::$with_local w3t::%get-field w3t::%put-field frozen-store iz6)
           :use ((:instance s-ctxt-lift-gen (s (w3t::$sof (szg bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (szg bytes sp pc clen result W)))
                            (b (list (list :label_%{%}% 0 nil nil))) (b2 nil)
                            (zp (zo6 bytes sp pc clen result W)) (fp2 (w3t::$fof (szg bytes sp pc clen result W))) (cont (cdr (const-tail3))))
                 e-frame-nil))))

(defthm e-spure-nil
  (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))))))

(defthm e-split-nil
  (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))))))

(defthm e-step-nil
  (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))
         (list (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u sframe0 milawa-func-module milawa-callee-frame milawa-func-body sz0 sz1 sz2 szm sz3 sz5 szg zlset1 zw2 w3t::$with_global w3t::$with_mem w3t::$with_local w3t::%get-field w3t::%put-field frozen-store iz6)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))
                 e-spure-nil e-split-nil e-lift-nil))))

(defthm e-lift-final-gen
  (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s f)
                                         (list (list :frame_%{%}% 0 fp nil))))
                        (list (list :|%;%| zp nil)))
                (consp zp) (equal (car zp) :|%;%|)
                (true-listp (cdr zp)) (equal (len (cdr zp)) 2)
                (consp cont) (true-listp cont)
                (< (w3t::%size (list (list :frame_%{%}% 0 fp nil)))
                   (w3t::%size (cons (list :frame_%{%}% 0 fp nil) cont))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (list :|%;%| s f)
                         (cons (list :frame_%{%}% 0 fp nil) cont)))
                  (list (list :|%;%| zp cont))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (cons (list :frame_%{%}% 0 fp nil) cont))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :frame_%{%}% 0 fp nil) cont)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :frame_%{%}% 0 fp nil) cont))
                            (w3t::%t9 0) (w3t::z (list :|%;%| s f))
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (cons (list :frame_%{%}% 0 fp nil) cont))))))))

(defthm e-frame-vals-gen
  (equal (w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 0 fp nil))))
         (list (list :|%;%| (list :|%;%| s f) nil))))

(defthm e-spure-nil2
  (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))))))

(defthm e-split-nil2
  (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))))))

(defthm e-final
  (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))
         (list (list :|%;%| (zo6 bytes sp pc clen result W) (cdr (const-tail3)))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ w3t::$nbytes_ wrt::%le-bytes wrt::%u sframe0 milawa-func-module milawa-callee-frame milawa-func-body sz0 sz1 sz2 szm sz3 sz5 szg zlset1 zw2 w3t::$with_global w3t::$with_mem w3t::$with_local w3t::%get-field w3t::%put-field frozen-store iz6)
           :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))
                 (:instance e-lift-final-gen (s (w3t::$sof (szg bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (szg bytes sp pc clen result W))) (zp (zo6 bytes sp pc clen result W)) (cont (cdr (const-tail3))))
                 (:instance e-frame-vals-gen (s (w3t::$sof (szg bytes sp pc clen result W))) (f (w3t::$fof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (szg bytes sp pc clen result W))))
                 e-spure-nil2 e-split-nil2))))

; ---------------------------------------------------------------------------
; The CONST branch's return of 1: the pure label and frame return steps
; ---------------------------------------------------------------------------
;
; The callee's void return leaves the tail's continuation ((const 1) (:return))
; at the post-$push state.  That value is the CONST opcode's answer: the
; machine is still running (status 1 is what the tail returns to the
; dispatcher's loop).  At the function-6 administration level the label 1 and
; the entry frame each consume the value+return by the pure return rules -- the
; generic returns.lisp facts -- so the run-level composition's last two steps
; are these.  The steps are expensive (35.6M and 11.6M) because the dispatcher's
; size checks evaluate the post-$push z; they are the price of the abstract
; state's many nested records.

(defun ret-z (bytes sp pc clen result W)
  (zo6 bytes sp pc clen result W))
(defconst *ret-cont* '((:const (:i32) 1) (:return)))
(defthm r1-label-return
  (equal (w3t::step (list :|%;%| (ret-z bytes sp pc clen result W)
                          (list (list :label_%{%}% 1 nil *ret-cont*))))
         (list (list :|%;%| (ret-z bytes sp pc clen result W) *ret-cont*)))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-pure w3t::step_pure)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (ret-z bytes sp pc clen result W)
                                            (list (list :label_%{%}% 1 nil *ret-cont*)))))
                 (:instance (:definition w3t::step/r-pure)
                            (w3t::%a0 (list :|%;%| (ret-z bytes sp pc clen result W)
                                            (list (list :label_%{%}% 1 nil *ret-cont*)))))
                 (:instance (:definition w3t::step_pure)
                            (w3t::%a0 (list (list :label_%{%}% 1 nil *ret-cont*))))
                 (:instance step-pure-return-out-of-label (n 1) (is0 nil) (x 1))))))
(defthm r2-frame-return
  (equal (w3t::step (list :|%;%| (ret-z bytes sp pc clen result W)
                          (list (list :frame_%{%}% 1 *frozen-entry-frame* *ret-cont*))))
         (list (list :|%;%| (ret-z bytes sp pc clen result W)
                     (list (list :const (list :i32) 1)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-pure w3t::step_pure)
           :use ((:instance (:definition w3t::step)
                            (w3t::%a0 (list :|%;%| (ret-z bytes sp pc clen result W)
                                            (list (list :frame_%{%}% 1 *frozen-entry-frame* *ret-cont*)))))
                 (:instance (:definition w3t::step/r-pure)
                            (w3t::%a0 (list :|%;%| (ret-z bytes sp pc clen result W)
                                            (list (list :frame_%{%}% 1 *frozen-entry-frame* *ret-cont*)))))
                 (:instance (:definition w3t::step_pure)
                            (w3t::%a0 (list (list :frame_%{%}% 1 *frozen-entry-frame* *ret-cont*))))
                 (:instance step-pure-return-out-of-frame (f *frozen-entry-frame*) (x 1))))))

; ---------------------------------------------------------------------------
; The (call 0) hand-off to the $push callee
; ---------------------------------------------------------------------------
;
; The CONST tail ends by calling function 0 ($push): the loaded word W is
; pushed onto the operand stack.  The call's read-layer rule expands
; (:CALL 0) to (ref.func_addr 0) + the call_ref type (*t0*); the entry's
; three-element slice ((const W) (ref.func_addr 0) *t0*) then fires the
; call_ref-func rule with one argument: the callee's frame carries W in
; local 0, with arity 0 for both its label and frame.  The dispatcher's
; ctxt phase refuses the call slices (its search cannot step a slice whose
; size is not smaller than the whole configuration), which is what makes the
; search terminate; and the failure facts for those slices must be stated in
; CONSTRUCTOR form ((list :%;% ...), not ICFG) or they never fire as rewrite
; rules inside the search's evaluation.

(defconst *t0* (list :call_ref (list :_def (list :rec (list (list :sub (list (list :final)) nil (list :func%->% (list (list :i32)) nil)))) 0)))

(defun sframe0 (bytes sp pc clen result W)
  (declare (ignore bytes sp pc clen result))
  (list :%rec
        (cons :locals (list (list (list :const (list :i32) W))))
        (cons :module (milawa-func-module 0))))

(defun sadmin (bytes sp pc clen result W)
  (list (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W)
              (list (list :label_%{%}% 0 nil (milawa-func-body 0))))))

(defthm dconst-call0-expand
  (equal (w3t::step (icfg (zw2 bytes sp pc clen result W)
                          (list (list :call 0))))
         (list (icfg (zw2 bytes sp pc clen result W)
                     (list (list :ref.func_addr 0) *t0*)))))

(defthm dconst-lone-call0-ref
  (equal (w3t::step (list :|%;%| z (list *t0*))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list *t0*))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list *t0*))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list *t0*))))))))

(defthm dconst-no-ctxt-call0-two
  (equal (w3t::step/r-ctxt-instrs
          (icfg (zw2 bytes sp pc clen result W)
                (list (list :ref.func_addr 0) *t0*)))
         nil)
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :expand ((w3t::step/r-ctxt-instrs
                     (icfg (zw2 bytes sp pc clen result W)
                           (list (list :ref.func_addr 0) *t0*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm dconst-call0-entry-two
  (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W)
                          (list (list :ref.func_addr 0) *t0*)))
         nil)
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use (dconst-no-ctxt-call0-two)
           :expand ((w3t::step (list :|%;%| (zw2 bytes sp pc clen result W)
                                     (list (list :ref.func_addr 0) *t0*)))))))

(defthm dconst-no-ctxt-call0-three
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (zw2 bytes sp pc clen result W)
                         (list (list :const (list :i32) W)
                               (list :ref.func_addr 0) *t0*)))
                  nil))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use (dconst-call0-entry-two)
           :expand ((w3t::step/r-ctxt-instrs
                     (icfg (zw2 bytes sp pc clen result W)
                           (list (list :const (list :i32) W)
                                 (list :ref.func_addr 0) *t0*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm dconst-call0-entry
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W)
                                   (list (list :const (list :i32) W)
                                         (list :ref.func_addr 0) *t0*)))
                  (list (list :|%;%| (zw2 bytes sp pc clen result W)
                              (sadmin bytes sp pc clen result W)))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
           :use (dconst-no-ctxt-call0-three)
           :expand ((w3t::step (list :|%;%| (zw2 bytes sp pc clen result W)
                                     (list (list :const (list :i32) W)
                                           (list :ref.func_addr 0) *t0*)))))))

(defthm dconst-call0-expand-ctxt
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (zw2 bytes sp pc clen result W)
                         (cons (list :const (list :i32) W) (const-tail3))))
                  (list (icfg (zw2 bytes sp pc clen result W)
                              (cons (list :const (list :i32) W)
                                    (cons (list :ref.func_addr 0)
                                          (cons *t0* (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (const-tail3)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) W)
                                           (const-tail3))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (const-tail3)))
                            (w3t::%t9 1) (w3t::z (zw2 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (const-tail3)))))
                 dconst-call0-expand))))

(defthm dconst-call0-expand-step
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step (icfg (zw2 bytes sp pc clen result W)
                                   (cons (list :const (list :i32) W) (const-tail3))))
                  (list (icfg (zw2 bytes sp pc clen result W)
                              (cons (list :const (list :i32) W)
                                    (cons (list :ref.func_addr 0)
                                          (cons *t0* (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (dconst-call0-expand-ctxt)
           :expand ((w3t::step (icfg (zw2 bytes sp pc clen result W)
                                     (cons (list :const (list :i32) W)
                                           (const-tail3))))))))

(defthm dconst-call0-entry-ctxt
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (zw2 bytes sp pc clen result W)
                         (cons (list :const (list :i32) W)
                               (cons (list :ref.func_addr 0)
                                     (cons *t0* (cdr (const-tail3)))))))
                  (list (icfg (zw2 bytes sp pc clen result W)
                              (append (sadmin bytes sp pc clen result W)
                                      (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_
                                      zw2 zlset1 iz6 frozen-store
                                      sframe0 sadmin milawa-callee-frame
                                      milawa-func-body milawa-func-module
                                      w3t::$with_local w3t::$with_global)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (cons (list :ref.func_addr 0)
                                                        (cons *t0* (cdr (const-tail3))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :const (list :i32) W)
                                           (cons (list :ref.func_addr 0)
                                                 (cons *t0* (cdr (const-tail3)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (cons (list :ref.func_addr 0)
                                                  (cons *t0* (cdr (const-tail3))))))
                            (w3t::%t9 2) (w3t::z (zw2 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (cons (list :ref.func_addr 0)
                                                        (cons *t0* (cdr (const-tail3))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (cons (list :ref.func_addr 0)
                                                  (cons *t0* (cdr (const-tail3))))))
                            (w3t::%t9 2) (w3t::z (zw2 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (cons (list :ref.func_addr 0)
                                                        (cons *t0* (cdr (const-tail3))))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (cons (list :const (list :i32) W)
                                            (cons (list :ref.func_addr 0)
                                                  (cons *t0* (cdr (const-tail3))))))
                            (w3t::%t9 2) (w3t::z (zw2 bytes sp pc clen result W))
                            (w3t::%a0 (icfg (zw2 bytes sp pc clen result W)
                                            (cons (list :const (list :i32) W)
                                                  (cons (list :ref.func_addr 0)
                                                        (cons *t0* (cdr (const-tail3))))))))
                 dconst-lone-call0-ref
                 dconst-call0-entry-two
                 dconst-call0-entry))))

(defthm dconst-call0-entry-step
  (implies (unsigned-byte-p 32 W)
           (equal (w3t::step (icfg (zw2 bytes sp pc clen result W)
                                   (cons (list :const (list :i32) W)
                                         (cons (list :ref.func_addr 0)
                                               (cons *t0* (cdr (const-tail3)))))))
                  (list (icfg (zw2 bytes sp pc clen result W)
                              (append (sadmin bytes sp pc clen result W)
                                      (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_)
           :use (dconst-call0-entry-ctxt)
           :expand ((w3t::step (icfg (zw2 bytes sp pc clen result W)
                                     (cons (list :const (list :i32) W)
                                           (cons (list :ref.func_addr 0)
                                                 (cons *t0* (cdr (const-tail3)))))))))))


; ---------------------------------------------------------------------------
; The run-level composition, part 1: the constructor respells and label lifts
; ---------------------------------------------------------------------------
;
; The admin composition needs each body-level step both in CONSTRUCTOR form
; (the label rule calls step on (list :%;% z body), not on (icfg z body)) and
; with function 6's label 1 wrapped around it.  The respells are one-line
; proofs from the ICFG facts; the lifts go by the label rule with the respell
; as the inner step.  The value functions (dsub/dmul/dltu/deqz) stay disabled
; or the label rule's guards unfold the symbolic arithmetic.  The lifts of
; the callee's remaining positions and the later tiers are next.

(defthm stepc-dconst-tail-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-tail-step))))

(defthm lbl-dconst-tail-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
                 stepc-dconst-tail-step))))

(defthm stepc-dconst-cal-read1-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest)))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-read1-step))))

(defthm lbl-dconst-cal-read1-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))))))
                 stepc-dconst-cal-read1-step))))

(defthm stepc-dconst-cal-sub-step
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (dadmin (dbody0 pc)) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (dadmin (dbody1 pc)) (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-sub-step))))

(defthm stepc-dconst-cal-ldis-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (dadmin (dbody4 pc clen)) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest)))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-ldis-step))))

(defthm stepc-dconst-cal-fdis-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (dframe3 (dbody4 pc clen)) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (dbody4 pc clen) (const-rest)))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-fdis-step))))

(defthm stepc-dconst-cal-read2-step2
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody1 pc))))) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-read2-step2))))

(defthm stepc-dconst-cal-mul-step2
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen))
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-mul-step2))))

(defthm stepc-dconst-cal-ltu-step2
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen))
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody3 pc clen))))) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (dbody4 pc clen))))) (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-cal-ltu-step2))))

(defthm stepc-dconst-tail-eqz-1-step
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-tail-eqz-1-step))))

(defthm lbl-dconst-tail-eqz-1-step
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))))))
                 stepc-dconst-tail-eqz-1-step))))

(defthm stepc-dconst-tail-ifelse-0-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) 0) (cdr (const-rest)))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-tail-ifelse-0-step))))

(defthm lbl-dconst-tail-ifelse-0-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))
                 stepc-dconst-tail-ifelse-0-step))))

(defthm stepc-dconst-block-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-block-step))))

(defthm lbl-dconst-block-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))
                 stepc-dconst-block-step))))

(defthm stepc-dconst-elabel-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cddr (const-rest)))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-elabel-step))))

(defthm lbl-dconst-elabel-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))
                 stepc-dconst-elabel-step))))

(defthm stepc-dconst-read-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cddr (const-rest))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-read-step))))

(defthm lbl-dconst-read-step
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cddr (const-rest))))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cddr (const-rest)))))))
                 stepc-dconst-read-step))))

(defthm stepc-dconst-load-step
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W)))
           (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) pc) (cdddr (const-rest)))))
         (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const (list :i32) W) (cddddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step) :use (dconst-load-step))))

; ---------------------------------------------------------------------------
; THE LITERAL-SPELLING CHAINS: the callee's remaining positions, at the
; spelling the rewriter actually produces.
;
; The raw-spelled stepc- facts above are proved by lockstep normalization of
; a :use instance, so they compose at the raw spelling.  Inside a context
; rule, though, the instruction list has already been normalized before any
; rule about `step` is tried: the frame record is the literal :%REC term, the
; tail is the literal 13-instruction list, and the numtype is the quoted
; constant '(:I32).  A rule whose LHS still contains (milawa-callee-frame 3)
; or (const-rest) can never fire there.
;
; So each position gets a chain stated at the literal spelling:
;
;   spure-<p>-body   (step_pure LIT0) = nil
;   sread-<p>-body   (step_read/split (:%;% Z LIT0)) = nil
;   ctxt-<p>-body    (step/r-ctxt-instrs (:%;% Z LIT0)) = (list (:%;% Z LIT1))
;   match-<p>-body   (step_pure/match135 (take 13 LIT0)) = nil
;   search-<p>-body  (step_pure/search141 14 14 14 LIT0) = nil
;   spure-<p>-label  (step_pure ((label 1 nil LIT0))) = nil
;   sread-<p>-label  (step_read/split (:%;% Z ((label 1 nil LIT0)))) = nil
;   lbl-dconst-<p>-lit  the label-1 lift
;
; and all the label lifts are instances of one generic lemma, label-lift-general,
; whose premises are exactly the phase and measure facts above.  The section is
; generated by harness/gen_compose.py from a table of the six positions; the
; events themselves are ordinary defthms so certification and inspection stay
; straightforward.

(defthm label-lift-general
  (implies (and (true-listp body)
                (true-listp body2)
                (equal (w3t::step_pure body) nil)
                (equal (w3t::step_read/split (list :|%;%| z body)) nil)
                (equal (w3t::step/r-ctxt-instrs (list :|%;%| z body))
                       (list (list :|%;%| z2 body2)))
                (equal (w3t::step_pure (list (list :label_%{%}% 1 nil body))) nil)
                (equal (w3t::step_read/split
                        (list :|%;%| z (list (list :label_%{%}% 1 nil body)))) nil)
                (< (w3t::%size body)
                   (w3t::%size (list (list :label_%{%}% 1 nil body)))))
           (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil body))))
                  (list (list :|%;%| z2 (list (list :label_%{%}% 1 nil body2))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil body)))))
                 no-ctxt-instrs-on-a-lone-label-general))))
(defthm spure-cal-sub-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-sub-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-sub-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-sub-ctxt))))
(defthm match-cal-sub-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-sub-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-sub-body))))
(defthm spure-cal-sub-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-sub-body))))
(defthm sread-cal-sub-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-sub-lit
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm spure-cal-ldis-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-ldis-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-ldis-body
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-ldis-ctxt))))
(defthm match-cal-ldis-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-ldis-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-ldis-body))))
(defthm spure-cal-ldis-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-ldis-body))))
(defthm sread-cal-ldis-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-ldis-lit
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm spure-cal-fdis-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-fdis-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-fdis-body
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-fdis-ctxt))))
(defthm match-cal-fdis-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-fdis-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-fdis-body))))
(defthm spure-cal-fdis-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-fdis-body))))
(defthm sread-cal-fdis-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-fdis-lit
  (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm spure-cal-read2-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-read2-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-read2-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-read2-ctxt2))))
(defthm match-cal-read2-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-read2-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-read2-body))))
(defthm spure-cal-read2-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-read2-body))))
(defthm sread-cal-read2-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-read2-lit
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) '((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm spure-cal-mul-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-mul-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-mul-body
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-mul-ctxt2))))
(defthm match-cal-mul-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-mul-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-mul-body))))
(defthm spure-cal-mul-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-mul-body))))
(defthm sread-cal-mul-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-mul-lit
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) clen) '((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))

(defthm spure-cal-ltu-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-ltu-body
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-ltu-body
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-cal-ltu-ctxt2))))
(defthm match-cal-ltu-body
  (equal (w3t::step_pure/match135 (take 13 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 13 x))))))
(defthm search-cal-ltu-body
  (equal (w3t::step_pure/search141 14 14 14 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure/search141 14 14 14 x)))
           :use (match-cal-ltu-body))))
(defthm spure-cal-ltu-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-ltu-body))))
(defthm sread-cal-ltu-label
  (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm lbl-dconst-cal-ltu-lit
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dsub pc)) (cons (list :const '(:i32) (dmul clen)) '((:RELOP (:I32) (:LT (:U))))))))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :frame_%{%}% 1 '(:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dltu (dsub pc) (dmul clen))) nil)))) '((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))



; ---------------------------------------------------------------------------
; THE LATER TIERS: load, local.set 1, the second read, the add, the write,
; and the local.get -- each lifted at label 1, with the store evolving.
;
; Two new pieces of machinery are needed here.
;
; The read phase.  For a lone label, the step_read/split dispatcher's label
; rules are the only ones whose body searches survive the shape checks: the
; return_call_ref-label rule searches the body for :RETURN_CALL_REF, and the
; throw_ref-label rule needs a two-element body.  read-on-a-lone-label-general
; takes the first search as a hypothesis and the second failure as the
; premise (len != 2), and reduces the whole phase to nil.  Per position the
; search is nil because %tag-lo returns (len body)+1 when the tag is absent,
; which is above the upper bound; the taglo- fact records that value and the
; rsearch- fact the (concrete-bound) nil result.
;
; The lbl proofs hand the phase facts in with :use rather than relying on
; backchaining through their hypotheses: an equality that is a literal of the
; clause composes by lockstep normalization, which is immune to the rule
; ordering that made the rewrite-rule route fragile.
;
; The store evolves: the local.set and the global.set change z, so their
; facts are stated at the concrete z of the chain (and the book's generic-z
; ctxt facts are instantiated explicitly).  The lset1 result body starts at
; (cddr (cddddr const-rest)): the local.set instruction itself is consumed.

(defthm read-on-a-lone-label-general
  (implies (and (true-listp body)
                (not (equal (acl2::len body) 2))
                (equal (w3t::step_read/split/search60
                        (w3t::%tag-lo :RETURN_CALL_REF 1 body)
                        (w3t::%tag-lo :RETURN_CALL_REF 1 body)
                        (acl2::len body)
                        body)
                       nil))
           (equal (w3t::step_read/split
                   (list :|%;%| z (list (list :label_%{%}% n is0 body))))
                  nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% n is0 body)))))))))

(defthm spure-cal-load-body
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-load-body
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-load-body
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-load-ctxt))))
(defthm match-cal-load-body
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure/match135 (take 10 (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 10 x))))))
(defthm search-cal-load-body
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure/search141 11 11 11 (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 11 11 11 x)))
           :use (match-cal-load-body))))
(defthm spure-cal-load-label
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-load-body))))
(defthm taglo-cal-load
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) 12)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-load
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_read/split/search60 12 12 11 (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-load-label
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (iz6 bytes sp pc clen result)) (n 1) (is0 nil) (body (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 rsearch-cal-load))))
(defthm lbl-dconst-cal-load-lit
  (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :const '(:i32) pc) '((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (iz6 bytes sp pc clen result)) (body2 (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 spure-cal-load-body sread-cal-load-body ctxt-cal-load-body
                 spure-cal-load-label sread-cal-load-label))))

(defthm spure-cal-lset1-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-lset1-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-lset1-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)) '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance dconst-lset1-ctxt (z (iz6 bytes sp pc clen result)))))))
(defthm match-cal-lset1-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/match135 (take 9 (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 9 x))))))
(defthm search-cal-lset1-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/search141 10 10 10 (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 10 10 10 x)))
           :use (match-cal-lset1-body))))
(defthm spure-cal-lset1-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-lset1-body))))
(defthm taglo-cal-lset1
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) 11)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-lset1
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split/search60 11 11 10 (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-lset1-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (iz6 bytes sp pc clen result)) (n 1) (is0 nil) (body (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 rsearch-cal-lset1))))
(defthm lbl-dconst-cal-lset1-lit
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)) (list (list :label_%{%}% 1 nil '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :const '(:i32) W) '((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (body2 '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
                 spure-cal-lset1-body sread-cal-lset1-body ctxt-cal-lset1-body
                 spure-cal-lset1-label sread-cal-lset1-label))))

(defthm spure-cal-get1-body
  (equal (w3t::step_pure '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-get1-body
  (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-get1-body
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zlset1 bytes sp pc clen result W) '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (list (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-get1-ctxt))))
(defthm match-cal-get1-body
  (equal (w3t::step_pure/match135 (take 7 '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 7 x))))))
(defthm search-cal-get1-body
  (equal (w3t::step_pure/search141 8 8 8 '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 8 8 8 x)))
           :use (match-cal-get1-body))))
(defthm spure-cal-get1-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-get1-body))))
(defthm taglo-cal-get1
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) 9)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-get1
  (equal (w3t::step_read/split/search60 9 9 8 '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-get1-label
  (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zlset1 bytes sp pc clen result W)) (n 1) (is0 nil) (body '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
                 rsearch-cal-get1))))
(defthm lbl-dconst-cal-get1-lit
  (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (list (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (zlset1 bytes sp pc clen result W)) (body '((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) (z2 (zlset1 bytes sp pc clen result W)) (body2 (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 spure-cal-get1-body sread-cal-get1-body ctxt-cal-get1-body
                 spure-cal-get1-label sread-cal-get1-label))))

(defthm spure-cal-add-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-add-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-add-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (dconst-add-ctxt))))
(defthm match-cal-add-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure/match135 (take 7 (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 7 x))))))
(defthm search-cal-add-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure/search141 8 8 8 (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 8 8 8 x)))
           :use (match-cal-add-body))))
(defthm spure-cal-add-label
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-add-body))))
(defthm taglo-cal-add
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) 9)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-add
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split/search60 9 9 8 (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-add-label
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zlset1 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 rsearch-cal-add))))
(defthm lbl-dconst-cal-add-lit
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (zlset1 bytes sp pc clen result W)) (body (cons (list :const '(:i32) pc) '((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (zlset1 bytes sp pc clen result W)) (body2 (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 spure-cal-add-body sread-cal-add-body ctxt-cal-add-body
                 spure-cal-add-label sread-cal-add-label))))

(defthm spure-cal-gset-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-gset-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-gset-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zlset1 bytes sp pc clen result W) (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance dconst-gset-ctxt (z (zlset1 bytes sp pc clen result W)))))))
(defthm match-cal-gset-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure/match135 (take 5 (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 5 x))))))
(defthm search-cal-gset-body
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure/search141 6 6 6 (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 6 6 6 x)))
           :use (match-cal-gset-body))))
(defthm spure-cal-gset-label
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-gset-body))))
(defthm taglo-cal-gset
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) 7)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-gset
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split/search60 7 7 6 (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-gset-label
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step_read/split (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zlset1 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 rsearch-cal-gset))))
(defthm lbl-dconst-cal-gset-lit
  (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list (list :label_%{%}% 1 nil '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (zlset1 bytes sp pc clen result W)) (body (cons (list :const '(:i32) (dadd pc)) '((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (body2 '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
                 spure-cal-gset-body sread-cal-gset-body ctxt-cal-gset-body
                 spure-cal-gset-label sread-cal-gset-label))))

(defthm spure-cal-lget-body
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_pure '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-lget-body
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_read/split (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-lget-body
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (list (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance dconst-lget-ctxt (z (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))))))))
(defthm match-cal-lget-body
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_pure/match135 (take 3 '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 3 x))))))
(defthm search-cal-lget-body
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_pure/search141 4 4 4 '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 4 4 4 x)))
           :use (match-cal-lget-body))))
(defthm spure-cal-lget-label
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-lget-body))))
(defthm taglo-cal-lget
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) 5)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-lget
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_read/split/search60 5 5 4 '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-lget-label
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step_read/split (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list (list :label_%{%}% 1 nil '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (n 1) (is0 nil) (body '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
                 rsearch-cal-lget))))
(defthm lbl-dconst-cal-lget-lit
  (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list (list :label_%{%}% 1 nil '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (list (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (body '((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))) (z2 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (body2 (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 spure-cal-lget-body sread-cal-lget-body ctxt-cal-lget-body
                 spure-cal-lget-label sread-cal-lget-label))))



; ---------------------------------------------------------------------------
; THE (CALL 0) HAND-OFF, at label 1.
;
; Two steps.  The expand replaces the call instruction by the ref.func_addr
; pair (the same step the body-level dconst-call0-expand proves); the entry
; turns the pair and the argument into the $push callee's admin, appended to
; the (const 1) (return) continuation.  Both are lifted at label 1 by the
; same nine-fact chain as the earlier positions.
;
; The entry's result body is the literal spelling of
; (append (sadmin ...) (cdr (const-tail3))): the $push frame record with W in
; its single local, the function-0 module record, the function-0 body, and
; the two-instruction continuation.  The ctxt facts are stated at the zw2
; spelling the book's call0 facts use, with zw2 kept opaque, while
; milawa-func-body is enabled so the admin literal forms in the proof.

(defthm spure-cal-call0-expand-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-call0-expand-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-call0-expand-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (list (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use (dconst-call0-expand-ctxt))))
(defthm match-cal-call0-expand-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/match135 (take 3 (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 3 x))))))
(defthm search-cal-call0-expand-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/search141 4 4 4 (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 4 4 4 x)))
           :use (match-cal-call0-expand-body))))
(defthm spure-cal-call0-expand-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-call0-expand-body))))
(defthm taglo-cal-call0-expand
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))) 5)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-call0-expand
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split/search60 5 5 4 (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-call0-expand-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zw2 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                 rsearch-cal-call0-expand))))
(defthm lbl-dconst-cal-call0-expand-lit
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (zw2 bytes sp pc clen result W)) (body (cons (list :const '(:i32) W) '((:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (z2 (zw2 bytes sp pc clen result W)) (body2 (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))))
                 spure-cal-call0-expand-body sread-cal-call0-expand-body ctxt-cal-call0-expand-body
                 spure-cal-call0-expand-label sread-cal-call0-expand-label))))

(defthm spure-cal-call0-entry-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-cal-call0-entry-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-cal-call0-entry-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (zw2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const '(:i32) W)))) (cons :module '(:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 0 nil '((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0))))) '((:CONST (:I32) 1) (:RETURN)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 dconst zlset1 zw2)
           :use (dconst-call0-entry-ctxt))))
(defthm match-cal-call0-entry-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/match135 (take 4 (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 4 x))))))
(defthm search-cal-call0-entry-body
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure/search141 5 5 5 (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 5 5 5 x)))
           :use (match-cal-call0-entry-body))))
(defthm spure-cal-call0-entry-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-cal-call0-entry-body))))
(defthm taglo-cal-call0-entry
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))) 6)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-cal-call0-entry
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split/search60 6 6 5 (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-cal-call0-entry-label
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step_read/split (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN))))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zw2 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))))
                 rsearch-cal-call0-entry))))
(defthm lbl-dconst-cal-call0-entry-lit
  (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const '(:i32) W)))) (cons :module '(:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 0 nil '((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0))))) '((:CONST (:I32) 1) (:RETURN)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::un-p mvm-word-to-bytes dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :use ((:instance label-lift-general (z (zw2 bytes sp pc clen result W)) (body (cons (list :const '(:i32) W) (cons (list :ref.func_addr 0) (cons *t0* '((:CONST (:I32) 1) (:RETURN)))))) (z2 (zw2 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const '(:i32) W)))) (cons :module '(:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 0 nil '((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0))))) '((:CONST (:I32) 1) (:RETURN)))))
                 spure-cal-call0-entry-body sread-cal-call0-entry-body ctxt-cal-call0-entry-body
                 spure-cal-call0-entry-label sread-cal-call0-entry-label))))



; ---------------------------------------------------------------------------
; THE $push CALLEE, at label 1: the seven positions and the two dissolves.
;
; The s-chain's s-stepK/s-liftK facts already give the body-level steps and
; the ctxt lifts inside the callee's frame and label 0; these events lift them
; to label 1, so the call-entry's admin literal and the callee's execution sit
; in one label-1 chain.  The bodies stay at the s-chain's spelling (sframe0,
; sbodyK, const-tail3, and the z's zpair0/zoK, kept opaque), which is what
; lets the ctxt facts apply verbatim.
;
; Positions 0-4 go through the ctxt route: label-lift-general with the
; s-liftK premise.  Position 5 (the global.set 0 write of sp+4) is the
; late-rule case -- its ctxt phase is nil (the two-element slice ties the
; search's measure) -- so its label lift uses the dispatcher directly with
; the phase facts and s-step5.  The two dissolves then follow: the label-0
; nil body is removed by the pure label-vals rule in the tail context
; (e-lift-nil), and the empty frame by e-final.  After them the label-1 body
; is the caller's continuation (cdr (const-tail3)) = ((const 1) (return)).

(defthm spure-push-s0-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s0-body
  (equal (w3t::step_read/split (list :|%;%| (zpair0 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-push-s0-body
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zpair0 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))) (list (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (s-lift0))))
(defthm match-push-s0-body
  (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 2 x))))))
(defthm search-push-s0-body
  (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s0-body))))
(defthm spure-push-s0-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s0-body))))
(defthm taglo-push-s0
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s0
  (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s0-label
  (equal (w3t::step_read/split (list :|%;%| (zpair0 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zpair0 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))))
                 rsearch-push-s0))))
(defthm lbl-dconst-push-s0-lit
  (equal (w3t::step (list :|%;%| (zpair0 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance label-lift-general (z (zpair0 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) (z2 (zo1 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))
                 spure-push-s0-body sread-push-s0-body ctxt-push-s0-body
                 spure-push-s0-label sread-push-s0-label))))

(defthm spure-push-s1-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s1-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-push-s1-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo1 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))) (list (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (s-lift1))))
(defthm match-push-s1-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 2 x))))))
(defthm search-push-s1-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s1-body))))
(defthm spure-push-s1-label
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s1-body))))
(defthm taglo-push-s1
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s1
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s1-label
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zo1 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))
                 rsearch-push-s1))))
(defthm lbl-dconst-push-s1-lit
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance label-lift-general (z (zo1 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) (z2 (zo2 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))
                 spure-push-s1-body sread-push-s1-body ctxt-push-s1-body
                 spure-push-s1-label sread-push-s1-label))))

(defthm spure-push-s2-body
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s2-body
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_read/split (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-push-s2-body
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo2 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))) (list (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (s-lift2))))
(defthm match-push-s2-body
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 2 x))))))
(defthm search-push-s2-body
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s2-body))))
(defthm spure-push-s2-label
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s2-body))))
(defthm taglo-push-s2
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s2
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s2-label
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step_read/split (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zo2 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))))
                 rsearch-push-s2))))
(defthm lbl-dconst-push-s2-lit
  (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance label-lift-general (z (zo2 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) (z2 (zo3 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))
                 spure-push-s2-body sread-push-s2-body ctxt-push-s2-body
                 spure-push-s2-label sread-push-s2-label))))

(defthm spure-push-s3-body
  (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s3-body
  (equal (w3t::step_read/split (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-push-s3-body
  (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo3 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))) (list (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (s-lift3))))
(defthm match-push-s3-body
  (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 2 x))))))
(defthm search-push-s3-body
  (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s3-body))))
(defthm spure-push-s3-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s3-body))))
(defthm taglo-push-s3
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s3
  (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s3-label
  (equal (w3t::step_read/split (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zo3 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))))
                 rsearch-push-s3))))
(defthm lbl-dconst-push-s3-lit
  (equal (w3t::step (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance label-lift-general (z (zo3 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) (z2 (zo4 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))
                 spure-push-s3-body sread-push-s3-body ctxt-push-s3-body
                 spure-push-s3-label sread-push-s3-label))))

(defthm spure-push-s4-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s4-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-push-s4-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))) (list (list :|%;%| (zo5 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use (s-lift4))))
(defthm match-push-s4-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 2 x))))))
(defthm search-push-s4-body
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s4-body))))
(defthm spure-push-s4-label
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s4-body))))
(defthm taglo-push-s4
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s4
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s4-label
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step_read/split (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general
                  (z (zo4 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))
                 rsearch-push-s4))))
(defthm lbl-dconst-push-s4-lit
  (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo5 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs)
           :use ((:instance label-lift-general (z (zo4 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) (z2 (zo5 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3)))))
                 spure-push-s4-body sread-push-s4-body ctxt-push-s4-body
                 spure-push-s4-label sread-push-s4-label))))



(defthm spure-push-s5-body
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-s5-body
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_read/split (list :|%;%| (zo4 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_read/split x))))))
(defthm match-push-s5-body
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/match135 x)) (:free (x) (take 2 x))))))
(defthm search-push-s5-body
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x)))
           :use (match-push-s5-body))))
(defthm spure-push-s5-label
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (search-push-s5-body))))
(defthm taglo-push-s5
  (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) 4)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-s5
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module)
           :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-s5-label
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step_read/split (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes)
           :use ((:instance read-on-a-lone-label-general (z (zo4 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))))
                 rsearch-push-s5))))
(defthm lbl-dconst-push-s5-lit
  (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))) (list (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))))))
  :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs w3t::$binop_ w3t::$nbytes_ w3t::%get-field w3t::%put-field w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store frozen-store)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))))
                 no-ctxt-instrs-on-a-lone-label-general
                 spure-push-s5-body sread-push-s5-body spure-push-s5-label sread-push-s5-label
                 s-ctxt5-nil s-step5))))


(defthm spure-push-ediss-body (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-ediss-body (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_read/split x))))))
(defthm match-push-ediss-body (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure/match135 x)) (:free (x) (take 2 x))))))
(defthm search-push-ediss-body (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x))) :use (match-push-ediss-body))))
(defthm spure-push-ediss-label (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure x))) :use (search-push-ediss-body))))
(defthm taglo-push-ediss (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) 4) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-ediss (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-ediss-label (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))) nil) :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes) :use ((:instance read-on-a-lone-label-general (z (zo6 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) rsearch-push-ediss))))
(defthm ctxt-push-ediss-body (equal (w3t::step/r-ctxt-instrs (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) (list (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use (e-lift-nil))))
(defthm lbl-dconst-push-ediss-lit (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))) (list (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))))) :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ w3t::%get-field w3t::%put-field w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store frozen-store szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module) :use ((:instance label-lift-general (z (zo6 bytes sp pc clen result W)) (body (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) (z2 (zo6 bytes sp pc clen result W)) (body2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) spure-push-ediss-body sread-push-ediss-body ctxt-push-ediss-body spure-push-ediss-label sread-push-ediss-label))))
(defthm spure-push-efinal-body (equal (w3t::step_pure (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-push-efinal-body (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_read/split x))))))
(defthm match-push-efinal-body (equal (w3t::step_pure/match135 (take 2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure/match135 x)) (:free (x) (take 2 x))))))
(defthm search-push-efinal-body (equal (w3t::step_pure/search141 3 3 3 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure/search141 3 3 3 x))) :use (match-push-efinal-body))))
(defthm spure-push-efinal-label (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (x) (w3t::step_pure x))) :use (search-push-efinal-body))))
(defthm taglo-push-efinal (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) 4) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-push-efinal (equal (w3t::step_read/split/search60 4 4 3 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ frozen-store iz6 zlset1 zw2 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0) :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-push-efinal-label (equal (w3t::step_read/split (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))) nil) :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes) :use ((:instance read-on-a-lone-label-general (z (zo6 bytes sp pc clen result W)) (n 1) (is0 nil) (body (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) rsearch-push-efinal))))
(defthm lbl-dconst-push-efinal-lit (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))) (list (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cdr (const-tail3))))))) :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dadd w3t::$binop_ w3t::$nbytes_ w3t::%get-field w3t::%put-field w3t::$with_global w3t::$with_mem w3t::$with_local w3t::$frame w3t::$store frozen-store szg sz0 sz1 sz2 sz3 sz5 szm zo1 zo2 zo3 zo4 zo5 zo6 zpair0 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-callee-frame milawa-func-module) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))))) no-ctxt-instrs-on-a-lone-label-general spure-push-efinal-body sread-push-efinal-body spure-push-efinal-label sread-push-efinal-label e-final))))


; ---------------------------------------------------------------------------
; THE FRAME-1 OUTER LIFTS: every label-1 step, wrapped in function 6's frame.
;
; dframe-outer-from-label is the generic wrapper: given the label-1 step at a
; state pair z0 (with z0's pair shape) and the label's size, the frame
; instruction around it steps to the same body inside the frame, the store
; from the result and the frames projected from z0/z1.  The run's enclosing
; frame and the instruction's frame are both function 6's, which is why f and
; fp are both ($fof z0).
;
; The zinfo-K facts record each state pair's shape (consp, car, true-listp,
; len, and the projection identity), proved by unfolding the z defuns once.
; The outer facts then :use the generic wrapper, the label fact and the two
; zinfos, with every z and body defun disabled so the label fact's arguments
; stay symbolic -- enabling them is what made the s4 instance normalize a
; whole store record.
;
; Twenty-nine label facts are lifted, so the whole CONST branch now has a
; frame-1 step for every label-1 step it takes.

(defthm dframe-outer-from-label
  (implies (and (equal z0 (list :|%;%| (w3t::$sof z0) (w3t::$fof z0)))
                (equal (w3t::step (list :|%;%| z0 (list (list :label_%{%}% 1 nil b))))
                       (list (list :|%;%| z1 (list (list :label_%{%}% 1 nil b2)))))
                (< (w3t::%size (list (list :label_%{%}% 1 nil b)))
                   (w3t::%size (list (list :frame_%{%}% 1 (w3t::$fof z0)
                                           (list (list :label_%{%}% 1 nil b))))))
                (consp z1) (equal (car z1) :|%;%|)
                (true-listp (cdr z1)) (equal (len (cdr z1)) 2))
           (equal (w3t::step (list :|%;%| z0
                                   (list (list :frame_%{%}% 1 (w3t::$fof z0)
                                               (list (list :label_%{%}% 1 nil b))))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof z1) (w3t::$fof z0))
                              (list (list :frame_%{%}% 1 (w3t::$fof z1)
                                          (list (list :label_%{%}% 1 nil b2))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance dstep-frame-outer-gen
                            (s (w3t::$sof z0)) (f (w3t::$fof z0))
                            (fp (w3t::$fof z0)) (zp z1))))))

(defthm zinfo-0
  (and (equal (consp (iz6 bytes sp pc clen result)) t)
       (equal (car (iz6 bytes sp pc clen result)) :|%;%|)
       (true-listp (cdr (iz6 bytes sp pc clen result)))
       (equal (len (cdr (iz6 bytes sp pc clen result))) 2)
       (equal (iz6 bytes sp pc clen result) (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-1
  (and (equal (consp (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) t)
       (equal (car (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) :|%;%|)
       (true-listp (cdr (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))))
       (equal (len (cdr (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)))) 2)
       (equal (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W)) (list :|%;%| (w3t::$sof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-2
  (and (equal (consp (zlset1 bytes sp pc clen result W)) t)
       (equal (car (zlset1 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zlset1 bytes sp pc clen result W)))
       (equal (len (cdr (zlset1 bytes sp pc clen result W))) 2)
       (equal (zlset1 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (zlset1 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-3
  (and (equal (consp (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) t)
       (equal (car (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) :|%;%|)
       (true-listp (cdr (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))))
       (equal (len (cdr (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))))) 2)
       (equal (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-4
  (and (equal (consp (zw2 bytes sp pc clen result W)) t)
       (equal (car (zw2 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zw2 bytes sp pc clen result W)))
       (equal (len (cdr (zw2 bytes sp pc clen result W))) 2)
       (equal (zw2 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-5
  (and (equal (consp (zpair0 bytes sp pc clen result W)) t)
       (equal (car (zpair0 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zpair0 bytes sp pc clen result W)))
       (equal (len (cdr (zpair0 bytes sp pc clen result W))) 2)
       (equal (zpair0 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zpair0 bytes sp pc clen result W)) (w3t::$fof (zpair0 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-6
  (and (equal (consp (zo1 bytes sp pc clen result W)) t)
       (equal (car (zo1 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo1 bytes sp pc clen result W)))
       (equal (len (cdr (zo1 bytes sp pc clen result W))) 2)
       (equal (zo1 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo1 bytes sp pc clen result W)) (w3t::$fof (zo1 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-7
  (and (equal (consp (zo2 bytes sp pc clen result W)) t)
       (equal (car (zo2 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo2 bytes sp pc clen result W)))
       (equal (len (cdr (zo2 bytes sp pc clen result W))) 2)
       (equal (zo2 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo2 bytes sp pc clen result W)) (w3t::$fof (zo2 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-8
  (and (equal (consp (zo3 bytes sp pc clen result W)) t)
       (equal (car (zo3 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo3 bytes sp pc clen result W)))
       (equal (len (cdr (zo3 bytes sp pc clen result W))) 2)
       (equal (zo3 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo3 bytes sp pc clen result W)) (w3t::$fof (zo3 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-9
  (and (equal (consp (zo4 bytes sp pc clen result W)) t)
       (equal (car (zo4 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo4 bytes sp pc clen result W)))
       (equal (len (cdr (zo4 bytes sp pc clen result W))) 2)
       (equal (zo4 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo4 bytes sp pc clen result W)) (w3t::$fof (zo4 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-10
  (and (equal (consp (zo5 bytes sp pc clen result W)) t)
       (equal (car (zo5 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo5 bytes sp pc clen result W)))
       (equal (len (cdr (zo5 bytes sp pc clen result W))) 2)
       (equal (zo5 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo5 bytes sp pc clen result W)) (w3t::$fof (zo5 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm zinfo-11
  (and (equal (consp (zo6 bytes sp pc clen result W)) t)
       (equal (car (zo6 bytes sp pc clen result W)) :|%;%|)
       (true-listp (cdr (zo6 bytes sp pc clen result W)))
       (equal (len (cdr (zo6 bytes sp pc clen result W))) 2)
       (equal (zo6 bytes sp pc clen result W) (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd))))
(defthm outer-lbl-dconst-tail-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) lbl-dconst-tail-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-read1-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))) (b2 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest)))) lbl-dconst-cal-read1-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-tail-eqz-1-step (implies (equal (dltu (dsub pc) (dmul clen)) 1) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))) (b2 (cons (list :const (list :i32) 0) (cdr (const-rest))))) lbl-dconst-tail-eqz-1-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-tail-ifelse-0-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (list :i32) 0) (cdr (const-rest)))) (b2 (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))) lbl-dconst-tail-ifelse-0-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-block-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (b2 (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))) lbl-dconst-block-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-elabel-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cddr (const-rest))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (b2 (cddr (const-rest)))) lbl-dconst-elabel-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-read-step (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cddr (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cddr (const-rest))) (b2 (cons (list :const (list :i32) pc) (cdddr (const-rest))))) lbl-dconst-read-step zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-sub-lit (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-sub-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-ldis-lit (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-ldis-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-fdis-lit (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-fdis-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-read2-lit (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-read2-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-mul-lit (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-mul-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-ltu-lit (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-ltu-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-load-lit (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (quote (:i32)) pc) (quote ((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-load-lit zinfo-0 zinfo-0))))
(defthm outer-lbl-dconst-cal-lset1-lit (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (list (list :label_%{%}% 1 nil (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (iz6 bytes sp pc clen result)) (z1 (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (b (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) lbl-dconst-cal-lset1-lit zinfo-0 zinfo-1))))
(defthm outer-lbl-dconst-cal-get1-lit (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (zlset1 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zlset1 bytes sp pc clen result W)) (z1 (zlset1 bytes sp pc clen result W)) (b (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-get1-lit zinfo-2 zinfo-2))))
(defthm outer-lbl-dconst-cal-add-lit (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (zlset1 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zlset1 bytes sp pc clen result W)) (z1 (zlset1 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-add-lit zinfo-2 zinfo-2))))
(defthm outer-lbl-dconst-cal-gset-lit (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (zlset1 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (zlset1 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zlset1 bytes sp pc clen result W)) (z1 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (b (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) lbl-dconst-cal-gset-lit zinfo-2 zinfo-3))))
(defthm outer-lbl-dconst-cal-lget-lit (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step (list :|%;%| (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (z1 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (b (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-lget-lit zinfo-3 zinfo-3))))
(defthm outer-lbl-dconst-cal-call0-expand-lit (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zw2 bytes sp pc clen result W)) (z1 (zw2 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))) lbl-dconst-cal-call0-expand-lit zinfo-4 zinfo-4))))
(defthm outer-lbl-dconst-cal-call0-entry-lit (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (zw2 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (zw2 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const (quote (:i32)) W)))) (cons :module (quote (:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))))) (list (list :label_%{%}% 0 nil (quote ((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0)))))) (quote ((:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zw2 bytes sp pc clen result W)) (z1 (zw2 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN))))))) (b2 (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const (quote (:i32)) W)))) (cons :module (quote (:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))))) (list (list :label_%{%}% 0 nil (quote ((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0)))))) (quote ((:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-call0-entry-lit zinfo-4 zinfo-4))))
(defthm outer-lbl-dconst-push-s0-lit (equal (w3t::step (list :|%;%| (zpair0 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zpair0 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo1 bytes sp pc clen result W)) (w3t::$fof (zpair0 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zpair0 bytes sp pc clen result W)) (z1 (zo1 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s0-lit zinfo-5 zinfo-6))))
(defthm outer-lbl-dconst-push-s1-lit (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (zo1 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo2 bytes sp pc clen result W)) (w3t::$fof (zo1 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo1 bytes sp pc clen result W)) (z1 (zo2 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))) lbl-dconst-push-s1-lit zinfo-6 zinfo-7))))
(defthm outer-lbl-dconst-push-s2-lit (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step (list :|%;%| (zo2 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo3 bytes sp pc clen result W)) (w3t::$fof (zo2 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo3 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo2 bytes sp pc clen result W)) (z1 (zo3 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))) lbl-dconst-push-s2-lit zinfo-7 zinfo-8))))
(defthm outer-lbl-dconst-push-s3-lit (equal (w3t::step (list :|%;%| (zo3 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo3 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo4 bytes sp pc clen result W)) (w3t::$fof (zo3 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo3 bytes sp pc clen result W)) (z1 (zo4 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s3-lit zinfo-8 zinfo-9))))
(defthm outer-lbl-dconst-push-s4-lit (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo5 bytes sp pc clen result W)) (w3t::$fof (zo4 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo5 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo4 bytes sp pc clen result W)) (z1 (zo5 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s4-lit zinfo-9 zinfo-10))))
(defthm outer-lbl-dconst-push-s5-lit (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step (list :|%;%| (zo4 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo4 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo4 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) lbl-dconst-push-s5-lit zinfo-9 zinfo-11))))
(defthm outer-lbl-dconst-push-ediss-lit (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo6 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) lbl-dconst-push-ediss-lit zinfo-11 zinfo-11))))
(defthm outer-lbl-dconst-push-efinal-lit (equal (w3t::step (list :|%;%| (zo6 bytes sp pc clen result W) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cdr (const-tail3))))))))) :hints (("Goal" :in-theory (disable w3t::step iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame frozen-store dadd) :use ((:instance dframe-outer-from-label (z0 (zo6 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) (b2 (cdr (const-tail3)))) lbl-dconst-push-efinal-lit zinfo-11 zinfo-11))))



; ---------------------------------------------------------------------------
; THE (CALL 3) ENTRY, at label 1.
;
; The expansion step (lbl-dconst-tail-step) leaves (ref.func_addr 3) and the
; call_ref type in front of the tail; this is the step that turns them into
; the callee's admin, appended to the same tail.  The ten facts are the
; standard chain: the body's pure/read phases, the ctxt lift from
; dconst-tail-entry-ctxt, the return-label search (the body ends in (:RETURN)
; at index 14), and the label-1 lift itself.
;
; The body's pure phase is nil because the call_ref redex is a context rule,
; not a pure one; the return-label search at k = 15 fails on the
; (ref.func_addr 3) head, which is not val-p at the prefix's first position.

(defthm spure-entry3-body (equal (w3t::step_pure (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (x) (w3t::step_pure x))))))
(defthm sread-entry3-body (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (x) (w3t::step_read/split x))))))
(defthm ctxt-entry3-body (equal (w3t::step/r-ctxt-instrs (list :|%;%| (iz6 bytes sp pc clen result) (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use (dconst-tail-entry-ctxt))))
(defthm match-entry3-body (equal (w3t::step_pure/match135 (take 14 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (x) (w3t::step_pure/match135 x)) (:free (x) (take 14 x))))))
(defthm search-entry3-body (equal (w3t::step_pure/search141 15 15 15 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (x) (w3t::step_pure/search141 15 15 15 x))) :use (match-entry3-body))))
(defthm spure-entry3-label (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (x) (w3t::step_pure x))) :use (search-entry3-body))))
(defthm taglo-entry3 (equal (w3t::%tag-lo :RETURN_CALL_REF 1 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) 16) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (a b c d) (w3t::%tag-lo1 a b c d))))))
(defthm rsearch-entry3 (equal (w3t::step_read/split/search60 16 16 15 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) nil) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :expand ((:free (a b c x) (w3t::step_read/split/search60 a b c x))))))
(defthm sread-entry3-label (equal (w3t::step_read/split (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) nil) :hints (("Goal" :in-theory (disable w3t::step_read/split w3t::un-p mvm-word-to-bytes) :use ((:instance read-on-a-lone-label-general (z (iz6 bytes sp pc clen result)) (n 1) (is0 nil) (body (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) rsearch-entry3))))
(defthm lbl-dconst-tail-entry-lit (equal (w3t::step (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) :hints (("Goal" :in-theory (disable w3t::step_pure w3t::step_read/split w3t::step/r-ctxt-instrs dadd dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst milawa-callee-admin milawa-callee-frame) :use ((:instance label-lift-general (z (iz6 bytes sp pc clen result)) (body (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (z2 (iz6 bytes sp pc clen result)) (body2 (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) spure-entry3-body sread-entry3-body ctxt-entry3-body spure-entry3-label sread-entry3-label))))


; ---------------------------------------------------------------------------
; THE RUN COMPOSITION'S LINKS: every chain step as a frame-1 step of the run.
;
; dframe-outer-sep is the frame step with the OUTER frame separate from the
; instruction's frame: the run's enclosing frame (function 6's) is constant,
; while the frame-1 instruction's record is the body's current frame, which
; the callee's writes update.  Each link is that lemma at one chain step: the
; outer config's z is (:%;% ($sof z0) F) with F = ($fof iz6), the frame-1
; instruction's record is ($fof z0), and the label-1 body is the step's own
; b0.  The proof is the dframe-outer-sep instance plus the label fact and its
; two zinfo facts, with every z and body defun disabled so nothing
; normalizes -- the links are cheap (the slow path was enabling the whole
; store record).
;
; A join where one step's result body is spelled differently from the next
; step's input gets a body-bridge fact; the ten bridges are proved with the
; body defuns enabled, once per join.  With the bridges as rewrite rules the
; links chain syntactically: a link's result z is (:%;% ($sof z1) F), which
; is exactly the next link's input z.

(defthm dframe-outer-sep (implies (and (equal z0 (list :|%;%| s fp)) (equal (w3t::step (list :|%;%| (list :|%;%| s fp) (list (list :label_%{%}% 1 nil b)))) (list (list :|%;%| z1 (list (list :label_%{%}% 1 nil b2))))) (< (w3t::%size (list (list :label_%{%}% 1 nil b))) (w3t::%size (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil b)))))) (consp z1) (equal (car z1) :|%;%|) (true-listp (cdr z1)) (equal (len (cdr z1)) 2)) (equal (w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil b)))))) (list (list :|%;%| (list :|%;%| (w3t::$sof z1) f) (list (list :frame_%{%}% 1 (w3t::$fof z1) (list (list :label_%{%}% 1 nil b2)))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen)) :use ((:instance dstep-frame-outer-gen (s s) (f f) (fp fp) (b b) (b2 b2) (zp z1))))))

(defthm link-00 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))) lbl-dconst-tail-step zinfo-0 zinfo-0))))
(defthm link-01 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :ref.func_addr 3) (cons *t3* (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) (b2 (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-tail-entry-lit zinfo-0 zinfo-0))))
(defthm link-02 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))) (b2 (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest)))) lbl-dconst-cal-read1-step zinfo-0 zinfo-0))))
(defthm link-03 (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-sub-lit zinfo-0 zinfo-0))))
(defthm link-04 (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (quote ((:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-read2-lit zinfo-0 zinfo-0))))
(defthm link-05 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) clen) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-mul-lit zinfo-0 zinfo-0))))
(defthm link-06 (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dsub pc)) (cons (list :const (quote (:i32)) (dmul clen)) (quote ((:RELOP (:I32) (:LT (:U)))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-ltu-lit zinfo-0 zinfo-0))))
(defthm link-07 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-ldis-lit zinfo-0 zinfo-0))))
(defthm link-08 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) nil)) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-fdis-lit zinfo-0 zinfo-0))))
(defthm link-09 (implies (equal (dltu (dsub pc) (dmul clen)) 1) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))) (b2 (cons (list :const (list :i32) 0) (cdr (const-rest))))) lbl-dconst-tail-eqz-1-step zinfo-0 zinfo-0))))
(defthm link-10 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (list :i32) 0) (cdr (const-rest)))) (b2 (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))) lbl-dconst-tail-ifelse-0-step zinfo-0 zinfo-0))))
(defthm link-11 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (b2 (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))) lbl-dconst-block-step zinfo-0 zinfo-0))))
(defthm link-12 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cddr (const-rest))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (b2 (cddr (const-rest)))) lbl-dconst-elabel-step zinfo-0 zinfo-0))))
(defthm link-13 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cddr (const-rest)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdddr (const-rest)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cddr (const-rest))) (b2 (cons (list :const (list :i32) pc) (cdddr (const-rest))))) lbl-dconst-read-step zinfo-0 zinfo-0))))
(defthm link-14 (implies (and (w3t::un-p pc 32) (w3t::un-p W 32) (<= (+ pc 4) (len bytes)) (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (iz6 bytes sp pc clen result)) (b (cons (list :const (quote (:i32)) pc) (quote ((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-load-lit zinfo-0 zinfo-0))))
(defthm link-15 (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (iz6 bytes sp pc clen result)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (list (list :label_%{%}% 1 nil (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (iz6 bytes sp pc clen result))) (fp (w3t::$fof (iz6 bytes sp pc clen result))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (iz6 bytes sp pc clen result)) (z1 (w3t::$with_local (iz6 bytes sp pc clen result) 1 (list :const (list :i32) W))) (b (cons (list :const (quote (:i32)) W) (quote ((:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) lbl-dconst-cal-lset1-lit zinfo-0 zinfo-1))))
(defthm link-16 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zlset1 bytes sp pc clen result W))) (fp (w3t::$fof (zlset1 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zlset1 bytes sp pc clen result W)) (z1 (zlset1 bytes sp pc clen result W)) (b (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-get1-lit zinfo-2 zinfo-2))))
(defthm link-17 (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zlset1 bytes sp pc clen result W))) (fp (w3t::$fof (zlset1 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zlset1 bytes sp pc clen result W)) (z1 (zlset1 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-add-lit zinfo-2 zinfo-2))))
(defthm link-18 (implies (and (unsigned-byte-p 32 pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zlset1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zlset1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zlset1 bytes sp pc clen result W))) (fp (w3t::$fof (zlset1 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zlset1 bytes sp pc clen result W)) (z1 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (b (cons (list :const (quote (:i32)) (dadd pc)) (quote ((:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) lbl-dconst-cal-gset-lit zinfo-2 zinfo-3))))
(defthm link-19 (implies (and (equal (w3t::$local (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))) 1) (list (list :const (list :i32) W)))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))))) (fp (w3t::$fof (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc))))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (z1 (w3t::$with_global (zlset1 bytes sp pc clen result W) 1 (list :const (list :i32) (dadd pc)))) (b (quote ((:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (b2 (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-lget-lit zinfo-3 zinfo-3))))
(defthm link-20 (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (zw2 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zw2 bytes sp pc clen result W)) (z1 (zw2 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) W) (quote ((:CALL 0) (:CONST (:I32) 1) (:RETURN))))) (b2 (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))) lbl-dconst-cal-call0-expand-lit zinfo-4 zinfo-4))))
(defthm link-21 (implies (and (unsigned-byte-p 32 W)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN)))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zw2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zw2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const (quote (:i32)) W)))) (cons :module (quote (:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))))) (list (list :label_%{%}% 0 nil (quote ((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0)))))) (quote ((:CONST (:I32) 1) (:RETURN)))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zw2 bytes sp pc clen result W))) (fp (w3t::$fof (zw2 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zw2 bytes sp pc clen result W)) (z1 (zw2 bytes sp pc clen result W)) (b (cons (list :const (quote (:i32)) W) (cons (list :ref.func_addr 0) (cons *t0* (quote ((:CONST (:I32) 1) (:RETURN))))))) (b2 (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const (quote (:i32)) W)))) (cons :module (quote (:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))))) (list (list :label_%{%}% 0 nil (quote ((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0)))))) (quote ((:CONST (:I32) 1) (:RETURN)))))) lbl-dconst-cal-call0-entry-lit zinfo-4 zinfo-4))))
(defthm link-22 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zpair0 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zpair0 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zpair0 bytes sp pc clen result W))) (fp (w3t::$fof (zpair0 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zpair0 bytes sp pc clen result W)) (z1 (zo1 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s0-lit zinfo-5 zinfo-6))))
(defthm link-23 (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo1 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo1 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo1 bytes sp pc clen result W))) (fp (w3t::$fof (zo1 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo1 bytes sp pc clen result W)) (z1 (zo2 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))) lbl-dconst-push-s1-lit zinfo-6 zinfo-7))))
(defthm link-24 (implies (store-hyps (sz2 bytes sp pc clen result W) sp W) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo2 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo2 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo3 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo3 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo2 bytes sp pc clen result W))) (fp (w3t::$fof (zo2 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo2 bytes sp pc clen result W)) (z1 (zo3 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))) lbl-dconst-push-s2-lit zinfo-7 zinfo-8))))
(defthm link-25 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo3 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo3 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo4 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo3 bytes sp pc clen result W))) (fp (w3t::$fof (zo3 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo3 bytes sp pc clen result W)) (z1 (zo4 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s3-lit zinfo-8 zinfo-9))))
(defthm link-26 (implies (unsigned-byte-p 32 sp) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo4 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo5 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo5 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo4 bytes sp pc clen result W))) (fp (w3t::$fof (zo4 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo4 bytes sp pc clen result W)) (z1 (zo5 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3))))) lbl-dconst-push-s4-lit zinfo-9 zinfo-10))))
(defthm link-27 (implies (w3t::val-p (list :const (list :i32) (dadd sp))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo4 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo4 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo4 bytes sp pc clen result W))) (fp (w3t::$fof (zo4 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo4 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))) lbl-dconst-push-s5-lit zinfo-9 zinfo-11))))
(defthm link-28 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo6 bytes sp pc clen result W))) (fp (w3t::$fof (zo6 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo6 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil nil))) (cdr (const-tail3)))) (b2 (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))) lbl-dconst-push-ediss-lit zinfo-11 zinfo-11))))
(defthm link-29 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (cdr (const-tail3))))))))) :hints (("Goal" :in-theory (disable w3t::step (:rewrite dstep-frame-outer-gen) (:rewrite dframe-outer-sep) iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest) :use ((:instance dframe-outer-sep (s (w3t::$sof (zo6 bytes sp pc clen result W))) (fp (w3t::$fof (zo6 bytes sp pc clen result W))) (f (w3t::$fof (iz6 bytes sp pc clen result))) (z0 (zo6 bytes sp pc clen result W)) (z1 (zo6 bytes sp pc clen result W)) (b (cons (list :frame_%{%}% 0 (w3t::$fof (szg bytes sp pc clen result W)) nil) (cdr (const-tail3)))) (b2 (cdr (const-tail3)))) lbl-dconst-push-efinal-lit zinfo-11 zinfo-11))))
(defthm body-bridge-01 (equal (append (milawa-callee-admin 3) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (milawa-func-body 3))))) (const-rest))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-02 (equal (append (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (list (list :label_%{%}% 1 nil (ibody3-after-1 pc))))) (const-rest)) (cons (list :frame_%{%}% 1 (quote (:%REC (:LOCALS) (:MODULE :%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11)))))) (list (list :label_%{%}% 1 nil (cons (list :const (quote (:i32)) pc) (quote ((:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-08 (equal (cons (list :const (quote (:i32)) (dltu (dsub pc) (dmul clen))) (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))) (cons (list :const (list :i32) (dltu (dsub pc) (dmul clen))) (const-rest))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-13 (equal (cons (list :const (list :i32) pc) (cdddr (const-rest))) (cons (list :const (quote (:i32)) pc) (quote ((:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-21 (equal (cons (list :frame_%{%}% 0 (list :%rec (cons :locals (list (list (list :const (quote (:i32)) W)))) (cons :module (quote (:%REC (:TYPES (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% ((:I32)) NIL)))) 0) (:_DEF (:REC ((:SUB ((:FINAL)) NIL (:FUNC%->% NIL ((:I32)))))) 0)) (:TAGS) (:GLOBALS 5 6 7 8 9) (:MEMS 0) (:TABLES) (:FUNCS 0 1 2 3 4 5 6 7 8 9 10 11) (:DATAS) (:ELEMS) (:EXPORTS (:%REC (:NAME 109 101 109 111 114 121) (:ADDR :MEM 0)) (:%REC (:NAME 114 101 115 101 116) (:ADDR :FUNC 5)) (:%REC (:NAME 115 116 101 112) (:ADDR :FUNC 6)) (:%REC (:NAME 115 116 97 116 117 115) (:ADDR :FUNC 7)) (:%REC (:NAME 114 101 115 117 108 116) (:ADDR :FUNC 8)) (:%REC (:NAME 112 99) (:ADDR :FUNC 9)) (:%REC (:NAME 115 112) (:ADDR :FUNC 10)) (:%REC (:NAME 99 111 100 101 95 98 97 115 101) (:ADDR :FUNC 11))))))) (list (list :label_%{%}% 0 nil (quote ((:GLOBAL.GET 0) (:LOCAL.GET 0) (:STORE (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:GLOBAL.GET 0) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 0)))))) (quote ((:CONST (:I32) 1) (:RETURN)))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody0)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-22 (equal (cons (list :frame_%{%}% 0 (w3t::$fof (sz0 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody1 sp)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-23 (equal (cons (list :frame_%{%}% 0 (w3t::$fof (sz1 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody2 sp W)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-24 (equal (cons (list :frame_%{%}% 0 (w3t::$fof (szm bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody3)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-25 (equal (cons (list :frame_%{%}% 0 (w3t::$fof (sz3 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (sbody4 sp)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))
(defthm body-bridge-26 (equal (cons (list :frame_%{%}% 0 (w3t::$fof (sz5 bytes sp pc clen result W)) (list (list :label_%{%}% 0 nil (sbody5 sp)))) (cdr (const-tail3))) (cons (list :frame_%{%}% 0 (sframe0 bytes sp pc clen result W) (list (list :label_%{%}% 0 nil (gset-instrs sp)))) (cdr (const-tail3)))) :hints (("Goal" :in-theory (enable iz6 zlset1 zw2 zpair0 sz0 sz1 sz2 sz3 sz5 szm szg zo1 zo2 zo3 zo4 zo5 zo6 sframe0 sbody0 sbody1 sbody2 sbody3 sbody4 sbody5 gset-instrs const-tail3 milawa-func-body milawa-func-module milawa-callee-frame milawa-callee-admin frozen-store dadd dconst ibody3-after-1 dadmin dbody0 dbody1 dbody2 dbody3 dbody4 const-rest))))



; ---------------------------------------------------------------------------
; THE RETURN END: the label-1 dissolve inside frame 1, the frame's return,
; and the stopped machine
; ---------------------------------------------------------------------------
;
; The 30 links leave the run at the config whose instruction list is the single
; frame-1 instruction (:frame 1 ($fof (zo6 ...)) ((:label 1 nil B))), B the
; CONST tail's answer instructions ((:const (:i32) 1) (:return)).  Three pieces
; close the run from there:
;
;   * STEP/R-CTXT-FRAME at that config (PRED31): the label dissolves inside the
;     frame, leaving (:frame 1 ($fof (zo6 ...)) B) at the outer pair's frame.
;     The rule's own measure ((OR (< a b) (AND (EQUAL a b) (< c d)))) is decided
;     by CHECK31-GROUND, the first disjunct in the form the rewriter leaves it:
;     the %SIZE calls expand to ACL2-COUNT, and the counts are 14 and 20 plus
;     the count of the frame record, so the inequality is linear arithmetic.
;     (The same comparison stated with %SIZE, or as a hypothesis, does not fire:
;     %SIZE normalizes to ACL2-COUNT before any rule can match it.)
;
;   * STEP at that config (ENDSTEP31): the dispatcher's five earlier rules are
;     the P-STEP-R-* nil facts, then the frame rule's value is PRED31's.
;
;   * the frame's return (R2-RETURN-1, an instance of the halt book's
;     DRET-FRAME-RETURN-GEN): the frame-1 instruction's body is the value and
;     the :RETURN, so the frame goes and the value (:CONST (:I32) 1) is pushed
;     into the caller's instruction list -- and CONSTSTEP-STUCK: a lone value is
;     not an instruction, so the machine has stopped (the frozen path's last
;     step, at this path's state).
;
; R1-INNER is the inner step the frame rule hands in: the label-1 rule at the
; same pair state, dissolving the label to B.
(defthm r1-inner (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W))) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W))) (quote ((:const (:i32) 1) (:return)))))) :hints (("Goal" :in-theory (disable frozen-store milawa-func-body milawa-func-module milawa-callee-frame iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd))))
(defthm size31 (< (w3t::%size (nth 2 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (zo6 bytes sp pc clen result W))) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return)))))))) (w3t::%size (nth 2 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))) :hints (("Goal" :in-theory (disable w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd))))
(defthm check31-ground
  (equal (< 14 (+ 20 (acl2-count (w3t::$fof (zo6 bytes sp pc clen result W))))) t))
(defthm pred31
  (equal (w3t::step/r-ctxt-frame (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return)))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (quote ((:const (:i32) 1) (:return))))))))
  :hints (("Goal" :in-theory (disable w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd))))

(defthm p-step-r-pure (equal (w3t::step/r-pure (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-pure w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-pure) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))))))
(defthm p-step-r-read (equal (w3t::step/r-read (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-read w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-read) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))))))
(defthm p-step-r-ctxt-instrs (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))))))
(defthm p-step-r-ctxt-label (equal (w3t::step/r-ctxt-label (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-label w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))))))
(defthm p-step-r-ctxt-handler (equal (w3t::step/r-ctxt-handler (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-handler w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-ctxt-handler) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))))))
(defthm endstep31 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (quote ((:const (:i32) 1) (:return))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-pure w3t::step/r-read
                                    w3t::step/r-ctxt-instrs w3t::step/r-ctxt-label
                                    w3t::step/r-ctxt-handler w3t::step/r-ctxt-frame w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (list (list :label_%{%}% 1 nil (quote ((:const (:i32) 1) (:return))))))))))
                 p-step-r-pure p-step-r-read p-step-r-ctxt-instrs
                 p-step-r-ctxt-label p-step-r-ctxt-handler pred31))))
(defthm r2-return-1 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :frame_%{%}% 1 (w3t::$fof (zo6 bytes sp pc clen result W)) (quote ((:const (:i32) 1) (:return)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :const (list :i32) 1)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local
                                    frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg
                                    w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance dret-frame-return-gen (z (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result)))) (fp (w3t::$fof (zo6 bytes sp pc clen result W))) (x 1))))))
(defthm conststep-stuck (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :const (list :i32) 1)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local
                                    frozen-store iz6 zo6 zw2 zlset1 sz0 sz1 sz2 sz3 sz5 szm szg
                                    w3t::$binop_ (:executable-counterpart w3t::$binop_) dadd)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (zo6 bytes sp pc clen result W)) (w3t::$fof (iz6 bytes sp pc clen result))) (list (list :const (list :i32) 1)))))))))

