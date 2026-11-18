; Milawa-Lisp, part 7b: differential checks for MVM.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; These are TESTS, not theorems about the module: each expectation below was
; recorded by running the same program words through wasm/milawa-verified.wat in
; Node (`node harness/run.js`), and what is asserted here is that the ACL2 model
; agrees.  That is testing, and it stays testing until L1 is proved -- but it is
; what makes L1 stateable, because it fixes the correspondence between a word
; index and the module's program counter, and it catches a model that has drifted
; from the text.
;
; The programs are raw instruction words, the same ones the harness takes:
;
;   0 HALT   1 CONST k   2 ADD   3 SUB   4 LT   5 IFZ k   6 JMP k
;
; and the numbers in the comments are the step counts Node reported.

(in-package "ACL2")

(include-book "mvm")

; The model reads code by word index, so no byte addresses appear here.  The
; module's PC is 4096 + 4*index; L1 carries that correspondence.  (No
; SET-GUARD-CHECKING: it is illegal during certification, and unnecessary --
; MVM's functions carry :VERIFY-GUARDS NIL, so execution does not check guards.)

(defun mvm-init (code)
  (mvm-make-state 1 0 nil 0 code))

; (if (< 1 2) 10 20) => 10, six steps
(assert-event
 (let* ((code '(1 1  1 2  4  5 10  1 10  0  1 20  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 10)
        (equal (mvm-stack st) nil)
        (equal (mvm-steps (mvm-init code) 100) 6))))

; (if (< 2 1) 10 20) => 20, six steps
(assert-event
 (let* ((code '(1 2  1 1  4  5 10  1 10  0  1 20  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 20)
        (equal (mvm-steps (mvm-init code) 100) 6))))

; (+ 20 (- 3 1)) => 22, six steps
(assert-event
 (let* ((code '(1 20  1 3  1 1  3  2  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 22)
        (equal (mvm-steps (mvm-init code) 100) 6))))

; An unknown opcode aborts, and the machine stays aborted however much fuel it
; is given: 7 is not an opcode.
(assert-event
 (let ((st (mvm-run (mvm-init '(7 0)) 10)))
   (and (mvm-abortedp st)
        (mvm-abortedp (mvm-step st))
        (equal (mvm-step st) st))))

; ADD with nothing on the stack aborts rather than reading memory.
(assert-event (mvm-abortedp (mvm-run (mvm-init '(2 0)) 10)))

; CONST with no immediate word aborts: the program is truncated.
(assert-event (mvm-abortedp (mvm-run (mvm-init '(1)) 10)))

; Running off the end aborts.
(assert-event (mvm-abortedp (mvm-run (mvm-init '(1 5 2)) 10)))

; A halted machine stays halted, and the host loop cannot restart it.
(assert-event
 (let* ((code '(1 5  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 5)
        (equal (mvm-step st) st))))

; Fuel exhaustion is not an answer: the machine is merely still running.  This is
; the same distinction MILAWA-RUNS draws, where stopping for lack of fuel is the
; runtime declining to answer.
(assert-event (mvm-runningp (mvm-run (mvm-init '(1 5  0)) 1)))

; Addition wraps at 32 bits, as i32.add does: #xFFFFFFFF + 1 = 0.
(assert-event
 (let* ((code (list 1 #xFFFFFFFF  1 1  2  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 0))))

; LT is SIGNED, as i32.lt_s is: -1 < 0 is true, so this halts with 1.
(assert-event
 (let* ((code (list 1 #xFFFFFFFF  1 0  4  0))
        (st (mvm-run (mvm-init code) 100)))
   (and (mvm-haltedp st)
        (equal (mvm-result st) 1))))
