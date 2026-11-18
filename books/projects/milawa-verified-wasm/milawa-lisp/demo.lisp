; Milawa-Lisp, part 4: evaluation checks on the demo program.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; These are executable checks, not theorems about all inputs: they establish
; that the evaluator and the program data agree on representative calls.  The
; general statement (the evaluator computes the function) is the subject of
; the machine/refinement books, not of this one.

(in-package "ACL2")

(include-book "eval")
(include-book "programs")

(defconst *prog* *milawa-demo-program*)

;; rank counts conses.

(assert-event
 (equal (milawa-call 'rank (list '((a) b)) *prog* 1000)
        (milawa-ok 3)))

(assert-event
 (equal (milawa-call 'rank (list nil) *prog* 1000)
        (milawa-ok 0)))

(assert-event
 (equal (milawa-call 'rank (list 'x) *prog* 1000)
        (milawa-ok 0)))

;; not

(assert-event
 (equal (milawa-call 'not (list t) *prog* 1000)
        (milawa-ok nil)))

(assert-event
 (equal (milawa-call 'not (list nil) *prog* 1000)
        (milawa-ok t)))

;; lookup

(assert-event
 (equal (milawa-call 'lookup (list 'a '((a . 1) (b . 2))) *prog* 1000)
        (milawa-ok '(a . 1))))

(assert-event
 (equal (milawa-call 'lookup (list 'b '((a . 1) (b . 2))) *prog* 1000)
        (milawa-ok '(b . 2))))

(assert-event
 (equal (milawa-call 'lookup (list 'c '((a . 1) (b . 2))) *prog* 1000)
        (milawa-ok nil)))

;; ord<

(assert-event
 (equal (milawa-call 'ord< (list 1 2) *prog* 1000)
        (milawa-ok t)))

(assert-event
 (equal (milawa-call 'ord< (list 2 1) *prog* 1000)
        (milawa-ok nil)))

(assert-event
 (equal (milawa-call 'ord< (list '(1 . 2) '(1 . 3)) *prog* 1000)
        (milawa-ok t)))

;; Running out of fuel aborts; it is never an acceptance.

(assert-event
 (equal (milawa-call 'rank (list '((a) b)) *prog* 1)
        (milawa-abort :fuel)))

;; An unbound variable aborts.

(assert-event
 (equal (milawa-eval 'z nil *prog* 10)
        (milawa-abort :unbound-variable)))

;; overflow: 2^30 - 1 + 1 aborts, where milawa2.lsp calls (error "Overflow in +.")

(assert-event
 (equal (milawa-eval '(+ (quote 1073741823) (quote 1)) nil *prog* 10)
        (milawa-abort :overflow)))

(assert-event
 (equal (milawa-eval '(+ (quote 1) (quote 2)) nil *prog* 10)
        (milawa-ok 3)))

;; - truncates at zero, as MILAWA::- does.

(assert-event
 (equal (milawa-eval '(- (quote 1) (quote 2)) nil *prog* 10)
        (milawa-ok 0)))

;; An unquoted constant is not a term.

(assert-event
 (equal (milawa-eval 3 nil *prog* 10)
        (milawa-abort :unquoted-constant)))
