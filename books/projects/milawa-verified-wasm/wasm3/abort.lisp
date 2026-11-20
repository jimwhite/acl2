; L1, the running branch: the unknown-opcode abort.
;
; Copyright (C) 2026 Kookamara LLC
;
; See the LICENSE file distributed with ACL2.

; The dispatch's last instruction is (:CALL 4), the unknown-opcode abort; it is
; what the JMP test's false branch falls through to.  Function 4 is
;
;   ((:CONST (:I32) 2) (:GLOBAL.SET 3) (:CONST (:I32) 2))
;
; i.e. status := 2 and the function's result is 2 -- an IMPLICIT return (the
; body ends with a value, there is no :RETURN).  This book takes the path from
; the call to the callee's frame:
;
;   * the call split ((:CALL 4) -> (:REF.FUNC_ADDR 4) + the call_ref type, the
;     same *t3* signature), proved at the callee pair;
;   * the call entry into function 4's frame/body, via the no-ctxt template;
;   * each of those lifted through the caller's admin label 1 and frame 6.
;
; Next come the frame descent, the status write (:GLOBAL.SET 3), and the
; implicit returns (Step_pure/label-vals and frame-vals) that carry the value 2
; back out to the host.

(in-package "MILAWA-WASM")

(include-book "halt")

(defthm dcall4-split
  (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                          (list (list :call 4))))
         (list (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                     (list (list :ref.func_addr 4) *t3*))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm no-ctxt-instrs-on-call-4
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%|
                (list :|%;%|
                      (w3t::$sof
                       (w3t::$with_global
                        (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                              (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w))))
                        1 (list :const (list :i32) (dadd pc))))
                      (w3t::$fof
                       (w3t::$with_global
                        (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                              (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w))))
                        1 (list :const (list :i32) (dadd pc)))))
                (list (list :ref.func_addr 4) *t3*)))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%|
                           (list :|%;%|
                                 (w3t::$sof
                                  (w3t::$with_global
                                   (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                                         (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                        (list :const (list :i32) w))))
                                   1 (list :const (list :i32) (dadd pc))))
                                 (w3t::$fof
                                  (w3t::$with_global
                                   (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                                         (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                        (list :const (list :i32) w))))
                                   1 (list :const (list :i32) (dadd pc)))))
                           (list (list :ref.func_addr 4) *t3*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))


(defun dcallee-pair (bytes sp pc clen result w)
  (list :|%;%|
        (w3t::$sof
         (w3t::$with_global
          (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                               (list :const (list :i32) w))))
          1 (list :const (list :i32) (dadd pc))))
        (w3t::$fof
         (w3t::$with_global
          (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                               (list :const (list :i32) w))))
          1 (list :const (list :i32) (dadd pc))))))


(defthm dcall4-entry
  (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                          (list (list :ref.func_addr 4) *t3*)))
         (list (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                     (milawa-callee-admin 4))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
                  :use ((:instance no-ctxt-instrs-on-call-4))
                  :expand ((w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                                            (list (list :ref.func_addr 4) *t3*)))))))

(defthm dlabel-abort-split (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :call 4)))))) (list (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :ref.func_addr 4) *t3*)))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dcallee-pair dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :call 4))))))) dcall4-split))))

(defthm dframe-abort-split (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :call 4)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :ref.func_addr 4) *t3*)))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dcallee-pair dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :call 4))))))))) dlabel-abort-split))))

;; ---------------------------------------------------------------------------
;; The entry's lift through the admin label (the frame lift is open)
;; ---------------------------------------------------------------------------

; The call entry's payload is function 4's frame/label/body.  Lifting it through
; the caller's admin label 1 is the same label rule as the split's; the lift
; through frame 6 is where the nesting bites: the frame rule's body steps the
; label config, whose inner step (the lone call) should be the entry, but the
; label rule's inner z is spelled out ($sof/$fof of the $with_global term), so
; the fact at (dcallee-pair ...) does not match and the dispatcher stalls on
; step/r-ctxt-instrs.  The next attempt should state the label fact at the
; spelled-out pair and hand it to the frame rule with the accessors disabled;
; the first two attempts at that (with the accessors enabled) still stall, so
; this is the open step.

(defthm dlabel-abort-entry (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :ref.func_addr 4) *t3*))))) (list (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (milawa-callee-admin 4)))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dcallee-pair dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :ref.func_addr 4) *t3*)))))) dcall4-entry))))

;; ---------------------------------------------------------------------------
;; The abort frame's pure and context behavior, isolated
;; ---------------------------------------------------------------------------

; The frame lift that remains open is decided by the STEP dispatcher's first
; three branches on the outer frame config and on the inner label config.  With
; the abort label's instruction list written as a constant, all four facts are
; immediate: the pure dispatcher returns nil on the lone label and on the lone
; frame (the label's body is an instruction list, not values), and the context
; search refuses both lone-list splices.  With these as rewrite rules the
; dispatcher reaches the frame rule; what still does not close is the frame
; rule's own body, whose inner-step case is described in AGENTS.md.

(defconst *abort-label-cfg*
  (list (list :label_%{%}% 1 nil (list (list :ref.func_addr 4) *t3*))))

(defthm rctxt-abort-label-nil
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| (list :|%;%| s fp) *abort-label-cfg*))
         nil))

(defthm step-pure-abort-label-nil
  (equal (w3t::step_pure *abort-label-cfg*) nil))

(defthm step-pure-abort-frame-nil
  (equal (w3t::step_pure (list (list :frame_%{%}% 1 fp *abort-label-cfg*)))
         nil))

(defthm rctxt-abort-frame-nil
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :frame_%{%}% 1 fp *abort-label-cfg*))))
         nil))

;; ---------------------------------------------------------------------------
;; The frame-rule wrapper, parameterized
;; ---------------------------------------------------------------------------

; The frame rule's wrapper is provable once, with the inner label step handed in
; as a hypothesis at the SAME variable pair (%;% s fp) the frame rule builds.
; The size guard is given as a hypothesis too; with the instruction lists
; concrete (the abort label) it is arithmetic.  This is the wrapper the open
; frame lift needs: instantiate s/fp with the callee pair's store and frame and
; discharge the inner-step hypothesis with the label step at that pair (the
; remaining piece -- dlabel-abort-entry-inzp -- is where the nesting bites).

(defconst *abort-label-cfg2*
  (list (list :label_%{%}% 1 nil (milawa-callee-admin 4))))

(defthm dstep-frame-abort-param
  (implies (and (equal (w3t::step
                        (list :|%;%| (list :|%;%| s fp)
                              *abort-label-cfg*))
                       (list (list :|%;%| (list :|%;%| s fp)
                                   *abort-label-cfg2*)))
                (< (w3t::%size *abort-label-cfg*)
                   (w3t::%size (list (list :frame_%{%}% 1 fp *abort-label-cfg*)))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (list (list :frame_%{%}% 1 fp *abort-label-cfg*))))
                  (list (list :|%;%| (list :|%;%| s f)
                              (list (list :frame_%{%}% 1 fp *abort-label-cfg2*))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :expand ((w3t::step
                            (list :|%;%| (list :|%;%| s f)
                                  (list (list :frame_%{%}% 1 fp *abort-label-cfg*)))))
                  :use ((:instance (:definition w3t::step/r-ctxt-frame)
                                   (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                                   (list (list :frame_%{%}% 1 fp *abort-label-cfg*)))))))))
