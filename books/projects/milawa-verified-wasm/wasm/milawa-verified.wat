;;; milawa-verified.wasm, milestone 1: one step of the Milawa machine.
;;;
;;; This is the module L1 is about.  It is written by hand, and hand-written code
;;; is where the trust has to be discharged: the ACL2 proofs say what this text
;;; does, so the text has to be readable, and this file is the whole of it.
;;;
;;; SHAPE.  Wasm gives us one exported function, STEP, which performs exactly one
;;; machine step.  That is the granularity of MILAWA-STEP in milawa-lisp/eval.lisp
;;; and of W3T::STEP in the certified WebAssembly semantics, so all three are
;;; directly comparable and the refinement proof (L1) never has to reason about a
;;; loop.
;;;
;;; The driver -- an untrusted host loop -- calls STEP until it answers 0.  The
;;; design document (books/projects/milawa/VERIFIED-WASM-LISP.md) says the shim
;;; can only cause a rejection, never a false acceptance, and this is the division
;;; of labour it means: the host decides when to stop asking, the module decides
;;; what a step is.
;;;
;;; MEMORY LAYOUT.  One page, three disjoint regions:
;;;
;;;   [0, 4096)        operand stack, one 32-bit word per value; SP is the byte
;;;                    offset of the next free word, so the stack is empty iff
;;;                    SP = 0
;;;   [4096, 8192)     code, one 32-bit word per instruction word; CODE_LEN is
;;;                    the number of words
;;;   [8192, ...)      free, for the frames and heap the later milestones need
;;;
;;; STATUS PROTOCOL.  0 = halted with a result, 1 = still running, 2 = aborted.
;;; STEP returns the status after the step, so a host loop is
;;; `while (step() === 1) {}`.  A machine that has halted or aborted stays that
;;; way: STEP is idempotent once it is no longer running.
;;;
;;; MILESTONE 1 SCOPE.  Values are 32-bit integers only.  That is enough to fix
;;; the interface -- exported functions, status protocol, memory regions -- which
;;; is the part L1 and L2 are stated against.  Conses, symbols, environments and
;;; the frame stack come next, and they extend this file rather than replace it.

(module
  (memory (export "memory") 1)

  (global $sp (mut i32) (i32.const 0))        ;; operand stack, byte offset
  (global $pc (mut i32) (i32.const 4096))     ;; byte address into the code region
  (global $code_len (mut i32) (i32.const 0))  ;; words of code
  (global $status (mut i32) (i32.const 1))    ;; see the protocol above
  (global $result (mut i32) (i32.const 0))    ;; valid when STATUS is 0

  ;; ---------------------------------------------------------------------
  ;; Operand stack
  ;; ---------------------------------------------------------------------

  (func $push (param $v i32)
    (i32.store (global.get $sp) (local.get $v))
    (global.set $sp (i32.add (global.get $sp) (i32.const 4))))

  (func $pop (result i32)
    (global.set $sp (i32.sub (global.get $sp) (i32.const 4)))
    (i32.load (global.get $sp)))

  ;; Depth in words.  Underflow is rejected rather than reading whatever happens
  ;; to be in memory.
  (func $depth (result i32)
    (i32.div_u (global.get $sp) (i32.const 4)))

  ;; Is there a whole word of code at the PC?  Used both for the instruction
  ;; word and for its immediate.
  (func $in_code (result i32)
    (i32.lt_u (i32.sub (global.get $pc) (i32.const 4096))
              (i32.mul (global.get $code_len) (i32.const 4))))

  (func $abort (result i32)
    (global.set $status (i32.const 2))
    (i32.const 2))

  ;; ---------------------------------------------------------------------
  ;; Reset: clear the machine and adopt a program length.  The host copies the
  ;; code words into the code region itself, then calls this, so that a program
  ;; can be run twice.
  ;; ---------------------------------------------------------------------

  (func (export "reset") (param $len i32)
    (global.set $sp (i32.const 0))
    (global.set $pc (i32.const 4096))
    (global.set $code_len (local.get $len))
    (global.set $status (i32.const 1))
    (global.set $result (i32.const 0)))

  ;; ---------------------------------------------------------------------
  ;; One machine step
  ;; ---------------------------------------------------------------------
  ;;
  ;; One opcode word, plus one immediate word for the opcodes that take one.  The
  ;; opcodes belong to the object language (Milawa-Lisp), not to wasm.

  (func (export "step") (result i32)
    (local $op i32)
    (local $imm i32)
    (local $a i32)
    (local $b i32)

    ;; A machine that is no longer running stays that way.
    (if (i32.ne (global.get $status) (i32.const 1))
        (then (return (global.get $status))))

    ;; Running off the end of the code is a malformed program.
    (if (i32.eqz (call $in_code))
        (then (return (call $abort))))

    (local.set $op (i32.load (global.get $pc)))
    (global.set $pc (i32.add (global.get $pc) (i32.const 4)))

    ;; --- HALT (0): stop, with the top of the stack as the result
    (if (i32.eq (local.get $op) (i32.const 0))
        (then
          (if (i32.eqz (call $depth))
              (then (return (call $abort))))
          (global.set $result (call $pop))
          (global.set $status (i32.const 0))
          (return (i32.const 0))))

    ;; --- CONST k (1): push the immediate
    (if (i32.eq (local.get $op) (i32.const 1))
        (then
          (if (i32.eqz (call $in_code))
              (then (return (call $abort))))
          (local.set $imm (i32.load (global.get $pc)))
          (global.set $pc (i32.add (global.get $pc) (i32.const 4)))
          (call $push (local.get $imm))
          (return (i32.const 1))))

    ;; --- ADD (2), SUB (3), LT (4): pop two, push one
    (if (i32.or (i32.or (i32.eq (local.get $op) (i32.const 2))
                        (i32.eq (local.get $op) (i32.const 3)))
                (i32.eq (local.get $op) (i32.const 4)))
        (then
          (if (i32.lt_u (call $depth) (i32.const 2))
              (then (return (call $abort))))
          ;; The stack holds a then b, so b is on top.
          (local.set $b (call $pop))
          (local.set $a (call $pop))
          (if (i32.eq (local.get $op) (i32.const 2))
              (then (call $push (i32.add (local.get $a) (local.get $b))))
              (else
               (if (i32.eq (local.get $op) (i32.const 3))
                   (then (call $push (i32.sub (local.get $a) (local.get $b))))
                   (else
                    ;; LT yields 1 or 0, which is the object language's boolean.
                    (call $push (i32.lt_s (local.get $a) (local.get $b)))))))
          (return (i32.const 1))))

    ;; --- IFZ k (5): pop; jump to word k when it was zero
    (if (i32.eq (local.get $op) (i32.const 5))
        (then
          (if (i32.eqz (call $in_code))
              (then (return (call $abort))))
          (local.set $imm (i32.load (global.get $pc)))
          (global.set $pc (i32.add (global.get $pc) (i32.const 4)))
          (if (i32.eqz (call $depth))
              (then (return (call $abort))))
          (if (i32.eqz (call $pop))
              (then (global.set $pc (i32.add (i32.const 4096)
                                             (i32.mul (local.get $imm)
                                                      (i32.const 4))))))
          (return (i32.const 1))))

    ;; --- JMP k (6): jump to word k
    (if (i32.eq (local.get $op) (i32.const 6))
        (then
          (if (i32.eqz (call $in_code))
              (then (return (call $abort))))
          (local.set $imm (i32.load (global.get $pc)))
          (global.set $pc (i32.add (i32.const 4096)
                                   (i32.mul (local.get $imm) (i32.const 4))))
          (return (i32.const 1))))

    ;; Unknown opcode: abort rather than guess.
    (call $abort))

  ;; ---------------------------------------------------------------------
  ;; Observation, for the host and for the differential tests
  ;; ---------------------------------------------------------------------

  (func (export "status") (result i32) (global.get $status))
  (func (export "result") (result i32) (global.get $result))
  (func (export "pc") (result i32) (global.get $pc))
  (func (export "sp") (result i32) (global.get $sp))
  (func (export "code_base") (result i32) (i32.const 4096)))
