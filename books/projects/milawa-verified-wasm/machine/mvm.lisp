; Milawa-Lisp, part 7: MVM, the machine milawa-verified.wasm implements.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This book is the ACL2 model of the hand-written module in ../wasm/
; milawa-verified.wat.  The module is the artifact that ships; the proofs are
; about this model; L1 is the theorem that ties them together, and it is what
; makes the model worth having.
;
; The model is deliberately a transliteration, not a tidy-up.  Every check in the
; module appears here in the same order, because L1 has to walk the module's
; instruction sequence and show it computes this function: a model that is
; cleaner than the module would make that proof harder, not easier.
;
; STATE.  (STATUS PC STACK RESULT CODE), where
;
;   STATUS  0 = halted with a result, 1 = running, 2 = aborted
;   PC      index of the next code word (the module keeps a BYTE address; the
;           correspondence is 4*PC + 4096, and the code region is word-indexed
;           here)
;   STACK   list of 32-bit words, most recent first
;   RESULT  valid when STATUS is 0
;   CODE    list of code words
;
; Values on the stack are 32-bit unsigned words, because that is what the module
; stores: i32.add and i32.sub wrap, and i32.lt_s compares signed.  Modelling that
; honestly costs three small functions and means the model does not quietly
; assume bignums the module does not have.

(in-package "ACL2")

;; ---------------------------------------------------------------------------
;; 32-bit arithmetic, as the module has it
;; ---------------------------------------------------------------------------

(defun mvm-u32 (x)
  (declare (xargs :guard (integerp x)))
  (logand x #xFFFFFFFF))

(defun mvm-s32 (x)
  (declare (xargs :guard (integerp x)))
  (if (< (mvm-u32 x) #x80000000)
      (mvm-u32 x)
    (- (mvm-u32 x) #x100000000)))

(defun mvm-wordp (x)
  (declare (xargs :guard t))
  (and (integerp x)
       (<= 0 x)
       (< x #x100000000)))

(defun mvm-word-listp (x)
  (declare (xargs :guard t))
  (if (consp x)
      (and (mvm-wordp (car x))
           (mvm-word-listp (cdr x)))
    (equal x nil)))

(defun mvm-statep (st)
  (declare (xargs :guard t))
  (and (true-listp st)
       (equal (len st) 5)
       (let ((status (nth 0 st))
             (pc (nth 1 st))
             (stack (nth 2 st))
             (result (nth 3 st))
             (code (nth 4 st)))
         (and (member-equal status '(0 1 2))
              (natp pc)
              (mvm-word-listp stack)
              (mvm-wordp result)
              (mvm-word-listp code)))))

;; ---------------------------------------------------------------------------
;; The opcodes, as the module numbers them
;; ---------------------------------------------------------------------------

(defconst *mvm-halt* 0)
(defconst *mvm-const* 1)
(defconst *mvm-add* 2)
(defconst *mvm-sub* 3)
(defconst *mvm-lt* 4)
(defconst *mvm-ifz* 5)
(defconst *mvm-jmp* 6)

(defun mvm-make-state (status pc stack result code)
  (declare (xargs :guard t))
  (list status pc stack result code))

; The accessors read a five-element list, so their guards cannot be verified from
; :GUARD T -- NTH needs the list to be long enough -- and the machine's own
; functions carry :VERIFY-GUARDS NIL for the same reason.  (NTH is total, so the
; logic is unaffected: on a malformed state these return NIL.)

(defun mvm-status (st) (declare (xargs :guard t :verify-guards nil)) (nth 0 st))
(defun mvm-pc (st) (declare (xargs :guard t :verify-guards nil)) (nth 1 st))
(defun mvm-stack (st) (declare (xargs :guard t :verify-guards nil)) (nth 2 st))
(defun mvm-result (st) (declare (xargs :guard t :verify-guards nil)) (nth 3 st))
(defun mvm-code (st) (declare (xargs :guard t :verify-guards nil)) (nth 4 st))

(defun mvm-haltedp (st)
  (declare (xargs :guard t :verify-guards nil))
  (equal (mvm-status st) 0))

(defun mvm-runningp (st)
  (declare (xargs :guard t :verify-guards nil))
  (equal (mvm-status st) 1))

(defun mvm-abortedp (st)
  (declare (xargs :guard t :verify-guards nil))
  (equal (mvm-status st) 2))

; Replacing the mutable parts, leaving status alone.  The module sets SP/PC/
; RESULT/STACK and returns the status; these mirror that.

(defun mvm-with-pc (pc st)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-make-state (mvm-status st) pc (mvm-stack st) (mvm-result st)
                  (mvm-code st)))

(defun mvm-with-stack (stack st)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-make-state (mvm-status st) (mvm-pc st) stack (mvm-result st)
                  (mvm-code st)))

(defun mvm-with-status-result (status result st)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-make-state status (mvm-pc st) (mvm-stack st) result (mvm-code st)))

(defun mvm-abort (st)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-make-state 2 (mvm-pc st) (mvm-stack st) (mvm-result st) (mvm-code st)))

(defun mvm-in-codep (pc st)
  (declare (xargs :guard t :verify-guards nil))
  (< pc (len (mvm-code st))))

;; ---------------------------------------------------------------------------
;; One step
;;
;; The order of the checks is the module's order: frozen status, then the bound
;; on the instruction word, then the dispatch, then -- for the opcodes that read
;; an immediate -- the bound again.  PC advances before the dispatch, exactly as
;; the module does, which is why the abort cases below keep the advanced PC.
;; ---------------------------------------------------------------------------

(defun mvm-step (st)
  (declare (xargs :guard t
                  :verify-guards nil))
  (if (not (mvm-runningp st))
      ;; A halted or aborted machine stays that way.
      st
    (let ((pc (mvm-pc st)))
      (if (not (mvm-in-codep pc st))
          ;; Running off the end of the code is a malformed program.
          (mvm-abort st)
        (let* ((op (nth pc (mvm-code st)))
               (pc1 (+ 1 pc))
               (stack (mvm-stack st))
               (st1 (mvm-with-pc pc1 st)))
          (cond
           ;; HALT: stop, with the top of the stack as the result.
           ((equal op *mvm-halt*)
            (if (not (consp stack))
                (mvm-abort st1)
              (mvm-with-status-result 0 (car stack)
                                      (mvm-with-stack (cdr stack) st1))))
           ;; CONST k: push the immediate.
           ((equal op *mvm-const*)
            (if (not (mvm-in-codep pc1 st1))
                (mvm-abort st1)
              (let ((imm (nth pc1 (mvm-code st1))))
                (mvm-with-pc (+ 1 pc1)
                             (mvm-with-stack (cons imm stack) st1)))))
           ;; ADD / SUB / LT: pop two, push one.
           ((member-equal op (list *mvm-add* *mvm-sub* *mvm-lt*))
            (if (< (len stack) 2)
                (mvm-abort st1)
              (let* ((b (car stack))
                     (a (car (cdr stack)))
                     (v (cond ((equal op *mvm-add*) (mvm-u32 (+ a b)))
                              ((equal op *mvm-sub*) (mvm-u32 (- a b)))
                              (t (if (< (mvm-s32 a) (mvm-s32 b)) 1 0)))))
                (mvm-with-stack (cons v (cdr (cdr stack))) st1))))
           ;; IFZ k: pop; jump to word k when it was zero.
           ((equal op *mvm-ifz*)
            (if (not (mvm-in-codep pc1 st1))
                (mvm-abort st1)
              (let ((imm (nth pc1 (mvm-code st1)))
                    (st2 (mvm-with-pc (+ 1 pc1) st1)))
                (cond ((not (consp stack)) (mvm-abort st2))
                      ((equal (car stack) 0)
                       (mvm-with-pc imm (mvm-with-stack (cdr stack) st2)))
                      (t (mvm-with-stack (cdr stack) st2))))))
           ;; JMP k: jump to word k.
           ((equal op *mvm-jmp*)
            (if (not (mvm-in-codep pc1 st1))
                (mvm-abort st1)
              (mvm-with-pc (nth pc1 (mvm-code st1)) st1)))
           ;; Unknown opcode: abort rather than guess.
           (t (mvm-abort st1))))))))

;; ---------------------------------------------------------------------------
;; Running
;;
;; The host loop asks for a step until the machine stops.  That is what
;; MILAWA-RUNS does for the interpreter, with the same notion of what the count
;; means, so the two are comparable.
;; ---------------------------------------------------------------------------

(defun mvm-run (st fuel)
  (declare (xargs :measure (nfix fuel)))
  (if (or (zp fuel)
          (not (mvm-runningp st)))
      st
    (mvm-run (mvm-step st) (1- fuel))))

(defun mvm-steps (st fuel)
  (declare (xargs :measure (nfix fuel)))
  (if (or (zp fuel)
          (not (mvm-runningp st)))
      0
    (+ 1 (mvm-steps (mvm-step st) (1- fuel)))))

;; ---------------------------------------------------------------------------
;; A stopped machine is a fixed point
;;
;; This is the property the host loop relies on: once STEP answers 0 or 2, asking
;; again cannot change the answer, so a driver that keeps asking cannot restart
;; the machine or lose a result.  It is the MVM analogue of the abort/acceptance
;; disjointness proved for the interpreter in milawa-lisp/metatheory.lisp.
;; ---------------------------------------------------------------------------

(defthm mvm-step-of-halted
  (implies (mvm-haltedp st)
           (equal (mvm-step st) st))
  :hints (("Goal" :in-theory (enable mvm-step mvm-haltedp mvm-runningp))))

(defthm mvm-step-of-aborted
  (implies (mvm-abortedp st)
           (equal (mvm-step st) st))
  :hints (("Goal" :in-theory (enable mvm-step mvm-abortedp mvm-runningp))))

(defthm mvm-run-is-idempotent-on-stopped
  (implies (not (mvm-runningp st))
           (equal (mvm-run st fuel) st))
  :hints (("Goal" :in-theory (enable mvm-run))))

;; ---------------------------------------------------------------------------
;; Fuel is a budget, not a part of the answer
;;
;; Two facts the run level needs.  The first bounds the steps actually spent by
;; the budget.  The second is the one that matters: once the machine has stopped
;; inside the budget, a larger budget changes nothing -- so the host loop's
;; stopping point is a property of the program, not of how patient the driver was.
;; ---------------------------------------------------------------------------

(defthm mvm-steps-bounded-by-fuel
  (<= (mvm-steps st fuel) (nfix fuel))
  :rule-classes :linear)

; STILL TO PROVE, and deliberately not faked: once the machine has stopped inside
; the budget, a larger budget changes nothing --
;
;   (implies (not (mvm-runningp (mvm-run st n)))
;            (equal (mvm-run st (+ n k)) (mvm-run st n)))
;
; The obvious statement does not go through by the induction ACL2 picks: the
; budget has to be split so that the hypothesis about N is available at the
; point where the extra K is spent, which wants the "run of n then k is run of
; n+k" decomposition proved first, by induction on K, with the fixed-point lemma
; above as the base case.  It is needed for L2 (the run-level theorem compares an
; exact number of steps against a fuelled loop) and is the next thing to do here,
; not a gap in the argument.
