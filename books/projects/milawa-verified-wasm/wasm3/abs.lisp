; L1, the abstraction: an MVM state as a configuration of the certified semantics.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; L1 says that one call to the module's exported STEP is one MVM-STEP.  For that
; to be a statement at all, an MVM state has to be turned into a configuration of
; the certified WASM 3.0 semantics, and the result of running that configuration
; has to be read back as an MVM state.  This book defines that map, and then
; checks it on every path the module has.
;
; ---------------------------------------------------------------------------
; The map
;
;   mvm-abs-z      MVM state -> the spec's store-and-frame pair Z
;   mvm-abs        MVM state -> the spec's ENTRY configuration for a call to
;                  function 6 (the exported STEP), with no arguments
;   milawa-*       the inverse observations: globals 0..4, and words out of the
;                  memory region
;
; The store is the pinned *MILAWA-VERIFIED-STORE* -- the artifact's own store,
; certified by DECODE -- with two regions written into memory and five globals
; set: SP (byte offset), PC (byte address, so 4096 + 4*word-index), CODE-LEN
; (words), STATUS and RESULT.  Those five globals are the whole of the module's
; mutable state apart from the memory itself, which is why reading them back is
; an inverse.
;
; The memory and the globals are updated through the spec's own constructors,
; $WITH_MEM and $WITH_GLOBAL, rather than by rebuilding the store: they are the
; functions the module's own i32.store and global.set reduce to, so the
; abstraction and the implementation meet in the middle rather than in two
; independently-invented encodings.  Both take the store-and-frame pair Z, not a
; store -- ($SOF Z) is the store and ($FOF Z) the frame, and the module vector
; that maps a module index to a store slot lives in the FRAME's :MODULE field.
; That last fact is worth writing down: it is why mvm-abs-z starts from
; *MILAWA-VERIFIED-FRAME* and why the store alone cannot be updated.
;
; ---------------------------------------------------------------------------
; What is proved here
;
; For sixteen states -- every opcode, every abort case, and the two frozen
; statuses -- the certified semantics, started from mvm-abs of the state, takes
; exactly the clock shown and then cannot step again; and the configuration it
; stops on has globals and memory that read back as MVM-STEP of the state.  Each
; is a ground theorem, proved by evaluation: no symbolic reasoning, no hypothesis
; about the module beyond "this is the artifact".
;
; That is not L1.  L1 is the same statement with the state symbolic, and it is a
; symbolic execution of the module's twelve function bodies -- the work the
; wasm-acl2 engine calls E11 and has not finished either.  What these sixteen
; theorems do is fix the STATEMENT, which is the part that is easy to get wrong
; (the store-or-Z distinction alone cost several wrong starts), pin the clock for
; every path, and give the symbolic proof its per-path skeleton and its target
; facts.  They are also the regression test for the abstraction: if mvm-abs or
; the inverse drifts from the module, one of these sixteen stops proving.
;
; ---------------------------------------------------------------------------
; The clock
;
;   already halted (status 0)                     9   the status guard alone
;   already aborted (status 2)                    9
;   PC off the end of the code                   26   status guard + $in_code
;   HALT with an empty stack                     47   status + $in_code + abort
;   HALT, one value                              53
;   HALT, two values (pops one, keeps one)       53
;   CONST                                        67
;   CONST with the immediate word off the end    55   (aborts before reading it)
;   ADD / SUB / LT                               96 / 101 / 101
;   ADD with less than two values                63
;   IFZ, branch taken                            99
;   IFZ, branch not taken                        95
;   JMP                                          78
;   unknown opcode                               63
;
; So one machine step is 47 to 101 spec steps, and the count is a function of the
; opcode alone -- it does not depend on the values, which is what makes the
; symbolic version's clock formula a small case split rather than a search.
;
; The numbers come from the module's own structure and are stable: the four
; checks up front (status, in_code) cost the same everywhere, each `call` costs a
; frame, and each `if` that is taken costs more than one that is not.  Two of
; them are worth reading twice: an unknown opcode is cheaper than a known one
; (63 < 96) because it falls out of the dispatch chain straight into $abort, and
; CONST with the immediate off the end is *cheaper* than a good CONST (55 < 67)
; because it aborts before pushing.

(in-package "MILAWA-WASM")

(include-book "/workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0/wasm3")
(include-book "state")
(include-book "memory")
(include-book "../machine/mvm")

;; ---------------------------------------------------------------------------
;; Reading a configuration back as machine state
;; ---------------------------------------------------------------------------

; A module global, read through the spec's own accessor so that the reading uses
; the same lookup the module's global.get does -- through the module's vector of
; store slots, which lives in the frame.
;
; The frame used for that lookup is the PINNED one, not the configuration's own.
; It has to be: $INVOKE builds its frame with the module in a different shape, and
; %GET-FIELD cannot read a module out of it (measured: it answers NIL, so a
; global.get through it would fail).  That does not matter, because the module is
; a constant of the artifact -- only the STORE varies, and $GLOBAL's other half,
; (%GET-FIELD ($SOF Z) :GLOBALS), is exactly the part that varies.  Reading the
; store through the artifact's index vector is therefore the observation we want,
; and it is the same one the module itself makes while it runs.
(defun milawa-global (z i)
  (declare (xargs :guard t :verify-guards nil))
  (let* ((g (w3t::$global (list :|%;%| (cadr z) *milawa-verified-frame*) i))
         (v (and (consp g) (w3t::%get-field g :value))))
    (if (and (consp v) (equal (len v) 3))
        (caddr v)          ; a value is (:CONST AT I), so the integer is I
      v)))

(defun milawa-mem-bytes (z)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%get-field (car (w3t::%get-field (w3t::$sof z) :mems)) :bytes))

; The word at absolute byte address A, little-endian, as the module's i32.load
; reads it.
(defun milawa-word-at (z a)
  (declare (xargs :guard t :verify-guards nil))
  (let ((b (milawa-mem-bytes z)))
    (+ (nth a b)
       (* 256 (nth (+ 1 a) b))
       (* 65536 (nth (+ 2 a) b))
       (* 16777216 (nth (+ 3 a) b)))))

(defun milawa-words (z a n)
  (declare (xargs :guard t :verify-guards nil))
  (if (zp n)
      nil
    (cons (milawa-word-at z a)
          (milawa-words z (+ 4 a) (1- n)))))

; What a configuration says about the machine it came from.  This is the
; statement of L1's conclusion, written once so that the sixteen paths below and
; the symbolic proof that has to follow all say the same thing.
(defun milawa-observations (z st)
  (declare (xargs :guard t :verify-guards nil))
  (and (equal (milawa-global z 0) (* 4 (len (mvm-stack st))))
       (equal (milawa-global z 1) (+ *mvm-code-base* (* 4 (mvm-pc st))))
       (equal (milawa-global z 2) (len (mvm-code st)))
       (equal (milawa-global z 3) (mvm-status st))
       (equal (milawa-global z 4) (mvm-result st))
       ; Memory holds the stack bottom-first; MVM keeps it top-first.
       (equal (milawa-words z *mvm-stack-base* (len (mvm-stack st)))
              (revappend (mvm-stack st) nil))))

;; ---------------------------------------------------------------------------
;; The map
;; ---------------------------------------------------------------------------

; The store-and-frame pair the module runs against, for a given machine state.
; Z is what $WITH_MEM and $WITH_GLOBAL take, and (CADR Z) is the store, which is
; what $INVOKE takes.
; Set a run of module globals, starting at index I, to a list of integers.  Each
; global holds a value, and a value is (:CONST AT I), which is why the integer V
; appears twice removed; writing this as a recursion rather than as five nested
; calls keeps mvm-abs-z readable, and it is still one $WITH_GLOBAL per field.
(defun milawa-set-globals (z i vs)
  (declare (xargs :guard t :verify-guards nil))
  (if (consp vs)
      (milawa-set-globals (w3t::$with_global z i (list :const (list :i32) (car vs)))
                          (+ 1 i)
                          (cdr vs))
    z))

(defun mvm-abs-z (st)
  (declare (xargs :guard t :verify-guards nil))
  (let* ((simg (mvm-stack-image (mvm-stack st)))
         (cimg (mvm-code-image (mvm-code st)))
         (z0 (list :|%;%| *milawa-verified-store* *milawa-verified-frame*))
         (z1 (w3t::$with_mem z0 0 *mvm-stack-base* (len simg) simg))
         (z2 (w3t::$with_mem z1 0 *mvm-code-base* (len cimg) cimg)))
    (milawa-set-globals z2 0 (list (len simg)
                                   (+ *mvm-code-base* (* 4 (mvm-pc st)))
                                   (len (mvm-code st))
                                   (mvm-status st)
                                   (mvm-result st)))))

; The entry configuration: a call to function 6, which DECODE's
; MILAWA-VERIFIED-STEP-IS-FUNCTION-6 says is the exported STEP.
(defun mvm-abs (st)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::$invoke (cadr (mvm-abs-z st)) 6 nil))

;; ---------------------------------------------------------------------------
;; The check, in the shape the symbolic proof will have
;; ---------------------------------------------------------------------------

; S steps, from the entry configuration, are not enough to finish the call; S+1
; are, and the configuration that cannot step again reads back as MVM-STEP of the
; state.  Stating the clock from both sides is what makes it the exact clock
; rather than a bound: STEPS/%FUEL answers NIL when it exhausts its fuel, and the
; stuck configuration when the machine stops on its own.  (The off-by-one is the
; reason for the S+1: STEPS/%FUEL spends a step and then asks STEP whether there
; is another, so it needs one more than the successful steps to report success.)
(defun milawa-step-check (s st)
  (declare (xargs :guard t :verify-guards nil))
  (and (null (w3t::steps/%fuel s (mvm-abs st)))
       (let ((r (w3t::steps/%fuel (1+ s) (mvm-abs st))))
         (and (consp r)
              (null (w3t::step (car r)))
              (milawa-observations (cadr (car r)) (mvm-step st))))))

;; ---------------------------------------------------------------------------
;; The states: every opcode, every abort, both frozen statuses
;; ---------------------------------------------------------------------------

(defconst *abs-halt*           (list 1 0 (list 7) 0 (list 0)))
(defconst *abs-halt-multi*     (list 1 1 (list 5 8) 0 (list 0 0)))
(defconst *abs-const*          (list 1 0 nil 0 (list 1 42 0)))
(defconst *abs-add*            (list 1 0 (list 3 4) 0 (list 2)))
(defconst *abs-sub*            (list 1 0 (list 3 4) 0 (list 3)))
(defconst *abs-lt*             (list 1 0 (list 3 4) 0 (list 4)))
(defconst *abs-ifz-taken*      (list 1 0 (list 0) 0 (list 5 3 0)))
(defconst *abs-ifz-not-taken*  (list 1 0 (list 9) 0 (list 5 3 0)))
(defconst *abs-jmp*            (list 1 0 nil 0 (list 6 5 0 0 0 0)))
(defconst *abs-bad-opcode*     (list 1 0 nil 0 (list 9)))
(defconst *abs-halt-empty*     (list 1 0 nil 0 (list 0)))
(defconst *abs-const-truncated* (list 1 0 nil 0 (list 1)))
(defconst *abs-add-underflow*  (list 1 0 (list 3) 0 (list 2)))
(defconst *abs-pc-off-end*     (list 1 1 nil 0 (list 0)))
(defconst *abs-halted*         (list 0 0 (list 5) 5 (list 0)))
(defconst *abs-aborted*        (list 2 0 nil 0 (list 0)))

;; ---------------------------------------------------------------------------
;; One theorem per path
;;
;; Each is proved by evaluation: the semantics is run on the artifact, the
;; configuration it stops on is read back, and the reading is compared with
;; MVM-STEP.  The clock is on the theorem's left-hand side because it is a fact
;; about the module, not a parameter of the proof.
;; ---------------------------------------------------------------------------

(defthm abs-halt-53
  (milawa-step-check 53 *abs-halt*))

(defthm abs-halt-multi-53
  (milawa-step-check 53 *abs-halt-multi*))

(defthm abs-const-67
  (milawa-step-check 67 *abs-const*))

(defthm abs-add-96
  (milawa-step-check 96 *abs-add*))

(defthm abs-sub-101
  (milawa-step-check 101 *abs-sub*))

(defthm abs-lt-101
  (milawa-step-check 101 *abs-lt*))

(defthm abs-ifz-taken-99
  (milawa-step-check 99 *abs-ifz-taken*))

(defthm abs-ifz-not-taken-95
  (milawa-step-check 95 *abs-ifz-not-taken*))

(defthm abs-jmp-78
  (milawa-step-check 78 *abs-jmp*))

(defthm abs-bad-opcode-63
  (milawa-step-check 63 *abs-bad-opcode*))

(defthm abs-halt-empty-47
  (milawa-step-check 47 *abs-halt-empty*))

(defthm abs-const-truncated-55
  (milawa-step-check 55 *abs-const-truncated*))

(defthm abs-add-underflow-63
  (milawa-step-check 63 *abs-add-underflow*))

(defthm abs-pc-off-end-26
  (milawa-step-check 26 *abs-pc-off-end*))

(defthm abs-halted-9
  (milawa-step-check 9 *abs-halted*))

(defthm abs-aborted-9
  (milawa-step-check 9 *abs-aborted*))
