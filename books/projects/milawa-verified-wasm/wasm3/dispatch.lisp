; L1, the running branch: $in_code's body, the opcode test, and the
; dispatch's shared tail.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; running.lisp leaves the machine in function 3's frame with function 3's body
; at the head of its label:
;
;   (global.get 1) (const 4096) (binop sub)
;   (global.get 2) (const 4)  (binop mul) (relop lt_u)
;
; This book executes it: the sub, the read of the code length, the mul, the
; comparison (which is the LAST instruction of the body and so is stepped by the
; pure rule on the body, not by the search), and the two value dissolves that
; return the comparison's result to function 6.  It then takes the running
; path's in-code case (the comparison is 1): the opcode test pushes the
; concrete 0, the second ifelse takes its ELSE branch, and the empty block and
; label dissolve, leaving the opcode fetch at the head of function 6's label.
; The in-code hypothesis is what makes the testop's value concrete; at a
; symbolic value the search's measure guards do not close (SUMMARY.md records
; why).  The test's two slice facts are at the end of the earlier section, and
; their literal cons/quote corollaries -- the shapes the search actually
; produces -- are the first lemmas of the opcode-test section.
;
; EVERY STEP HAS THE SAME SEVEN PART PROOF, and the parts are separate lemmas so
; that each is a small rewrite problem rather than one deep one:
;
;   slice  -- the instruction's own step, on the exact three-or-two element slice
;   ctxt   -- step/r-ctxt-instrs on the body, with the search instances
;   step   -- the bridge from the context rule to `step`
;   label  -- the same step inside label 3
;   frame  -- the same step inside frame 3
;   body6  -- the same step inside label 6 (the search's k = 0 slice)
;   label6 -- the same step inside label 6's label
;   outer  -- the same step inside frame 6
;
; The values are kept as the spec's own terms ($BINOP_, $RELOP_, $TESTOP_): the
; intermediate results are what the next instruction consumes, and keeping them
; as terms is what lets the measure checks compare two spellings of the same
; list instead of two numbers.

(in-package "MILAWA-WASM")

(include-book "running")

;; ---------------------------------------------------------------------------
;; Bodies and values
;; ---------------------------------------------------------------------------

(defun dconst (v) (list :const (list :i32) v))

(defun dsub (pc) (car (w3t::$binop_ (list :i32) (list :sub) pc 4096)))
(defun dmul (clen) (car (w3t::$binop_ (list :i32) (list :mul) clen 4)))
(defun dltu (sub mul) (w3t::$relop_ (list :i32) (list :lt (list :u)) sub mul))
(defun deqz (pc clen)
  (w3t::$testop_ (list :i32) (list :eqz) (dltu (dsub pc) (dmul clen))))

; Function 3's body after each of its instructions.
(defun dbody0 (pc) (ibody3-after-1 pc))                                      ; after the read of global 1
(defun dbody1 (pc)
  (cons (dconst (dsub pc)) (nthcdr 3 (dbody0 pc))))                          ; after the sub
(defun dbody2 (pc clen)
  (cons (dconst (dsub pc))
        (cons (dconst clen) (nthcdr 2 (dbody1 pc)))))                        ; after the read of global 2
(defun dbody3 (pc clen)
  (cons (dconst (dsub pc))
        (cons (dconst (dmul clen)) (nthcdr 4 (dbody2 pc clen)))))            ; after the mul
(defun dbody4 (pc clen)
  (list (dconst (dltu (dsub pc) (dmul clen)))))                              ; after the comparison

; The admin around a body: frame 3 around label 3 around it.
(defun dadmin (b)
  (list (list :frame_%{%}% 1 (milawa-callee-frame 3)
              (list (list :label_%{%}% 1 nil b)))))

; frame 3 around a body, without the label (the shape after the label dissolves).
(defun dframe3 (b)
  (list (list :frame_%{%}% 1 (milawa-callee-frame 3) b)))

; THE FULL BODY AT LABEL 6: frame 3, then the rest of function 6.
; NOTE the APPEND: dadmin is a LIST of one instruction, so the frame instruction
; is (car (dadmin b)) and the tail is rest6.  Writing (cons (dadmin b) rest6)
; would put a list of instructions where an instruction belongs, and every
; measure and search fact below then quietly stops applying.
(defun dfull (b)
  (append (dadmin b) (cdr (nthcdr 4 *body-6*))))

; The same after the label dissolved, and after the frame dissolved.
(defun dfl (b)
  (append (dframe3 b) (cdr (nthcdr 4 *body-6*))))
(defun dvl (b)
  (append b (cdr (nthcdr 4 *body-6*))))
(defun dvl-after-testop (b)
  (append b (cddr (nthcdr 4 *body-6*))))
(defun dvl-after-ifelse (b)
  (append b (cdddr (nthcdr 4 *body-6*))))

(defun dcfg (bytes sp pc clen result b)
  (frozen-body-cfg bytes sp pc clen 1 result (dfull b)))

;; ---------------------------------------------------------------------------
;; The values are integers (needed by acl2-count in the context rules' measures)
;; ---------------------------------------------------------------------------

(defthm integerp-dltu
  (integerp (w3t::$relop_ (list :i32) (list :lt (list :u)) a b))
  :rule-classes :type-prescription)

(defthm ub32-testop-eqz
  (unsigned-byte-p 32 (w3t::$testop_ (list :i32) (list :eqz) c)))

(defthm integerp-testop-eqz
  (integerp (w3t::$testop_ (list :i32) (list :eqz) c))
  :hints (("Goal" :use (ub32-testop-eqz)))
  :rule-classes :type-prescription)

; The intermediate values, kept as opaque terms by the lift proofs below.  The
; facts here are what val-p and acl2-count need: each says the value is an
; integer (so acl2-count charges it as integer-abs, and two spellings of the
; same body compare without arithmetic), and each val-p fact lets the search's
; match13 accept the const that holds it.
(defthm un-p-dsub
  (implies (unsigned-byte-p 32 pc)
           (w3t::un-p (dsub pc) 32))
  :hints (("Goal" :in-theory (disable w3t::$binop_)
           :use ((:instance subval-is-a-value (a pc) (b 4096))))))

(defthm integerp-dsub
  (implies (unsigned-byte-p 32 pc)
           (integerp (dsub pc)))
  :hints (("Goal" :use un-p-dsub))
  :rule-classes :type-prescription)

(defthm un-p-dmul
  (implies (unsigned-byte-p 32 clen)
           (w3t::un-p (dmul clen) 32))
  :hints (("Goal" :in-theory (disable w3t::$binop_)
           :use ((:instance mulval-is-a-value (a clen) (b 4))))))

(defthm integerp-dmul
  (implies (unsigned-byte-p 32 clen)
           (integerp (dmul clen)))
  :hints (("Goal" :use un-p-dmul))
  :rule-classes :type-prescription)

(defthm un-p-dltu
  (w3t::un-p (dltu sub mul) 32)
  :hints (("Goal" :in-theory (disable w3t::$relop_)
           :use ltuval-is-a-value)))

(defthm un-p-deqz
  (w3t::un-p (deqz pc clen) 32)
  :hints (("Goal" :in-theory (disable w3t::$testop_)
           :use ub32-testop-eqz)))

;; ---------------------------------------------------------------------------
;; The slices: each instruction's own step
;; ---------------------------------------------------------------------------

(defthm dstep-slice-sub-raw
  (equal (w3t::step (icfg z (list (list :const (list :i32) pc)
                                  (list :const (list :i32) 4096)
                                  (list :binop (list :i32) (list :sub)))))
         (list (icfg z (list (list :const (list :i32) (dsub pc)))))))

(defthm dread-slice
  (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (list (list :global.get 2))))
         (list (icfg (iz3 bytes sp pc clen result) (list (dconst clen))))))

(defthm dmul-slice
  (equal (w3t::step (icfg (iz3 bytes sp pc clen result)
                          (list (dconst clen) (dconst 4) (list :binop (list :i32) (list :mul)))))
         (list (icfg (iz3 bytes sp pc clen result) (list (dconst (dmul clen)))))))

(defthm dltu-body
  (equal (w3t::step (icfg (iz3 bytes sp pc clen result)
                          (list (dconst (dsub pc)) (dconst (dmul clen))
                                (list :relop (list :i32) (list :lt (list :u))))))
         (list (icfg (iz3 bytes sp pc clen result)
                     (list (dconst (dltu (dsub pc) (dmul clen))))))))

;; ---------------------------------------------------------------------------
;; Position 2: the sub
;; ---------------------------------------------------------------------------


(defthm dctxt-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step/r-ctxt-instrs (icfg (iz3 bytes sp pc clen result) (dbody0 pc)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody1 pc)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody0 pc))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dbody0 pc)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (dbody0 pc)) (w3t::%t9 2)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody0 pc))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (dbody0 pc)) (w3t::%t9 2)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody0 pc))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                            (w3t::%t6 (dbody0 pc)) (w3t::%t9 2)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody0 pc))))
                 dstep-slice-sub-raw
                 (:instance fail-lone-sub (z (iz3 bytes sp pc clen result)))
                 (:instance fail-sub-one (z (iz3 bytes sp pc clen result)) (c 4096))))))

(defthm dstep-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (dbody0 pc)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody1 pc)))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-sub)
           :expand ((w3t::step (icfg (iz3 bytes sp pc clen result) (dbody0 pc)))))))

(defthm dlabel-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody0 pc)))))
                  (list (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody1 pc)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody0 pc))))))
                 dstep-sub))))

(defthm dframe-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody0 pc))))
                  (list (icfg (iz6 bytes sp pc clen result) (dadmin (dbody1 pc))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dadmin (dbody0 pc)))))
                 (:instance dlabel-sub)))))

(defthm dbody6-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody0 pc))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfull (dbody1 pc))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody0 pc)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfull (dbody0 pc))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfull (dbody0 pc))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody0 pc)))))
                 (:instance dframe-sub)))))

(defthm dlabel6-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody0 pc))))))
                  (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody1 pc))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody0 pc)))))))
                 (:instance dbody6-sub)))))

(defthm douter-sub
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (dcfg bytes sp pc clen result (dbody0 pc)))
                  (list (dcfg bytes sp pc clen result (dbody1 pc)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfull (dbody0 pc)))))))))
                 (:instance dlabel6-sub)))))

(defthm dctxt-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step/r-ctxt-instrs (icfg (iz3 bytes sp pc clen result) (dbody1 pc)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody1 pc))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dbody1 pc)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (dbody1 pc)) (w3t::%t9 1)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody1 pc))))
                 dread-slice))))

(defthm dstep-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (dbody1 pc)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen)))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-read)
           :expand ((w3t::step (icfg (iz3 bytes sp pc clen result) (dbody1 pc)))))))

(defthm dlabel-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody1 pc)))))
                  (list (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody2 pc clen)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody1 pc))))))
                 dstep-read))))

(defthm dframe-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody1 pc))))
                  (list (icfg (iz6 bytes sp pc clen result) (dadmin (dbody2 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dadmin (dbody1 pc)))))
                 (:instance dlabel-read)))))

(defthm dbody6-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody1 pc))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfull (dbody2 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody1 pc)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfull (dbody1 pc))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfull (dbody1 pc))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody1 pc)))))
                 (:instance dframe-read)))))

(defthm dlabel6-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody1 pc))))))
                  (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody2 pc clen))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody1 pc)))))))
                 (:instance dbody6-read)))))

(defthm douter-read
  (implies (and (unsigned-byte-p 32 pc))
           (equal (w3t::step (dcfg bytes sp pc clen result (dbody1 pc)))
                  (list (dcfg bytes sp pc clen result (dbody2 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfull (dbody1 pc)))))))))
                 (:instance dlabel6-read)))))

(defthm dctxt-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step/r-ctxt-instrs (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody3 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dbody2 pc clen)))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 3) (w3t::%lo 0) (w3t::%hi 3)
                            (w3t::%t6 (dbody2 pc clen)) (w3t::%t9 3)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 3)
                            (w3t::%t6 (dbody2 pc clen)) (w3t::%t9 3)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 3)
                            (w3t::%t6 (dbody2 pc clen)) (w3t::%t9 3)
                            (w3t::z (iz3 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen))))
                 dmul-slice
                 (:instance fail-lone-mul (z (iz3 bytes sp pc clen result)))
                 (:instance fail-mul-one (z (iz3 bytes sp pc clen result)) (c 4))))))

(defthm dstep-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen)))
                  (list (icfg (iz3 bytes sp pc clen result) (dbody3 pc clen)))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-mul)
           :expand ((w3t::step (icfg (iz3 bytes sp pc clen result) (dbody2 pc clen)))))))

(defthm dlabel-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody2 pc clen)))))
                  (list (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody3 pc clen)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dbody2 pc clen))))))
                 dstep-mul))))

(defthm dframe-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody2 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dadmin (dbody3 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dadmin (dbody2 pc clen)))))
                 (:instance dlabel-mul)))))

(defthm dbody6-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody2 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfull (dbody3 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody2 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfull (dbody2 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfull (dbody2 pc clen))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody2 pc clen)))))
                 (:instance dframe-mul)))))

(defthm dlabel6-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody2 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody3 pc clen))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody2 pc clen)))))))
                 (:instance dbody6-mul)))))

(defthm douter-mul
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 clen))
           (equal (w3t::step (dcfg bytes sp pc clen result (dbody2 pc clen)))
                  (list (dcfg bytes sp pc clen result (dbody3 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfull (dbody2 pc clen)))))))))
                 (:instance dlabel6-mul)))))

(defthm dlabel-ltu
  (equal (w3t::step (icfg (iz3 bytes sp pc clen result)
                          (list (list :label_%{%}% 1 nil (dbody3 pc clen)))))
         (list (icfg (iz3 bytes sp pc clen result)
                     (list (list :label_%{%}% 1 nil (dbody4 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz3 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil (dbody3 pc clen))))))
                 dltu-body))))

(defthm dframe-ltu
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody3 pc clen))))
         (list (icfg (iz6 bytes sp pc clen result) (dadmin (dbody4 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dadmin (dbody3 pc clen)))))
                 (:instance dlabel-ltu)))))

(defthm dbody6-ltu
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody3 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfull (dbody4 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody3 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfull (dbody3 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfull (dbody3 pc clen))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody3 pc clen)))))
                 (:instance dframe-ltu)))))

(defthm dlabel6-ltu
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody3 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody4 pc clen)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dfull (dbody3 pc clen)))))))
                 (:instance dbody6-ltu)))))

(defthm douter-ltu
  (equal (w3t::step (dcfg bytes sp pc clen result (dbody3 pc clen)))
                  (list (dcfg bytes sp pc clen result (dbody4 pc clen))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfull (dbody3 pc clen)))))))))
                 (:instance dlabel6-ltu)))))

;; ---------------------------------------------------------------------------
;; The two value dissolves: label 3, then frame 3
;; ---------------------------------------------------------------------------
;
; The comparison leaves its result as the instruction list of label 3.  A label
; whose body is all values dissolves to those values (step_pure/label-vals); a
; frame whose body is exactly its arity's worth of values dissolves too
; (step_pure/frame-vals).  The two steps are below, then the same label-6 /
; frame-6 lifts as everywhere else.

(defthm dlabel-dissolve
  (equal (w3t::step (icfg z (list (list :label_%{%}% 1 nil (dbody4 pc clen)))))
         (list (icfg z (dbody4 pc clen)))))

(defthm dframe3-dissolve-label
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody4 pc clen))))
         (list (icfg (iz6 bytes sp pc clen result) (dframe3 (dbody4 pc clen)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dadmin (dbody4 pc clen)))))
                 dlabel-dissolve))))

(defthm dbody6-label-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dadmin (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dframe3 (dbody4 pc clen)))))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody4 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfull (dbody4 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfull (dbody4 pc clen))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfull (dbody4 pc clen)))))
                 (:instance dframe3-dissolve-label)))))

(defthm dlabel6-label-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfull (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen)))))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dfull (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil (dfl (dbody4 pc clen))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil (dfull (dbody4 pc clen)))))))
                 (:instance dbody6-label-dissolve)))))

(defthm douter-label-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dfull (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil (dfl (dbody4 pc clen)))))))
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (dfull (dbody4 pc clen))))
                  (list (frozen-body-cfg bytes sp pc clen 1 result (dfl (dbody4 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfull (dbody4 pc clen)))))))))
                 (:instance dlabel6-label-dissolve)))))

(defthm dframe-dissolve
  (equal (w3t::step (icfg z (list (list :frame_%{%}% 1 (milawa-callee-frame 3) (dbody4 pc clen)))))
         (list (icfg z (dbody4 pc clen)))))

(defthm dbody6-frame-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dframe3 (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dbody4 pc clen))))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dvl (dbody4 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dfl (dbody4 pc clen))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dfl (dbody4 pc clen))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen)))))
                 (:instance dframe-dissolve)))))

(defthm dlabel6-frame-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dfl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result) (dvl (dbody4 pc clen)))))
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dfl (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil (dvl (dbody4 pc clen))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil (dfl (dbody4 pc clen)))))))
                 (:instance dbody6-frame-dissolve)))))

(defthm douter-frame-dissolve
  (implies (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dfl (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil (dvl (dbody4 pc clen)))))))
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (dfl (dbody4 pc clen))))
                  (list (frozen-body-cfg bytes sp pc clen 1 result (dvl (dbody4 pc clen))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dfl (dbody4 pc clen)))))))))
                 (:instance dlabel6-frame-dissolve)))))


;; ---------------------------------------------------------------------------

;; ---------------------------------------------------------------------------
;; The first two pieces of the opcode test
;; ---------------------------------------------------------------------------
;
; The result of $in_code is tested with (testop eqz).  At a symbolic value the
; *lift* of the testop step is not done yet: the value's $TESTOP_ term must be
; kept opaque through the context rules, and a search whose k = 1 test runs
; against a concrete instruction list rewrites the step test rather than using
; the facts.  The two facts the lift needs are:

(defthm fail-lone-testop
  (equal (w3t::step (icfg z (list (list :testop (list :i32) (list :eqz))))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list (list :testop (list :i32) (list :eqz))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :testop (list :i32) (list :eqz))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list (list :testop (list :i32) (list :eqz))))))))))

(defthm deqz-slice
  (equal (w3t::step (icfg z (list (dconst (dltu (dsub pc) (dmul clen)))
                                  (list :testop (list :i32) (list :eqz)))))
         (list (icfg z (list (dconst (deqz pc clen)))))))

;; ---------------------------------------------------------------------------
;; The opcode test and the second ifelse (the in-code case)
;; ---------------------------------------------------------------------------
;
; The running path is the in-code case: $in_code's comparison is 1 (the two
; sides of the lt_u are pc - 4096 and 4 * clen, and pc is in range).  Under that
; hypothesis the testop's value is the CONCRETE 0 and the ifelse takes its
; ELSE branch, so the instruction lists are concrete at every step and the
; standard recipe goes through.  The hypothesis is what makes this provable:
; at a symbolic value the search's measure guards compare sizes of lists
; containing the value, and the definition instance's false branches do not
; close (see SUMMARY.md).
;
; The chain ends where the dispatch's opcode fetch begins.  Measured: the
; testop chain is 1.09M prover steps (the context rule 101k, the label and
; frame lifts 320k and 485k), the ifelse chain 1.05M, and the block/label
; chain 2.41M.

(defthm fail-lone-testop-cons
  (equal (w3t::step (list :|%;%| z '((:TESTOP (:I32) (:EQZ))))) nil)
  :hints (("Goal" :in-theory (disable w3t::step)
           :use ((:instance fail-lone-testop (z z))))))

(defthm testop-slice-one
  (equal (w3t::step (list :|%;%| z
                          (cons (list :const '(:i32) 1) '((:TESTOP (:I32) (:EQZ))))))
         (list (list :|%;%| z (list (list :const '(:i32) 0))))))

(defthm dsearch21-eqz
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step/search21 1 0 1
                                       (dvl (dbody4 pc clen)) 1
                                       (iz6 bytes sp pc clen result)
                                       (icfg (iz6 bytes sp pc clen result)
                                             (dvl (dbody4 pc clen))))
                  (list (list :|%;%| (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 0)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (dvl (dbody4 pc clen))) (w3t::%t9 1)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl (dbody4 pc clen)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (dvl (dbody4 pc clen))) (w3t::%t9 1)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl (dbody4 pc clen)))))
                 (:instance fail-lone-testop-cons (z (iz6 bytes sp pc clen result)))
                 (:instance testop-slice-one (z (iz6 bytes sp pc clen result)))))))

(defthm dctxt-eqz
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (iz6 bytes sp pc clen result) (dvl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 0)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl (dbody4 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl (dbody4 pc clen))))
                 dsearch21-eqz))))

(defthm dstep-eqz
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (dvl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 0)))))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-eqz)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl (dbody4 pc clen))))))))

(defthm dlabel6-eqz
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dvl (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil
                                          (dvl-after-testop (list (dconst 0)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl (dbody4 pc clen)))))))
                 dstep-eqz))))

(defthm douter-eqz
  (implies (equal (dltu (dsub pc) (dmul clen)) 1)
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                              (dvl (dbody4 pc clen))))
                  (list (frozen-body-cfg bytes sp pc clen 1 result
                                         (dvl-after-testop (list (dconst 0)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl (dbody4 pc clen)))))))))
                 (:instance dlabel6-eqz)))))


;; ---------------------------------------------------------------------------
;; The block and label the second ifelse leaves (the in-code case)
;; ---------------------------------------------------------------------------
;
; The ifelse's ELSE branch is NIL, so the block is empty; the block becomes a
; label 0 and the label dissolves, leaving the rest of function 6's body (the
; opcode fetch) at the head of the label.  These bodies are concrete, so the
; search's measure tests compute.  NOTE the tails: after the testop the rest is
; (cddr (nthcdr 4 *body-6*)), and after the ifelse it is
; (cdddr (nthcdr 4 *body-6*)); appending the whole rest6 instead would state
; lemmas about a body that never occurs.

(defthm fail-lone-ifelse
  (equal (w3t::step (icfg z (list (list :ifelse (list :_result nil)
                                        (list (list :call 4) (list :return)) nil))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list (list :ifelse (list :_result nil)
                                                             (list (list :call 4) (list :return)) nil)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :ifelse (list :_result nil)
                                                  (list (list :call 4) (list :return)) nil)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list (list :ifelse (list :_result nil)
                                                            (list (list :call 4) (list :return)) nil)))))))))

(defthm fail-lone-ifelse-cons (equal (w3t::step (list :|%;%| z '((:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL)))) nil) :hints (("Goal" :in-theory (disable w3t::step) :use ((:instance fail-lone-ifelse (z z))))))

(defthm difelse-slice-0 (equal (w3t::step (list :|%;%| z (cons (list :const '(:i32) 0) '((:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL))))) (list (list :|%;%| z (list '(:BLOCK (:_RESULT NIL) NIL))))))

(defthm dctxt-ifelse (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0))))) (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) NIL)))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (dvl-after-testop (list (dconst 0))))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (dvl-after-testop (list (dconst 0)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0)))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (dvl-after-testop (list (dconst 0)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0)))))) (:instance fail-lone-ifelse-cons (z (iz6 bytes sp pc clen result))) (:instance difelse-slice-0 (z (iz6 bytes sp pc clen result)))))))

(defthm dstep-ifelse (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0))))) (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) NIL)))))) :hints (("Goal" :in-theory (disable dsub dmul dltu deqz) :use (dctxt-ifelse) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 0)))))))))

(defthm dlabel6-ifelse (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 0))))))) (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) NIL)))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 0)))))))) dstep-ifelse))))

(defthm douter-ifelse (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-testop (list (dconst 0))))) (list (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) NIL)))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (milawa-callee-frame 6) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 0)))))))))) (:instance dlabel6-ifelse)))))

(defthm dctxt-block
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :block (list :_result nil) nil))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dvl-after-ifelse (list (list :block (list :_result nil) nil)))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :block (list :_result nil) nil))))))
                 (:instance rstep-empty-block (z (iz6 bytes sp pc clen result)))))))

(defthm dstep-block
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-block)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))))))

(defthm dlabel6-block
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :label_%{%}% 1 nil
                                      (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 1 nil
                                 (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl-after-ifelse (list (list :block (list :_result nil) nil))))))))
                 dstep-block))))

(defthm douter-block
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                     (dvl-after-ifelse (list (list :block (list :_result nil) nil)))))
         (list (frozen-body-cfg bytes sp pc clen 1 result
                                (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl-after-ifelse (list (list :block (list :_result nil) nil))))))))))
                 (:instance dlabel6-block)))))

(defthm dctxt-elabel
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse nil))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))
                 (:instance rstep-empty-label (z (iz6 bytes sp pc clen result)))))))

(defthm dstep-elabel
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))
         (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse nil))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-elabel)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))))))

(defthm dlabel6-elabel
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :label_%{%}% 1 nil (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 1 nil (dvl-after-ifelse nil))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))))
                 dstep-elabel))))

(defthm douter-elabel
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil)))))
         (list (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-ifelse nil))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl-after-ifelse (list (list :label_%{%}% 0 nil nil))))))))))
                 (:instance dlabel6-elabel)))))
