; L1, the frozen path: the module's first test, taken the other way.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The module's body begins
;
;   (global.get 3) (const 1) (relop (:ne)) (ifelse (:_result nil) ((global.get 3) (return)) nil) ...
;
; so when global 3 -- the status word -- is anything but 1, the module returns
; the status unchanged and does nothing else.  That is the path a stopped machine
; takes (status 0 or 2) and the path the frozen tests in abs.lisp exercise, and
; it is the shortest of the sixteen: nine steps from the entry configuration.
;
; WHAT THIS BOOK PROVES.  The nine steps, one link at a time, for a SYMBOLIC
; status and a symbolic memory: from MVM-ABS-ABSTRACT -- a call to function 6 --
; the certified semantics runs to a configuration that cannot step again, with
; the store unchanged and the returned value the status it was given.  The
; hypothesis is exactly the branch's guard: (UNSIGNED-BYTE-P 32 STATUS) and
; STATUS /= 1.
;
; WHY THIS IS A NEW BOOK, and not more of links.lisp.  The configuration a call
; leaves behind is NOT the one links.lisp's links are stated at.  There the
; frame under the label is (CADDR Z) -- the pinned frame, with no locals -- and
; Z is the abstract store.  The call actually leaves
;
;   (:;% (:;% STORE ENTRY-FRAME) ((:FRAME_ 1 CALLEE-FRAME ((:LABEL_ 1 NIL BODY)))))
;
; where ENTRY-FRAME is the empty frame $INVOKE builds and CALLEE-FRAME is the
; one Step/call_ref-func builds from the store's function record, with the four
; zero-initialised locals.  The two frames differ, and the body reads globals
; THROUGH ITS FRAME'S MODULE, so the links have to be stated where the call
; really leaves them.  The walk tool's configuration (and links.lisp's) is a
; faithful shape, not the actual term; this book is the actual term.
;
; THE RECIPE, once per step, and it is the one links.lisp found:
;
;   inner   -- what the instruction does at the store it actually sees
;   flat    -- the search's slice at this position, with the inner step as a
;              hypothesis, and the search's failures at the smaller slices
;   bridge  -- step on the body list is step/r-ctxt-instrs on it (the earlier
;              rule families do not apply, and the body is a literal)
;   label   -- the same step one label up
;   frame   -- and one frame up
;
; The one new phenomenon is step 5 and 6: the block rewrote itself into a
; LABEL, so from then on the descent has TWO labels to pass through, and the
; second position of the inner label is not an instruction of the outer body at
; all -- it is a one-instruction configuration in its own right.

(in-package "ACL2")

(include-book "links")

;; ---------------------------------------------------------------------------
;; The configuration the call leaves behind
;; ---------------------------------------------------------------------------

; $INVOKE's frame: no locals, and a module record whose nine fields are all NIL.
; (The $INVOKE frame's module cannot be read by %GET-FIELD, which is why
; abs.lisp's milawa-global uses the pinned frame instead; here it is only
; carried, and the body's global.get reads through the CALLEE frame.)
(defconst *frozen-entry-frame*
  '(:%REC (:LOCALS)
          (:MODULE :%REC (:TYPES) (:TAGS) (:GLOBALS) (:MEMS) (:TABLES)
                    (:FUNCS) (:DATAS) (:ELEMS) (:EXPORTS))))

(defun frozen-store (bytes sp pc clen status result)
  (declare (xargs :guard t :verify-guards nil))
  (cadr (mvm-abs-z-abstract bytes sp pc clen status result)))

(defun frozen-z (bytes sp pc clen status result)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| (frozen-store bytes sp pc clen status result) *frozen-entry-frame*))

; The store-and-frame pair the BODY runs against: the same store, the callee's
; frame.  This is the Z that appears inside the frame rule.
(defun frozen-callee-z (bytes sp pc clen status result)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| (frozen-store bytes sp pc clen status result) (milawa-callee-frame 6)))

(defun frozen-cfg (bytes sp pc clen status result instrs)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| (frozen-z bytes sp pc clen status result) instrs))

; frame, then label, then BODY: the nesting a call leaves behind.
(defun frozen-body-cfg (bytes sp pc clen status result body)
  (declare (xargs :guard t :verify-guards nil))
  (frozen-cfg bytes sp pc clen status result
              (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                          (list (list :label_%{%}% 1 nil body))))))

; The same with the frame's instruction list given directly, which is the shape
; after the label has been consumed by a return.
(defun frozen-frame-cfg (bytes sp pc clen status result instrs)
  (declare (xargs :guard t :verify-guards nil))
  (frozen-cfg bytes sp pc clen status result
              (list (list :frame_%{%}% 1 (milawa-callee-frame 6) instrs))))

;; ---------------------------------------------------------------------------
;; Step 1 of nine: the call
;; ---------------------------------------------------------------------------

; The entry configuration is a call to function 6, and the call rule pushes the
; callee's frame and label and hands control to the callee's body.  Measured
; first (harness/probe): (CADDR Z) here is the $INVOKE frame, not the pinned
; one, and the module record has :MODULE written as a CDR, not a one-element
; list.  Both matter -- a frame written the other way makes this goal NIL.
(defthm frozen-step-entry
  (equal (w3t::step (mvm-abs-abstract bytes sp pc clen status result))
         (list (frozen-body-cfg bytes sp pc clen status result *body-6*))))

;; ---------------------------------------------------------------------------
;; The read the first instruction makes, at the callee's store
;; ---------------------------------------------------------------------------

; Global 3 through the CALLEE frame's module.  The module is the artifact's --
; (milawa-callee-frame 6)'s :MODULE is the pinned frame's :MODULE, measured --
; so the same lookup as head.lisp's step-of-global-get-3, through a frame with
; four locals in it.  21,742 prover steps.
(defthm frozen-step-global-get-3
  (equal (w3t::step
          (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                (list (list :global.get 3))))
         (list (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                     (list (list :const (list :i32) status))))))

; ---------------------------------------------------------------------------
;; Step 2 of nine: the read of the status global
;; ---------------------------------------------------------------------------

; The first link, at the configuration the call leaves.  The three bridges from
; chain.lisp are parametric in the store and the frames, so they are reused:
; the flat bridge with Z = the callee's store; the label bridge; the frame
; bridge with f-prime the callee's frame.  330,449 prover steps.
(defthm frozen-step-first
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen status result *body-6*))
         (list (frozen-body-cfg bytes sp pc clen status result
                                (cons (list :const (list :i32) status)
                                      (cdr *body-6*)))))
  :hints (("Goal"
           :use ((:instance frame-body-6-general
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance label-body-6-general
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance flat-body-6-general
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (val (list (list :const (list :i32) status))))
                 frozen-step-global-get-3)
           :in-theory (disable w3t::step/r-ctxt-instrs))))

;; ---------------------------------------------------------------------------
;; Step 3 of nine: the comparison, and the value it pushes
;; ---------------------------------------------------------------------------

; The comparison of the status against 1, at the callee's store.  Its VALUE is
; left as the spec's own $RELOP_ term; the branch's guard is a separate fact
; (see frozen-relop-is-one below), because this step is true for every status.
(defthm frozen-step-relop
  (equal (w3t::step
          (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                (list (list :const (list :i32) status)
                      (list :const (list :i32) 1)
                      (list :relop (list :i32) (list :ne)))))
         (list (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                     (list (list :const (list :i32)
                                 (w3t::$relop_ (list :i32) (list :ne) status 1)))))))

; The body-level search, at the callee's store, with the three instructions
; taken as ONE step.  The search walks k = 2 (a lone comparison) and k = 1 (one
; operand) before succeeding at k = 0; the two failures are search.lisp's
; step-nil-on-a-lone-relop and step-nil-on-a-relop-with-one-value.  This is
; flat-body-6-second instantiated; 75,924 prover steps.
(defthm frozen-ctxt-second
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                         (cons (list :const (list :i32) status)
                               (cdr *body-6*))))
                  (list (list :|%;%| (frozen-callee-z bytes sp pc clen status result)
                              (cons (list :const (list :i32)
                                          (w3t::$relop_ (list :i32) (list :ne) status 1))
                                    (nthcdr 3 *body-6*))))))
  :hints (("Goal"
           :use ((:instance flat-body-6-second
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (val (list (list :const (list :i32)
                                             (w3t::$relop_ (list :i32) (list :ne) status 1))))
                            (rest (nthcdr 3 *body-6*))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

; step on the body is step/r-ctxt-instrs on it: the earlier rule families do
; not apply, because the body's last instruction is (:CALL 4) and the pure and
; read rules all match on the last instruction or on a lone admin.  Stated
; with the ctxt-instrs answer as a hypothesis so the two proofs stay separate;
; 13,024 prover steps.
(defthm frozen-step-body-second
  (implies (and (unsigned-byte-p 32 status)
                (equal (w3t::step/r-ctxt-instrs
                        (list :|%;%| z
                              (cons (list :const (list :i32) status)
                                    (cdr *body-6*))))
                       (list (list :|%;%| z2
                                   (cons (list :const (list :i32) c)
                                         (nthcdr 3 *body-6*))))))
           (equal (w3t::step
                   (list :|%;%| z
                         (cons (list :const (list :i32) status)
                               (cdr *body-6*))))
                  (list (list :|%;%| z2
                              (cons (list :const (list :i32) c)
                                    (nthcdr 3 *body-6*))))))
  :hints (("Goal"
           :expand ((w3t::step
                     (list :|%;%| z
                           (cons (list :const (list :i32) status)
                                 (cdr *body-6*))))))))

; The label level, with the body step as a hypothesis.  The pinned version in
; links.lisp (step-in-label-body-6-second) is this with z = the abstract store;
; the callee's store needs the general form.  589,221 prover steps.
(defthm frozen-label-second
  (implies (equal (w3t::step
                   (list :|%;%| z
                         (cons (list :const (list :i32) status)
                               (cdr *body-6*))))
                  (list (list :|%;%| z2
                              (cons (list :const (list :i32) c)
                                    (nthcdr 3 *body-6*)))))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 1 nil
                                     (cons (list :const (list :i32) status)
                                           (cdr *body-6*))))))
                  (list (list :|%;%| z2
                              (list (list :label_%{%}% 1 nil
                                          (cons (list :const (list :i32) c)
                                                (nthcdr 3 *body-6*))))))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| z
                                            (list (list :label_%{%}% 1 nil
                                                        (cons (list :const (list :i32) status)
                                                              (cdr *body-6*))))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

; And the frame level, at the callee's frame.  step-in-frame-body-6-second is
; already parametric in the frames and the store, so this is its instance, with
; the value (CONST C) in the place its VAL occupies.
(defun frozen-third-body (c)
  (declare (xargs :guard t :verify-guards nil))
  (cons (list :const (list :i32) c) (nthcdr 3 *body-6*)))

(defthm frozen-step-second
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-body-cfg bytes sp pc clen status result
                                    (cons (list :const (list :i32) status)
                                          (cdr *body-6*))))
                  (list (frozen-body-cfg
                         bytes sp pc clen status result
                         (frozen-third-body
                          (w3t::$relop_ (list :i32) (list :ne) status 1))))))
  :hints (("Goal"
           :use ((:instance step-in-frame-body-6-second
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6))
                            (val (list (list :const (list :i32)
                                             (w3t::$relop_ (list :i32) (list :ne) status 1)))))
                 (:instance frozen-label-second
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (c (w3t::$relop_ (list :i32) (list :ne) status 1)))
                 (:instance frozen-step-body-second
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (c (w3t::$relop_ (list :i32) (list :ne) status 1)))
                 frozen-ctxt-second
                 frozen-step-relop)
           :in-theory (disable w3t::step/r-ctxt-instrs))))

;; ---------------------------------------------------------------------------
;; Step 4 of nine: the branch test, and the block it produces
;; ---------------------------------------------------------------------------

; The body at this position is the comparison's value, then the :IFELSE.  The
; branch taken is the THEN branch -- the frozen test -- so the blocktype's body
; is ((:GLOBAL.GET 3) (:RETURN)) and the else branch NIL.

(defun frozen-block-body ()
  (declare (xargs :guard t :verify-guards nil))
  (cons (list :block (list :_result nil)
              (list (list :global.get 3) (list :return)))
        (nthcdr 4 *body-6*)))

(defun frozen-lone-ifelse-cfg (z)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| z (list (list :ifelse (list :_result nil)
                             (list (list :global.get 3) (list :return))
                             nil))))

(defun frozen-third-one (z c)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| z (list (list :const (list :i32) c)
                       (list :ifelse (list :_result nil)
                             (list (list :global.get 3) (list :return))
                             nil))))

; A lone :IFELSE is not stepped: the rule needs a value before it, and the
; search refuses a single instruction.  This is the failure the search meets at
; k = 1 on this position, and it is search.lisp's pattern exactly.
(defthm frozen-step-lone-ifelse
  (equal (w3t::step (frozen-lone-ifelse-cfg z)) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-lone-ifelse-cfg z)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :ifelse (list :_result nil)
                                                  (list (list :global.get 3) (list :return))
                                                  nil)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (frozen-lone-ifelse-cfg z)))))))

; With a nonzero value before it the branch is taken, and it is taken by
; REWRITING THE :IFELSE INTO A :BLOCK: the semantics' Step_pure/if-true turns
; the branch into a block whose body is the then-clause.  That block is the
; instruction the next step has to enter, and the reason the path's shape
; changes here.
(defthm frozen-step-ifelse
  (implies (and (unsigned-byte-p 32 c) (not (equal c 0)))
           (equal (w3t::step (frozen-third-one z c))
                  (list (list :|%;%| z
                              (list (list :block (list :_result nil)
                                          (list (list :global.get 3)
                                                (list :return)))))))))

; The search at this position: prefix7 = 1, k = 1 gives a lone :IFELSE (nil),
; k = 0 gives the value and the :IFELSE together, which steps.
(defthm frozen-ctxt-third
  (implies (and (unsigned-byte-p 32 c)
                (not (equal c 0))
                (equal (w3t::step (frozen-third-one z c))
                       (list (list :|%;%| z2
                                   (list (list :block (list :_result nil)
                                               (list (list :global.get 3)
                                                     (list :return))))))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (frozen-third-body c)))
                  (list (list :|%;%| z2 (frozen-block-body)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (frozen-third-body c))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (frozen-third-body c)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (frozen-third-body c))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (frozen-third-body c))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (frozen-third-body c))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (frozen-third-body c))))
                 frozen-step-lone-ifelse))))

(defthm frozen-step-body-third
  (implies (and (unsigned-byte-p 32 c)
                (not (equal c 0))
                (equal (w3t::step/r-ctxt-instrs
                        (list :|%;%| z (frozen-third-body c)))
                       (list (list :|%;%| z2 (frozen-block-body)))))
           (equal (w3t::step (list :|%;%| z (frozen-third-body c)))
                  (list (list :|%;%| z2 (frozen-block-body)))))
  :hints (("Goal"
           :expand ((w3t::step (list :|%;%| z (frozen-third-body c)))))))

(defthm frozen-label-third
  (implies (equal (w3t::step (list :|%;%| z (frozen-third-body c)))
                  (list (list :|%;%| z2 (frozen-block-body))))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 1 nil
                                     (frozen-third-body c)))))
                  (list (list :|%;%| z2
                              (list (list :label_%{%}% 1 nil
                                          (frozen-block-body)))))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| z
                                            (list (list :label_%{%}% 1 nil
                                                        (frozen-third-body c)))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

; The frame level, per position.  A fully symbolic label body DIVERGES here --
; the frame rule's %SIZE guard has nothing to compute on -- so the body is the
; position's own term, as everywhere else in the chain.  5,124,587 prover steps.
(defthm frozen-frame-third
  (implies (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f-prime)
                         (list (list :label_%{%}% 1 nil
                                     (frozen-third-body c)))))
                  (list (list :|%;%| (list :|%;%| s2 f2)
                              (list (list :label_%{%}% 1 nil
                                          (frozen-block-body))))))
           (equal (w3t::step
                   (list :|%;%| (list :|%;%| s f)
                         (list (list :frame_%{%}% 1 f-prime
                                     (list (list :label_%{%}% 1 nil
                                                 (frozen-third-body c)))))))
                  (list (list :|%;%| (list :|%;%| s2 f)
                              (list (list :frame_%{%}% 1 f2
                                          (list (list :label_%{%}% 1 nil
                                                      (frozen-block-body)))))))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (list :|%;%| s f)
                                            (list (list :frame_%{%}% 1 f-prime
                                                        (list (list :label_%{%}% 1 nil
                                                                    (frozen-third-body c)))))))))
           :in-theory (disable w3t::step/r-ctxt-instrs))))

(defthm frozen-step-third
  (implies (and (unsigned-byte-p 32 c) (not (equal c 0)))
           (equal (w3t::step
                   (frozen-body-cfg bytes sp pc clen status result
                                    (frozen-third-body c)))
                  (list (frozen-body-cfg
                         bytes sp pc clen status result
                         (frozen-block-body)))))
  :hints (("Goal"
           :use ((:instance frozen-frame-third
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance frozen-label-third
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-step-body-third
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-ctxt-third
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 frozen-step-ifelse)
           :in-theory (disable w3t::step/r-ctxt-instrs))))


;; ---------------------------------------------------------------------------
;; Building the configurations, once, so the lemmas stay readable
;; ---------------------------------------------------------------------------

(defun frozen-cfg-of (z instrs)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| z instrs))

(defun frozen-one (x)
  (declare (xargs :guard t :verify-guards nil))
  (list x))

(defun frozen-block-instr ()
  (declare (xargs :guard t :verify-guards nil))
  (list :block (list :_result nil)
        (list (list :global.get 3) (list :return))))

(defun frozen-inner-label-instr ()
  (declare (xargs :guard t :verify-guards nil))
  (list :label_%{%}% 0 nil (list (list :global.get 3) (list :return))))

(defun frozen-inner-label-instr-done (status)
  (declare (xargs :guard t :verify-guards nil))
  (list :label_%{%}% 0 nil
        (list (list :const (list :i32) status) (list :return))))

(defun frozen-label-instr (body)
  (declare (xargs :guard t :verify-guards nil))
  (list (list :label_%{%}% 1 nil body)))

(defun frozen-frame-instr (f instrs)
  (declare (xargs :guard t :verify-guards nil))
  (list (list :frame_%{%}% 1 f instrs)))

(defun frozen-inner-label-body ()
  (declare (xargs :guard t :verify-guards nil))
  (cons (frozen-inner-label-instr) (nthcdr 4 *body-6*)))

(defun frozen-inner-label-body-done (status)
  (declare (xargs :guard t :verify-guards nil))
  (cons (frozen-inner-label-instr-done status) (nthcdr 4 *body-6*)))

(defun frozen-ret-body (status)
  (declare (xargs :guard t :verify-guards nil))
  (cons (list :const (list :i32) status)
        (cons (list :return) (nthcdr 4 *body-6*))))

(defun frozen-ret-instrs (status)
  (declare (xargs :guard t :verify-guards nil))
  (list (list :const (list :i32) status) (list :return)))

(defun frozen-result-instrs (status)
  (declare (xargs :guard t :verify-guards nil))
  (list (list :const (list :i32) status)))

;; ---------------------------------------------------------------------------
;; Step 5 of nine: the block, entered
;; ---------------------------------------------------------------------------

; The block rule is in the READ layer, not a context rule: Step_read/block
; rewrites (:BLOCK bt BODY) into (:LABEL_ n NIL BODY), with n the number of
; result types in the blocktype -- here 0.  A lone block is therefore stepped
; by step_read/split, and it proves by evaluation at the abstract store.
(defthm frozen-step-lone-block
  (equal (w3t::step
          (frozen-cfg-of z (frozen-one (frozen-block-instr))))
         (list (frozen-cfg-of z (frozen-one (frozen-inner-label-instr))))))

(defthm frozen-ctxt-fourth
  (implies (equal (w3t::step (frozen-cfg-of z (frozen-one (frozen-block-instr))))
                  (list (frozen-cfg-of z2 (frozen-one (frozen-inner-label-instr)))))
           (equal (w3t::step/r-ctxt-instrs
                   (frozen-cfg-of z (frozen-block-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-cfg-of z (frozen-block-body))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (frozen-block-body))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (frozen-cfg-of z (frozen-block-body))))))))

(defthm frozen-step-body-fourth
  (implies (equal (w3t::step/r-ctxt-instrs
                   (frozen-cfg-of z (frozen-block-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body))))
           (equal (w3t::step (frozen-cfg-of z (frozen-block-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body)))))
  :hints (("Goal"
           :expand ((w3t::step (frozen-cfg-of z (frozen-block-body)))))))

(defthm frozen-label-fourth
  (implies (equal (w3t::step (frozen-cfg-of z (frozen-block-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body))))
           (equal (w3t::step
                   (frozen-cfg-of z (frozen-label-instr (frozen-block-body))))
                  (list (frozen-cfg-of z2
                                       (frozen-label-instr (frozen-inner-label-body))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (frozen-cfg-of z (frozen-label-instr (frozen-block-body)))))))))

(defthm frozen-frame-fourth
  (implies (equal (w3t::step
                   (frozen-cfg-of (list :|%;%| s f-prime)
                                  (frozen-label-instr (frozen-block-body))))
                  (list (frozen-cfg-of (list :|%;%| s2 f2)
                                       (frozen-label-instr (frozen-inner-label-body)))))
           (equal (w3t::step
                   (frozen-cfg-of (list :|%;%| s f)
                                  (frozen-frame-instr f-prime
                                                      (frozen-label-instr (frozen-block-body)))))
                  (list (frozen-cfg-of
                         (list :|%;%| s2 f)
                         (frozen-frame-instr f2
                                             (frozen-label-instr (frozen-inner-label-body)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (frozen-cfg-of
                                       (list :|%;%| s f)
                                       (frozen-frame-instr
                                        f-prime
                                        (frozen-label-instr (frozen-block-body))))))))))

(defthm frozen-step-fourth
  (equal (w3t::step
          (frozen-body-cfg bytes sp pc clen status result (frozen-block-body)))
         (list (frozen-body-cfg bytes sp pc clen status result
                                (frozen-inner-label-body))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance frozen-frame-fourth
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance frozen-label-fourth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-step-body-fourth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-ctxt-fourth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))))))

;; ---------------------------------------------------------------------------
;; Step 6 of nine: the read inside the block's label
;; ---------------------------------------------------------------------------

; The lone inner label steps by the label rule, which steps its body
; ((:GLOBAL.GET 3) (:RETURN)) by the search at k = 0 -- a read after no values.
; A label is not a value, so prefix7 is 0 and the search has one slice to try.
(defthm frozen-step-inner-read
  (equal (w3t::step
          (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                         (frozen-one (frozen-inner-label-instr))))
         (list (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                              (frozen-one (frozen-inner-label-instr-done status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance frozen-step-global-get-3)
                 (:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-cfg-of
                                       (frozen-callee-z bytes sp pc clen status result)
                                       (list (list :global.get 3) (list :return)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :global.get 3) (list :return)))
                            (w3t::%t9 0)
                            (w3t::z (frozen-callee-z bytes sp pc clen status result))
                            (w3t::%a0 (frozen-cfg-of
                                       (frozen-callee-z bytes sp pc clen status result)
                                       (list (list :global.get 3) (list :return)))))
                 (:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (frozen-cfg-of
                                       (frozen-callee-z bytes sp pc clen status result)
                                       (frozen-one (frozen-inner-label-instr)))))))))

(defthm frozen-ctxt-fifth
  (implies (equal (w3t::step (frozen-cfg-of z (frozen-one (frozen-inner-label-instr))))
                  (list (frozen-cfg-of z2 (frozen-one (frozen-inner-label-instr-done status)))))
           (equal (w3t::step/r-ctxt-instrs
                   (frozen-cfg-of z (frozen-inner-label-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body-done status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-cfg-of z (frozen-inner-label-body))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (frozen-inner-label-body))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (frozen-cfg-of z (frozen-inner-label-body))))))))

(defthm frozen-step-body-fifth
  (implies (equal (w3t::step/r-ctxt-instrs
                   (frozen-cfg-of z (frozen-inner-label-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body-done status))))
           (equal (w3t::step (frozen-cfg-of z (frozen-inner-label-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body-done status)))))
  :hints (("Goal"
           :expand ((w3t::step (frozen-cfg-of z (frozen-inner-label-body)))))))

(defthm frozen-label-fifth
  (implies (equal (w3t::step (frozen-cfg-of z (frozen-inner-label-body)))
                  (list (frozen-cfg-of z2 (frozen-inner-label-body-done status))))
           (equal (w3t::step
                   (frozen-cfg-of z (frozen-label-instr (frozen-inner-label-body))))
                  (list (frozen-cfg-of z2
                                       (frozen-label-instr
                                        (frozen-inner-label-body-done status))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (frozen-cfg-of
                                       z (frozen-label-instr (frozen-inner-label-body)))))))))

(defthm frozen-frame-fifth
  (implies (equal (w3t::step
                   (frozen-cfg-of (list :|%;%| s f-prime)
                                  (frozen-label-instr (frozen-inner-label-body))))
                  (list (frozen-cfg-of
                         (list :|%;%| s2 f2)
                         (frozen-label-instr (frozen-inner-label-body-done status)))))
           (equal (w3t::step
                   (frozen-cfg-of (list :|%;%| s f)
                                  (frozen-frame-instr
                                   f-prime
                                   (frozen-label-instr (frozen-inner-label-body)))))
                  (list (frozen-cfg-of
                         (list :|%;%| s2 f)
                         (frozen-frame-instr
                          f2
                          (frozen-label-instr (frozen-inner-label-body-done status)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (frozen-cfg-of
                                       (list :|%;%| s f)
                                       (frozen-frame-instr
                                        f-prime
                                        (frozen-label-instr
                                         (frozen-inner-label-body))))))))))

(defthm frozen-step-fifth
  (equal (w3t::step
          (frozen-body-cfg bytes sp pc clen status result (frozen-inner-label-body)))
         (list (frozen-body-cfg bytes sp pc clen status result
                                (frozen-inner-label-body-done status))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance frozen-frame-fifth
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6))
                            (status status))
                 (:instance frozen-label-fifth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (status status))
                 (:instance frozen-step-body-fifth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (status status))
                 (:instance frozen-ctxt-fifth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result))
                            (status status))
                 (:instance frozen-step-inner-read (status status))))))

;; ---------------------------------------------------------------------------
;; Step 7 of nine: the inner label's return
;; ---------------------------------------------------------------------------

; The inner label's body is now ((:CONST (:I32) STATUS) (:RETURN)), so the
; RETURN rule fires -- but the rule is a PURE one, on the label as a whole:
; Step_pure/return-label drops the label and keeps val* ++ (return).  The
; return is therefore consumed in two pieces: the label goes at this step, the
; frame at the next.
(defthm frozen-step-inner-return
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                                  (frozen-one (frozen-inner-label-instr-done status))))
                  (list (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                                       (frozen-ret-instrs status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance step-pure-return-out-of-label
                            (n 0) (is0 nil) (x status))
                 (:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (frozen-cfg-of
                                       (frozen-callee-z bytes sp pc clen status result)
                                       (frozen-one (frozen-inner-label-instr-done status)))))))))

(defthm frozen-ctxt-sixth
  (implies (and (unsigned-byte-p 32 status)
                (equal (w3t::step
                        (frozen-cfg-of z (frozen-one (frozen-inner-label-instr-done status))))
                       (list (frozen-cfg-of z2 (frozen-ret-instrs status)))))
           (equal (w3t::step/r-ctxt-instrs
                   (frozen-cfg-of z (frozen-inner-label-body-done status)))
                  (list (frozen-cfg-of z2 (frozen-ret-body status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-cfg-of z (frozen-inner-label-body-done status))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (frozen-inner-label-body-done status))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (frozen-cfg-of z (frozen-inner-label-body-done status))))))))

(defthm frozen-step-body-sixth
  (implies (and (unsigned-byte-p 32 status)
                (equal (w3t::step/r-ctxt-instrs
                        (frozen-cfg-of z (frozen-inner-label-body-done status)))
                       (list (frozen-cfg-of z2 (frozen-ret-body status)))))
           (equal (w3t::step (frozen-cfg-of z (frozen-inner-label-body-done status)))
                  (list (frozen-cfg-of z2 (frozen-ret-body status)))))
  :hints (("Goal"
           :expand ((w3t::step
                     (frozen-cfg-of z (frozen-inner-label-body-done status)))))))

(defthm frozen-label-sixth
  (implies (equal (w3t::step (frozen-cfg-of z (frozen-inner-label-body-done status)))
                  (list (frozen-cfg-of z2 (frozen-ret-body status))))
           (equal (w3t::step
                   (frozen-cfg-of z (frozen-label-instr
                                     (frozen-inner-label-body-done status))))
                  (list (frozen-cfg-of z2
                                       (frozen-label-instr (frozen-ret-body status))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (frozen-cfg-of
                                       z (frozen-label-instr
                                          (frozen-inner-label-body-done status)))))))))

(defthm frozen-frame-sixth
  (implies (equal (w3t::step
                   (frozen-cfg-of (list :|%;%| s f-prime)
                                  (frozen-label-instr
                                   (frozen-inner-label-body-done status))))
                  (list (frozen-cfg-of
                         (list :|%;%| s2 f2)
                         (frozen-label-instr (frozen-ret-body status)))))
           (equal (w3t::step
                   (frozen-cfg-of
                    (list :|%;%| s f)
                    (frozen-frame-instr
                     f-prime
                     (frozen-label-instr (frozen-inner-label-body-done status)))))
                  (list (frozen-cfg-of
                         (list :|%;%| s2 f)
                         (frozen-frame-instr
                          f2
                          (frozen-label-instr (frozen-ret-body status)))))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (frozen-cfg-of
                                       (list :|%;%| s f)
                                       (frozen-frame-instr
                                        f-prime
                                        (frozen-label-instr
                                         (frozen-inner-label-body-done status))))))))))

(defthm frozen-step-sixth
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-body-cfg bytes sp pc clen status result
                                    (frozen-inner-label-body-done status)))
                  (list (frozen-body-cfg bytes sp pc clen status result
                                         (frozen-ret-body status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance frozen-frame-sixth
                            (s (frozen-store bytes sp pc clen status result))
                            (f (milawa-callee-frame 6))
                            (f-prime (milawa-callee-frame 6))
                            (s2 (frozen-store bytes sp pc clen status result))
                            (f2 (milawa-callee-frame 6)))
                 (:instance frozen-label-sixth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-step-body-sixth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 (:instance frozen-ctxt-sixth
                            (z (frozen-callee-z bytes sp pc clen status result))
                            (z2 (frozen-callee-z bytes sp pc clen status result)))
                 frozen-step-inner-return))))

;; ---------------------------------------------------------------------------
;; Step 8 of nine: the outer label's return
;; ---------------------------------------------------------------------------

; The outer label's body is (CONST STATUS) (RETURN) followed by the rest of the
; module's body.  Step_pure/return-label's search finds the return at index 1
; and returns val* ++ (return) -- DROPPING everything after it, which is the
; rest of the module's body.  So the label is consumed and the frame is left
; holding just the two instructions.
(defthm frozen-step-inner-label-return
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                                  (frozen-label-instr (frozen-ret-body status))))
                  (list (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                                       (frozen-ret-instrs status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance step-pure-return-out-of-label
                            (n 1) (is0 nil) (x status))
                 (:instance (:definition w3t::step_pure/search141)
                            (w3t::%k 2) (w3t::%lo 2)
                            (w3t::%hi (len (frozen-ret-body status)))
                            (w3t::%t130 (frozen-ret-body status))))
           :expand ((w3t::step
                     (frozen-cfg-of (frozen-callee-z bytes sp pc clen status result)
                                    (frozen-label-instr (frozen-ret-body status))))))))

(defthm frozen-step-seventh
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-body-cfg bytes sp pc clen status result
                                    (frozen-ret-body status)))
                  (list (frozen-frame-cfg bytes sp pc clen status result
                                          (frozen-ret-instrs status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (frozen-body-cfg
                                       bytes sp pc clen status result
                                       (frozen-ret-body status))))
                 frozen-step-inner-label-return))))

;; ---------------------------------------------------------------------------
;; Step 9 of nine: the frame's return
;; ---------------------------------------------------------------------------

; The frame rule's search sees val* (RETURN) at the end, with exactly the
; frame's arity (1) values before it, and answers val* -- the frame itself and
; the :RETURN both go.  What survives is the callee's result, pushed into the
; caller's instruction list: one (:CONST (:I32) STATUS).
(defthm frozen-step-eighth
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-frame-cfg bytes sp pc clen status result
                                     (frozen-ret-instrs status)))
                  (list (frozen-cfg bytes sp pc clen status result
                                    (frozen-result-instrs status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance step-pure-return-out-of-frame (x status))
                 (:instance (:definition w3t::step/r-pure)
                            (w3t::%a0 (frozen-frame-cfg
                                       bytes sp pc clen status result
                                       (frozen-ret-instrs status))))))))

; A lone value is not an instruction: the machine has stopped.
(defthm frozen-step-stuck
  (implies (unsigned-byte-p 32 status)
           (equal (w3t::step
                   (frozen-cfg bytes sp pc clen status result
                               (frozen-result-instrs status)))
                  nil))
  :hints (("Goal"
           :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (frozen-cfg
                                       bytes sp pc clen status result
                                       (frozen-result-instrs status))))))))

;; ---------------------------------------------------------------------------
;; The branch's guard, and the step count that follows from the chain
;; ---------------------------------------------------------------------------

; The frozen test is (not (= status 1)), so the comparison's value is 1.  This
; is the one fact about the values (as opposed to the shapes) in the whole path.
(defthm relop-ne-of-status-and-1
  (implies (and (unsigned-byte-p 32 status) (not (equal status 1)))
           (equal (w3t::$relop_ (list :i32) (list :ne) status 1) 1)))

; WHY THE COMPOSITION NEEDS THESE TWO AND NOT A :REWRITE RULE.  STEPS/%FUEL
; unrolls on its FUEL argument, and ACL2 will not unroll it here: the argument
; is a constant, but the configuration is opaque, so the executable counterpart
; cannot evaluate it and the definition rule is not applied by itself.  A
; :REWRITE rule whose conclusion reduces the fuel would be exactly the
; fuel-decreasing rule the project has already been burned by (it loops), so
; these are :RULE-CLASSES NIL and are used through :USE, one per step.  The
; definition instance is what makes each one a single unfolding.
(defthm steps-fuel-succ-of-a-step
  (implies (equal (w3t::step c) (list c+))
           (equal (w3t::steps/%fuel (1+ n) c) (w3t::steps/%fuel n c+)))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use ((:instance (:definition w3t::steps/%fuel)
                            (w3t::%fuel (1+ n)) (w3t::%a0 c))))))

(defthm steps-fuel-one-when-stuck
  (implies (equal (w3t::step c) nil)
           (equal (w3t::steps/%fuel 1 c) (list c)))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (disable w3t::step)
           :use ((:instance (:definition w3t::steps/%fuel)
                            (w3t::%fuel 1) (w3t::%a0 c))))))

;; ---------------------------------------------------------------------------
;; THE FROZEN PATH
;; ---------------------------------------------------------------------------
;
; Nine steps from the entry configuration, and a tenth fuel to discover that
; the machine has stopped.  This is the symbolic form of abs.lisp's
; (milawa-step-check 9 st) for the states whose status is not 1 (the halted and
; aborted ones, and every other non-running status the module can be handed).
;
; The configuration it stops on is the abstract store, UNCHANGED, with the
; status pushed back into the caller's instruction list: the module's answer is
; the status it was given.  That is the whole of the frozen path.
(defthm frozen-path-ten
  (implies (and (unsigned-byte-p 32 status) (not (equal status 1)))
           (equal (w3t::steps/%fuel 10 (mvm-abs-abstract bytes sp pc clen status result))
                  (list (frozen-cfg bytes sp pc clen status result
                                    (frozen-result-instrs status)))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                               mvm-abs-abstract mvm-abs-z-abstract
                               frozen-body-cfg frozen-cfg frozen-z frozen-store
                               frozen-callee-z frozen-frame-cfg frozen-cfg-of
                               frozen-one frozen-frame-instr frozen-label-instr
                               frozen-block-body frozen-inner-label-body
                               frozen-inner-label-body-done frozen-ret-body
                               frozen-third-body frozen-result-instrs
                               frozen-ret-instrs frozen-inner-label-instr
                               frozen-inner-label-instr-done frozen-block-instr
                               milawa-callee-frame)
           :use ((:instance steps-fuel-succ-of-a-step
                            (n 9)
                            (c (mvm-abs-abstract bytes sp pc clen status result))
                            (c+ (frozen-body-cfg bytes sp pc clen status result *body-6*)))
                 (:instance steps-fuel-succ-of-a-step
                            (n 8)
                            (c (frozen-body-cfg bytes sp pc clen status result *body-6*))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (cons (list :const (list :i32) status)
                                                       (cdr *body-6*)))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 7)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (cons (list :const (list :i32) status)
                                                      (cdr *body-6*))))
                            (c+ (frozen-body-cfg
                                 bytes sp pc clen status result
                                 (frozen-third-body
                                  (w3t::$relop_ (list :i32) (list :ne) status 1)))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 6)
                            (c (frozen-body-cfg
                                bytes sp pc clen status result
                                (frozen-third-body
                                 (w3t::$relop_ (list :i32) (list :ne) status 1))))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-block-body))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 5)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-block-body)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-inner-label-body))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 4)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-inner-label-body)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-inner-label-body-done status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 3)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-inner-label-body-done status)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-ret-body status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 2)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-ret-body status)))
                            (c+ (frozen-frame-cfg bytes sp pc clen status result
                                                  (frozen-ret-instrs status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 1)
                            (c (frozen-frame-cfg bytes sp pc clen status result
                                                 (frozen-ret-instrs status)))
                            (c+ (frozen-cfg bytes sp pc clen status result
                                            (frozen-result-instrs status))))
                 (:instance steps-fuel-one-when-stuck
                            (c (frozen-cfg bytes sp pc clen status result
                                           (frozen-result-instrs status))))
                 (:instance frozen-step-entry)
                 (:instance frozen-step-first)
                 (:instance frozen-step-second)
                 (:instance frozen-step-third
                            (c (w3t::$relop_ (list :i32) (list :ne) status 1)))
                 (:instance frozen-step-fourth)
                 (:instance frozen-step-fifth)
                 (:instance frozen-step-sixth)
                 (:instance frozen-step-seventh)
                 (:instance frozen-step-eighth)
                 (:instance frozen-step-stuck)
                 relop-ne-of-status-and-1))))

; And the other half of the clock: the nine steps SPEND the nine fuel, which is
; why steps/%fuel needs a tenth to report the stopped configuration.  Same
; chain, one fewer step and no stuck fact.
(defthm frozen-path-nine
  (implies (and (unsigned-byte-p 32 status) (not (equal status 1)))
           (null (w3t::steps/%fuel 9 (mvm-abs-abstract bytes sp pc clen status result))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                               mvm-abs-abstract mvm-abs-z-abstract
                               frozen-body-cfg frozen-cfg frozen-z frozen-store
                               frozen-callee-z frozen-frame-cfg frozen-cfg-of
                               frozen-one frozen-frame-instr frozen-label-instr
                               frozen-block-body frozen-inner-label-body
                               frozen-inner-label-body-done frozen-ret-body
                               frozen-third-body frozen-result-instrs
                               frozen-ret-instrs frozen-inner-label-instr
                               frozen-inner-label-instr-done frozen-block-instr
                               milawa-callee-frame)
           :use ((:instance steps-fuel-succ-of-a-step
                            (n 8)
                            (c (mvm-abs-abstract bytes sp pc clen status result))
                            (c+ (frozen-body-cfg bytes sp pc clen status result *body-6*)))
                 (:instance steps-fuel-succ-of-a-step
                            (n 7)
                            (c (frozen-body-cfg bytes sp pc clen status result *body-6*))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (cons (list :const (list :i32) status)
                                                       (cdr *body-6*)))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 6)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (cons (list :const (list :i32) status)
                                                      (cdr *body-6*))))
                            (c+ (frozen-body-cfg
                                 bytes sp pc clen status result
                                 (frozen-third-body
                                  (w3t::$relop_ (list :i32) (list :ne) status 1)))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 5)
                            (c (frozen-body-cfg
                                bytes sp pc clen status result
                                (frozen-third-body
                                 (w3t::$relop_ (list :i32) (list :ne) status 1))))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-block-body))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 4)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-block-body)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-inner-label-body))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 3)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-inner-label-body)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-inner-label-body-done status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 2)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-inner-label-body-done status)))
                            (c+ (frozen-body-cfg bytes sp pc clen status result
                                                 (frozen-ret-body status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 1)
                            (c (frozen-body-cfg bytes sp pc clen status result
                                                (frozen-ret-body status)))
                            (c+ (frozen-frame-cfg bytes sp pc clen status result
                                                  (frozen-ret-instrs status))))
                 (:instance steps-fuel-succ-of-a-step
                            (n 0)
                            (c (frozen-frame-cfg bytes sp pc clen status result
                                                 (frozen-ret-instrs status)))
                            (c+ (frozen-cfg bytes sp pc clen status result
                                            (frozen-result-instrs status))))
                 (:instance frozen-step-entry)
                 (:instance frozen-step-first)
                 (:instance frozen-step-second)
                 (:instance frozen-step-third
                            (c (w3t::$relop_ (list :i32) (list :ne) status 1)))
                 (:instance frozen-step-fourth)
                 (:instance frozen-step-fifth)
                 (:instance frozen-step-sixth)
                 (:instance frozen-step-seventh)
                 (:instance frozen-step-eighth)
                 relop-ne-of-status-and-1))))

;; ---------------------------------------------------------------------------
;; The readback, halfway: the globals
;; ---------------------------------------------------------------------------

; L1's conclusion is MILAWA-OBSERVATIONS on the configuration the semantics
; stops on.  This path leaves the abstract store unchanged, so the five globals
; read back by evaluation: the store's :GLOBALS list was built by MILAWA-SET-GLOBALS
; from SP PC CLEN STATUS RESULT, and MILAWA-GLOBAL reaches them through the
; pinned frame's module vector.  The sixth clause -- the stack words -- is the
; one that is not here; see the note in SUMMARY.md, "the readback of the stopped
; store": MILAWA-WORDS walks the memory an index at a time and MVM-IMAGE-WORDS
; consumes four bytes a step, and relating the two by rewrite rules runs into
; ACL2's arithmetic matcher (a rule about (NTHCDR (+ 4 A) L) is applied to its
; own right-hand side with A bound to 0).  That is a statement problem of the
; same kind MEMORY.LISP solved for the word-list image, and it is the next
; piece, not a missing fact.
(defthm frozen-globals-read-back
  (and (equal (milawa-global (frozen-z bytes sp pc clen status result) 0) sp)
       (equal (milawa-global (frozen-z bytes sp pc clen status result) 1) pc)
       (equal (milawa-global (frozen-z bytes sp pc clen status result) 2) clen)
       (equal (milawa-global (frozen-z bytes sp pc clen status result) 3) status)
       (equal (milawa-global (frozen-z bytes sp pc clen status result) 4) result)))

;; ---------------------------------------------------------------------------
;; The readback, the other half: the machinery for the stack words
;; ---------------------------------------------------------------------------
;
; The remaining clause of MILAWA-OBSERVATIONS is
;
;   (milawa-words Z 0 (len stack)) = (revappend stack nil)
;
; and the route to it is the one MEMORY.LISP took for the word-list image:
; work with the APPEND form of the image, not with an index into it.  The
; lemmas below are that machinery, all proved.  What they add up to is:
;
;   * a read at a prefix boundary -- (nth (+ i (len pre)) (append pre b))
;     is (nth i b) -- proved through NTHCDR, not by unfolding NTH at a
;     symbolic index (doing the latter diverges: NTH's definition recurses
;     on the index);
;   * the byte sum the abstract word reader computes is the word --
;     (loghead 8 w), (loghead 8 (logtail 8 w)), ... with weights 256^i --
;     via LOGAPP, the byte decoder of memory.lisp, and the round trip
;     MVM-BYTES-TO-WORD-OF-WORD-TO-BYTES;
;   * and MILAWA-WORD-AT-OF-IMAGE, which is the per-word read:
;     at offset (len pre), the abstract reader on
;     (append pre (mvm-word-to-bytes w) rest) is w.
;
; WHAT IS NOT HERE is the induction that puts these together over a word
; list: MILAWA-WORDS-OF-WORD-LIST-IMAGE.  Its step needs the hypothesis at
; the SHIFTED prefix (append pre (word-to-bytes (car ws))), so the induction
; scheme has to shift the prefix with the list (see BRIDGE-INDUCT below), and
; the remaining work is getting that scheme's hypotheses to line up with the
; append associativity and the (len ...) arithmetic.  The state of that
; attempt is recorded in SUMMARY.md, "the readback of the stopped store".

(defthm loghead-8-when-byte
  (implies (and (integerp b) (<= 0 b) (< b 256))
           (equal (loghead 8 b) b))
  :hints (("Goal" :in-theory (disable loghead)
           :use ((:instance loghead-identity (size 8) (i b))))))
(defthm logapp-four-bytes
  (implies (mvm-bytes-p (list b0 b1 b2 b3))
           (equal (mvm-bytes4-to-word b0 b1 b2 b3)
                  (+ b0 (* 256 b1) (* 65536 b2) (* 16777216 b3))))
  :hints (("Goal" :in-theory (e/d (mvm-bytes4-to-word logapp expt2) (loghead)))))
(defthm sum-of-bytes-is-word
  (implies (unsigned-byte-p 32 w)
           (equal (+ (loghead 8 w) (* 256 (loghead 8 (logtail 8 w)))
                     (* 65536 (loghead 8 (logtail 16 w)))
                     (* 16777216 (loghead 8 (logtail 24 w))))
                  w))
  :hints (("Goal"
           :in-theory (disable loghead logtail logapp)
           :use ((:instance logapp-four-bytes
                            (b0 (loghead 8 w))
                            (b1 (loghead 8 (logtail 8 w)))
                            (b2 (loghead 8 (logtail 16 w)))
                            (b3 (loghead 8 (logtail 24 w))))
                 (:instance mvm-bytes-to-word-of-word-to-bytes (w w))))))
; The three NTH/NTHCDR facts are :RULE-CLASSES NIL on purpose.  As rewrite
; rules they are exactly the kind that loops here: ACL2's arithmetic matcher
; can bind a = 0 and apply a rule about (+ 4 a) to its own right-hand side.
; They are used through :USE, one instance at a time.
(defthm nth-is-car-of-nthcdr
  (equal (nth n l) (car (nthcdr n l)))
  :rule-classes nil)
(defthm nthcdr-of-plus
  (implies (and (natp a) (natp b))
           (equal (nthcdr (+ a b) l) (nthcdr b (nthcdr a l))))
  :rule-classes nil
  :hints (("Goal" :induct (nthcdr a l))))
(defthm nthcdr-of-len-of-append
  (implies (true-listp a)
           (equal (nthcdr (len a) (append a b)) b))
  :hints (("Goal" :induct (len a))))
(defthm nth-of-append-len
  (implies (and (true-listp a) (natp i))
           (equal (nth (+ i (len a)) (append a b)) (nth i b)))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (disable nth)
           :use ((:instance nth-is-car-of-nthcdr (l (append a b)))
                 (:instance nth-is-car-of-nthcdr (l b))
                 (:instance nthcdr-of-plus (a (len a)) (b i) (l (append a b)))
                 nthcdr-of-len-of-append))))
(defthm milawa-word-at-of-image
  (implies (and (unsigned-byte-p 32 w) (true-listp pre))
           (equal (milawa-word-at
                   (frozen-z (append pre (append (mvm-word-to-bytes w) rest))
                             sp pc clen status result)
                   (len pre))
                  w))
  :hints (("Goal"
           :in-theory (disable nth)
           :use ((:instance nth-of-append-len (a pre) (b (append (mvm-word-to-bytes w) rest)) (i 0))
                 (:instance nth-of-append-len (a pre) (b (append (mvm-word-to-bytes w) rest)) (i 1))
                 (:instance nth-of-append-len (a pre) (b (append (mvm-word-to-bytes w) rest)) (i 2))
                 (:instance nth-of-append-len (a pre) (b (append (mvm-word-to-bytes w) rest)) (i 3))
                 (:instance sum-of-bytes-is-word (w w))))))

; The induction the remaining bridge needs: the prefix grows by one word's bytes
; exactly as the word list shrinks, and (len pre) is returned in the base case
; only to keep PRE from being an irrelevant formal.
(defun bridge-induct (pre ws)
  (declare (xargs :measure (len ws)))
  (if (consp ws)
      (bridge-induct (append pre (mvm-word-to-bytes (car ws))) (cdr ws))
    (len pre)))
