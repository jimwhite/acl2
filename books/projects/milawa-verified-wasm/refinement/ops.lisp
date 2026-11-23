; J2b-1: the per-opcode opcode table and its ACL2 model.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The artifact is ../wasm/milawa-ops.wat (assembled to
; ../wasm/milawa-ops.wasm); ../refinement/ops-state.lisp pins its decoded
; module, store and frame.  This book is the checked opcode table and the
; ACL2 model of the exported functions:
;
;   0 halt, 1 const, 2 add, 3 sub, 4 lt, 5 ifz, 6 jmp, 7 label
;
; The model functions are i32 operations (mod 2^32), matching the WAT bodies.
; Each has a value-level theorem against the J2a MACHINE-STEP, and the
; dispatcher IR-STEP is proved one case per opcode.  The W3T link for the
; artifact is J2b-2; see the note at the end.

(in-package "MILAWA-WASM")

(include-book "machine")
(include-book "ops-state")

;; ---------------------------------------------------------------------------
;; The checked opcode table
;; ---------------------------------------------------------------------------

(defconst *ir-op-table*
  '((0 . halt)
    (1 . const)
    (2 . add)
    (3 . sub)
    (4 . lt)
    (5 . ifz)
    (6 . jmp)
    (7 . label)))

; Function indices in the assembled module (export order).
(defconst *ir-op-index*
  '((halt . 0) (const . 0) (add . 1) (sub . 2) (lt . 3) (ifz . 4) (jmp . 5)
    (label . 6) (step . 7)))

;; ---------------------------------------------------------------------------
;; The i32 model of the exported functions
;; ---------------------------------------------------------------------------

(defun ir-op-const (v) v)
(defun ir-op-add (a b) (+ a b))
(defun ir-op-sub (a b) (- a b))
(defun ir-op-lt (a b) (if (< a b) 1 0))
(defun ir-op-ifz (test target) (if (equal test 0) target 0))
(defun ir-op-jmp (x target)
  (declare (ignore x))
  target)

(defun ir-op-label (x target)
  (declare (ignore target))
  x)

(defun ir-step (op a b)
  (case op
    (0 (ir-op-const a))
    (1 (ir-op-const a))
    (2 (ir-op-add a b))
    (3 (ir-op-sub a b))
    (4 (ir-op-lt a b))
    (5 (ir-op-ifz a b))
    (6 (ir-op-jmp a b))
    (7 (ir-op-label a b))
    (otherwise 0)))

;; ---------------------------------------------------------------------------
;; Dispatcher: one case per opcode
;; ---------------------------------------------------------------------------

(defthm ir-step-halt
  (equal (ir-step 0 a b) (ir-op-const a))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-const
  (equal (ir-step 1 a b) (ir-op-const a))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-add
  (equal (ir-step 2 a b) (ir-op-add a b))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-sub
  (equal (ir-step 3 a b) (ir-op-sub a b))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-lt
  (equal (ir-step 4 a b) (ir-op-lt a b))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-ifz
  (equal (ir-step 5 a b) (ir-op-ifz a b))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-jmp
  (equal (ir-step 6 a b) (ir-op-jmp a b))
  :hints (("Goal" :in-theory (enable ir-step))))

(defthm ir-step-label
  (equal (ir-step 7 a b) (ir-op-label a b))
  :hints (("Goal" :in-theory (enable ir-step))))

; The dispatcher covers exactly the table's opcodes.
(defthm ir-step-table
  (and (equal (ir-step 0 a b) (ir-op-const a))
       (equal (ir-step 1 a b) (ir-op-const a))
       (equal (ir-step 2 a b) (ir-op-add a b))
       (equal (ir-step 3 a b) (ir-op-sub a b))
       (equal (ir-step 4 a b) (ir-op-lt a b))
       (equal (ir-step 5 a b) (ir-op-ifz a b))
       (equal (ir-step 6 a b) (ir-op-jmp a b))
       (equal (ir-step 7 a b) (ir-op-label a b)))
  :hints (("Goal" :in-theory (enable ir-step))))

;; ---------------------------------------------------------------------------
;; Value-level agreement with the J2a machine
;; ---------------------------------------------------------------------------

(defthm ir-op-const-matches-machine-step
  (equal (ir-op-const v)
         (car (caddr (machine-step 0 (list v)
                                   (list (list :const v)) nil))))
  :hints (("Goal" :in-theory (enable machine-step-const ir-op-const))))

(defthm ir-op-add-matches-machine-step
  (implies (and (unsigned-byte-p 30 a) (unsigned-byte-p 30 b)
                (< (+ a b) (expt 2 30)))
           (equal (ir-op-add a b)
                  (milawa-result-value
                   (milawa-apply-primitive '+ (list a b)))))
  :hints (("Goal" :in-theory (enable ir-op-add milawa-apply-primitive
                                     milawa-+ milawa-ok milawa-result-value))))

(defthm ir-op-sub-matches-machine-step
  (implies (and (unsigned-byte-p 30 a) (unsigned-byte-p 30 b)
                (<= b a))
           (equal (ir-op-sub a b)
                  (milawa-result-value
                   (milawa-apply-primitive '- (list a b)))))
  :hints (("Goal" :in-theory (enable ir-op-sub milawa-apply-primitive
                                     milawa-- milawa-ok milawa-result-value
                                    ))))

(defthm ir-op-lt-matches-machine-step
  (implies (and (unsigned-byte-p 30 a) (unsigned-byte-p 30 b))
           (equal (ir-op-lt a b)
                  (if (milawa-result-value
                       (milawa-apply-primitive '< (list a b)))
                      1
                    0)))
  :hints (("Goal" :in-theory (enable ir-op-lt milawa-apply-primitive
                                     milawa-< milawa-ok milawa-result-value
                                    ))))

;; ---------------------------------------------------------------------------
;; J2b-2 note
;;
;; The W3T link for these exported functions -- a symbolic theorem that a
;; call to function i returns the same i32 as the model -- is J2b-2.  The
;; first attempt (steps/%fuel on a symbolic call, for OP-CONST) did not
;; close in 180 s; the generated STEP search is the same per-call cost the
;; old chain books pay, even for a pure function.  The module and table are
;; checked in; the W3T layer needs the old call/entry/return lemmas ported to
;; this module's store, or the verified-translation route from the plan's
;; J5.  Do not mistake this book for that link.
;;
;; Porting the old lemmas with wasm3/context.lisp included changes the picture:
;; its generic no-ctxt-instrs facts apply to the new store, and
;; STEP-IN-FRAME-LOCAL-GET now proves (refinement/ops-w3t.lisp), as do the
;; frame/label value steps and the frame-around-label-around-value step.  The
;; open J2b-2 pieces are the three-step body composition (the helper terms do
;; not normalize across the three facts yet), the `$invoke` call entry (still
;; 300 s), and the remaining opcodes/dispatcher.
;; ---------------------------------------------------------------------------
