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


