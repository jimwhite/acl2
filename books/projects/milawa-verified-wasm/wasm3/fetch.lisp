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
