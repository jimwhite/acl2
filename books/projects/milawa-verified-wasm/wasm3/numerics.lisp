; L1, the numeric bridge between the spec's little-endian bytes and the
; project's word image.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The module reads and writes its operand stack and its code with i32.load and
; i32.store, so the spec's memory is a byte array, while the MVM abstraction in
; memory.lisp writes a word as the four bytes in MVM-WORD-TO-BYTES.  For an
; i32.load to be provable, the two spellings have to be the same list of bytes,
; and the spec's own encode/decode pair has to round-trip:
;
;   word-to-bytes-is-le-bytes       (MVM-WORD-TO-BYTES w) = ($le-bytes 4 w)
;   le-int-of-le-bytes-4            ($le-int ($le-bytes 4 w)) = w mod 2^32
;   inv-nbytes-of-word-bytes        ($inv_nbytes_ i32 (word bytes of w)) = w
;   nbytes-of-word                  ($nbytes_ i32 w) = (word bytes of w)
;   nbytes-of-inv-nbytes-word-bytes ($nbytes_ i32 ($inv_nbytes_ i32 B)) = B
;
; The last two are the two directions of the load's guard check, stated at the
; shapes the semantics' Step_read/load-num-val rule produces (see the rule in
; 4_3-execution_instructions.lisp: it reads C = ($inv_nbytes_ NT (take ...)),
; then checks ($nbytes_ NT C) = (take ...)).
;
; This book exists apart from memory.lisp because these facts mention the
; generated semantics (package W3T), which memory.lisp deliberately does not
; include: memory.lisp is the abstraction's vocabulary, and this is the bridge
; from it to the spec's vocabulary.
;
; Two proof notes, both measured, both worth knowing before touching this:
;
;   * Do not let FLOOR and MOD unfold.  ACL2 normalizes them to a
;     numerator/denominator form, and then the same floor-of-floor identity
;     appears with two spellings and the arithmetic never closes.  The facts
;     here are stated with FLOOR and MOD kept abstract and are proved with
;     ihs/quotient-remainder-lemmas' MOD-X-I*J-OF-POSITIVES and
;     FLOOR-FLOOR-INTEGER doing the arithmetic.
;
;   * A recursive function whose body calls FLOOR or MOD does not unfold by its
;     definition rule in a theory where FLOOR and MOD are disabled (measured on
;     %LE-BYTES: the same goal proves with (enable %le-bytes) and stalls with
;     the definition enabled but floor/mod disabled).  Give the k = 4
;     unfoldings explicitly with :expand, which does unfold.

(in-package "MILAWA-WASM")

(include-book "../wasm-acl2/translate/gen/wasm-3.0/wasm3")
(include-book "memory")
(include-book "ihs/quotient-remainder-lemmas" :dir :system)

;; ---------------------------------------------------------------------------
;; The two names for a word's bytes
;; ---------------------------------------------------------------------------

; MVM-WORD-TO-BYTES uses LOGHEAD/LOGTAIL; %LE-BYTES uses MOD/FLOOR.  These four
; rules are the translation, one per byte position.  Measured: 1947, 501, 501,
; 501 prover steps.
(defthm loghead-8-is-mod
  (implies (integerp w) (equal (loghead 8 w) (mod w 256))))

(defthm logtail-8-is-floor
  (implies (integerp w) (equal (logtail 8 w) (floor w 256))))

(defthm logtail-16-is-floor
  (implies (integerp w) (equal (logtail 16 w) (floor w 65536))))

(defthm logtail-24-is-floor
  (implies (integerp w) (equal (logtail 24 w) (floor w 16777216))))

; %LE-BYTES 4 builds the bytes from nested floors, MVM-WORD-TO-BYTES from the
; flat ones (floor w 65536, floor w 16777216).  These two flatten the nesting,
; so the two sides meet literally.  Both are immediate from
; FLOOR-FLOOR-INTEGER (0 prover steps).
(defthm floor-flatten-65536
  (implies (integerp w)
           (equal (floor (floor w 256) 256) (floor w 65536)))
  :hints (("Goal" :in-theory (disable floor)
                  :use ((:instance acl2::floor-floor-integer
                                   (x w) (i 256) (j 256))))))

(defthm floor-flatten-16777216
  (implies (integerp w)
           (equal (floor (floor w 65536) 256) (floor w 16777216)))
  :hints (("Goal" :in-theory (disable floor)
                  :use ((:instance acl2::floor-floor-integer
                                   (x w) (i 65536) (j 256))))))

; The bridge.  The :expand list is the four unfoldings of the recursive
; %LE-BYTES; ACL2's definition rule does not take them here (see the note
; above).  Measured: 7542 prover steps.
(defthm word-to-bytes-is-le-bytes
  (implies (integerp w)
           (equal (mvm-word-to-bytes w) (w3t::%le-bytes 4 w)))
  :hints (("Goal" :expand ((w3t::%le-bytes 4 w)
                           (w3t::%le-bytes 3 (floor w 256))
                           (w3t::%le-bytes 2 (floor w 65536))
                           (w3t::%le-bytes 1 (floor w 16777216)))
                  :in-theory (e/d () (floor mod)))))

;; ---------------------------------------------------------------------------
;; The spec's decode/encode round trip at four bytes
;; ---------------------------------------------------------------------------

; ($le-int ($le-bytes 4 w)) = w mod 2^32.  The three MOD-X-I*J-OF-POSITIVES
; instances are the digit decomposition 256^4 = 256 * 256^3 = ... and the
; expansion above supplies the same digits on the left.  Measured: 9165 steps.
(defthm le-int-of-le-bytes-4
  (implies (integerp w)
           (equal (w3t::%le-int (w3t::%le-bytes 4 w))
                  (mod w (expt 256 4))))
  :hints (("Goal" :expand ((w3t::%le-bytes 4 w)
                           (w3t::%le-bytes 3 (floor w 256))
                           (w3t::%le-bytes 2 (floor w 65536))
                           (w3t::%le-bytes 1 (floor w 16777216)))
                  :in-theory (e/d (w3t::%le-int) (floor mod))
                  :use ((:instance acl2::mod-x-i*j-of-positives
                                   (x w) (i 256) (j 16777216))
                        (:instance acl2::mod-x-i*j-of-positives
                                   (x (floor w 256)) (i 256) (j 65536))
                        (:instance acl2::mod-x-i*j-of-positives
                                   (x (floor w 65536)) (i 256) (j 256))))))

; %U is the spec's wrap to N bits; a word that already fits is unchanged.
; Measured: 1045 prover steps.
(defthm u32-of-word
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::%u 32 w) w))
  :hints (("Goal" :in-theory (enable w3t::%u w3t::%pow2))))

; The same round trip directly on the image's bytes, which is the form the
; load's value has.  Measured: 860 prover steps.
(defthm le-int-of-word-bytes
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::%le-int (mvm-word-to-bytes w)) w))
  :hints (("Goal" :use ((:instance le-int-of-le-bytes-4)
                        (:instance u32-of-word)))))

;; ---------------------------------------------------------------------------
;; $NBYTES_ and $INV_NBYTES_ at i32
;; ---------------------------------------------------------------------------

; The spec's i32 load value of a word's bytes is the word.  Measured: 419.
(defthm inv-nbytes-of-word-bytes
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::$inv_nbytes_ '(:i32) (mvm-word-to-bytes w)) w))
  :hints (("Goal" :in-theory (enable w3t::$inv_nbytes_ w3t::$inv_ibytes_
                                    w3t::$nbytes_ w3t::$ibytes_
                                    w3t::%u w3t::%pow2
                                    w3t::%num-size w3t::%int-nt-p))))

; The spec's i32 encoding of a word is the image's bytes.  Measured: 711.
(defthm nbytes-of-word
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::$nbytes_ '(:i32) w) (mvm-word-to-bytes w)))
  :hints (("Goal" :in-theory (enable w3t::$nbytes_ w3t::$ibytes_
                                    w3t::%u w3t::%pow2
                                    w3t::%num-size w3t::%int-nt-p))))

; The load rule's guard check, at the exact shape it checks: encode the decoded
; bytes and get them back.  Measured: 2167.
(defthm nbytes-of-inv-nbytes-word-bytes
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::$nbytes_ '(:i32)
                                 (w3t::$inv_nbytes_ '(:i32)
                                                    (mvm-word-to-bytes w)))
                  (mvm-word-to-bytes w)))
  :hints (("Goal" :use ((:instance inv-nbytes-of-word-bytes)
                        (:instance nbytes-of-word)))))
