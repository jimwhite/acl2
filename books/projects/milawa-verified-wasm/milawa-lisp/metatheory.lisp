; Milawa-Lisp, part 5: metatheory.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; Four facts, and the first is the interesting one.
;
;   * FUEL MONOTONICITY.  A run that succeeds with n units of fuel succeeds with
;     any larger amount and returns the same value.  This lets a caller pick a
;     generous budget without changing the answer, and it is what the
;     refinement books need when they compose a long run out of short ones.
;
;     The proof is short because MILAWA-RUN has exactly one recursive call:
;     MILAWA-STEP has no fuel argument at all, so the step taken at fuel m is
;     the step taken at fuel n, and the recursive calls are at (1- m) and
;     (1- n).
;
;   * A result is an OK or an ABORT, and the two are disjoint.  Because ABORT is
;     a constructor and not a side condition, "the runtime failed" is a value we
;     can reason about, and an abort can never be mistaken for an acceptance.
;
;   * Fuel exhaustion is an abort, so running out of fuel can only make the
;     runtime reject; it can never make it accept something new.
;
;   * MILAWA-- stays inside the value domain.

(in-package "MILAWA-WASM")

(include-book "eval")
(include-book "programs")

;; ---------------------------------------------------------------------------
;; Fuel monotonicity
;; ---------------------------------------------------------------------------

; When a step finishes the machine, the run is that step's result, whatever the
; fuel was.  This documents that a result never depends on fuel; it is not
; needed by the monotonicity proof below, which keeps the step symbolic.

(defthm milawa-run-when-not-run
  (implies (and (not (zp fuel))
                (not (equal (car (milawa-step mode obj env stack ftbl)) :run)))
           (equal (milawa-run mode obj env stack ftbl fuel)
                  (milawa-step mode obj env stack ftbl)))
  :hints (("Goal" :in-theory (enable milawa-run))))

; MILAWA-RUN-INDUCT is not a function anyone calls: it exists only to give
; ACL2 an induction scheme that descends n and m together, one machine step at
; a time.  Inducting on n alone is not enough, because the induction hypothesis
; would mention the original m instead of (1- m).  This is the usual ACL2 idiom
; for supplying an induction scheme; see :DOC induction.

(defun milawa-run-induct (mode obj env stack ftbl n m)
  (declare (xargs :measure (nfix n)))
  (if (zp n)
      (list mode obj env stack ftbl n m)
    (let ((s (milawa-step mode obj env stack ftbl)))
      (if (eq (car s) :run)
          (milawa-run-induct (nth 1 s) (nth 2 s) (nth 3 s) (nth 4 s)
                             ftbl (1- n) (1- m))
        (list mode obj env stack ftbl n m)))))

; The step is deliberately kept symbolic (MILAWA-STEP and the apply functions
; are disabled): the proof is then a case analysis on whether the next step
; continues, and expanding the step's twenty branches only obscures it.

(defthm milawa-run-monotone
  (implies (and (natp n)
                (natp m)
                (<= n m)
                (milawa-okp (milawa-run mode obj env stack ftbl n)))
           (equal (milawa-run mode obj env stack ftbl m)
                  (milawa-run mode obj env stack ftbl n)))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (e/d (milawa-run milawa-okp)
                           (milawa-step milawa-apply-or-run
                            milawa-apply-step milawa-apply-primitive))
           :induct (milawa-run-induct mode obj env stack ftbl n m))))

; MILAWA-EVAL is MILAWA-RUN from the initial configuration, so this is the
; monotonicity theorem at that configuration.  Note that the induction must be
; the one for MILAWA-RUN: MILAWA-EVAL has no stack argument, so an induction
; over it could not track the stack a recursive call carries.

(defthm milawa-eval-monotone
  (implies (and (natp n)
                (natp m)
                (<= n m)
                (milawa-okp (milawa-eval term env ftbl n)))
           (equal (milawa-eval term env ftbl m)
                  (milawa-eval term env ftbl n)))
  :rule-classes nil
  :hints (("Goal"
           :in-theory (e/d (milawa-eval) (milawa-run-when-not-run))
           :use ((:instance milawa-run-monotone
                            (mode :eval)
                            (obj term)
                            (stack nil))))))

;; Both monotonicity theorems are stored with :RULE-CLASSES NIL.  As rewrite
;; rules they would be fuel-decreasing rewrites -- (RUN ... M) becomes
;; (RUN ... N) for a smaller N -- which the rewriter would apply over and over.
;; Use them through :USE, or instantiate them by functional instantiation.


;; ---------------------------------------------------------------------------
;; Aborts and acceptances are disjoint
;; ---------------------------------------------------------------------------

(defthm milawa-abort-is-not-acceptance
  (implies (milawa-abortp r)
           (not (milawa-okp r)))
  :hints (("Goal" :in-theory (enable milawa-okp milawa-abortp))))

(defthm milawa-result-is-ok-or-abort
  (implies (milawa-resultp r)
           (or (milawa-okp r)
               (milawa-abortp r)))
  :hints (("Goal" :in-theory (enable milawa-resultp milawa-okp milawa-abortp))))

(defthm milawa-ok-is-a-result
  (milawa-resultp (milawa-ok value))
  :hints (("Goal" :in-theory (enable milawa-resultp milawa-ok))))

(defthm milawa-abort-is-a-result
  (milawa-resultp (milawa-abort reason))
  :hints (("Goal" :in-theory (enable milawa-resultp milawa-abort))))

;; ---------------------------------------------------------------------------
;; Fuel exhaustion is an abort
;; ---------------------------------------------------------------------------

(defthm milawa-run-of-zero-fuel
  (equal (milawa-run mode obj env stack ftbl 0)
         (milawa-abort :fuel))
  :hints (("Goal" :in-theory (enable milawa-run))))

(defthm milawa-eval-of-zero-fuel
  (equal (milawa-eval term env ftbl 0)
         (milawa-abort :fuel))
  :hints (("Goal" :in-theory (enable milawa-eval))))

;; ---------------------------------------------------------------------------
;; MILAWA-- stays inside the value domain
;; ---------------------------------------------------------------------------

(defthm milawa-fixnump-of-milawa--
  (implies (and (milawa-valuep x)
                (milawa-valuep y))
           (milawa-fixnump (milawa-- x y)))
  :hints (("Goal" :in-theory (enable milawa-- milawa-fixnump milawa-valuep))))
