; L1, the running branch: the shared head of the fourteen running paths.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The frozen path (frozen.lisp) takes the status test one way.  When the status
; IS 1 -- a running machine -- the same three test steps take the OTHER way,
; and the module then calls $in_code (function 3) before it can dispatch.  Every
; one of the fourteen running paths starts this way, so this book proves the
; shared head: seven steps from the post-call configuration to function 3's
; frame, with function 3's body at the head of its label and the rest of
; function 6's body after it.  What each path adds from here is the dispatch --
; $in_code's body and return (the same for all of them), the opcode test, and
; the per-opcode tail.
;
; THE SHAPES, from `make walk --value 1` (they are not the frozen path's):
;
;   step 3  (:IFELSE ...) with value 0  ->  (:BLOCK (:_RESULT NIL) NIL)
;   step 4  the empty block            ->  (:LABEL_ 0 NIL NIL)
;   step 5  the empty label            ->  disappears (its body is all values)
;   step 6  (:CALL 3)                  ->  (:REF.FUNC_ADDR 3) (:CALL_REF ...)
;   step 7  the call                   ->  a frame around function 3's label
;
; Steps 1 and 2 are frozen-step-first and frozen-step-second: the status test is
; status-independent until the branch, and at status 1 the comparison's value is
; 0, which is what the top-level link here (running-step-three) takes.
;
; THE LAST TWO STEPS ARE THE READ LAYER'S CALL RULES.  step_read/split/r-call
; resolves the module index through the frame's module and emits
; (ref.func_addr A) (call_ref type); step/r-call_ref-func then pushes the
; callee's frame.  A lone call_ref is NOT stepped, which is the search failure
; the entry's k = 1 slice needs (rstep-lone-call-ref).
;
; THE WIRING, and the one rule that cost time.  Each step is the frozen book's
; recipe: the inner instruction step, the search's slice, the bridge from
; step/r-ctxt-instrs to step, the label, the frame, and the top-level link.  The
; ctxt lemmas disable STEP and STEP/R-CTXT-INSTRS; the label, frame and
; composition lemmas disable only STEP/R-CTXT-INSTRS.  Disabling STEP in a
; composition leaves its facts' hypotheses unprovable, and leaving it enabled in
; a ctxt lemma lets ACL2 re-expand the search instead of using the fact.
;
; AND ONE ABOUT SYMBOLIC STATUS.  The call-entry fact is stated at a symbolic
; status; a bare :USE will not bind it against a configuration at status 1
; (ACL2 chooses the free variables by matching and the store forms differ), so
; rstep-call-entry-3-at-1 specializes it first.  The same pattern applies to any
; status-general fact a running path composes.

(in-package "ACL2")

(include-book "frozen")

;; ---------------------------------------------------------------------------
;; Bodies at each position, and the two instructions the call becomes
;; ---------------------------------------------------------------------------


(defun rcfg (z instrs) (list :|%;%| z instrs))

(defun rbody-block () (cons (list :block (list :_result nil) nil) (nthcdr 4 *body-6*)))

(defconst *t3* (list :call_ref (list :_def (list :rec (list (list :sub (list (list :final)) nil (list :func%->% nil (list (list :i32)))))) 0)))

(defun rbody-label () (cons (list :label_%{%}% 0 nil nil) (nthcdr 4 *body-6*)))

(defun rbody-call () (nthcdr 4 *body-6*))

(defun rbody-split () (cons (list :ref.func_addr 3) (cons *t3* (cdr (nthcdr 4 *body-6*)))))

(defun rbody-callee () (append (milawa-callee-admin 3) (cdr (nthcdr 4 *body-6*))))

;; The inner steps, one per position.
(defthm rstep-if-false
  (equal (w3t::step (frozen-third-one z 0))
         (list (rcfg z (list (list :block (list :_result nil) nil))))))

(defthm rstep-empty-block
  (equal (w3t::step (rcfg z (list (list :block (list :_result nil) nil))))
         (list (rcfg z (list (list :label_%{%}% 0 nil nil))))))

(defthm rstep-empty-label
  (equal (w3t::step (rcfg z (list (list :label_%{%}% 0 nil nil))))
         (list (rcfg z nil))))

(defthm rstep-call-split
  (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen status result) (list (list :call 3))))
         (list (rcfg (frozen-callee-z bytes sp pc clen status result)
                     (list (list :ref.func_addr 3) *t3*)))))

(defthm rstep-lone-call-ref
  (equal (w3t::step (rcfg z (list *t3*))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg z (list *t3*))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list *t3*))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (rcfg z (list *t3*))))))))

(defthm no-ctxt-instrs-on-call-3
  (equal (w3t::step/r-ctxt-instrs
          (rcfg (frozen-callee-z bytes sp pc clen status result)
                (list (list :ref.func_addr 3) *t3*)))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (rcfg (frozen-callee-z bytes sp pc clen status result)
                           (list (list :ref.func_addr 3) *t3*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm rstep-call-entry-3
  (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen status result)
                          (list (list :ref.func_addr 3) *t3*)))
         (list (rcfg (frozen-callee-z bytes sp pc clen status result)
                     (milawa-callee-admin 3))))
  :hints (("Goal" :use no-ctxt-instrs-on-call-3
           :expand ((w3t::step (rcfg (frozen-callee-z bytes sp pc clen status result)
                                     (list (list :ref.func_addr 3) *t3*)))))))

;; Step 7's chain: the call into function 3's frame.
(defthm rctxt-seven
  (implies (equal (w3t::step (rcfg z (list (list :ref.func_addr 3) *t3*)))
                  (list (rcfg z2 (milawa-callee-admin 3))))
           (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-split)))
                  (list (rcfg z2 (rbody-callee)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg z (rbody-split))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (rbody-split)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (rbody-split)) (w3t::%t9 1)
                            (w3t::z z) (w3t::%a0 (rcfg z (rbody-split))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (rbody-split)) (w3t::%t9 1)
                            (w3t::z z) (w3t::%a0 (rcfg z (rbody-split))))
                 (:instance rstep-lone-call-ref (z z))))))

(defthm rbody-seven
  (implies (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-split)))
                  (list (rcfg z2 (rbody-callee))))
           (equal (w3t::step (rcfg z (rbody-split)))
                  (list (rcfg z2 (rbody-callee)))))
  :hints (("Goal" :expand ((w3t::step (rcfg z (rbody-split)))))))

(defthm rstep-call-entry-3-at-1
  (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                          (list (list :ref.func_addr 3) *t3*)))
         (list (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                     (milawa-callee-admin 3))))
  :hints (("Goal" :use ((:instance rstep-call-entry-3 (status 1))))))

(defthm rbody-seven-instance
  (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen 1 result) (rbody-split)))
         (list (rcfg (frozen-callee-z bytes sp pc clen 1 result) (rbody-callee))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance rctxt-seven
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rbody-seven
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 rstep-call-entry-3-at-1))))

(defthm rlabel-seven
  (implies (equal (w3t::step (rcfg z (rbody-split)))
                  (list (rcfg z2 (rbody-callee))))
           (equal (w3t::step (rcfg z (frozen-label-instr (rbody-split))))
                  (list (rcfg z2 (frozen-label-instr (rbody-callee))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (rcfg z (frozen-label-instr (rbody-split)))))))))

(defthm rframe-seven
  (implies (equal (w3t::step (rcfg (list :|%;%| s f-prime)
                                   (frozen-label-instr (rbody-split))))
                  (list (rcfg (list :|%;%| s2 f2)
                              (frozen-label-instr (rbody-callee)))))
           (equal (w3t::step (rcfg (list :|%;%| s f)
                                   (frozen-frame-instr f-prime
                                                       (frozen-label-instr (rbody-split)))))
                  (list (rcfg (list :|%;%| s2 f)
                              (frozen-frame-instr f2
                                                  (frozen-label-instr (rbody-callee)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (rcfg (list :|%;%| s f)
                                            (frozen-frame-instr f-prime
                                                                (frozen-label-instr (rbody-split))))))))))

(defthm running-label-instance
  (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                          (frozen-label-instr (rbody-split))))
         (list (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                     (frozen-label-instr (rbody-callee)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rlabel-seven
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 rbody-seven-instance))))

(defthm running-step-seven
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (rbody-split)))
         (list (frozen-body-cfg bytes sp pc clen 1 result (rbody-callee))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rframe-seven
                            (s (frozen-store bytes sp pc clen 1 result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen 1 result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance running-label-instance)))))

;; Step 3: the status test, else branch.
(defthm rctxt-third-false
  (implies (equal (w3t::step (frozen-third-one z 0))
                  (list (rcfg z2 (list (list :block (list :_result nil) nil)))))
           (equal (w3t::step/r-ctxt-instrs (rcfg z (frozen-third-body 0)))
                  (list (rcfg z2 (rbody-block)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg z (frozen-third-body 0))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (frozen-third-body 0)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (frozen-third-body 0))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (rcfg z (frozen-third-body 0))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (frozen-third-body 0))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (rcfg z (frozen-third-body 0))))
                 frozen-step-lone-ifelse))))

(defthm rbody-third-false
  (implies (equal (w3t::step/r-ctxt-instrs (rcfg z (frozen-third-body 0)))
                  (list (rcfg z2 (rbody-block))))
           (equal (w3t::step (rcfg z (frozen-third-body 0)))
                  (list (rcfg z2 (rbody-block)))))
  :hints (("Goal"
           :expand ((w3t::step (rcfg z (frozen-third-body 0)))))))

(defthm rlabel-third-false
  (implies (equal (w3t::step (rcfg z (frozen-third-body 0)))
                  (list (rcfg z2 (rbody-block))))
           (equal (w3t::step (rcfg z (frozen-label-instr (frozen-third-body 0))))
                  (list (rcfg z2 (frozen-label-instr (rbody-block))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (rcfg z (frozen-label-instr (frozen-third-body 0)))))))))

(defthm rframe-third-false
  (implies (equal (w3t::step (rcfg (list :|%;%| s f-prime)
                                   (frozen-label-instr (frozen-third-body 0))))
                  (list (rcfg (list :|%;%| s2 f2)
                              (frozen-label-instr (rbody-block)))))
           (equal (w3t::step (rcfg (list :|%;%| s f)
                                   (frozen-frame-instr f-prime
                                                       (frozen-label-instr (frozen-third-body 0)))))
                  (list (rcfg (list :|%;%| s2 f)
                              (frozen-frame-instr f2
                                                  (frozen-label-instr (rbody-block)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (rcfg (list :|%;%| s f)
                                            (frozen-frame-instr f-prime
                                                                (frozen-label-instr (frozen-third-body 0))))))))))

(defthm running-step-three
  (implies (unsigned-byte-p 32 1)
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                              (frozen-third-body 0)))
                  (list (frozen-body-cfg bytes sp pc clen 1 result
                                         (rbody-block)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rframe-third-false
                            (s (frozen-store bytes sp pc clen 1 result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen 1 result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance rlabel-third-false
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rbody-third-false
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rctxt-third-false
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 rstep-if-false))))

;; Steps 4-6: the empty block, the empty label, the call split.
(defthm rctxt-four
  (implies (equal (w3t::step (rcfg z (list (list :block (list :_result nil) nil))))
                  (list (rcfg z2 (list (list :label_%{%}% 0 nil nil)))))
           (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-block)))
                  (list (rcfg z2 (rbody-label)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg z (rbody-block))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (rbody-block)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (rbody-block)) (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (rcfg z (rbody-block))))))))

(defthm rbody-four
  (implies (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-block)))
                  (list (rcfg z2 (rbody-label))))
           (equal (w3t::step (rcfg z (rbody-block)))
                  (list (rcfg z2 (rbody-label)))))
  :hints (("Goal" :expand ((w3t::step (rcfg z (rbody-block)))))))

(defthm rlabel-four
  (implies (equal (w3t::step (rcfg z (rbody-block)))
                  (list (rcfg z2 (rbody-label))))
           (equal (w3t::step (rcfg z (frozen-label-instr (rbody-block))))
                  (list (rcfg z2 (frozen-label-instr (rbody-label))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (rcfg z (frozen-label-instr (rbody-block)))))))))

(defthm rframe-four
  (implies (equal (w3t::step (rcfg (list :|%;%| s f-prime)
                                   (frozen-label-instr (rbody-block))))
                  (list (rcfg (list :|%;%| s2 f2)
                              (frozen-label-instr (rbody-label)))))
           (equal (w3t::step (rcfg (list :|%;%| s f)
                                   (frozen-frame-instr f-prime
                                                       (frozen-label-instr (rbody-block)))))
                  (list (rcfg (list :|%;%| s2 f)
                              (frozen-frame-instr f2
                                                  (frozen-label-instr (rbody-label)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (rcfg (list :|%;%| s f)
                                            (frozen-frame-instr f-prime
                                                                (frozen-label-instr (rbody-block))))))))))

(defthm running-step-four
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (rbody-block)))
         (list (frozen-body-cfg bytes sp pc clen 1 result (rbody-label))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rframe-four
                            (s (frozen-store bytes sp pc clen 1 result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen 1 result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance rlabel-four
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rbody-four
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rctxt-four
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 rstep-empty-block))))

(defthm rctxt-five
  (implies (equal (w3t::step (rcfg z (list (list :label_%{%}% 0 nil nil))))
                  (list (rcfg z2 nil)))
           (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-label)))
                  (list (rcfg z2 (rbody-call)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg z (rbody-label))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (rbody-label)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (rbody-label)) (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (rcfg z (rbody-label))))))))

(defthm rbody-five
  (implies (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-label)))
                  (list (rcfg z2 (rbody-call))))
           (equal (w3t::step (rcfg z (rbody-label)))
                  (list (rcfg z2 (rbody-call)))))
  :hints (("Goal" :expand ((w3t::step (rcfg z (rbody-label)))))))

(defthm rlabel-five
  (implies (equal (w3t::step (rcfg z (rbody-label)))
                  (list (rcfg z2 (rbody-call))))
           (equal (w3t::step (rcfg z (frozen-label-instr (rbody-label))))
                  (list (rcfg z2 (frozen-label-instr (rbody-call))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (rcfg z (frozen-label-instr (rbody-label)))))))))

(defthm rframe-five
  (implies (equal (w3t::step (rcfg (list :|%;%| s f-prime)
                                   (frozen-label-instr (rbody-label))))
                  (list (rcfg (list :|%;%| s2 f2)
                              (frozen-label-instr (rbody-call)))))
           (equal (w3t::step (rcfg (list :|%;%| s f)
                                   (frozen-frame-instr f-prime
                                                       (frozen-label-instr (rbody-label)))))
                  (list (rcfg (list :|%;%| s2 f)
                              (frozen-frame-instr f2
                                                  (frozen-label-instr (rbody-call)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (rcfg (list :|%;%| s f)
                                            (frozen-frame-instr f-prime
                                                                (frozen-label-instr (rbody-label))))))))))

(defthm running-step-five
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (rbody-label)))
         (list (frozen-body-cfg bytes sp pc clen 1 result (rbody-call))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rframe-five
                            (s (frozen-store bytes sp pc clen 1 result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen 1 result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance rlabel-five
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rbody-five
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rctxt-five
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 rstep-empty-label))))

(defthm rctxt-six
  (implies (equal (w3t::step (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                                   (list (list :call 3))))
                  (list (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                              (list (list :ref.func_addr 3) *t3*))))
           (equal (w3t::step/r-ctxt-instrs (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                                                 (rbody-call)))
                  (list (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                              (rbody-split)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                                            (rbody-call))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (rbody-call)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (rbody-call)) (w3t::%t9 0)
                            (w3t::z (frozen-callee-z bytes sp pc clen 1 result))
                            (w3t::%a0 (rcfg (frozen-callee-z bytes sp pc clen 1 result)
                                            (rbody-call))))))))

(defthm rbody-six
  (implies (equal (w3t::step/r-ctxt-instrs (rcfg z (rbody-call)))
                  (list (rcfg z2 (rbody-split))))
           (equal (w3t::step (rcfg z (rbody-call)))
                  (list (rcfg z2 (rbody-split)))))
  :hints (("Goal" :expand ((w3t::step (rcfg z (rbody-call)))))))

(defthm rlabel-six
  (implies (equal (w3t::step (rcfg z (rbody-call)))
                  (list (rcfg z2 (rbody-split))))
           (equal (w3t::step (rcfg z (frozen-label-instr (rbody-call))))
                  (list (rcfg z2 (frozen-label-instr (rbody-split))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (rcfg z (frozen-label-instr (rbody-call)))))))))

(defthm rframe-six
  (implies (equal (w3t::step (rcfg (list :|%;%| s f-prime)
                                   (frozen-label-instr (rbody-call))))
                  (list (rcfg (list :|%;%| s2 f2)
                              (frozen-label-instr (rbody-split)))))
           (equal (w3t::step (rcfg (list :|%;%| s f)
                                   (frozen-frame-instr f-prime
                                                       (frozen-label-instr (rbody-call)))))
                  (list (rcfg (list :|%;%| s2 f)
                              (frozen-frame-instr f2
                                                  (frozen-label-instr (rbody-split)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (rcfg (list :|%;%| s f)
                                            (frozen-frame-instr f-prime
                                                                (frozen-label-instr (rbody-call))))))))))

(defthm running-step-six
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (rbody-call)))
         (list (frozen-body-cfg bytes sp pc clen 1 result (rbody-split))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance rframe-six
                            (s (frozen-store bytes sp pc clen 1 result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen 1 result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance rlabel-six
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rbody-six
                            (z (frozen-callee-z bytes sp pc clen 1 result))
                            (z2 (frozen-callee-z bytes sp pc clen 1 result)))
                 (:instance rctxt-six)
                 rstep-call-split))))
