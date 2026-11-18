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

; The four-byte primitive, and the list version in terms of it: the decoder below
; reads with CAR/CADR/CADDR/CADDR, so this is the shape the proofs want.
(defun mvm-bytes4-to-word (b0 b1 b2 b3)
  (declare (xargs :guard t :verify-guards nil))
  (logapp 8 b0 (logapp 8 b1 (logapp 8 b2 (loghead 8 b3)))))

(defun mvm-bytes-to-word (bs)
  (declare (xargs :guard t :verify-guards nil))
  (mvm-bytes4-to-word (nth 0 bs) (nth 1 bs) (nth 2 bs) (nth 3 bs)))

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
  :hints (("Goal" :in-theory (e/d (mvm-word-to-bytes mvm-bytes-to-word
                                                    mvm-bytes4-to-word)
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

;; ---------------------------------------------------------------------------
;; Reading words back out of the image
;;
;; The module walks memory a word at a time, so the decoder consumes four bytes
;; per step rather than indexing with (nthcdr (* 4 i)).  The indexed version needs
;; (* 4 i) rewritten into (+ 4 (* 4 (i-1))) before the APPEND lemmas can match, and
;; the recognizer MVM-WORD-LIST-P then splits the induction into (INTEGERP (CAR WS)),
;; (<= 0 (CAR WS)) and (< (CAR WS) 2^32) cases at every step: 259 and then 4963
;; subgoals were measured.  The way out is a STEP rule about the append form, with
;; the recognizer's facts supplied by forward chaining and the recognizer itself
;; DISABLED.
;; ---------------------------------------------------------------------------

(defun mvm-word-list-p (ws)
  (declare (xargs :guard t))
  (if (consp ws)
      (and (unsigned-byte-p 32 (car ws))
           (mvm-word-list-p (cdr ws)))
    (equal ws nil)))

(defthm mvm-word-list-p-car
  (implies (and (mvm-word-list-p ws) (consp ws))
           (unsigned-byte-p 32 (car ws)))
  :rule-classes :forward-chaining)

(defthm mvm-word-list-p-cdr
  (implies (mvm-word-list-p ws)
           (mvm-word-list-p (cdr ws)))
  :rule-classes :forward-chaining)

(defun mvm-image-words (bytes n)
  (declare (xargs :guard (natp n) :verify-guards nil))
  (if (zp n)
      nil
    (cons (mvm-bytes4-to-word (car bytes)
                              (car (cdr bytes))
                              (car (cdr (cdr bytes)))
                              (car (cdr (cdr (cdr bytes)))))
          (mvm-image-words (cdr (cdr (cdr (cdr bytes)))) (1- n)))))

; The step rule.  A word's bytes are a literal four-list, so the four CARs and
; the CDDDDR of (append (word-to-bytes w) rest) all unfold, and what is left is
; the per-word round trip.
(defthm mvm-image-words-of-append-word
  (implies (and (unsigned-byte-p 32 w) (natp n))
           (equal (mvm-image-words (append (mvm-word-to-bytes w) rest) (+ 1 n))
                  (cons w (mvm-image-words rest n))))
  :hints (("Goal" :in-theory (e/d (mvm-image-words mvm-word-to-bytes
                                                  mvm-bytes4-to-word
                                                  mvm-bytes-to-word)
                                  (loghead logtail logapp)))))

; The base case of the induction needs to know that a non-cons word list is NIL,
; and the recognizer is disabled in the proof so it cannot be unfolded there.
(defthm mvm-word-list-p-of-atom
  (implies (atom ws)
           (equal (mvm-word-list-p ws)
                  (equal ws nil)))
  :hints (("Goal" :in-theory (enable mvm-word-list-p))))

; The region: decoding a word list's image gives the word list back, bottom-first.
(defthm mvm-image-words-of-mvm-word-list-to-bytes
  (implies (mvm-word-list-p ws)
           (equal (mvm-image-words (mvm-word-list-to-bytes ws) (len ws))
                  ws))
  ; MVM-WORD-TO-BYTES and the byte-level decoders stay DISABLED: unfolding them
  ; brings LOGHEAD/LOGTAIL into the goal, and ACL2 then splits on the arithmetic
  ; (9.5M prover steps were measured that way).  The step rule
  ; MVM-IMAGE-WORDS-OF-APPEND-WORD already knows what the bytes mean, so the
  ; induction never needs to see them.
  :hints (("Goal" :induct (len ws)
                  :in-theory (e/d (mvm-word-list-to-bytes)
                                  (mvm-word-list-p mvm-image-words
                                   mvm-word-to-bytes mvm-bytes-to-word
                                   mvm-bytes4-to-word)))))

; ... and the stack region, which is MVM's stack bottom-first: the module pushes
; at increasing addresses while MVM keeps the most recent value first.
;; REVAPPEND generalises: the accumulator must be a word list too, so state the
;; lemma that way and get the NIL case by instantiation.
(defthm mvm-word-list-p-of-revappend
  (implies (and (mvm-word-list-p x)
                (mvm-word-list-p acc))
           (mvm-word-list-p (revappend x acc)))
  :hints (("Goal" :induct (revappend x acc)
                  :in-theory (enable mvm-word-list-p revappend))))

(defthm mvm-word-list-p-of-revappend-nil
  (implies (mvm-word-list-p x)
           (mvm-word-list-p (revappend x nil)))
  :hints (("Goal" :use ((:instance mvm-word-list-p-of-revappend (acc nil)))
                  :in-theory (enable mvm-word-list-p))))

(defthm mvm-image-of-stack
  (implies (mvm-word-list-p stack)
           (equal (mvm-image-words (mvm-stack-image stack) (len stack))
                  (revappend stack nil)))
  :hints (("Goal" :in-theory (e/d (mvm-stack-image)
                                  (mvm-image-words-of-mvm-word-list-to-bytes mvm-word-list-p))
                  :use ((:instance mvm-image-words-of-mvm-word-list-to-bytes
                                   (ws (revappend stack nil)))))))
