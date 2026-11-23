; K1, first slice: generated arithmetic code on the verified WASM engine.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The corrected plan's K1 is a compiled, not hand-written, artifact: a
; generator emits the WASM instruction stream and one theorem says the
; verified engine executes it to the source value.
;
; This book is the arithmetic slice.  The source is a small integer term
; language (quoted naturals and +); the target is the engine's own
; instruction list.  The engine's list machine is the verified WASM model:
; engine-run-is-spec-run in ../wasm-acl2/engine/run.lisp relates it to
; W3T::STEPS/%FUEL.  The generated code is a postfix sequence of
; :const/:binop instructions; no WAT file and no hand-written module is
; involved.
;
; Two engine details shape the statements below.  A :const instruction is
; a value, so MACHINE-STEP moves it to VALS.  A :binop instruction is an
; operation, so OP-STEP leaves its result in IS; the next step moves that
; value to VALS.  The clock is therefore 1 per constant and 2 per
; operation, and the run theorem stops in the state whose VALS is the
; computed stack (status still :RUN).  A final MACHINE-STEP sets :DONE.

(in-package "MILAWA-WASM")

(include-book "ihs/quotient-remainder-lemmas" :dir :system)
(include-book "../wasm-acl2/engine/machine/machine")

(set-prover-step-limit 20000000)

;; ---------------------------------------------------------------------------
;; Arithmetic facts about the W3T binop result
;; ---------------------------------------------------------------------------

(defthm consp-when-len-1
  (implies (equal (len x) 1) (consp x))
  :hints (("Goal" :in-theory (enable len))))

(defthm len-binop-add
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (equal (len (w3t::$binop_ (list :i32) (list :add) v1 v2))
                  1))
  :hints (("Goal" :in-theory (enable w3t::$binop_ w3t::$iadd_))))

(defthm rem-bounds-nat
  (implies (and (natp x) (posp y))
           (and (<= 0 (rem x y)) (< (rem x y) y)))
  :hints (("Goal" :in-theory (disable rem truncate)
                  :use ((:instance acl2::rem-bounds (x x) (y y))))))

(defthm binop-add-value
  (implies (and (unsigned-byte-p 32 v1) (unsigned-byte-p 32 v2))
           (unsigned-byte-p 32
                            (car (w3t::$binop_ (list :i32) (list :add)
                                               v1 v2))))
  :hints (("Goal" :in-theory (disable rem truncate)
                  :use ((:instance rem-bounds-nat
                                   (x (+ v1 v2))
                                   (y (expt 2 32)))))))

;; ---------------------------------------------------------------------------
;; One engine step for each generated instruction
;; ---------------------------------------------------------------------------

(defthm k1-step-const
  (implies (unsigned-byte-p 32 v)
           (equal (we::machine-step
                   (we::ms st f vals
                            (cons (list :const (list :i32) v) rest)
                            ctrl :run))
                  (we::ms st f
                          (cons (list :const (list :i32) v) vals)
                          rest ctrl :run)))
  :hints (("Goal" :in-theory (enable we::machine-step
                                     we::value-instr-p))))

(defthm apply-rule-step-pure-r-binop-val-add-len1
  (implies (equal (len (w3t::$binop_ (list :i32) (list :add) v1 v2)) 1)
           (equal (we::apply-rule
                   'w3t::step_pure/r-binop-val
                   z
                   (list (list :const (list :i32) v1)
                         (list :const (list :i32) v2)
                         (list :binop (list :i32) (list :add))))
                  (mv t z
                      (list (list :const
                                  (list :i32)
                                  (car (w3t::$binop_ (list :i32)
                                                     (list :add)
                                                     v1 v2)))))))
  :hints (("Goal" :in-theory (e/d (we::apply-rule
                                     w3t::step_pure/r-binop-val)
                                  (w3t::$binop_ w3t::$iadd_)))))

(defthm k1-step-binop-add
  (implies (equal (len (w3t::$binop_ (list :i32) (list :add) v1 v2)) 1)
           (equal (we::machine-step
                   (we::ms st f
                            (cons (list :const (list :i32) v2)
                                  (cons (list :const (list :i32) v1)
                                        more))
                            (cons (list :binop (list :i32) (list :add)) rest)
                            ctrl :run))
                  (we::ms st f more
                          (cons (list :const
                                      (list :i32)
                                      (car (w3t::$binop_ (list :i32)
                                                         (list :add)
                                                         v1 v2)))
                                rest)
                          ctrl :run)))
  :hints (("Goal" :in-theory (e/d (we::machine-step
                                   we::op-step
                                   we::redex-arity
                                   we::try-rules
                                   we::apply-rule
                                   w3t::step_pure/r-binop-val)
                                  (apply-rule-step-pure-r-binop-val-add-len1
                                   w3t::$binop_ w3t::$iadd_)))))

;; ---------------------------------------------------------------------------
;; The source term language and the generator
;; ---------------------------------------------------------------------------

(defun k1-term-p (x)
  (declare (xargs :guard t :verify-guards nil))
  (or (and (integerp x) (<= 0 x) (< x 4294967296))
      (and (consp x)
           (eq (car x) '+)
           (consp (cdr x))
           (consp (cddr x))
           (null (cdddr x))
           (k1-term-p (cadr x))
           (k1-term-p (caddr x)))))

(defun k1-gen (x)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
  (cond ((integerp x)
         (list (list :const (list :i32) x)))
        ((consp x)
         (append (k1-gen (cadr x))
                 (append (k1-gen (caddr x))
                         (list (list :binop (list :i32) (list :add))))))
        (t nil)))

(defun k1-value (x)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count x)))
  (cond ((integerp x) x)
        ((consp x)
         (car (w3t::$binop_ (list :i32)
                            (list :add)
                            (k1-value (cadr x))
                            (k1-value (caddr x)))))
        (t 0)))

(defun k1-clock (code)
  (declare (xargs :guard t :verify-guards nil))
  (if (endp code)
      0
    (+ (if (eq (car (car code)) :const) 1 2)
       (k1-clock (cdr code)))))

(defun k1-vals-p (vals)
  (declare (xargs :guard t :verify-guards nil))
  (if (atom vals)
      (null vals)
    (and (consp (car vals))
         (equal (car (car vals)) :const)
         (equal (cadr (car vals)) (list :i32))
         (unsigned-byte-p 32 (caddr (car vals)))
         (k1-vals-p (cdr vals)))))

(defthm k1-vals-p-cons
  (equal (k1-vals-p (cons (list :const (list :i32) v) vals))
         (and (unsigned-byte-p 32 v)
              (k1-vals-p vals))))

(defthm k1-value-unsigned-byte-p
  (implies (k1-term-p x)
           (unsigned-byte-p 32 (k1-value x)))
  :hints (("Goal" :induct (k1-value x)
                  :in-theory (e/d (k1-term-p k1-value)
                                  (w3t::$binop_ w3t::$iadd_)))))

(defthm k1-clock-append
  (equal (k1-clock (append a b))
         (+ (k1-clock a) (k1-clock b)))
  :hints (("Goal" :induct (k1-clock a)
                  :in-theory (enable k1-clock))))

(defthm k1-clock-const
  (equal (k1-clock (list (list :const (list :i32) v))) 1)
  :hints (("Goal" :in-theory (enable k1-clock))))

(defthm k1-clock-binop
  (equal (k1-clock (list (list :binop (list :i32) (list :add)))) 2)
  :hints (("Goal" :in-theory (enable k1-clock))))

;; ---------------------------------------------------------------------------
;; Composing machine runs
;; ---------------------------------------------------------------------------

(defthm k1-machine-run-succ
  (implies (and (we::machine-running s) (natp n))
           (equal (we::machine-run (1+ n) s)
                  (we::machine-run n (we::machine-step s))))
  :hints (("Goal" :expand ((we::machine-run (1+ n) s))
                  :in-theory (e/d (we::machine-running zp)
                                  (we::machine-run))
                  :do-not-induct t)))

(defthm k1-machine-run-two
  (implies (and (we::machine-running s)
                (we::machine-running (we::machine-step s))
                (natp n))
           (equal (we::machine-run (+ 2 n) s)
                  (we::machine-run n
                                   (we::machine-step (we::machine-step s)))))
  :hints (("Goal" :use ((:instance k1-machine-run-succ
                                   (n (+ 1 n)) (s s))
                        (:instance k1-machine-run-succ
                                   (n n) (s (we::machine-step s))))
                  :in-theory (e/d (zp natp)
                                  (we::machine-run we::machine-step
                                                   we::machine-running
                                                   k1-machine-run-succ))
                  :do-not-induct t)))


;; ---------------------------------------------------------------------------
;; Closed generated-code checks (the general composition is the next step)
;; ---------------------------------------------------------------------------

(defthm k1-poc-add
  (equal (we::machine-run 4 (we::ms nil nil nil (k1-gen '(+ 1 2)) nil :run))
         (we::ms nil nil (list (list :const (list :i32) 3)) nil nil :run))
  :hints (("Goal" :in-theory (enable k1-gen
                                     we::machine-run
                                     we::machine-step
                                     we::value-instr-p
                                     we::op-step
                                     we::redex-arity
                                     we::try-rules
                                     we::apply-rule
                                     w3t::step_pure/r-binop-val
                                     w3t::$binop_
                                     w3t::$iadd_))))

(defthm k1-poc-nested
  (equal (we::machine-run 7
                          (we::ms nil nil nil (k1-gen '(+ 1 (+ 2 3))) nil :run))
         (we::ms nil nil (list (list :const (list :i32) 6)) nil nil :run))
  :hints (("Goal" :in-theory (enable k1-gen
                                     we::machine-run
                                     we::machine-step
                                     we::value-instr-p
                                     we::op-step
                                     we::redex-arity
                                     we::try-rules
                                     we::apply-rule
                                     w3t::step_pure/r-binop-val
                                     w3t::$binop_
                                     w3t::$iadd_))))

(value-triple
 (list :term '(+ 1 2)
       :code (k1-gen '(+ 1 2))
       :value (k1-value '(+ 1 2))
       :nested-value (k1-value '(+ 1 (+ 2 3)))))
