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
                (cons (list :global.get 1) (cddr (const-rest)))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (cons (list :const (list :i32) pc) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cons (list :global.get 1) (cddr (const-rest))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :global.get 1) (cddr (const-rest)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :global.get 1) (cddr (const-rest))))
                            (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cons (list :global.get 1) (cddr (const-rest))))))
                 dconst-read-slice))))

(defthm dconst-read-step
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (cons (list :global.get 1) (cddr (const-rest)))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (cons (list :const (list :i32) pc) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (cons (list :global.get 1) (cddr (const-rest))))))
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

