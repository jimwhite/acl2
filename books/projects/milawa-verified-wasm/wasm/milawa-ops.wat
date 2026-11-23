;;; milawa-ops.wasm: the per-opcode compute library for the J2b slice.
;;;
;;; Each exported function is one integer arithmetic/control operation from
;;; the J2a machine's subset.  The functions are pure: they take their operands
;;; and return a value; the stack/pc/control live in the ACL2 machine.  STEP
;;; is the tiny dispatcher over the opcode table.
;;;
;;; Opcodes (the checked table in refinement/ops.lisp):
;;;   0 halt, 1 const, 2 add, 3 sub, 4 lt, 5 ifz, 6 jmp, 7 label.

(module
  (func (export "op_const") (param i32) (result i32)
    (local.get 0))

  (func (export "op_add") (param i32 i32) (result i32)
    (i32.add (local.get 0) (local.get 1)))

  (func (export "op_sub") (param i32 i32) (result i32)
    (i32.sub (local.get 0) (local.get 1)))

  (func (export "op_lt") (param i32 i32) (result i32)
    (i32.lt_s (local.get 0) (local.get 1)))

  (func (export "op_ifz") (param i32 i32) (result i32)
    (i32.mul (local.get 1) (i32.eqz (local.get 0))))

  (func (export "op_jmp") (param i32 i32) (result i32)
    (local.get 1))

  (func (export "op_label") (param i32 i32) (result i32)
    (local.get 0))

  (func (export "step") (param i32 i32 i32) (result i32)
    (if (i32.eq (local.get 0) (i32.const 0))
        (then (return (local.get 1))))
    (if (i32.eq (local.get 0) (i32.const 1))
        (then (return (local.get 1))))
    (if (i32.eq (local.get 0) (i32.const 2))
        (then (return (i32.add (local.get 1) (local.get 2)))))
    (if (i32.eq (local.get 0) (i32.const 3))
        (then (return (i32.sub (local.get 1) (local.get 2)))))
    (if (i32.eq (local.get 0) (i32.const 4))
        (then (return (i32.lt_s (local.get 1) (local.get 2)))))
    (if (i32.eq (local.get 0) (i32.const 5))
        (then (return (i32.mul (local.get 2) (i32.eqz (local.get 1))))))
    (if (i32.eq (local.get 0) (i32.const 6))
        (then (return (local.get 2))))
    (if (i32.eq (local.get 0) (i32.const 7))
        (then (return (local.get 1))))
    (i32.const 0)))
