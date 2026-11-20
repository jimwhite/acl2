; Milawa-Lisp, part 6: the run relation.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; MILAWA-RUNS C N R FTBL says: from configuration C the machine takes EXACTLY N
; steps and stops with result R.  It is the two inference rules below, read as a
; function:
;
;   halt: C's next step already finishes, so one step suffices.
;   step: C's next step continues to C2, and C2 reaches R in N steps.
;
; The only difference from an inductive presentation is that the continuation C2
; is named by (CDR S) rather than being existentially quantified, which is what
; the machine gives you anyway: a continuing step returns (:RUN . C2).
;
; "EXACTLY N" matters.  MILAWA-RUN stops the moment it produces a result, so
; (MILAWA-CONF-RUN C FTBL N) answers for every N at least as large as the number
; of steps taken; a relation defined from it would say that a halting machine
; "runs" in any number of steps.  The definition below spends its count instead,
; so it is exact, and it is what a WASM STEP derivation gives you.
;
; WHY NOT DEFINDUCTIVE?  An earlier version defined the relation with
; std/util's DEFINDUCTIVE (Coglio and Jurgensen, ACL2 Workshop 2026), which
; takes exactly the two rules above and generates the predicate, the intro rules
; and an elimination principle.  It certified, but the elimination principle was
; unusable: DEFINDUCTIVE admits the predicate over a *proof object*, so its
; induction scheme's step case is stated in terms of MILAWA-RUNS-PROOF-KIND and
; MILAWA-RUNS-PROOF-STEP->C2 rather than the rule's premises, and the only way
; back to the premises is the ALT rule, whose functional instantiation re-proves
; the source theorem by induction on that proof object.  Measured: over a
; quarter of an hour, and it had not finished.  The function below gives the
; same facts in milliseconds and, being a plain recursion on the step count,
; hands ACL2 exactly the halt/step induction that a refinement proof wants.
; (The DEFINDUCTIVE version is in the history at commit 4814380c1b.)

(in-package "MILAWA-WASM")

(include-book "metatheory")

;; ---------------------------------------------------------------------------
;; Configurations
;; ---------------------------------------------------------------------------

(defun milawa-conf (mode obj env stack)
  (declare (xargs :guard t))
  (list mode obj env stack))

(defun milawa-conf-step (c ftbl)
  (declare (xargs :guard t
                  :verify-guards nil))
  (milawa-step (nth 0 c) (nth 1 c) (nth 2 c) (nth 3 c) ftbl))

(defun milawa-conf-run (c ftbl n)
  (declare (xargs :guard t
                  :verify-guards nil))
  (milawa-run (nth 0 c) (nth 1 c) (nth 2 c) (nth 3 c) ftbl n))

(defthm milawa-conf-run-of-make-conf
  (equal (milawa-conf-run (milawa-conf mode obj env stack) ftbl n)
         (milawa-run mode obj env stack ftbl n))
  :hints (("Goal" :in-theory (enable milawa-conf-run milawa-conf))))

(defthm milawa-conf-step-of-make-conf
  (equal (milawa-conf-step (milawa-conf mode obj env stack) ftbl)
         (milawa-step mode obj env stack ftbl))
  :hints (("Goal" :in-theory (enable milawa-conf-step milawa-conf))))

;; ---------------------------------------------------------------------------
;; The run relation
;; ---------------------------------------------------------------------------

; A count must be a positive integer: zero steps is not a run.

(defun milawa-runs (c n r ftbl)
  (declare (xargs :measure (nfix n)
                  :guard t
                  :verify-guards nil))
  (and (integerp n)
       (< 0 n)
       (let ((s (milawa-conf-step c ftbl)))
         (if (equal (car s) :run)
             (milawa-runs (cdr s) (1- n) r ftbl)
           (and (equal n 1)
                (equal r s))))))

;; ---------------------------------------------------------------------------
;; The inference rules
;;
;; The two rules the relation is built from, stated as rewrite rules.  These are
;; what L1 compares a WASM module's per-instruction STEP rules against: the
;; shapes and the exact step counts are the same.  The step rule has a free
;; variable (the continuation), so it is a rule to :USE, not to backchain.
;; ---------------------------------------------------------------------------

(defthm milawa-runs-halt
  (implies (not (equal (car (milawa-conf-step c ftbl)) :run))
           (milawa-runs c 1 (milawa-conf-step c ftbl) ftbl))
  :hints (("Goal" :in-theory (e/d (milawa-runs)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

(defthm milawa-runs-step
  (implies (and (equal (milawa-conf-step c ftbl) (cons :run c2))
                (milawa-runs c2 n r ftbl))
           (milawa-runs c (+ 1 n) r ftbl))
  :hints (("Goal" :in-theory (e/d (milawa-runs)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

;; ---------------------------------------------------------------------------
;; Shape: the elimination principle
;;
;; What a caller may assume on the way IN to a run, i.e. the case analysis a
;; refinement proof performs.  Because the relation is a function of the exact
;; step count there is no proof tree to eliminate; this is the definition, and
;; it is also the induction scheme ACL2 uses for MILAWA-RUNS.
;; ---------------------------------------------------------------------------

(defthm milawa-runs-positive
  (implies (milawa-runs c n r ftbl)
           (and (integerp n)
                (< 0 n)))
  :hints (("Goal" :induct (milawa-runs c n r ftbl)
                  :in-theory (e/d (milawa-runs)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

; The same fact as :FORWARD-CHAINING rules, because the shape lemma below needs
; it about BOTH the run it is given and, in the continuing case, the shorter run
; the definition hands it -- and a forward-chaining rule fires on each
; hypothesis of that shape, which a rewrite rule cannot do (the run it would
; have to recognise is a subterm the rewriter has not been asked about).

(defthm milawa-runs-positive-integerp
  (implies (milawa-runs c n r ftbl)
           (integerp n))
  :rule-classes :forward-chaining
  :hints (("Goal" :in-theory (enable milawa-runs-positive))))

(defthm milawa-runs-positive-lower-bound
  (implies (milawa-runs c n r ftbl)
           (< 0 n))
  :rule-classes :forward-chaining
  :hints (("Goal" :in-theory (enable milawa-runs-positive))))

(defthm milawa-runs-shape
  (implies (milawa-runs c n r ftbl)
           (let ((s (milawa-conf-step c ftbl)))
             (if (equal (car s) :run)
                 (and (< 1 n)
                      (milawa-runs (cdr s) (1- n) r ftbl))
               (and (equal n 1)
                    (equal r s)))))
  :hints (("Goal" :expand ((milawa-runs c n r ftbl))
                  :in-theory (disable milawa-runs
                                      milawa-conf-step milawa-step
                                      milawa-apply-or-run milawa-apply-step
                                      milawa-apply-primitive))))

;; ---------------------------------------------------------------------------
;; Stepping, for the agreement theorem with MILAWA-RUN
;;
;; MILAWA-RUN takes the machine's four arguments, but a step result packs them
;; into a list, so the loop reads them back with NTH.  These rewrites turn
;; (NTH i (CONS :RUN C2)) into (NTH (i-1) C2), which lets the loop's next
;; iteration be read as a run from C2.
;; ---------------------------------------------------------------------------

(defthm nth-of-cons-step
  (and (equal (nth 0 (cons x y)) x)
       (equal (nth 1 (cons x y)) (nth 0 y))
       (equal (nth 2 (cons x y)) (nth 1 y))
       (equal (nth 3 (cons x y)) (nth 2 y))
       (equal (nth 4 (cons x y)) (nth 3 y))))

; MILAWA-STEP stays DISABLED in both proofs below.  It is the term that appears
; in the hypothesis, and expanding it into its twenty branches turns one
; subgoal into a hundred.

(defthm milawa-conf-run-halt
  (implies (not (equal (car (milawa-conf-step c ftbl)) :run))
           (equal (milawa-conf-run c ftbl 1)
                  (milawa-conf-step c ftbl)))
  :hints (("Goal" :in-theory (e/d (milawa-conf-run milawa-conf-step
                                     milawa-conf)
                                  (milawa-step milawa-apply-or-run
                                   milawa-apply-step
                                   milawa-apply-primitive)))))

(defthm milawa-conf-run-step
  (implies (and (equal (milawa-conf-step c ftbl) (cons :run c2))
                (integerp n)
                (< 0 n))
           (equal (milawa-conf-run c ftbl (+ 1 n))
                  (milawa-conf-run c2 ftbl n)))
  :hints (("Goal" :in-theory (e/d (milawa-conf-run milawa-conf-step
                                     milawa-conf)
                                  (milawa-step milawa-apply-or-run
                                   milawa-apply-step
                                   milawa-apply-primitive)))))

; The same step fact phrased in CAR/CDR terms, because a caller that has split
; on (CAR S) does not have (CONS :RUN C2) any more -- and (CDR S) need not even
; be a proper list, since a malformed step result is just an atom there.

(defthm milawa-conf-run-of-run
  (implies (and (integerp n)
                (< 0 n)
                (equal (car (milawa-conf-step c ftbl)) :run))
           (equal (milawa-conf-run c ftbl n)
                  (milawa-conf-run (cdr (milawa-conf-step c ftbl))
                                   ftbl (1- n))))
  :hints (("Goal" :in-theory (e/d (milawa-conf-run milawa-conf-step
                                     milawa-conf)
                                  (milawa-step milawa-apply-or-run
                                   milawa-apply-step
                                   milawa-apply-primitive)))))

;; ---------------------------------------------------------------------------
;; Agreement with MILAWA-RUN
;;
;; MILAWA-RUN is given a fuel budget and stops as soon as it has a result, so its
;; answer is the same for every budget at least as large as the number of steps
;; actually taken.  MILAWA-RUNS spends its count exactly.  These two theorems say
;; the relation is about the same machine as the loop: a run of the relation is
;; what the loop computes (soundness), and whatever the loop computes is a run of
;; some count no larger than the budget (completeness).  MILAWA-STEPS recovers
;; how many steps the loop spent, which is what makes the second direction state
;; itself without an existential.
;; ---------------------------------------------------------------------------

(defun milawa-steps (c ftbl n)
  (declare (xargs :measure (nfix n)
                  :guard t
                  :verify-guards nil))
  (if (zp n)
      0
    (let ((s (milawa-conf-step c ftbl)))
      (if (equal (car s) :run)
          (+ 1 (milawa-steps (cdr s) ftbl (1- n)))
        1))))

; A halted machine answers immediately, whatever budget it was given.

(defthm milawa-conf-run-of-halt
  (implies (and (integerp n)
                (< 0 n)
                (not (equal (car (milawa-conf-step c ftbl)) :run)))
           (equal (milawa-conf-run c ftbl n)
                  (milawa-conf-step c ftbl)))
  :hints (("Goal" :in-theory (e/d (milawa-conf-run milawa-conf-step
                                     milawa-conf)
                                  (milawa-step milawa-apply-or-run
                                   milawa-apply-step
                                   milawa-apply-primitive)))))

; The loop spends at least one step whenever it has a budget, which is what
; keeps the degenerate continuations below from being taken seriously.

(defthm milawa-steps-positive
  (implies (not (zp n))
           (< 0 (milawa-steps c ftbl n)))
  :hints (("Goal" :induct (milawa-steps c ftbl n)
                  :in-theory (e/d (milawa-steps)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

; Soundness: the loop agrees with the relation at the relation's own count.

(defthm milawa-runs-implies-conf-run
  (implies (milawa-runs c n r ftbl)
           (equal (milawa-conf-run c ftbl n) r))
  :hints (("Goal" :induct (milawa-runs c n r ftbl)
                  :in-theory (e/d (milawa-runs
                                   milawa-conf-run-of-halt
                                   milawa-conf-run-of-run)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

; How MILAWA-STEPS spends a budget: one step when the machine has halted, and
; one step plus the rest when it continues.

(defthm milawa-steps-halt
  (implies (and (not (zp n))
                (not (equal (car (milawa-conf-step c ftbl)) :run)))
           (equal (milawa-steps c ftbl n) 1))
  :hints (("Goal" :in-theory (e/d (milawa-steps)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

(defthm milawa-steps-run
  (implies (and (not (zp n))
                (equal (car (milawa-conf-step c ftbl)) :run))
           (equal (milawa-steps c ftbl n)
                  (+ 1 (milawa-steps (cdr (milawa-conf-step c ftbl))
                                     ftbl (1- n)))))
  :hints (("Goal" :in-theory (e/d (milawa-steps)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

; Completeness: whatever the loop computes is a run of MILAWA-STEPS steps.
; The fuel-exhaustion case is excluded, and it has to be: when the budget runs
; out the loop answers (:MILAWA-ABORT :FUEL), and stopping for lack of fuel is
; not a run -- it is the runtime declining to answer.  Excluding it is also what
; forces the recursion below to stay above one step, since a budget of zero
; answers with exactly that abort.

(defthm milawa-conf-run-implies-runs
  (implies (and (integerp n)
                (< 0 n)
                (not (equal (milawa-conf-run c ftbl n) (milawa-abort :fuel))))
           (milawa-runs c
                        (milawa-steps c ftbl n)
                        (milawa-conf-run c ftbl n)
                        ftbl))
  :hints (("Goal" :in-theory (e/d (milawa-runs
                                   milawa-steps-halt
                                   milawa-steps-run
                                   milawa-conf-run-of-halt
                                   milawa-conf-run-of-run)
                                  (milawa-conf-step milawa-step
                                   milawa-apply-or-run milawa-apply-step
                                   milawa-apply-primitive)))))

;; ---------------------------------------------------------------------------
;; A worked derivation
;; ---------------------------------------------------------------------------

; Two steps on (quote 5): evaluate the constant, then return it to the empty
; stack, which finishes the machine.  Note that N = 1 does NOT work here: the
; count is exact, so spending two steps on a one-step machine is not a run.

(defthm milawa-runs-of-quote
  (milawa-runs (milawa-conf :eval '(quote 5) nil nil) 2 (milawa-ok 5) nil)
  :hints (("Goal" :in-theory (enable milawa-runs
                                     milawa-conf-step
                                     milawa-conf
                                     milawa-step
                                     milawa-apply-or-run
                                     milawa-apply-step))))
