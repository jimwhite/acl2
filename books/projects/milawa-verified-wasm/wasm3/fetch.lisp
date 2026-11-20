; L1, the running branch: the rest of the opcode fetch after local.set 0.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; load.lisp leaves the module in function 6's frame with the opcode in local 0:
; the frame instruction's frame is the updated callee frame (its local 0 holds
; the opcode) and the label's body is the tail after the local.set:
;
;   (global.get 1) (const 4) (add) (global.set 1)   ; pc = pc + 4
;   (local.get 0) (const 0) (eq) (ifelse ...)       ; dispatch
;
; This book takes the first of those: the second read of global 1 (pc), inside
; the updated frame.  The read's value does not depend on the frame's locals,
; so the slice fact is proved at the updated pair once (21.6k steps); the lift
; is the standard context/step/label/frame recipe (434k / 53k / 381k / 908k).
; The frame lift's RHS keeps the updated frame field as ($frame z1) and the
; advanced body, which is the shape the next positions start from.

(in-package "MILAWA-WASM")

(include-book "load")

;; ---------------------------------------------------------------------------
;; The second global.get 1: pc, through the updated frame
;; ---------------------------------------------------------------------------

(defthm read-pc-after-local-set-slice
  (equal (w3t::step (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                           (list :const (list :i32) w))
                          (list (list :global.get 1))))
         (list (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                       (list :const (list :i32) w))
                     (list (list :const (list :i32) pc))))))

(defthm dctxt-get1-after
  (equal (w3t::step/r-ctxt-instrs
          (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                  (list :const (list :i32) w))
                (cdr *ft2*)))
         (list (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                       (list :const (list :i32) w))
                     (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                   (list :const (list :i32) w))
                                                   (cdr *ft2*))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cdr *ft2*)))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                                   (w3t::%t6 (cdr *ft2*)) (w3t::%t9 0)
                                   (w3t::z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w)))
                                   (w3t::%a0 (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                    (list :const (list :i32) w))
                                                   (cdr *ft2*))))
                        read-pc-after-local-set-slice))))


(defthm dstep-get1-after (equal (w3t::step (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cdr *ft2*))) (list (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))) :hints (("Goal" :in-theory (disable) :use (dctxt-get1-after) :expand ((w3t::step (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cdr *ft2*)))))))

(defthm dlabel6-get1-after (equal (w3t::step (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cdr *ft2*))))) (list (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (icfg (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cdr *ft2*)))))) dstep-get1-after))))

(defthm douter-get1-after (equal (w3t::step (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cdr *ft2*))))))) (list (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cdr *ft2*)))))))) (:instance dlabel6-get1-after)))))

;; ---------------------------------------------------------------------------
;; The add: pc + 4 (the (const 4) was already a value on the stack)
;; ---------------------------------------------------------------------------

; The body after the second global.get 1 is
;
;   (const pc) (const 4) (binop add) (global.set 1) ...
;
; The (const 4) is NOT a step of its own: the semantics represents a constant on
; the stack by the same (:CONST nt c) list as the instruction, so the add's
; pure rule consumes both leading value-consts in one step.  The search's k = 2
; and k = 1 slices are the lone binop and one-operand binop, which must be
; unsteppable (fail-lone-add, fail-add-one); the k = 0 slice is the three-element
; add (dadd-slice).  All four slice and failure facts are stated in constructor
; form ((LIST :%;% ...), not ICFG): with ICFG the context lift runs to 8.9M
; steps and fails, and with constructors it is 349k.
;
; The value fact is the add's wrap: ($binop_ :i32 :add) is (rem (+ a b) 2^32),
; so binop-add-value is the same rem-bounds argument as binop-sub/mul-value.

(defun dadd (pc) (car (w3t::$binop_ (list :i32) (list :add) pc 4)))

(defthm binop-add-value
  (implies (and (unsigned-byte-p 32 a) (unsigned-byte-p 32 b))
           (unsigned-byte-p 32 (car (w3t::$binop_ (list :i32) (list :add) a b))))
  :hints (("Goal" :in-theory (disable rem truncate)
           :use ((:instance rem-bounds-nat (x (+ a b)) (y (expt 2 32)))))))

(defthm addval-is-a-value
  (implies (and (unsigned-byte-p 32 a) (unsigned-byte-p 32 b))
           (w3t::un-p (car (w3t::$binop_ (list :i32) (list :add) a b)) 32))
  :hints (("Goal" :in-theory (disable w3t::$binop_))))

(defthm un-p-dadd
  (implies (unsigned-byte-p 32 pc)
           (w3t::un-p (dadd pc) 32))
  :hints (("Goal" :in-theory (disable w3t::$binop_)
           :use ((:instance addval-is-a-value (a pc) (b 4))))))

(defthm integerp-dadd
  (implies (unsigned-byte-p 32 pc)
           (integerp (dadd pc)))
  :hints (("Goal" :use un-p-dadd))
  :rule-classes :type-prescription)

(defthm dadd-slice
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) pc)
                                           (list :const (list :i32) 4)
                                           (list :binop (list :i32) (list :add)))))
                  (list (list :|%;%| z (list (list :const (list :i32) (dadd pc))))))))

(defthm fail-lone-add
  (equal (w3t::step (list :|%;%| z (list (list :binop (list :i32) (list :add))))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :binop (list :i32) (list :add))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :binop (list :i32) (list :add))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :binop (list :i32) (list :add))))))))))

(defthm fail-add-one
  (implies (unsigned-byte-p 32 c)
           (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) c)
                                           (list :binop (list :i32) (list :add)))))
                  nil))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :binop (list :i32) (list :add))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) c)
                                          (list :binop (list :i32) (list :add)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :binop (list :i32) (list :add))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :binop (list :i32) (list :add))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :binop (list :i32) (list :add))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :binop (list :i32) (list :add))))))
                 (:instance fail-lone-add (z z))))))

(defthm dctxt-add
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                           (list :const (list :i32) w))
                         (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))
                  (list (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                (list :const (list :i32) w))
                              (cons (list :const (list :i32) (dadd pc))
                                    (cdr (cdr (cdr (cdr *ft2*)))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                   (list :const (list :i32) w))
                                                   (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))
                                   (w3t::%t9 2)
                                   (w3t::z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w)))
                                   (w3t::%a0 (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                    (list :const (list :i32) w))
                                                   (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))
                                   (w3t::%t9 2)
                                   (w3t::z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w)))
                                   (w3t::%a0 (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                    (list :const (list :i32) w))
                                                   (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))
                                   (w3t::%t9 2)
                                   (w3t::z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                             (list :const (list :i32) w)))
                                   (w3t::%a0 (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                                    (list :const (list :i32) w))
                                                   (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))
                        dadd-slice
                        (:instance fail-lone-add
                                   (z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                        (list :const (list :i32) w))))
                        (:instance fail-add-one
                                   (z (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                        (list :const (list :i32) w)))
                                   (c 4))))))


(defthm dstep-add (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))) (list (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))))) :hints (("Goal" :use (dctxt-add) :expand ((w3t::step (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))))))

(defthm dlabel6-add (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))) (list (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))))) dstep-add))))

(defthm douter-add (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*))))))))) (list (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc) (cdr (cdr *ft2*)))))))))) (:instance dlabel6-add)))))

;; ---------------------------------------------------------------------------
;; The global.set 1: pc = pc + 4
;; ---------------------------------------------------------------------------

; The add leaves the value (const (pc+4)) at the head of the body, followed by
; (global.set 1).  The write rule Step/r-global.set consumes the value and the
; instruction and rewrites the STORE's global 6 (the module maps global 1 to
; store global 6) through $with_global.  The slice chain is the local.set's:
; the lone global.set and the context rule on the two-instruction slice must be
; shown unsteppable first (fail-lone-global-set, ctxt-global-set-slice-fails),
; then the slice (dglobal-set-slice-gen).  The (dadd pc) value must stay opaque
; (disable dadd $binop_): unfolded, its rem expression enters the search's
; acl2-count guards and the slice proof fails on numerator arithmetic.
;
; The lift is generic in the pair Z (the $with_global term is carried through),
; and the frame lift states the new store as ($sof z2) and the frame as
; ($fof z2) with the accessors DISABLED: with them enabled the frame rule's
; measure unfolds the store and the proof costs 43M steps instead of 4.6M.

(defthm val-p-dadd-const
  (implies (unsigned-byte-p 32 pc)
           (w3t::val-p (list :const (list :i32) (dadd pc))))
  :hints (("Goal" :in-theory (disable w3t::$binop_)
                  :use un-p-dadd)))

(defthm fail-lone-global-set
  (equal (w3t::step (icfg z (list '(:global.set 1)))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list '(:global.set 1)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list '(:global.set 1)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list '(:global.set 1)))))))))

(defthm ctxt-global-set-slice-fails
  (implies (w3t::val-p (list :const (list :i32) (dadd pc)))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (list (list :const (list :i32) (dadd pc)) '(:global.set 1))))
                  nil))
  :hints (("Goal"
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) (dadd pc)) '(:global.set 1)))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (list (list :const (list :i32) (dadd pc)) '(:global.set 1))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (list (list :const (list :i32) (dadd pc)) '(:global.set 1)))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) (dadd pc)) '(:global.set 1)))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (list (list :const (list :i32) (dadd pc)) '(:global.set 1)))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) (dadd pc)) '(:global.set 1)))))
                        (:instance fail-lone-global-set (z z))))))

(defthm dglobal-set-slice-gen
  (implies (w3t::val-p (list :const (list :i32) (dadd pc)))
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) (dadd pc)) '(:global.set 1))))
                  (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc)))
                              nil))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm dctxt-global-set-gen
  (implies (unsigned-byte-p 32 pc)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) (dadd pc))
                               (cdr (cdr (cdr (cdr *ft2*)))))))
                  (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc)))
                              (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (dadd pc))
                                                         (cdr (cdr (cdr (cdr *ft2*))))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) (dadd pc))
                                                  (cdr (cdr (cdr (cdr *ft2*)))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (dadd pc))
                                                   (cdr (cdr (cdr (cdr *ft2*))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (dadd pc))
                                                         (cdr (cdr (cdr (cdr *ft2*))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (dadd pc))
                                                   (cdr (cdr (cdr (cdr *ft2*))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (dadd pc))
                                                         (cdr (cdr (cdr (cdr *ft2*))))))))
                        dglobal-set-slice-gen
                        (:instance fail-lone-global-set (z z))))))


(defthm dstep-global-set-gen (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))) (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc))) (cdr (cdr (cdr (cdr (cdr *ft2*))))))))) :hints (("Goal" :in-theory (disable dadd w3t::$binop_) :use (dctxt-global-set-gen) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*)))))))))))

(defthm dlabel6-global-set-gen (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))))) (list (list :|%;%| (w3t::$with_global z 1 (list :const (list :i32) (dadd pc))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*)))))))))) dstep-global-set-gen))))

(defthm douter-global-set (implies (unsigned-byte-p 32 pc) (equal (w3t::step (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dadd pc)) (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance dlabel6-global-set-gen)))))


;; ---------------------------------------------------------------------------
;; The local.get 0: the opcode back onto the stack
;; ---------------------------------------------------------------------------

; The fetch's dispatch test begins (local.get 0) (const 0) (relop eq): the
; saved opcode against zero.  The local is the singleton list ((:CONST (:I32) w))
; that local.set stored; the read rule's split version pushes its car, so the
; slice needs one fact about $LOCAL at the updated pair (local-of-updated-pair,
; 57k).  The slice and the context rule are stated for a VARIABLE pair Z with
; that $LOCAL equality as the hypothesis: the store is by now a $with_global
; term, and a rule stated at the spelled-out pair cannot match the search's
; step call, which sees the store unfolded.  With the hypothesis and a variable
; Z the slice is 52k and the context rule 68k.  The label lift's hypothesis is
; discharged by local-of-updated-pair as a rewrite rule; the frame lift keeps
; $local/$sof/$fof/$with_global and frozen-store DISABLED, which is what keeps
; its measure proof at 4.6M rather than 43M.

(defthm dlocal-get-slice-gen
  (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w)))
           (equal (w3t::step (list :|%;%| z (list (list :local.get 0))))
                  (list (list :|%;%| z (list (list :const (list :i32) w)))))))

(defthm dctxt-local-get-gen
  (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w)))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cdr (cdr (cdr (cdr (cdr *ft2*)))))))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32) w)
                                    (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cdr (cdr (cdr (cdr (cdr *ft2*))))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cdr (cdr (cdr (cdr (cdr *ft2*)))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                                   (w3t::%t6 (cdr (cdr (cdr (cdr (cdr *ft2*))))))
                                   (w3t::%t9 0) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cdr (cdr (cdr (cdr (cdr *ft2*))))))))
                        dlocal-get-slice-gen))))


;; The local is the opcode: proved once, so the label/frame lifts do not
;; re-derive it inside their big measure proofs.
(defthm local-of-updated-pair
  (equal (w3t::$local
          (list :|%;%|
                (w3t::$sof
                 (w3t::$with_global
                  (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                        (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                       (list :const (list :i32) w))))
                  1 (list :const (list :i32) (dadd pc))))
                (w3t::$fof
                 (w3t::$with_global
                  (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                        (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0
                                                       (list :const (list :i32) w))))
                  1 (list :const (list :i32) (dadd pc)))))
          0)
         (list (list :const (list :i32) w))))

(defthm dstep-local-get-gen (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr *ft2*))))))) (list (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) :hints (("Goal" :use (dctxt-local-get-gen) :expand ((w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))

(defthm dlabel6-local-get-gen (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))) dstep-local-get-gen))))

(defthm douter-local-get (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance dlabel6-local-get-gen (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The opcode test: (local.get 0) (const 0) (relop eq)
;; ---------------------------------------------------------------------------

; The dispatch test computes the opcode against zero.  The relop is a pure
; instruction; the (const 0) is already a value, so both leading consts and the
; relop are one step (deq-slice).  The search's k = 2 and k = 1 slices (the lone
; relop and one operand) must be unsteppable; as with the add, keep the facts in
; constructor form (the icfg form of fail-relop-eq-one is 286k steps, the
; constructor form 35k).  (deq w) is 1 when w is 0 and 0 otherwise, so the next
; step, the ifelse, is where the per-opcode case analysis begins.

(defun deq (w) (w3t::$relop_ (list :i32) (list :eq) w 0))

(defthm relop-eq-value
  (unsigned-byte-p 32 (deq w)))

(defthm integerp-deq
  (integerp (deq w))
  :rule-classes :type-prescription)

(defthm deq-slice
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) w)
                                         (list :const (list :i32) 0)
                                         (list :relop (list :i32) (list :eq)))))
                  (list (list :|%;%| z (list (list :const (list :i32) (deq w))))))))

(defthm fail-lone-relop-eq
  (equal (w3t::step (list :|%;%| z (list (list :relop (list :i32) (list :eq))))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :relop (list :i32) (list :eq))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :relop (list :i32) (list :eq))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :relop (list :i32) (list :eq))))))))))

(defthm fail-relop-eq-one
  (implies (unsigned-byte-p 32 c)
           (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) c)
                                           (list :relop (list :i32) (list :eq)))))
                  nil))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :relop (list :i32) (list :eq))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) c)
                                          (list :relop (list :i32) (list :eq)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :relop (list :i32) (list :eq))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :relop (list :i32) (list :eq))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :relop (list :i32) (list :eq))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :relop (list :i32) (list :eq))))))
                 (:instance fail-lone-relop-eq (z z))))))


(defthm dctxt-relop-eq
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) w)
                               (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32) (deq w))
                                    (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deq)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) w)
                                                         (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) w)
                                                  (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) w)
                                                   (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))
                                   (w3t::%t9 2) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) w)
                                                         (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) w)
                                                   (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))
                                   (w3t::%t9 2) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) w)
                                                         (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2)
                                   (w3t::%t6 (cons (list :const (list :i32) w)
                                                   (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))
                                   (w3t::%t9 2) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) w)
                                                         (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                        deq-slice
                        (:instance fail-lone-relop-eq (z z))
                        (:instance fail-relop-eq-one (z z) (c 0))))))


(defthm dstep-relop-eq-gen (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :use (dctxt-relop-eq) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))

(defthm dlabel6-relop-eq-gen (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) dstep-relop-eq-gen))))

(defthm douter-relop-eq (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (:instance dlabel6-relop-eq-gen (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The dispatch ifelse: HALT vs the next opcode test
;; ---------------------------------------------------------------------------

; The opcode test's value (deq w) is 1 exactly when the opcode is HALT (0), so
; the ifelse has two cases: w = 0 takes the then branch (a BLOCK around the
; halt instructions) and w != 0 takes the else branch (a BLOCK around NIL, which
; will dissolve and leave the next opcode test).  The ifelse instruction is
; written out as *d-ifelse* because the search's step call sees the literal and
; a term (nth 8 *ft2*) does not match it; the lone-ifelse failure is the
; dispatch book's proof shape (icfg form), 12,765 steps.  Both branches are
; carried through the context/step/label/frame recipe.  The frame lifts are the
; expensive ones (26M each): the frame rule's measure sees the whole remaining
; dispatch after the block, but it is a one-time cost per branch.

(defconst *d-ifelse* '(:IFELSE (:_RESULT NIL)
           ((:CALL 2)
            (:TESTOP (:I32) (:EQZ))
            (:IFELSE (:_RESULT NIL)
                     ((:CALL 4) (:RETURN))
                     NIL)
            (:CALL 1)
            (:GLOBAL.SET 4)
            (:CONST (:I32) 0)
            (:GLOBAL.SET 3)
            (:CONST (:I32) 0)
            (:RETURN))
           NIL))

(defthm fail-lone-ifelse-op
  (equal (w3t::step (icfg z (list *d-ifelse*))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list *d-ifelse*))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list *d-ifelse*)) (w3t::%t9 0)
                            (w3t::z z)
                            (w3t::%a0 (icfg z (list *d-ifelse*))))))))



(defthm difelse-halt-true-slice
  (implies (equal w 0)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) (deq w))
                               (nth 8 *ft2*))))
                  (list (list :|%;%| z
                              (list (list :block (cadr (nth 8 *ft2*))
                                          (caddr (nth 8 *ft2*)))))))))

(defthm difelse-halt-false-slice
  (implies (not (equal w 0))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) (deq w))
                               (nth 8 *ft2*))))
                  (list (list :|%;%| z
                              (list (list :block (cadr (nth 8 *ft2*))
                                          (cadddr (nth 8 *ft2*)))))))))


(defthm dctxt-ifelse-op-true
  (implies (equal w 0)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) (deq w))
                               (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))
                  (list (list :|%;%| z
                              (cons (list :block (cadr *d-ifelse*)
                                          (caddr *d-ifelse*))
                                    (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) (deq w))
                                                  (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (deq w))
                                                   (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (deq w))
                                                   (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        difelse-halt-true-slice
                        (:instance fail-lone-ifelse-op (z z))))))

(defthm dstep-ifelse-op-true (implies (equal w 0) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :use (dctxt-ifelse-op-true) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))

(defthm dlabel6-ifelse-op-true (implies (equal w 0) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) dstep-ifelse-op-true))))

(defthm douter-ifelse-op-true (implies (equal w 0) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance dlabel6-ifelse-op-true (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))


(defthm dctxt-ifelse-op-false
  (implies (not (equal w 0))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (cons (list :const (list :i32) (deq w))
                               (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))
                  (list (list :|%;%| z
                              (cons (list :block (cadr *d-ifelse*)
                                          (cadddr *d-ifelse*))
                                    (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) (deq w))
                                                  (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (deq w))
                                                   (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) (deq w))
                                                   (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (cons (list :const (list :i32) (deq w))
                                                         (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))
                        difelse-halt-false-slice
                        (:instance fail-lone-ifelse-op (z z))))))


(defthm dstep-ifelse-op-false (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :use (dctxt-ifelse-op-false) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))

(defthm dlabel6-ifelse-op-false (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) dstep-ifelse-op-false))))

(defthm douter-ifelse-op-false (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance dlabel6-ifelse-op-false (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The taken branch's block: a BLOCK around the branch, then a LABEL
;; ---------------------------------------------------------------------------

; The ifelse leaves a (:BLOCK (:_RESULT NIL) INSTR-STAR).  The block's step is
; the read rule Step_read/block: it turns the block into
; (:LABEL_%{%}% N NIL (append values INSTR-STAR)) with N the block type's result
; count (0 here) and the values captured before the block (none here).  The two
; block bodies the dispatch produces are the halt instructions (the then
; branch) and NIL (the else branch); both slices are 504 steps.
;
; For the ELSE branch the block becomes the empty label (:LABEL 0 NIL NIL),
; whose own step is the pure rule Step_pure/label-vals with an empty match: its
; payload is NIL, so step/r-pure returns the configuration with an empty
; instruction list.  The search's splice then appends the rest of the dispatch,
; which is how the fall-through reaches the next opcode test.  (%RULE is a
; transparent macro in the ACL2 build -- it expands to its result -- which is
; why a rule's payload is what the step functions pattern-match.)
;
; Next: lift these two steps through the context/label/frame recipe, then take
; the halt branch (its label's first instruction is (:CALL 2), the depth call).

(defconst *d-ifelse* '(:IFELSE (:_RESULT NIL)
           ((:CALL 2)
            (:TESTOP (:I32) (:EQZ))
            (:IFELSE (:_RESULT NIL)
                     ((:CALL 4) (:RETURN))
                     NIL)
            (:CALL 1)
            (:GLOBAL.SET 4)
            (:CONST (:I32) 0)
            (:GLOBAL.SET 3)
            (:CONST (:I32) 0)
            (:RETURN))
           NIL))

(defthm dblock-halt-slice
  (equal (w3t::step (list :|%;%| z
                          (list (list :block (cadr *d-ifelse*)
                                      (caddr *d-ifelse*)))))
         (list (list :|%;%| z
                     (list (list :label_%{%}% 0 nil
                                 (caddr *d-ifelse*)))))))

(defthm dblock-empty-slice
  (equal (w3t::step (list :|%;%| z
                          (list (list :block (cadr *d-ifelse*)
                                      (cadddr *d-ifelse*)))))
         (list (list :|%;%| z
                     (list (list :label_%{%}% 0 nil
                                 (cadddr *d-ifelse*)))))))

;; ---------------------------------------------------------------------------
;; The block position, both branches
;; ---------------------------------------------------------------------------

; The block step is a READ (Step_read/block) and its slice is at k = 0 with no
; values before it.  The two bodies the dispatch produces are the halt block
; (the then branch) and the empty block (the else branch); each is lifted
; through the context, label-6 and frame-6 rules.  The false branch's context
; lift is 3k steps, the frame lifts 470k each -- cheap compared with the ifelse
; before them because the frame rule's measure here sees one instruction plus
; the rest, and the rest is the same on both sides.

(defthm dctxt-block-halt (implies (equal w 0) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) dblock-halt-slice))))

(defthm dstep-block-halt (implies (equal w 0) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :use (dctxt-block-halt) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))

(defthm dlabel6-block-halt (implies (equal w 0) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) dstep-block-halt))))

(defthm douter-block-halt (implies (equal w 0) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (caddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance dlabel6-block-halt (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-block-empty (implies (not (equal w 0)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) dblock-empty-slice))))

(defthm dstep-block-empty (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) :hints (("Goal" :use (dctxt-block-empty) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))

(defthm dlabel6-block-empty (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) dstep-block-empty))))

(defthm douter-block-empty (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr *d-ifelse*) (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance dlabel6-block-empty (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))


;; ---------------------------------------------------------------------------
;; The empty label dissolves: the fall-through reaches the next opcode test
;; ---------------------------------------------------------------------------

; A label whose instruction list is all values is removed by the pure rule
; Step_pure/label-vals; for the empty label its payload is NIL, so the step is
; the configuration with an empty instruction list and the search's splice
; appends the rest of the dispatch.  The slice is 125 steps; the lifts are the
; usual four, with the frame lift at 479k.  The body after this position is
; REST6: (:LOCAL.GET 0) (:CONST (:I32) 1) (relop eq) (ifelse ...), i.e. the
; CONST test.

(defthm delabel-empty-slice
  (equal (w3t::step (list :|%;%| z
                          (list (list :label_%{%}% 0 nil nil))))
         (list (list :|%;%| z nil))))

(defthm dctxt-elabel-op (implies (not (equal w 0)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) delabel-empty-slice))))

(defthm dstep-elabel-op (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) :hints (("Goal" :use (dctxt-elabel-op) :expand ((w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))

(defthm dlabel6-elabel-op (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) dstep-elabel-op))))

(defthm douter-elabel-op (implies (not (equal w 0)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr *d-ifelse*)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance dlabel6-elabel-op (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The ifelse facts, once, for every dispatch test
;; ---------------------------------------------------------------------------

; Every dispatch test ends in an ifelse with the same shape: a condition value
; (an i32 const), then (:IFELSE (:_RESULT NIL) THEN ELSE).  The lone ifelse is
; unsteppable for ANY branch contents (the pure rules need a value before it,
; and the search refuses a whole-list splice), and the two slice facts are the
; pure Step_pure/if-true and if-false rules.  Proving them with variables over
; bt/t1/t2 covers all the tests; the hypotheses are the true-listp checks the
; rules make and the integer/nonzero-or-zero condition.

(defthm fail-lone-ifelse-gen
  (equal (w3t::step (icfg z (list (list :ifelse bt t1 t2)))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list (list :ifelse bt t1 t2)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :ifelse bt t1 t2))) (w3t::%t9 0)
                            (w3t::z z)
                            (w3t::%a0 (icfg z (list (list :ifelse bt t1 t2)))))))))

(defthm difelse-true-slice-gen
  (implies (and (integerp c) (not (equal c 0))
                (true-listp bt) (true-listp t1) (true-listp t2))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) c)
                               (list :ifelse bt t1 t2))))
                  (list (list :|%;%| z (list (list :block bt t1)))))))

(defthm difelse-false-slice-gen
  (implies (and (equal c 0)
                (true-listp bt) (true-listp t1) (true-listp t2))
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :const (list :i32) c)
                               (list :ifelse bt t1 t2))))
                  (list (list :|%;%| z (list (list :block bt t2)))))))

;; ---------------------------------------------------------------------------
;; The second opcode test: local.get 0, (const 1), relop eq
;; ---------------------------------------------------------------------------

; The fall-through reaches REST6: (:LOCAL.GET 0) (:CONST (:I32) 1) (relop eq)
; (ifelse ...).  The local.get reads the same local 0 (the pair is unchanged),
; through the same $local fact; the relop is the same pure rule with the
; immediate 1 (deq1); the ifelse uses the generic fail/slice facts.  Costs: the
; local.get position 68k/53k/918k/4.55M, the relop position 26k/14k/49k/832k,
; and the ifelse position 26M for each frame lift (the frame measure sees the
; whole remaining dispatch).

(defthm dctxt-local-get-op (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) dlocal-get-slice-gen))))

(defthm dstep-local-get-op (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) :hints (("Goal" :use (dctxt-local-get-op) :expand ((w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))

(defthm dlabel6-local-get-op (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) dstep-local-get-op))))

(defthm douter-local-get-op (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance dlabel6-local-get-op (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defun deq1 (w) (w3t::$relop_ (list :i32) (list :eq) w 1))

(defthm relop-eq1-value
  (unsigned-byte-p 32 (deq1 w)))

(defthm integerp-deq1
  (integerp (deq1 w))
  :rule-classes :type-prescription)

(defthm deq1-slice
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) w)
                                         (list :const (list :i32) 1)
                                         (list :relop (list :i32) (list :eq)))))
                  (list (list :|%;%| z
                              (list (list :const (list :i32) (deq1 w))))))))

(defthm dctxt-relop-eq1 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deq1) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) deq1-slice (:instance fail-lone-relop-eq (z z)) (:instance fail-relop-eq-one (z z) (c 1))))))

(defthm dstep-relop-eq1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :use (dctxt-relop-eq1) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))

(defthm dlabel6-relop-eq1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) dstep-relop-eq1))))

(defthm douter-relop-eq1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (:instance dlabel6-relop-eq1 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))


;; ---------------------------------------------------------------------------
;; The CONST test's ifelse: the CONST branch or the ADD/SUB/LT test
;; ---------------------------------------------------------------------------

(defthm dctxt-ifelse-const-true (implies (equal w 1) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance difelse-true-slice-gen (z z) (c (deq1 w)) (bt (cadr (nth 12 *ft2*))) (t1 (caddr (nth 12 *ft2*))) (t2 (cadddr (nth 12 *ft2*)))) (:instance fail-lone-ifelse-gen (z z) (bt (cadr (nth 12 *ft2*))) (t1 (caddr (nth 12 *ft2*))) (t2 (cadddr (nth 12 *ft2*))))))))

(defthm dstep-ifelse-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :use (dctxt-ifelse-const-true) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm dlabel6-ifelse-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) dstep-ifelse-const-true))))

(defthm douter-ifelse-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (:instance dlabel6-ifelse-const-true (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-ifelse-const-false (implies (not (equal w 1)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance difelse-false-slice-gen (z z) (c (deq1 w)) (bt (cadr (nth 12 *ft2*))) (t1 (caddr (nth 12 *ft2*))) (t2 (cadddr (nth 12 *ft2*)))) (:instance fail-lone-ifelse-gen (z z) (bt (cadr (nth 12 *ft2*))) (t1 (caddr (nth 12 *ft2*))) (t2 (cadddr (nth 12 *ft2*))))))))

(defthm dstep-ifelse-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :use (dctxt-ifelse-const-false) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm dlabel6-ifelse-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) dstep-ifelse-const-false))))

(defthm douter-ifelse-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deq1 w)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (:instance dlabel6-ifelse-const-false (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The CONST test's block and label positions
;; ---------------------------------------------------------------------------

; Same recipe, with the CONST branch's block (which starts with (:CALL 3), the
; in-code check) and the empty block/label of the false branch.  The frame
; lifts are again 26M each.  After the empty label dissolves, the body is
; REST10: (:LOCAL.GET 0) (:CONST (:I32) 2) (relop eq) ... -- the ADD/SUB/LT
; test's OR-chain.

(defthm dblock-const-true-slice (equal (w3t::step (list :|%;%| z (list (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*)))))) (list (list :|%;%| z (list (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*))))))))

(defthm dblock-const-false-slice (equal (w3t::step (list :|%;%| z (list (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*)))))) (list (list :|%;%| z (list (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))))))))

(defthm dctxt-block-const-true (implies (equal w 1) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) dblock-const-true-slice))))

(defthm dstep-block-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :use (dctxt-block-const-true) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

(defthm dlabel6-block-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) dstep-block-const-true))))

(defthm douter-block-const-true (implies (equal w 1) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (caddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (:instance dlabel6-block-const-true (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-block-const-false (implies (not (equal w 1)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) dblock-const-false-slice))))

(defthm dstep-block-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) :hints (("Goal" :use (dctxt-block-const-false) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

(defthm dlabel6-block-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) dstep-block-const-false))))

(defthm douter-block-const-false (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 12 *ft2*)) (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (:instance dlabel6-block-const-false (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))


;; ---------------------------------------------------------------------------
;; The halt branch's first call: (:CALL 2) is (:REF.FUNC_ADDR 2) + call_ref
;; ---------------------------------------------------------------------------

; The halt block's label body starts with (:CALL 2), the $depth call.  The
; call split is a read rule whose type lookup goes through the frame's module
; and the store's functions, so the slice must be stated at the CALLEE pair
; (%;% store (frame 6)) -- at the entry pair the frame's module is the empty
; entry module and no type is found.  Function 2 and function 3 have the same
; signature (no args, one i32), so the call_ref type is the same *t3*.  This
; slice is the first step of the halt branch; the next pieces are the call
; entry (into function 2's frame) and $depth's body.

(defthm dcall2-split (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :call 2)))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) (list (list :ref.func_addr 2) *t3*))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_))))

(defthm dctxt-elabel-const (implies (not (equal w 1)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) delabel-empty-slice))))

(defthm dstep-elabel-const (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) :hints (("Goal" :use (dctxt-elabel-const) :expand ((w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))

(defthm dlabel6-elabel-const (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) dstep-elabel-const))))

(defthm douter-elabel-const (implies (not (equal w 1)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 12 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (:instance dlabel6-elabel-const (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The ADD/SUB/LT test's atoms: equality against any constant, and the OR
;; ---------------------------------------------------------------------------

; The third dispatch test ORs three equalities: (eq op 2) | (eq op 3) | (eq op
; 4).  The equality is the same relop rule with an arbitrary i32 immediate
; (deqc); the OR is the i32 binop (rem-free: $ior_ is (%u 32 (logior a b))).
; The or's value fact needs the mod bound, which is provable only with mod and
; floor KEPT ABSTRACT (`disable mod floor`): unfolded, their rational normal
; form blocks the linear rules.  mod-2^32-value is that fact once (155 steps);
; binop-or-value then uses it (1.1k).  The failure facts for the lone or and
; the one-operand or are the add's, with the operator changed.

(defun deqc (w c) (w3t::$relop_ (list :i32) (list :eq) w c))
(defthm relop-eqc-value (unsigned-byte-p 32 (deqc w c)))
(defthm integerp-deqc (integerp (deqc w c)) :rule-classes :type-prescription)
(defthm deqc-slice
  (implies (and (unsigned-byte-p 32 w) (unsigned-byte-p 32 c))
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) w)
                                         (list :const (list :i32) c)
                                         (list :relop (list :i32) (list :eq)))))
                  (list (list :|%;%| z (list (list :const (list :i32) (deqc w c))))))))

(defun dor (a b) (car (w3t::$binop_ (list :i32) (list :or) a b)))

(defthm mod-2^32-value
  (implies (integerp x)
           (unsigned-byte-p 32 (mod x (expt 2 32))))
  :hints (("Goal" :in-theory (disable mod floor))))

(defthm binop-or-value
  (implies (and (unsigned-byte-p 32 a) (unsigned-byte-p 32 b))
           (unsigned-byte-p 32 (dor a b)))
  :hints (("Goal" :in-theory (e/d (w3t::%u w3t::%pow2) (mod floor)))))

(defthm integerp-dor
  (integerp (dor a b))
  :rule-classes :type-prescription)

(defthm dor-slice
  (implies (and (unsigned-byte-p 32 a) (unsigned-byte-p 32 b))
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) a)
                                         (list :const (list :i32) b)
                                         (list :binop (list :i32) (list :or)))))
                  (list (list :|%;%| z (list (list :const (list :i32) (dor a b))))))))

(defthm fail-lone-or
  (equal (w3t::step (list :|%;%| z (list (list :binop (list :i32) (list :or))))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :binop (list :i32) (list :or))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :binop (list :i32) (list :or))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :binop (list :i32) (list :or))))))))))

(defthm fail-or-one
  (implies (unsigned-byte-p 32 c)
           (equal (w3t::step (list :|%;%| z (list (list :const (list :i32) c)
                                                   (list :binop (list :i32) (list :or)))))
                  nil))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                           (list :binop (list :i32) (list :or))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :const (list :i32) c)
                                          (list :binop (list :i32) (list :or)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :binop (list :i32) (list :or))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                           (list :binop (list :i32) (list :or))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :const (list :i32) c)
                                           (list :binop (list :i32) (list :or))))
                            (w3t::%t9 1) (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (list (list :const (list :i32) c)
                                                           (list :binop (list :i32) (list :or))))))
                 (:instance fail-lone-or (z z))))))

;; ---------------------------------------------------------------------------
;; The ADD/SUB/LT test's OR-chain, position by position
;; ---------------------------------------------------------------------------

; REST10 is local.get 0, const 2, relop eq, local.get 0, const 3, relop eq,
; binop or, local.get 0, const 4, relop eq, binop or, ifelse.  The eight shared
; positions are proved with the generic eq/or facts and the same recipe; the
; local.gets after a value (P3, P6) are the ones where the search's k = 1
; slice is the lone read and the splice keeps the value, and they are the
; expensive pure positions (16.4M and 22.3M: the fold's measure sees the
; accumulated eq/or terms).  The ifelse's value is
; (or (or (eq op 2) (eq op 3)) (eq op 4)); its true case is op in {2,3,4}
; (61.3M, the frame lift 48.7M) and its false case is the complement (26.7M).


(defthm dctxt-local-get-or (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) dlocal-get-slice-gen))))

(defthm dstep-local-get-or (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) :hints (("Goal" :use (dctxt-local-get-or) :expand ((w3t::step (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm dlabel6-local-get-or (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) dstep-local-get-or))))

(defthm douter-local-get-or (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (:instance dlabel6-local-get-or (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-relop-eq2 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (:instance deqc-slice (c 2)) (:instance fail-lone-relop-eq (z z)) (:instance fail-relop-eq-one (z z) (c 2))))))

(defthm dstep-relop-eq2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) :hints (("Goal" :use (dctxt-relop-eq2) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))

(defthm dlabel6-relop-eq2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) dstep-relop-eq2))))

(defthm douter-relop-eq2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance dlabel6-relop-eq2 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-local-get-or2 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) dlocal-get-slice-gen))))

(defthm dstep-local-get-or2 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) :hints (("Goal" :use (dctxt-local-get-or2) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))

(defthm dlabel6-local-get-or2 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) dstep-local-get-or2))))

(defthm douter-local-get-or2 (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance dlabel6-local-get-or2 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-relop-eq3 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 3) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (:instance deqc-slice (c 3)) (:instance fail-lone-relop-eq (z z)) (:instance fail-relop-eq-one (z z) (c 3))))))

(defthm dstep-relop-eq3 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-relop-eq3) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))

(defthm dlabel6-relop-eq3 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) dstep-relop-eq3))))

(defthm douter-relop-eq3 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance dlabel6-relop-eq3 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-or1 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc dor) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance dor-slice) (:instance fail-lone-or (z z)) (:instance fail-or-one (z z) (c (deqc w 3)))))))

(defthm dstep-or1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-or1) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))

(defthm dlabel6-or1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) dstep-or1))))

(defthm douter-or1 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc dor) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (deqc w 2)) (cons (list :const (list :i32) (deqc w 3)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance dlabel6-or1 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-local-get-or3 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc dor) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) dlocal-get-slice-gen))))

(defthm dstep-local-get-or3 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-local-get-or3) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))

(defthm dlabel6-local-get-or3 (implies (equal (w3t::$local z 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) dstep-local-get-or3))))

(defthm douter-local-get-or3 (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc))))) 0) (list (list :const (list :i32) w))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc dor) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance dlabel6-local-get-or3 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-relop-eq4 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc dor) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 3) (w3t::%lo 0) (w3t::%hi 3) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))) (w3t::%t9 3) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (:instance deqc-slice (c 4)) (:instance fail-lone-relop-eq (z z)) (:instance fail-relop-eq-one (z z) (c 4))))))

(defthm dstep-relop-eq4 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-relop-eq4) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))

(defthm dlabel6-relop-eq4 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) dstep-relop-eq4))))

(defthm douter-relop-eq4 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc dor) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) w) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) (:instance dlabel6-relop-eq4 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-or2 (implies (unsigned-byte-p 32 w) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs deqc dor) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 2) (w3t::%lo 0) (w3t::%hi 2) (w3t::%t6 (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 2) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance dor-slice) (:instance fail-lone-or (z z)) (:instance fail-or-one (z z) (c (deqc w 4)))))))

(defthm dstep-or2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-or2) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))

(defthm dlabel6-or2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) dstep-or2))))

(defthm douter-or2 (implies (unsigned-byte-p 32 w) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_ deqc dor) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (deqc w 2) (deqc w 3))) (cons (list :const (list :i32) (deqc w 4)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (:instance dlabel6-or2 (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-ifelse-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance fail-lone-ifelse-gen (z z) (bt (cadr (nth 24 *ft2*))) (t1 (caddr (nth 24 *ft2*))) (t2 (cadddr (nth 24 *ft2*)))) (:instance difelse-true-slice-gen (z z) (c (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (bt (cadr (nth 24 *ft2*))) (t1 (caddr (nth 24 *ft2*))) (t2 (cadddr (nth 24 *ft2*))))))))

(defthm dstep-ifelse-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-ifelse-or-true) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))

(defthm dlabel6-ifelse-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) dstep-ifelse-or-true))))

(defthm douter-ifelse-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (:instance dlabel6-ifelse-or-true (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-ifelse-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))) (w3t::%t9 1) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance fail-lone-ifelse-gen (z z) (bt (cadr (nth 24 *ft2*))) (t1 (caddr (nth 24 *ft2*))) (t2 (cadddr (nth 24 *ft2*)))) (:instance difelse-false-slice-gen (z z) (c (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (bt (cadr (nth 24 *ft2*))) (t1 (caddr (nth 24 *ft2*))) (t2 (cadddr (nth 24 *ft2*))))))))

(defthm dstep-ifelse-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-ifelse-or-false) :expand ((w3t::step (list :|%;%| z (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))

(defthm dlabel6-ifelse-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) dstep-ifelse-or-false))))

(defthm douter-ifelse-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) (dor (dor (deqc w 2) (deqc w 3)) (deqc w 4))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (:instance dlabel6-ifelse-or-false (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

;; ---------------------------------------------------------------------------
;; The OR-chain's block and label positions
;; ---------------------------------------------------------------------------

; The true branch's block starts the ADD/SUB/LT body (call 2, const 2, relop lt,
; an inner ifelse, the pops and the binop dispatch); its frame lift is 50.8M.
; The false branch's block is empty, and its label dissolves to REST11, the IFZ
; test: local.get 0, const 5, relop eq, ifelse at *ft2* index 28.

(defthm dblock-or-true-slice (equal (w3t::step (list :|%;%| z (list (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*)))))) (list (list :|%;%| z (list (list :label_%{%}% 0 nil (caddr (nth 24 *ft2*))))))))

(defthm dblock-or-false-slice (equal (w3t::step (list :|%;%| z (list (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*)))))) (list (list :|%;%| z (list (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))))))))

(defthm dctxt-block-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) dblock-or-true-slice))))

(defthm dstep-block-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-block-or-true) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))

(defthm dlabel6-block-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) dstep-block-or-true))))

(defthm douter-block-or-true (implies (or (equal w 2) (or (equal w 3) (equal w 4))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (caddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) (:instance dlabel6-block-or-true (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-block-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) dblock-or-false-slice))))

(defthm dstep-block-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-block-or-false) :expand ((w3t::step (list :|%;%| z (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))

(defthm dlabel6-block-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) dstep-block-or-false))))

(defthm douter-block-or-false (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :block (cadr (nth 24 *ft2*)) (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) (:instance dlabel6-block-or-false (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))

(defthm dctxt-elabel-or (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) (:instance w3t::step/prefix7 (w3t::%s (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))) (w3t::%t9 0) (w3t::z z) (w3t::%a0 (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) delabel-empty-slice))))

(defthm dstep-elabel-or (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))) (list (list :|%;%| z (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))) :hints (("Goal" :use (dctxt-elabel-or) :expand ((w3t::step (list :|%;%| z (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))

(defthm dlabel6-elabel-or (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))) (list (list :|%;%| z (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))) dstep-elabel-or))))

(defthm douter-elabel-or (implies (not (or (equal w 2) (or (equal w 3) (equal w 4)))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs w3t::$local w3t::$sof w3t::$fof w3t::$with_global frozen-store dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-frame (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cadddr (nth 24 *ft2*))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))))))))))))) (:instance dlabel6-elabel-or (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))) (w3t::$fof (w3t::$with_global (list :|%;%| (frozen-store bytes sp pc clen 1 result) (w3t::$frame (w3t::$with_local (iz6 bytes sp pc clen result) 0 (list :const (list :i32) w)))) 1 (list :const (list :i32) (dadd pc)))))))))))
