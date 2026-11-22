; The PoC: a piece of Milawa-Lisp, running on the artifact, end to end.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; ---------------------------------------------------------------------------
; What this book is
;
; Jitawa's front door is a composed theorem: a Lisp expression, evaluated by
; the spec, equals the answer the verified machine returns.  Its examples are
; small -- '3, (cons 5 '(6 7)), (increment 5) -- and the point of each is that
; the expression, the spec's evaluator, and the machine code are all named in
; one statement.
;
; This book is the same shape for milawa-verified.wasm, using the smallest
; Milawa-Lisp expression that exercises arithmetic:
;
;     (+ (quote 1) (quote 2))          ; MILAWA-EVAL => 3
;          |
;          | POC-COMPILE (an ordinary ACL2 function, not a verified compiler)
;          v
;     (1 1 1 2 2 0)                    ; CONST 1; CONST 2; ADD; HALT
;          |
;          | four calls to the module's exported STEP, as a host drives it
;          v
;     the certified WASM 3.0 semantics stops at a configuration whose
;     observations are (MVM-RUN (POC-INIT term) 100)
;
; The claims are separate theorems:
;
;   POC-COMPILE-CORRECT       the code constant is what POC-COMPILE says
;   POC-ADD-MODEL             the model's answer is status 0, result 3, four steps
;   POC-ADD                   the artifact's four calls stop at that model state
;   POC-ADD-EACH-CALL         each call is exactly one MVM-STEP
;   POC-ADD-REFINES-MILAWA    that answer is MILAWA-EVAL's answer
;   POC-ADD-ARTIFACT-RESULT   the artifact's result global is that answer
;
; ---------------------------------------------------------------------------
; What this book is NOT
;
; This is a closed instance, not L1.  Each of the four calls is the same kind of
; concrete fact ABS.LISP proves for one opcode path, threaded through the store
; the previous call returned.  The symbolic theorem -- one call equals
; MVM-STEP for a symbolic state whose invariant is maintained -- is still open,
; and is what would make the statement hold for every program and every input.
; The value of this book is that it fixes the SHAPE of that theorem and gives
; it a runnable instance: if the artifact, the model, or the abstraction drifts,
; one of these ground theorems stops proving.
;
; It is deliberately not in the example corpus.  The corpus is recorded from a
; host and checked against the model; this book is the proof that the certified
; semantics itself reaches the model's answer.  The two claims stay separate,
; which is the project's rule.

(in-package "MILAWA-WASM")

(include-book "abs")
(include-book "../milawa-lisp/eval")
(include-book "../milawa-lisp/programs")

;; ---------------------------------------------------------------------------
;; The term and the (untrusted) compiler
;; ---------------------------------------------------------------------------

(defconst *poc-term* '(+ (quote 1) (quote 2)))

; The compiler is an ordinary ACL2 function, exactly as Jitawa's compiler is
; not verified: its output is checked by the theorem below.  It handles the two
; forms this PoC needs, and compiles anything else to a HALT on an empty stack,
; which the machine reports as an abort rather than a silent wrong answer.
(defun poc-compile (term)
  (declare (xargs :guard t :verify-guards nil))
  (cond
   ((and (consp term)
         (equal (car term) 'quote)
         (consp (cdr term))
         (equal (cddr term) nil))
    (list *mvm-const* (cadr term)))
   ((and (consp term)
         (equal (car term) '+)
         (consp (cdr term))
         (consp (cddr term))
         (equal (cdddr term) nil))
    (append (poc-compile (cadr term))
            (poc-compile (caddr term))
            (list *mvm-add*)))
   (t (list *mvm-halt*))))

(defun poc-program (term)
  (declare (xargs :guard t :verify-guards nil))
  (append (poc-compile term) (list *mvm-halt*)))

(defun poc-init (term)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-make-state 1 0 nil 0 (poc-program term)))

; The first check on the compiler: the code this term compiles to is the
; expected four-instruction program.
(defthm poc-compile-correct
  (equal (poc-program *poc-term*) '(1 1 1 2 2 0)))

;; ---------------------------------------------------------------------------
;; Driving the artifact
;; ---------------------------------------------------------------------------

; One exported STEP call, from the store-and-frame pair Z the previous call
; returned.  SPENT is the number of steps the path spends, and the clock is
; checked from both sides exactly as MILAWA-STEP-CHECK in ABS.LISP does it:
; STEPS/%FUEL at SPENT is NIL (the budget is exhausted), and at (1+ SPENT) it
; reports the stopped configuration.  Both halves are needed for the clock to be
; exact rather than merely an upper bound.
(defun poc-call (spent z)
  (declare (xargs :guard t :verify-guards nil))
  (and (null (w3t::steps/%fuel spent (w3t::$invoke (cadr z) 6 nil)))
       (let ((r (w3t::steps/%fuel (1+ spent) (w3t::$invoke (cadr z) 6 nil))))
         (and (consp r)
              (null (w3t::step (car r)))
              (cadr (car r))))))

; The per-opcode clocks ABS.LISP measured (47-101 spec steps, opcode-determined):
; CONST 67, ADD 96, HALT 53.  This term is CONST 1; CONST 2; ADD; HALT.
(defconst *poc-clock* '(67 67 96 53))

(defun poc-run (clocks z)
  (declare (xargs :guard t :verify-guards nil))
  (if (or (endp clocks) (not z))
      z
    (poc-run (cdr clocks) (poc-call (car clocks) z))))

;; ---------------------------------------------------------------------------
;; The claims
;; ---------------------------------------------------------------------------

; The model's side.  These are ordinary evaluations of MVM-RUN; the theorem is
; here so the artifact theorem below has a named answer to agree with.
(defthm poc-add-model
  (let ((st (mvm-run (poc-init *poc-term*) 100)))
    (and (equal (mvm-status st) 0)
         (equal (mvm-result st) 3)
         (equal (mvm-pc st) 6)
         (equal (mvm-stack st) nil)
         (equal (mvm-steps (poc-init *poc-term*) 100) 4)))
  :rule-classes nil)

; The artifact's side.  Four calls to the exported STEP, threaded through the
; actual store each call returns, stop where MVM-RUN stops, and the stopped
; configuration's globals and stack words read back as the model's state.
(defthm poc-add
  (let* ((st (poc-init *poc-term*))
         (final (mvm-run st 100))
         (z (poc-run *poc-clock* (mvm-abs-z st))))
    (and (consp z)
         (milawa-observations z final)))
  :rule-classes nil)

; Each call is one MVM step, not just the endpoint: after the first, second,
; third and fourth calls the artifact's observations are the corresponding
; MVM-STEP state.  (POC-ADD only reads the stopped configuration; this one reads
; every intermediate one, so a call that quietly took two MVM steps could not
; pass both.)
(defthm poc-add-each-call
  (let* ((st0 (poc-init *poc-term*))
         (st1 (mvm-step st0))
         (st2 (mvm-step st1))
         (st3 (mvm-step st2))
         (st4 (mvm-step st3))
         (z1 (poc-call 67 (mvm-abs-z st0)))
         (z2 (poc-call 67 z1))
         (z3 (poc-call 96 z2))
         (z4 (poc-call 53 z3)))
    (and (consp z1) (milawa-observations z1 st1)
         (consp z2) (milawa-observations z2 st2)
         (consp z3) (milawa-observations z3 st3)
         (consp z4) (milawa-observations z4 st4)))
  :rule-classes nil)

; The bridge to Milawa-Lisp.  MILAWA-EVAL is the interpreter the L1/L3 plan
; refines; its answer for this term is the number the artifact returned.
(defthm poc-add-refines-milawa
  (equal (mvm-result (mvm-run (poc-init *poc-term*) 100))
         (milawa-result-value
          (milawa-eval *poc-term* nil *milawa-demo-program* 10)))
  :rule-classes nil)

; The composition in one statement, so the front door does not have to be read
; off two theorems: the result global the artifact leaves is MILAWA-EVAL's
; answer.
(defthm poc-add-artifact-result
  (let* ((st (poc-init *poc-term*))
         (z (poc-run *poc-clock* (mvm-abs-z st))))
    (and (consp z)
         (equal (milawa-global z 4)
                (milawa-result-value
                 (milawa-eval *poc-term* nil *milawa-demo-program* 10)))))
  :rule-classes nil)

;; ---------------------------------------------------------------------------
;; What MAKE POC prints
;; ---------------------------------------------------------------------------

; A real computation, not a remembered sentence: the same run the theorems
; above are about, evaluated again at the top level.
(defun poc-summary ()
  (declare (xargs :guard t :verify-guards nil))
  (let* ((st (poc-init *poc-term*))
         (final (mvm-run st 100))
         (z (poc-run *poc-clock* (mvm-abs-z st))))
    (list :term *poc-term*
          :program (poc-program *poc-term*)
          :mvm-status (mvm-status final)
          :mvm-result (mvm-result final)
          :mvm-pc (mvm-pc final)
          :mvm-steps (mvm-steps st 100)
          :milawa-result
          (milawa-result-value
           (milawa-eval *poc-term* nil *milawa-demo-program* 10))
          :artifact-stopped (and (consp z) t)
          :observations (and (consp z) (milawa-observations z final)))))
