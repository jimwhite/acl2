; Running the Milawa demo (milawa-on-jitawa/100.events) on the verified
; Milawa-Lisp evaluator.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; MILAWA-CHECK-RUN starts the kernel in the initial state MILAWA-INIT would
; build (the translated core function table, the initial axioms and arity
; table, and the checker LOGIC.PROOFP) and feeds it the event list.  The
; result is (MILAWA-OK . SUCCESS) exactly when every event is accepted.
;
; This is the Jitawa demo run, on the model rather than a compiled runtime:
; the events are data and the kernel is interpreted by MILAWA-EVAL.  It is a
; checked run (evaluation), not a soundness theorem; the kernel is the same
; milawa2.lsp program the WASM checker runs.

(in-package "MILAWA-WASM")

(include-book "milawa-check")

(defun nth-event (n events)
  (declare (xargs :guard t :verify-guards nil))
  (if (zp n)
      (car events)
    (nth-event (1- n) (cdr events))))

(defun take-events (n events)
  (declare (xargs :guard t :verify-guards nil))
  (if (zp n)
      nil
    (cons (car events) (take-events (1- n) (cdr events)))))

; The kernel entry term.  The state is built by the kernel's own CORE.STATE
; from the initial axioms/atbl; the event number is a quoted constant because
; MILAWA-EVAL takes terms, not values.

(defun milawa-check-term (events)
  (declare (xargs :guard t :verify-guards nil))
  (list 'if
        (list '|CORE.ACCEPT-COMMANDS|
              (list 'quote events)
              (list 'quote 1)
              (list '|CORE.STATE|
                    (list '|CORE.INITIAL-AXIOMS|)
                    (list 'quote nil)
                    (list '|CORE.INITIAL-ATBL|)
                    (list 'quote '|LOGIC.PROOFP|)
                    (list 'quote *core-ftbl*)))
        (list 'quote 'success)
        nil))

(defun milawa-check-run (events fuel)
  (declare (xargs :guard t :verify-guards nil))
  (milawa-eval (milawa-check-term events) nil *core-ftbl* fuel))

; Prefixes are cheap checks of the entry term and the event reader.
(assert-event
 (equal (milawa-check-run (take-events 1 *milawa-100-events*) 1000000)
        (milawa-ok 'success)))

(assert-event
 (equal (milawa-check-run (take-events 6 *milawa-100-events*) 10000000)
        (milawa-ok 'success)))

; The whole demo: 100 events, with the large proofs at the end.
(assert-event
 (equal (milawa-check-run *milawa-100-events* 1000000000)
        (milawa-ok 'success)))

; The assertion above is the run.  This prints the input size without
; replaying 100 events.
(value-triple
 (list :milawa-events (len *milawa-100-events*)
       :check '(:milawa-ok . success)))
