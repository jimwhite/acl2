; L1, the memory correspondence.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; L1 says a run of the module corresponds to MVM-STEP.  For that statement to
; mean anything, an MVM state has to be mapped to the bytes the module's memory
; holds: the operand stack below 4096, the code above it, one 32-bit
; little-endian word per value (see the header of ../wasm/milawa-verified.wat).
; This book defines that map and proves the two facts everything else needs --
; that a word survives the round trip through its bytes, and that the image has
; the length the arithmetic says it should.
;
; Two details that are easy to get wrong, and are the reason this book exists
; rather than being folded into the statement:
;
;   * the operand stack is TOP-FIRST in the model (MVM's stack is a list whose
;     CAR is the most recent value) but BOTTOM-FIRST in memory (the module pushes
;     at increasing addresses), so the image reverses it;
;   * the module's values are unsigned 32-bit words, because that is what i32
;     load/store moves, so a word is four bytes and no more.

(in-package "ACL2")

; IH S (the integer hardware library in books/ihs) supplies the bit-vector
; lemmas; with plain MOD/FLOOR the round trip below is provable in principle but
; needs the digit decomposition by hand, and there is no reason to redo that.
(include-book "ihs/logops-lemmas" :dir :system)

;; ---------------------------------------------------------------------------
;; A word and its bytes
;; ---------------------------------------------------------------------------

; LOGHEAD/LOGTAIL/LOGAPP rather than MOD/FLOOR: these are the functions the
; library's lemmas are about, and I32 load/store is exactly a little-endian
; four-byte move.

(defun mvm-word-to-bytes (w)
  (declare (xargs :guard t :verify-guards nil))
  (list (loghead 8 w)
        (loghead 8 (logtail 8 w))
        (loghead 8 (logtail 16 w))
        (loghead 8 (logtail 24 w))))

(defun mvm-bytes-to-word (bs)
  (declare (xargs :guard t :verify-guards nil))
  (logapp 8 (nth 0 bs)
          (logapp 8 (nth 1 bs)
                  (logapp 8 (nth 2 bs)
                          (loghead 8 (nth 3 bs))))))

(defun mvm-bytes-p (bs)
  (declare (xargs :guard t))
  (if (consp bs)
      (and (integerp (car bs))
           (<= 0 (car bs))
           (< (car bs) 256)
           (mvm-bytes-p (cdr bs)))
    (equal bs nil)))

; The round trip: a 32-bit word survives being written and read back.  This is
; the one fact the memory correspondence rests on, and with LOGHEAD/LOGTAIL the
; library's LOGAPP lemmas do the work.
(defthm mvm-bytes-to-word-of-word-to-bytes
  (implies (unsigned-byte-p 32 w)
           (equal (mvm-bytes-to-word (mvm-word-to-bytes w)) w))
  ; LOGHEAD, LOGTAIL and LOGAPP stay DISABLED: their definitions expand into MOD
  ; and FLOOR, after which the library's algebraic lemmas about them no longer
  ; match and the goal becomes a mess of rationals.  This is the same lesson as
  ; keeping MILAWA-STEP symbolic, in a different library.
  :hints (("Goal" :in-theory (e/d (mvm-word-to-bytes mvm-bytes-to-word)
                                  (loghead logtail logapp)))))

(defthm mvm-word-to-bytes-length
  (equal (len (mvm-word-to-bytes w)) 4))

;; ---------------------------------------------------------------------------
;; Words to bytes, in the order the module lays them out
;; ---------------------------------------------------------------------------

(defun mvm-word-list-to-bytes (ws)
  (declare (xargs :guard (true-listp ws) :verify-guards nil))
  (if (consp ws)
      (append (mvm-word-to-bytes (car ws))
              (mvm-word-list-to-bytes (cdr ws)))
    nil))

(defthm mvm-word-list-to-bytes-length
  (equal (len (mvm-word-list-to-bytes ws))
         (* 4 (len ws))))

; The structural fact the slot lemma below will need: the image of an append is
; the append of the images.  (This one goes through; the Nthcdr version does not,
; see the note at the end of the book.)
(defthm mvm-word-list-to-bytes-of-append
  (equal (mvm-word-list-to-bytes (append a b))
         (append (mvm-word-list-to-bytes a)
                 (mvm-word-list-to-bytes b))))

;; ---------------------------------------------------------------------------
;; The two regions
;; ---------------------------------------------------------------------------

; The module's layout constants, repeated here so the proofs and the .wat agree
; by construction rather than by memory.  CODE_BASE is also one of the module's
; eight exports, so a loader does not have to hard-code it.
(defconst *mvm-stack-base* 0)
(defconst *mvm-code-base* 4096)

; The operand stack, reversed: MVM keeps the most recent value first, memory
; keeps the first value pushed at the lowest address.
; Reversing a list does not change its length, and appending adds lengths; these
; are what make the stack image's length arithmetic go through, and neither is a
; rewrite rule by default.
(defthm len-of-revappend
  (equal (len (revappend x y)) (+ (len x) (len y)))
  :hints (("Goal" :induct (revappend x y)
                  :in-theory (enable revappend len))))

(defthm len-of-revappend-nil
  (equal (len (revappend x nil)) (len x)))

(defun mvm-stack-image (stack)
  (declare (xargs :guard (true-listp stack) :verify-guards nil))
  (mvm-word-list-to-bytes (revappend stack nil)))

(defun mvm-code-image (code)
  (declare (xargs :guard (true-listp code) :verify-guards nil))
  (mvm-word-list-to-bytes code))

(defthm mvm-stack-image-length
  (equal (len (mvm-stack-image stack)) (* 4 (len stack))))

; The stack region stays below the code region as long as at most 1024 values
; are on the stack -- the invariant the module's layout needs in order not to
; overwrite its own program.  Stated as the inequality rather than as a magic
; number, so the hypothesis L1 will carry is visible in the statement.
(defthm mvm-regions-disjoint
  (implies (< (* 4 (len stack)) *mvm-code-base*)
           (< (len (mvm-stack-image stack)) *mvm-code-base*)))

;; ---------------------------------------------------------------------------
;; Next: reading a stack slot back out of the image
;;
;; L1's i32.load cases need to know which stack element a four-byte load returns,
;; which is this lemma:
;;
;;   (defthm mvm-stack-image-slot
;;     (implies (and (natp i) (< i (len stack)) (unsigned-byte-p 32 (nth i stack)))
;;              (equal (mvm-bytes-to-word (take 4 (nthcdr (* 4 i)
;;                                             (mvm-stack-image stack))))
;;                     (nth (- (len stack) 1 i) stack))))
;;
;; (the stack is top-first, so byte offset 4i is the element (len stack)-1-i from
;; the top).  It rests on
;;
;;   (equal (nthcdr (* 4 i) (mvm-word-list-to-bytes ws))
;;          (mvm-word-list-to-bytes (nthcdr i ws)))
;;
;; which is the shape to prove by induction on WS with I general, splitting on
;; (zp i): the i>0 case is Nthcdr-of-nthcdr then the induction hypothesis, and the
;; i=0 case is trivial.  DO NOT let ACL2 induct on (nthcdr i ws) instead -- that
;; was tried and it spent 387 s and 56 GB before giving up, because the (* 4 i)
;; inside NTHCDR blocks the step case.  The APPEND lemma above is the part of that
;; proof that does go through, and is kept for it.

