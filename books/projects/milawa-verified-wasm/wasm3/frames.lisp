; L1, layer 3: call frames and the locals.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; Layer 2 read the store.  This floor reads the FRAME: the module's `step` has four
; i32 locals ($op, $imm, $a, $b), and every one of the seven opcodes loads its
; operand word through them:
;
;   (local.set $op (i32.load (global.get $pc)))     -- the dispatch word
;   (local.set $imm (i32.load (global.get $pc)))    -- an immediate, for CONST/IFZ/JMP
;   (local.set $b (call $pop)) (local.set $a (call $pop))
;
; so `local.get` is on every path, and this layer is what makes the dispatch
; expressible.
;
; TWO REPRESENTATION FACTS, both found by measuring rather than by reading:
;
;   * a local is stored as a SINGLETON LIST holding its value --
;     (:LOCALS ((:CONST (:I32) 0)) ((:CONST (:I32) 9)) ...) -- which is why the
;     rule's value is (CAR ($LOCAL Z X)) and why $LOCAL itself answers a list.
;     Writing the locals unwrapped makes every lean on this layer answer NIL, and
;     looks exactly like "the semantics has no local.get rule".
;
;   * the config is (:;% Z instrs) where Z is (:;% STORE FRAME).  Passing the STORE
;     where Z belongs also answers NIL, silently.  This is the same trap that
;     abs.lisp records for $WITH_MEM and $WITH_GLOBAL, and it cost a second
;     afternoon here: (step_read/split (:;% store frame instrs)) works,
;     (step_read/split (:;% store instrs)) does not, and neither complains.
;
; A bare instruction list cannot be stepped at all -- (step ...) answers NIL --
; because a body always executes inside a :LABEL_ or :FRAME_ admin.  The read layer
; is what steps the instruction itself; the context rules above it are layer 4.
;
; WHAT IS PROVED HERE.  local.get of all four locals with the frame's locals
; symbolic, in the abstract store with symbolic globals: the value read is whatever
; the frame holds, with no constraint on what that is.

(in-package "ACL2")

(include-book "reads")

; The artifact's frame with its locals replaced.  Everything else -- the module,
; the types -- stays the artifact's, which is what keeps the lookups concrete.
(defun frame-with-locals (locals)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%put-field *milawa-verified-frame* :locals locals))

; The abstraction for a configuration whose body is running in a call frame: the
; abstract memory and the frame's locals.  It takes no globals, and that is not an
; oversight -- local.get does not read one, and taking arguments a layer does not
; use is how a statement comes to promise more than it proves.
(defun mvm-abs-z-locals (bytes locals)
  (declare (xargs :guard t :verify-guards nil))
  (list :|%;%| (store-with-memory bytes) (frame-with-locals locals)))

; The four locals of the module's step, each a singleton list holding a symbolic
; value.  L0 is $op, L1 is $imm, L2 is $a, L3 is $b.
(defun mvm-locals (l0 l1 l2 l3)
  (declare (xargs :guard t))
  (list (list l0) (list l1) (list l2) (list l3)))

; $op: the value in local 0, whatever it is.
(defthm step-read-local-get-0
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                (list (list :local.get 0))))
         (list (list l0))))

; $imm: the value in local 1, whatever it is.
(defthm step-read-local-get-1
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                (list (list :local.get 1))))
         (list (list l1))))

; $a: the value in local 2, whatever it is.
(defthm step-read-local-get-2
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                (list (list :local.get 2))))
         (list (list l2))))

; $b: the value in local 3, whatever it is.
(defthm step-read-local-get-3
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                (list (list :local.get 3))))
         (list (list l3))))
