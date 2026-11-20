; L1, layer 2: reading the store, symbolically.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; Layer 1 (instructions.lisp) proves the instructions whose meaning is entirely in
; the values on the stack.  This book is the next floor: instructions that READ the
; machine's state.  For our module that is `global.get`, and it is the single most
; important read, because the module's dispatch begins `(global.get $status)` and
; every address computation goes through `(global.get $pc)`.
;
; THE SHAPE.  The read rules need the store, so they take a CONFIGURATION rather
; than an instruction list:
;
;   (step_read/split (:;% Z instrs)) = (list instrs')
;
; and the answer is a singleton list of the new instruction list.  Measured
; concretely first (a pinned store, `(global.get 3)`): the value of global 3 comes
; back as a pushed `(:CONST (:I32) 1)`.
;
; WHY THIS IS WORTH ITS OWN BOOK.  It is the first place in this project where the
; STORE is symbolic: the five globals arrive as variables, the store is built from
; them by MILAWA-SET-GLOBALS, and the semantics has to dig the value back out.  If
; that did not work, no amount of arithmetic lemmas would help.  It does work --
; 12,101 prover steps for the first one -- because the lookup is `assoc-equal` on
; keys and the keys are concrete, which is the fact symbolic.lisp proved.
;
; All five globals are covered because all five are read by the module: SP and PC
; for addressing, CODE-LEN for the bounds checks, STATUS for the frozen test, and
; RESULT for the observation that ends a run.

(in-package "MILAWA-WASM")

(include-book "instructions")

; Global 0 -- the stack pointer, a byte offset.
(defthm step-read-global-get-0
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 0))))
         (list (list (list :const (list :i32) sp)))))

; Global 1 -- the program counter, a byte address.
(defthm step-read-global-get-1
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 1))))
         (list (list (list :const (list :i32) pc)))))

; Global 2 -- the code length, in words.
(defthm step-read-global-get-2
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 2))))
         (list (list (list :const (list :i32) clen)))))

; Global 3 -- the status word: what the module's dispatch reads first.
(defthm step-read-global-get-3
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 3))))
         (list (list (list :const (list :i32) status)))))

; Global 4 -- the result word, valid when the status says halted.
(defthm step-read-global-get-4
  (equal (w3t::step_read/split
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 4))))
         (list (list (list :const (list :i32) result)))))
