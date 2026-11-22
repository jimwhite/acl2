; Literal splicing for the semantics' instruction lists.
;
; The search in `step` computes only on a literal list, so every position in a
; chain lemma has to carry the module's body as a quoted literal.  Copying those
; literals by hand is where the silent mistakes come from: an extra list, a
; missing cdr, a keyword typed as :TESTTOP.  These macros compute the literal
; from the module the proofs are about, at macro-expansion time, and splice it
; into the event.  A position is written as
;
;     (func-tail-lit 6 3)
;
; instead of as the 40-instruction list it denotes.
;
; The macros are :program-mode checks followed by a quote, so a malformed
; instruction list (a non-cons element, or a tail that is not a true list) is
; an error at expansion time rather than a false lemma that ACL2 reduces to
; NIL.  They do not check that the keyword names a real rule; that is what the
; semantics' own rule table is for.
;
; (C) 2026 Kookamara LLC
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "context")       ; milawa-func-body, milawa-func-code

;; ---------------------------------------------------------------------------
;; The check

(defun check-instruction-list (l)
  (declare (xargs :mode :program))
  (cond ((atom l)
         (or (null l)
             (er hard? 'literal-splice "the tail ~x0 is not nil" l)))
        ((not (and (consp (car l)) (keywordp (caar l))))
         (er hard? 'literal-splice "~x0 is not an instruction" (car l)))
        (t (check-instruction-list (cdr l)))))

;; ---------------------------------------------------------------------------
;; The splicers
;;
;; Each returns (quote <value>) where <value> is computed from the module's
;; function body.  Because the value is computed here, not in the book, a
;; change to the module changes every use at the next certification.

(defmacro func-body-lit (i)
  (let ((l (milawa-func-body i)))
    (prog2$ (check-instruction-list l)
            (list 'quote l))))

(defmacro func-tail-lit (i n)
  (let ((l (nthcdr n (milawa-func-body i))))
    (prog2$ (check-instruction-list l)
            (list 'quote l))))

(defmacro func-instr-lit (i n)
  (let ((x (nth n (milawa-func-body i))))
    (prog2$ (check-instruction-list (list x))
            (list 'quote x))))

(defmacro func-prefix-lit (i n)
  (let ((l (take n (milawa-func-body i))))
    (prog2$ (check-instruction-list l)
            (list 'quote l))))

;; The same values as named constants.  A defconst is evaluated at event time
;; and its value is spliced wherever the symbol is used, so a lemma written
;; with *body-6* carries the literal the search needs -- measured: the
;; step_pure fact below proves by evaluation, in 4 prover steps.  This is the
;; route for a whole body or a long tail; the macros above are for a position
;; written inline.

(defmacro def-func-body (name i)
  `(defconst ,name (milawa-func-body ,i)))

(defmacro def-func-tail (name i n)
  `(defconst ,name (nthcdr ,n (milawa-func-body ,i))))

(defmacro def-func-instr (name i n)
  `(defconst ,name (nth ,n (milawa-func-body ,i))))

;; ---------------------------------------------------------------------------
;; The module's function 6, read back through the splicers.
;;
;; These are executable checks: the point is that the spliced literal is the
;; one the semantics' own body has, not a copy that happens to look right.

(assert-event (equal (len (func-body-lit 6)) 43))
(assert-event (equal (car (func-body-lit 6)) '(:GLOBAL.GET 3)))
(assert-event (equal (car (func-tail-lit 6 3)) '(:IFELSE (:_RESULT NIL) ((:GLOBAL.GET 3) (:RETURN)) NIL)))
(assert-event (equal (func-instr-lit 6 3) '(:IFELSE (:_RESULT NIL) ((:GLOBAL.GET 3) (:RETURN)) NIL)))
(assert-event (equal (func-prefix-lit 6 4) (take 4 (func-body-lit 6))))

;; A fact about the semantics stated at a spliced literal.  The tail at
;; position 3 begins with the ifelse, which the pure rules do not step.
(defthm literals-pure-tail-6-3
  (equal (w3t::step_pure (func-tail-lit 6 3)) nil))

;; The named-constant spelling of the same fact.
(def-func-body *literals-body-6* 6)
(def-func-tail *literals-tail-6-3* 6 3)
(def-func-instr *literals-instr-6-3* 6 3)

(defthm literals-defconst-tail-pure
  (equal (w3t::step_pure *literals-tail-6-3*) nil)
  :rule-classes nil)

(assert-event (equal *literals-body-6* (func-body-lit 6)))
(assert-event (equal *literals-instr-6-3* (func-instr-lit 6 3)))
