; L1, the CONST path: the front and the tail, joined.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The front (const.lisp) ends at a configuration whose store is the front's
; two writes and whose instruction list is function 6's frame around label 1
; around label 0 around the CONST branch's 13-instruction tail.  The tail
; books (const-tail.lisp onward) start at the same configuration, but spell
; it through the abbreviations GSET, IZ6 and the data-spelling label body.
;
; The first fact here is that the two spellings are the same state:
; CONST-FRONT-ENDPOINT-IS-TAIL-ENTRY.  The front's endpoint is written with
; the constructors unfolded (the form FRONT-ADVANCE-19 and
; FRONT2-ADVANCE-15 produce), and the tail's entry through GSET with the
; literal 13-instruction body; enabling GSET and the two abbreviations, and
; the ground fact that (CADDR (NTH 12 *FT2*)) is that literal body, closes
; it.
;
; Then CONST-FRONT-35 composes the front's 34 steps (19 + 15) with the tail's
; first run-level step, TAIL-FRAME1 (the lone (:CALL 3) split), into one
; 35-step advance, and CONST-FRONT-36 adds the call entry
; (TAIL-ENTRY-ZL-FRAME).  These are the first links of the CONST path's
; run-level composition; the tail's remaining steps are the same shape, each
; one consuming the state the previous one leaves.
;
; Measured: 8 events, 3,384,013 prover steps, 8.7 s (the two compositions are
; 1.65M and 2.73M, the bridges 75k and 1.08M); the rewrite hints keep every
; state spelling function disabled, exactly as the front's own advances do.

(in-package "MILAWA-WASM")

(include-book "const-tail")

;; ---------------------------------------------------------------------------
;; The two spellings of the join state
;; ---------------------------------------------------------------------------

; The front's endpoint inside label 0: (CADDR (NTH 12 *FT2*)) is the CONst
; branch's tail, but the tail books write it as a quoted literal.
(defthm const-front-nth12
  (equal (caddr (nth 12 *ft2*))
         (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))

; The front's store, with $WITH_GLOBAL/$WITH_LOCAL unfolded.  This is GSET's
; body; the point of naming it is that the front's endpoint and the tail's
; entry can be compared without unfolding GSET inside the composition.
(defun const-front-store (bytes sp pc clen result w)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::$with_global
   (list :|%;%| (frozen-store bytes sp pc clen 1 result)
         (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                        (list :const (list :i32) w))))
   1 (list :const (list :i32) (dadd pc))))

(defun const-front-body (bytes sp pc clen result w)
  (declare (xargs :guard t :verify-guards nil))
  (list
   (list :frame_%{%}% 1
         (w3t::$fof (const-front-store bytes sp pc clen result w))
         (list
          (list :label_%{%}% 1 nil
                (cons (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*)))
                      (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defun const-front-endpoint (bytes sp pc clen result w)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%|
        (list :|%;%| (w3t::$sof (const-front-store bytes sp pc clen result w))
              *frozen-entry-frame*)
        (const-front-body bytes sp pc clen result w)))

; The tail's entry: the same state through GSET and the literal body.
(defun const-tail-entry (bytes sp pc clen result w)
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
                                  (quote ((:CALL 3) (:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
                            (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

; THE JOIN: the front's endpoint and the tail's entry are the same state.
(defthm const-front-endpoint-is-tail-entry
  (equal (const-front-endpoint bytes sp pc clen result w)
         (const-tail-entry bytes sp pc clen result w))
  :hints (("Goal" :in-theory (enable const-front-endpoint const-tail-entry
                                     const-front-store const-front-body
                                     gset))))

;; ---------------------------------------------------------------------------
;; The first tail step, and the 35-step advance
;; ---------------------------------------------------------------------------

; TAIL-FRAME1's result, named so the composition can refer to it.
(defun const-tail-after-split (bytes sp pc clen result w)
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
                                  (cons (list :ref.func_addr 3)
                                        (cons *t3*
                                              (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))))
                            (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

; TAIL-FRAME1 at the front's spelling.
(defthm const-tail-after-split-step
  (equal (w3t::step (const-front-endpoint bytes sp pc clen result w))
         (list (const-tail-after-split bytes sp pc clen result w)))
  :hints (("Goal" :in-theory (enable const-front-endpoint const-tail-entry
                                     const-tail-after-split
                                     const-front-store const-front-body gset)
                  :use (tail-frame1))))

; The front's 19 + 15 steps and the tail's first step, in one advance:
; 35 spec steps from the entry configuration to TAIL-AFTER-SPLIT, with the
; fuel remainder R.
(defthm const-front-35
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 35 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r (const-tail-after-split bytes sp pc clen result w))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel
                               mvm-abs-abstract mvm-abs-z-abstract
                               frozen-body-cfg frozen-cfg frozen-z frozen-store frozen-frame-cfg
                               frozen-third-body dvl-after-testop dvl-after-ifelse
                               dcfg dfull dfl dvl dadmin dframe3
                               dbody0 dbody1 dbody2 dbody3 dbody4 dconst
                               rbody-block rbody-label rbody-call rbody-split rbody-callee
                               ibody ibody3-after-1 iz6 icfg
                               milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                               dsub dmul dltu deqz
                               w3t::$sof w3t::$fof w3t::$with_global w3t::$frame w3t::$with_local
                               w3t::$with_mem dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance front-advance-19 (r (+ 16 r)))
                 (:instance front2-advance-15 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-front-endpoint bytes sp pc clen result w))
                            (c+ (const-tail-after-split bytes sp pc clen result w)))
                 const-tail-after-split-step))))

;; ---------------------------------------------------------------------------
;; The second tail step: the call entry, and 36 steps
;; ---------------------------------------------------------------------------

; TAIL-ENTRY-ZL-FRAME's output, with the callee administration written out
; as the frame-and-label cons the next fact (TAIL-CL-READ1-FRAME) expects.
(defthm milawa-func-body-3-literal
  (equal (milawa-func-body 3)
         (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))

(defthm callee-admin-3-cons
  (equal (append (milawa-callee-admin 3)
                 (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN))))
         (cons (list :frame_%{%}% 1 (milawa-callee-frame 3)
                     (list (list :label_%{%}% 1 nil
                                 (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))
               (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
  :hints (("Goal" :in-theory (enable milawa-callee-admin milawa-func-body))))

(defun const-tail-after-entry (bytes sp pc clen result w)
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
                                              (list (list :label_%{%}% 1 nil
                                                          (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U))))))))
                                        (quote ((:TESTOP (:I32) (:EQZ)) (:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL) (:GLOBAL.GET 1) (:LOAD (:I32) NIL 0 (:%REC (:ALIGN . 2) (:OFFSET . 0))) (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD)) (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)))))
                            (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

(defthm const-tail-entry-step
  (equal (w3t::step (const-tail-after-split bytes sp pc clen result w))
         (list (const-tail-after-entry bytes sp pc clen result w)))
  :hints (("Goal" :in-theory (enable const-tail-after-split const-tail-after-entry
                                     milawa-callee-admin milawa-func-body)
                  :use (tail-entry-zl-frame))))

(defthm const-front-36
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 36 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r (const-tail-after-entry bytes sp pc clen result w))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-35 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-after-split bytes sp pc clen result w))
                            (c+ (const-tail-after-entry bytes sp pc clen result w)))
                 const-tail-entry-step))))
