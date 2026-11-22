; L1, the CONST path's callee, read1: the context rung through the engine.
;
; `tail-iframe3` (const-tail) is the isolated frame step at the run's Z:
;
;   step (:%;% Z ((:frame 1 callee ((:label 1 nil (milawa-func-body 3))))))
;   = (:%;% Z ((:frame 1 callee ((:label 1 nil (ibody3-after-1 (dadd pc)))))))
;
; The engine's flat/context lemma, `engine-ctxt-from-instr-step`, turns the
; isolated step into the context search over the same frame with the tail
; after it.  This is the rung `tail-cl-read1-ctxt-d` and
; `tail-cl-read1-label0-rest` are about; it replaces the hand-rolled
; `:definition step/r-ctxt-instrs` + prefix7/search21 proof.
;
; The `step` definition is disabled in the hint: it is an eager rewrite rule
; that unfolds the frame rule (and the store literal) before TAIL-IFRAME3 can
; match the isolated-step hypothesis.
;
; The engine books are MIT-licensed; see wasm-acl2/LICENSE.

(in-package "MILAWA-WASM")

(include-book "const-callee")
(include-book "engine-flat")

(defconst *r1-tail*
  '((:TESTOP (:I32) (:EQZ))
    (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL)
    (:GLOBAL.GET 1)
    (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0)))
    (:LOCAL.SET 1)
    (:GLOBAL.GET 1)
    (:CONST (:I32) 4)
    (:BINOP (:I32) (:ADD))
    (:GLOBAL.SET 1)
    (:LOCAL.GET 1)
    (:CALL 0)
    (:CONST (:I32) 1)
    (:RETURN)))

(defun clr1-outer-z (bytes sp pc clen result w)
  (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w))
        (w3t::$fof (gset bytes sp pc clen result w))))

(defun clr1-frame-term (b)
  (list :frame_%{%}% 1 (milawa-callee-frame 3)
        (list (list :label_%{%}% 1 nil b))))

(defun clr1-label0-term (b)
  (list :label_%{%}% 0 nil (cons (clr1-frame-term b) *r1-tail*)))

(defthm clr1-ctxt-engine
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (clr1-outer-z bytes sp pc clen result w)
                         (cons (clr1-frame-term (milawa-func-body 3)) *r1-tail*)))
                  (list (list :|%;%| (clr1-outer-z bytes sp pc clen result w)
                              (cons (clr1-frame-term (ibody3-after-1 (dadd pc)))
                                    *r1-tail*)))))
  :hints (("Goal"
           :in-theory (disable (:definition w3t::step)
                               w3t::step/r-ctxt-instrs
                               dadd
                               w3t::$binop_ (:executable-counterpart w3t::$binop_)
                               milawa-func-body (:executable-counterpart milawa-func-body)
                               ;; TAIL-IFRAME3 is stated with (sof (gset ...));
                               ;; the bridge would rewrite it out of reach.
                               sof-gset-is-frozen-store
                               gset frozen-store mvm-abs-z-abstract
                               milawa-callee-frame
                               (:executable-counterpart milawa-callee-frame)
                               w3t::$sof w3t::$fof)
           :use ((:instance engine-ctxt-from-instr-step
                            (i (clr1-frame-term (milawa-func-body 3)))
                            (r *r1-tail*)
                            (z (clr1-outer-z bytes sp pc clen result w))
                            (inner (list (list :|%;%|
                                               (clr1-outer-z bytes sp pc clen result w)
                                               (list (clr1-frame-term
                                                      (ibody3-after-1 (dadd pc))))))))))))

