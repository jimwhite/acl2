; J1 bridge checks: R-EV against the runtime's MILAWA-RUN.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; R-EV is the Jitawa-style high-level spec; MILAWA-RUN is the existing
; runtime interpreter.  A general R-EV = MILAWA-RUN theorem (at a computed
; clock) is the remaining J1b piece.  This book is the first validation:
; the PoC's expressions and a few representative forms agree, by evaluation,
; on both semantics.  It is deliberately not a claim about all terms.

(in-package "MILAWA-WASM")

(include-book "spec")
(include-book "../milawa-lisp/eval")

(defthm r-ev-add-agrees-with-milawa-run
  (equal (r-ev '(+ (quote 1) (quote 2)) nil)
         (milawa-run :eval '(+ (quote 1) (quote 2)) nil nil nil 100)))

(defthm r-ev-if-agrees-with-milawa-run
  (equal (r-ev '(if (< (quote 1) (quote 2)) (quote 10) (quote 20)) nil)
         (milawa-run :eval
                     '(if (< (quote 1) (quote 2)) (quote 10) (quote 20))
                     nil nil nil 100)))

(defthm r-ev-cons-agrees-with-milawa-run
  (equal (r-ev '(cons (quote 1) (quote 2)) nil)
         (milawa-run :eval '(cons (quote 1) (quote 2)) nil nil nil 100)))

(defthm r-ev-variable-agrees-with-milawa-run
  (equal (r-ev 'x '((x . 5)))
         (milawa-run :eval 'x '((x . 5)) nil nil 100)))

(defthm r-ev-quote-agrees-with-milawa-run
  (equal (r-ev '(quote (1 2 3)) nil)
         (milawa-run :eval '(quote (1 2 3)) nil nil nil 100)))
