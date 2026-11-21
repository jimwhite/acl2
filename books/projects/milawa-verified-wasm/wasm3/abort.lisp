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

; The halt book's store-pair projection lemmas (with-global-pair2 and
; fof-of-with-global) are rewrite rules whose terms occur in this book's
; statements; keep them out of the theory here so the facts read the way they
; are written.
(in-theory (disable fof-of-with-global with-global-pair2))

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

;; ---------------------------------------------------------------------------
;; The frame lift's inner step: the pair bridge
;; ---------------------------------------------------------------------------

; The frame rule builds the inner pair as (%;% ($sof ...) ($fof ...)) with the
; accessors spelled out, while the facts are stated at (dcallee-pair ...).  The
; bridge rewrites the spelled pair to the helper -- and with dcallee-pair AND
; the accessors DISABLED the bridge fires before the pair's arguments unfold,
; after which the label fact (dlabel-abort-entry) matches the whole step and
; the label step at the spelled pair is 218 steps (without the disable the
; step's dispatcher unfolds first and stalls on r-ctxt-instrs).

(defthm pair-spelled-is-dcallee
  (equal (list :|%;%|
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
         (dcallee-pair bytes sp pc clen result w))
  :hints (("Goal" :in-theory (enable dcallee-pair))))

(defthm dlabel-abort-entry-inzp
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) *abort-label-cfg*))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) *abort-label-cfg2*)))
  :hints (("Goal" :in-theory (disable dcallee-pair w3t::$sof w3t::$fof w3t::$with_global frozen-store w3t::$with_local iz6 dadd w3t::$binop_))))

;; ---------------------------------------------------------------------------
;; The frame lift, closed
;; ---------------------------------------------------------------------------

; The abstract frame lift: the frame rule's wrapper (dstep-frame-abort-param)
; instantiated at s = ($sof the updated store), f = *frozen-entry-frame*,
; fp = ($fof the updated store), with the inner label step discharged by the
; pair bridge + dlabel-abort-entry.  This is the step that takes the abort's
; call from the split's frame config to the entry's (the callee's frame inside
; the caller's label), and it was the open step.  689k prover steps.

(defthm dframe-abort-entry-abstract (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *abort-label-cfg*)))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *abort-label-cfg2*))))) :hints (("Goal" :in-theory (disable dcallee-pair w3t::$sof w3t::$fof w3t::$with_global frozen-store w3t::$with_local iz6 dadd w3t::$binop_) :use ((:instance dstep-frame-abort-param (s (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (f *frozen-entry-frame*) (fp (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))) (:instance dlabel-abort-entry-inzp)))))

;; ---------------------------------------------------------------------------
;; The callee's body: the status write, and the descent into function 4
;; ---------------------------------------------------------------------------

; Function 4's body is ((const 2) (global.set 3) (const 2)): the value 2, the
; status write (wasm global 3, store global 8), then the implicit result.  The
; body step is the local.set recipe: the lone global.set 3 fails
; (fail-lone-global-set-3), the context search refuses the two-instruction
; slice (ctxt-global-set3-slice-fails), and the slice is $WITH_GLOBAL
; (dglobal-set3-slice).  The body's context/step/label lifts are generic in
; the pair; the frame rule's wrapper for these bodies is parameterized with
; the inner step at the same variable pair, and the application at the callee
; pair (s = the store, f = the caller's frame 6, fp = function 4's frame) is
; 6,877 steps.  This is the abort's descent into the callee; the step back OUT
; (the caller's label lift over the callee frame, then the implicit returns)
; is next and needs the accessors-off spelling treatment.

(defthm fail-lone-global-set-3
  (equal (w3t::step (list :|%;%| z (list '(:global.set 3)))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list '(:global.set 3)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list '(:global.set 3)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list '(:global.set 3)))))))))

(defthm ctxt-global-set3-slice-fails
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z
                (list (list :const (list :i32) 2) '(:global.set 3))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z
                                            (list (list :const (list :i32) 2) '(:global.set 3)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) 2) '(:global.set 3))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) 2) '(:global.set 3)))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (list (list :const (list :i32) 2) '(:global.set 3)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) 2) '(:global.set 3)))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z
                                            (list (list :const (list :i32) 2) '(:global.set 3)))))
                 (:instance fail-lone-global-set-3 (z z))))))

(defthm dglobal-set3-slice
  (equal (w3t::step (list :|%;%| z
                          (list (list :const (list :i32) 2)
                                '(:global.set 3))))
         (list (list :|%;%| (w3t::$with_global z 3 (list :const (list :i32) 2))
                     nil))))

(defconst *abort-body*
  (list (list :const (list :i32) 2)
        '(:global.set 3)
        (list :const (list :i32) 2)))

(defconst *abort-body-after*
  (list (list :const (list :i32) 2)))

(defthm dctxt-abort-body
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z *abort-body*))
         (list (list :|%;%| (w3t::$with_global z 3 (list :const (list :i32) 2))
                     *abort-body-after*)))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z *abort-body*)))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s *abort-body*))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 *abort-body*) (w3t::%t9 1)
                                   (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z *abort-body*)))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 *abort-body*) (w3t::%t9 1)
                                   (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z *abort-body*)))
                        dglobal-set3-slice
                        (:instance fail-lone-global-set-3 (z z))))))

(defthm dstep-abort-body
  (equal (w3t::step (list :|%;%| z *abort-body*))
         (list (list :|%;%| (w3t::$with_global z 3 (list :const (list :i32) 2))
                     *abort-body-after*)))
  :hints (("Goal" :in-theory (disable)
                  :use (dctxt-abort-body)
                  :expand ((w3t::step (list :|%;%| z *abort-body*))))))

(defthm dlabel-abort-body-gen
  (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil *abort-body*))))
         (list (list :|%;%| (w3t::$with_global z 3 (list :const (list :i32) 2))
                     (list (list :label_%{%}% 1 nil *abort-body-after*)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-label)
                                   (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil *abort-body*)))))
                        dctxt-abort-body))))

(defthm dstep-frame-abort-body-param (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s fp) (list (list :label_%{%}% 1 nil *abort-body*)))) (list (list :|%;%| (w3t::$with_global (list :|%;%| s fp) 3 (list :const (list :i32) 2)) (list (list :label_%{%}% 1 nil *abort-body-after*))))) (< (w3t::%size (list (list :label_%{%}% 1 nil *abort-body*))) (w3t::%size (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*))))))) (equal (w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*)))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| s fp) 3 (list :const (list :i32) 2))) f) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| s fp) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*)))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :expand ((w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*))))))) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*))))))) (:instance dlabel-abort-body-gen (z (list :|%;%| s fp)))))))

(defthm dframe-abort-callee (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*)))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*))))))) :hints (("Goal" :use ((:instance dstep-frame-abort-body-param (s (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (f (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (fp (milawa-callee-frame 4))) (:instance dlabel-abort-body-gen (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4))))))))

;; The same descent stated at the HELPLE pair, so the way-out composition does
;; not need the forward bridge.

(defthm dframe-abort-callee-helper (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*)))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*))))))) :hints (("Goal" :use ((:instance dstep-frame-abort-body-param (s (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (f (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (fp (milawa-callee-frame 4))) (:instance dlabel-abort-body-gen (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4))))))))

;; ---------------------------------------------------------------------------
;; The way out, step 1: the caller's label over the callee frame
;; ---------------------------------------------------------------------------

; With the pair held opaque, the dispatcher's guards need the pair's shape and
; components as facts (dcallee-pair-shape): the accessors are opaque only
; because the pair bridge needs them to be, so nothing computes the shape on
; its own.  The helper-stated label lift then goes by the label rule, with the
; helper descent as the inner step: 28.6M prover steps (the guards and the
; label rule's measure over the full store dominate).

(defthm dlabel-abort-callee-helper (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dcallee-pair milawa-callee-frame))))

;; ---------------------------------------------------------------------------
;; The spelled-pair label lift, and the store's shape
;; ---------------------------------------------------------------------------

; The same label lift stated at the SPELLED pair, so the frame rule's inner
; step (which builds (%;% ($sof ...) ($fof ...))) matches it directly with no
; bridge.  Two things make it go in 36k: the store's shape is a fact
; (with-global-shape: $with_global is a cons whose car is :%;% and whose cdr
; is a two-element true list), and the outer step is unfolded by handing in the
; STEP DEFINITION INSTANCE as a :use -- the :expand of the step does not fire
; once the config's arguments have been rewritten.

(defthm dlabel-abort-callee (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dcallee-pair pair-spelled-is-dcallee w3t::$sof w3t::$fof w3t::$store w3t::$frame w3t::$with_global frozen-store w3t::$with_local iz6 dadd w3t::$binop_ milawa-callee-frame) :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*))))))))) :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*))))))))) (:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*))))))))) dframe-abort-callee))))

;; The outer frame rule's wrapper, for the caller's frame/label containing the
;; callee's frame.  The inner step is a hypothesis at the same variable pair;
;; the inner result's z-prime needs its pair shape (consp, car :%;%, true-listp
;; cdr, len 2) or the frame rule's payload checks case-split on it.

(defthm dstep-frame-abort-outer-param (implies (and (equal (w3t::step (list :|%;%| (list :|%;%| s fp) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*)))))))) (list (list :|%;%| zp (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof zp) (list (list :label_%{%}% 1 nil *abort-body-after*))))))))) (< (w3t::%size (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*))))))) (w3t::%size (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*)))))))))) (consp zp) (equal (car zp) :|%;%|) (true-listp (cdr zp)) (equal (len (cdr zp)) 2)) (equal (w3t::step (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof zp) f) (list (list :frame_%{%}% 1 (w3t::$fof zp) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof zp) (list (list :label_%{%}% 1 nil *abort-body-after*)))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step) (w3t::%a0 (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*))))))))))) (:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| s f) (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fp (list (list :label_%{%}% 1 nil *abort-body*)))))))))))))))

;; ---------------------------------------------------------------------------
;; The implicit returns: the pure value-steps
;; ---------------------------------------------------------------------------

; Function 4's body ends with a value, so its return is implicit: the label
; whose body is all values is removed by Step_pure/label-vals, and the frame
; whose body is all values by Step_pure/frame-vals.  The wrapper step
; (a callee frame around a label of one value) is the two composed.  All three
; are immediate: 125, 912 and 19,570 steps.

(defthm dstep-label-vals
  (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2))))))
         (list (list :|%;%| z (list (list :const (list :i32) 2))))))

(defthm dstep-frame-label-vals
  (equal (w3t::step (list :|%;%| (list :|%;%| s fp)
                          (list (list :frame_%{%}% 1 fp
                                      (list (list :label_%{%}% 1 nil
                                                  (list (list :const (list :i32) 2))))))))
         (list (list :|%;%| (list :|%;%| s fp)
                     (list (list :frame_%{%}% 1 fp
                                 (list (list :const (list :i32) 2))))))))

(defthm dstep-frame-vals
  (equal (w3t::step (list :|%;%| z (list (list :frame_%{%}% 1 fp
                                                (list (list :const (list :i32) 2))))))
         (list (list :|%;%| z (list (list :const (list :i32) 2))))))

;; The outer frame lift, closed: the caller's frame 6 over the label over the
;; callee's frame.  Instantiate the outer wrapper at s = the updated store,
;; f = the entry frame, fp = the caller's frame 6, zp = the label result's
;; pair; the inner step is the spelled-pair label lift.  8.9M steps.

(defthm dframe-abort-callee-outer (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (milawa-callee-frame 4) (list (list :label_%{%}% 1 nil *abort-body*)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil *abort-body-after*))))))))))) :hints (("Goal" :use ((:instance dstep-frame-abort-outer-param (s (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (f *frozen-entry-frame*) (fp (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (zp (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))))) (:instance dlabel-abort-callee)))))

;; ---------------------------------------------------------------------------
;; The implicit return, step by step
;; ---------------------------------------------------------------------------
;
; Function 4's body ends with the value 2, and function 6's dispatch calls it
; at the end of its own body.  The value comes back out through four pure
; steps, each wrapped in every enclosing context: the callee's label, the
; callee's frame, function 6's label, function 6's frame.
;
; The four facts below are the whole return path, stated ONCE with the state's
; frame (FE), the outer frame's locals (FA) and the inner frame's locals (FB)
; as independent variables -- the frame rule runs the inner frame's body with
; the INNER frame's locals, so the two must not be confused.  They are what
; the halt branch's return will need too.
;
; The nesting each fact's left-hand side has is
;
;   (%;% (%;% S FE) ((frame 1 FA ((label 1 nil ((frame 1 FB ((label 1 nil ((const 2)))))))))))
;
; and the four steps peel it in order: the innermost label (label-vals), the
; inner frame (frame-vals), function 6's label (label-vals), its frame
; (frame-vals).  Costs: 10.4M, 1.07M, 19.6k, 43.
;
; The first is the only expensive one: its innermost step is a label-vals
; three context rules down (frame, label, frame), and the dispatcher has to
; be shown that each rule applies at the config it builds.  The others peel
; one level at a time and the dispatcher finds them by itself.

(defthm dret-label-vals-in-frame (equal (w3t::step (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fb (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2)))))))))))) (list (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fb (list (list :const (list :i32) 2))))))))))))

(defthm dret-frame-vals-in-label (equal (w3t::step (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 fb (list (list :const (list :i32) 2)))))))))) (list (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2))))))))))

(defthm dret-label-vals-in-top (equal (w3t::step (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2)))))))) (list (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :const (list :i32) 2))))))))

(defthm dret-frame-vals-in-top (equal (w3t::step (list :|%;%| (list :|%;%| s fe) (list (list :frame_%{%}% 1 fa (list (list :const (list :i32) 2)))))) (list (list :|%;%| (list :|%;%| s fe) (list (list :const (list :i32) 2))))))


; And the same four at the abort's own store, which is what the outer lift's
; result is: s = ($sof W4), fe = the entry frame, fa = ($fof G1), fb = ($fof W4).
; They are direct instantiations, so the rewriter should use the generic
; facts as rewrite rules; the hints only keep the store accessors and the
; step definition out of the way.

(defthm dret-abort-1 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2)))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :const (list :i32) 2))))))))))))

(defthm dret-abort-2 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) (list (list :const (list :i32) 2)))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2))))))))))

(defthm dret-abort-3 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (list (list :const (list :i32) 2)))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :const (list :i32) 2))))))))

(defthm dret-abort-4 (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :const (list :i32) 2)))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (milawa-callee-frame 4)) 3 (list :const (list :i32) 2))) *frozen-entry-frame*) (list (list :const (list :i32) 2))))))
