; L1, the symbolic abstraction: an abstract memory, and where the step gets stuck.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; abs.lisp states L1's target with the PINNED store: the 65536-byte page is a
; literal in the abstraction, which is what makes its sixteen theorems provable by
; evaluation and is also what makes a symbolic proof hopeless -- every term would
; carry that page.
;
; This book is the abstraction the SYMBOLIC proof wants: the same store, but with
; its memory bytes a variable.  Nothing else changes: the module's code, types and
; exports stay the artifact's, and the five globals are set as before.  The point
; is that a configuration built this way is a small term, so a failed proof leaves
; a residual goal a human can read.
;
; Measured, in this book's own lemmas:
;
;   * a field lookup on a store whose leaves are symbolic IS decidable, because
;     %GET-FIELD is assoc-equal on keys and the keys are concrete;
;   * so the memory field reads back as the variable BYTES it was given.
;
; and measured, in a scratch session (see SUMMARY.md):
;
;   * with the abstract memory, ONE step of the entry configuration still fails,
;     and now in a single readable subgoal:
;
;       Subgoal 2
;       (IMPLIES (W3T::STEP/R-CTXT-INSTRS <the configuration>) ...)
;
;     STEP/R-CTXT-INSTRS is the rule that steps INSIDE the instruction sequence.
;     ACL2 asserts it as a hypothesis instead of evaluating it, because evaluating
;     it needs (STEP <inner configuration>), and that inner configuration has the
;     symbolic store in it, so the recursion -- STEP/SEARCH21 walking k down the
;     instruction list -- cannot bottom out.
;
; That residual names the first lemma of the instruction library, and it is
; smaller than it looks: the innermost objects are instruction lists, not
; configurations.  STEP_PURE and STEP_READ transform an instruction list and need
; no store at all, so their lemmas are about symbolic VALUES only:
;
;   step_pure  : instr* -> instr* option        (arithmetic, tests, consts)
;   step_read  : config -> instr* option        (loads, global.get, local.get)
;
; AND A SHAPE THAT DOES NOT WORK, measured: the first instruction lemma was attempted
; as "concrete instruction PREFIX, symbolic CONTINUATION" --
;
;   (step_pure (cons '(:const (:i32) 1) (cons '(:const (:i32) 2)
;                 (cons '(:binop (:i32) (:add)) rest))))
;
; -- and it is the wrong shape, not merely a hard one: STEP_PURE's rules require the
; instruction under reduction to be the LAST element of the list (the prefix is the
; values already pushed), so a non-empty REST means no rule fires at all.  77946
; prover steps went into proving something false.
;
; The symbolic part has to be the VALUE PREFIX, not the continuation:
;
;   (step_pure (append vals (list <concrete instruction>)))
;
; with VALS a list of (:CONST (:I32) v) entries whose v are symbolic.  And then the
; lemmas have to be about STEP/PREFIX7 over an APPEND, because that is what the
; rules inspect to find the split point.  That is where this work starts, and it is
; why the layer is worth cutting here: no store appears in any of it.
;
; So the layering for one instruction is
;
;   STEP_PURE lemma   (no store: symbolic values only)
;     -> STEP_READ lemma  (store read at a concrete place)
;       -> ctxt-label / ctxt-frame lemma   (one level of nesting)
;         -> ctxt-instrs lemma             (the split point)
;           -> call rule                   (entering and leaving a function)
;
; each proved with only its own rule enabled and its recursive call discharged by
; the lemma below it.  That is the plan; this book only fixes the abstraction it
; will be stated over.

(in-package "ACL2")

(include-book "/workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0/wasm3")
(include-book "state")
(include-book "memory")
(include-book "abs")

;; ---------------------------------------------------------------------------
;; How a field is stored, which is easy to get wrong
;; ---------------------------------------------------------------------------

; A record is (KEY . VALUE) per field, i.e. the value is the CDR of the pair:
;
;   (%get-field '(:%rec (:globals . g)) :globals) = g
;
; Writing (list :globals g) instead stores a ONE-ELEMENT LIST and the same lookup
; answers (g) -- so a probe written that way proves NIL and looks like a failure of
; ACL2 rather than of the probe.  It did, once.
(defthm get-field-of-a-one-field-record
  (equal (w3t::%get-field (list :%rec (cons :globals g)) :globals) g))

;; ---------------------------------------------------------------------------
;; The store with an abstract memory
;; ---------------------------------------------------------------------------

; The pinned store's memory record with its bytes replaced: a variable.  The
; record keeps its :TYPE, so the page is still one page of i32 and the module's
; bounds arithmetic is unchanged.
(defun mem-record-of (bytes)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%put-field
   (car (w3t::%get-field *milawa-verified-store* :mems))
   :bytes bytes))

(defun store-with-memory (bytes)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%put-field *milawa-verified-store* :mems (list (mem-record-of bytes))))

; The whole abstraction: the artifact's store and frame, the memory abstract, and
; the five globals from the machine state.  Compare MVM-ABS-Z in abs.lisp, which is
; the same thing with the memory written out as an image.
(defun mvm-abs-z-abstract (bytes sp pc clen status result)
  (declare (xargs :guard t :verify-guards nil))
  (milawa-set-globals
   (list :|%;%| (store-with-memory bytes) *milawa-verified-frame*)
   0 (list sp pc clen status result)))

(defun mvm-abs-abstract (bytes sp pc clen status result)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::$invoke (cadr (mvm-abs-z-abstract bytes sp pc clen status result)) 6 nil))

; The memory survives the round trip through the store: what the module will load
; from is exactly the BYTES the abstraction was handed.  (This is the lemma every
; i32.load in the proof will need, and it is proved once, here.)
(defthm memory-of-the-abstract-store
  (equal (w3t::%get-field
          (car (w3t::%get-field
                (cadr (mvm-abs-z-abstract bytes sp pc clen status result))
                :mems))
          :bytes)
         bytes))
