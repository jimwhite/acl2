; L1, the running branch: the opcode fetch and the first frame write.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; dispatch.lisp leaves the opcode fetch at the head of function 6's label:
;
;   (const pc) (i32.load)               ; the opcode
;   (local.set 0)                       ; save it
;   (global.get 1) (const 4) (add) (global.set 1)   ; pc = pc + 4
;   (local.get 0) (const 0) (eq) (ifelse ...)       ; dispatch
;
; This book executes the load and the local.set, end to end at symbolic pc,
; clen, bytes and opcode, and returns the machine into function 6's frame with
; the opcode in local 0.  The load's slice is a READ: the semantics'
; Step_read/load-num-val checks ($nbytes_ i32 C) = the four bytes at pc and
; takes C = ($inv_nbytes_ i32 those bytes), so the two directions of the
; encode/decode round trip in numerics.lisp are what make it fire; its in-bounds
; guard is the (<= (+ pc 4) (len bytes)) hypothesis, without which the
; out-of-bounds TRAP case is a legitimate branch.
;
; The local.set is the first WRITE: its rule is Step/r-local.set, which stores
; the value in the frame's locals.  It taught two things worth recording:
;
;   * A slice whose step cannot be taken by a rule EARLIER in the dispatcher
;     (pure, read) reaches step/r-ctxt-instrs first.  The search then refuses
;     the slice itself (its splice would consume the whole instruction list),
;     so the slice's own step is provable only once a "context rule fails on
;     this slice" fact exists.  ctxt-local-set-slice-fails is that fact; state
;     it with the config in constructor (LIST :%;% ...) form, not ICFG form:
;     the ICFG call is unfolded before the rule is tried, so a rule whose LHS
;     contains ICFG never matches.
;
;   * The label and frame lifts must be stated with the store-and-frame PAIR as
;     a variable Z (dctxt/dstep/dlabel6-local-set-gen), and instantiated at
;     (iz6 ...) only in the frame lift.  With Z written as (iz6 ...) inside
;     the label lift, the pair is normalized to its LIST* form by the label
;     rule's own measure test, and the inner step no longer matches the lift's
;     LHS.  The generic statements are also much cheaper: the context lift is
;     37k steps generically against 1.17M with the pair spelled out.
;
; Measured: the load chain 7.87M prover steps, the local.set chain 0.62M.

(in-package "MILAWA-WASM")

(include-book "dispatch")
(include-book "numerics")

;; ---------------------------------------------------------------------------
;; The opcode load
;; ---------------------------------------------------------------------------



(defthm mem-of-iz6
  (equal (w3t::%get-field (w3t::$mem (iz6 bytes sp pc clen result) 0) :bytes)
         bytes))

(defthm val-p-dconst
  (implies (unsigned-byte-p 32 v) (w3t::val-p (list :const (list :i32) v)))
  :hints (("Goal" :in-theory (enable w3t::val-p w3t::num_-p w3t::in-p))))

(defthm dload-slice
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 w)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w)))
           (equal (w3t::step
                   (icfg (iz6 bytes sp pc clen result)
                         (list (list :const (list :i32) pc)
                               '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :const (list :i32) w)))))))

(defthm fail-lone-load
  (equal (w3t::step (icfg z (list '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))))))
         nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))))))

(defthm dctxt-load
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 w)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w)))
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (iz6 bytes sp pc clen result)
                         (cons (list :const (list :i32) pc)
                               (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))
                                     *ft2*))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (cons (list :const (list :i32) w) *ft2*)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                                   (cons (list :const (list :i32) pc)
                                                         (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) pc)
                                                  (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) pc)
                                                   (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))
                                   (w3t::%t9 1)
                                   (w3t::z (iz6 bytes sp pc clen result))
                                   (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                                   (cons (list :const (list :i32) pc)
                                                         (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) pc)
                                                   (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))
                                   (w3t::%t9 1)
                                   (w3t::z (iz6 bytes sp pc clen result))
                                   (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                                   (cons (list :const (list :i32) pc)
                                                         (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))))
                        dload-slice
                        (:instance fail-lone-load (z (iz6 bytes sp pc clen result)))))))

(defthm dstep-load
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 w)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w)))
           (equal (w3t::step
                   (icfg (iz6 bytes sp pc clen result)
                         (cons (list :const (list :i32) pc)
                               (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))
                                     *ft2*))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (cons (list :const (list :i32) w) *ft2*)))))
  :hints (("Goal" :in-theory (disable)
                  :use (dctxt-load)
                  :expand ((w3t::step
                            (icfg (iz6 bytes sp pc clen result)
                                  (cons (list :const (list :i32) pc)
                                        (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))
                                              *ft2*))))))))


(defthm dlabel6-load
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 w)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w)))
           (equal (w3t::step
                   (icfg (iz6 bytes sp pc clen result)
                         (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc)
                                        (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) w) *ft2*)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-label)
                                   (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                                   (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc)
                                        (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))))))
                        dstep-load))))

(defthm douter-load
  (implies (and (unsigned-byte-p 32 pc)
                (unsigned-byte-p 32 w)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w)))
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (cons (list :const (list :i32) pc)
                                        (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*))))
                  (list (frozen-body-cfg bytes sp pc clen 1 result (cons (list :const (list :i32) w) *ft2*)))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-frame)
                                   (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                                   (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                               (list (list :label_%{%}% 1 nil (cons (list :const (list :i32) pc)
                                        (cons '(:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0))) *ft2*)))))))))
                        (:instance dlabel6-load)))))

;; ---------------------------------------------------------------------------
;; The first frame write: local 0 gets the opcode
;; ---------------------------------------------------------------------------

(defthm fail-lone-local-set
  (equal (w3t::step (icfg z (list '(:local.set 0)))) nil)
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg z (list '(:local.set 0)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list '(:local.set 0)))
                            (w3t::%t9 0) (w3t::z z)
                            (w3t::%a0 (icfg z (list '(:local.set 0)))))))))

(defthm ctxt-local-set-slice-fails
  (implies (w3t::val-p (list :const (list :i32) w))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z
                         (list (list :const (list :i32) w) '(:local.set 0))))
                  nil))
  :hints (("Goal"
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) w) '(:local.set 0)))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (list (list :const (list :i32) w) '(:local.set 0))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (list (list :const (list :i32) w) '(:local.set 0)))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) w) '(:local.set 0)))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (list (list :const (list :i32) w) '(:local.set 0)))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :const (list :i32) w) '(:local.set 0)))))
                        (:instance fail-lone-local-set (z z))))))

(defthm dlocal-set-slice-gen
  (implies (w3t::val-p (list :const (list :i32) w))
           (equal (w3t::step (list :|%;%| z
                                   (list (list :const (list :i32) w) '(:local.set 0))))
                  (list (list :|%;%| (w3t::$with_local z 0 (list :const (list :i32) w))
                              nil)))))

(defthm dctxt-local-set-gen
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cons (list :const (list :i32) w) *ft2*)))
                  (list (list :|%;%| (w3t::$with_local z 0 (list :const (list :i32) w))
                              (cdr *ft2*)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                                   (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) *ft2*))))
                        (:instance (:definition w3t::step/prefix7)
                                   (w3t::%s (cons (list :const (list :i32) w) *ft2*)))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) w) *ft2*))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) *ft2*))))
                        (:instance (:definition w3t::step/search21)
                                   (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                                   (w3t::%t6 (cons (list :const (list :i32) w) *ft2*))
                                   (w3t::%t9 1) (w3t::z z)
                                   (w3t::%a0 (list :|%;%| z (cons (list :const (list :i32) w) *ft2*))))
                        (:instance dlocal-set-slice-gen)
                        (:instance fail-lone-local-set (z z))))))

(defthm dstep-local-set-gen
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step (list :|%;%| z
                                   (cons (list :const (list :i32) w) *ft2*)))
                  (list (list :|%;%| (w3t::$with_local z 0 (list :const (list :i32) w))
                              (cdr *ft2*)))))
  :hints (("Goal" :in-theory (disable)
                  :use (dctxt-local-set-gen)
                  :expand ((w3t::step (list :|%;%| z
                                            (cons (list :const (list :i32) w) *ft2*)))))))

(defthm dlabel6-local-set-gen
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step
                   (list :|%;%| z
                         (list (list :label_%{%}% 1 nil
                                     (cons (list :const (list :i32) w) *ft2*)))))
                  (list (list :|%;%| (w3t::$with_local z 0 (list :const (list :i32) w))
                              (list (list :label_%{%}% 1 nil (cdr *ft2*)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-label)
                                   (w3t::%a0 (list :|%;%| z
                                                   (list (list :label_%{%}% 1 nil
                                                               (cons (list :const (list :i32) w) *ft2*))))))
                        dstep-local-set-gen))))

(defthm douter-local-set
  (implies (unsigned-byte-p 32 w)
           (equal (w3t::step
                   (frozen-body-cfg bytes sp pc clen 1 result
                                    (cons (list :const (list :i32) w) *ft2*)))
                  (list (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                              (list (list :frame_%{%}% 1
                                          (w3t::$frame
                                           (w3t::$with_local
                                            (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                                                  (milawa-callee-frame 6))
                                            0 (list :const (list :i32) w)))
                                          (list (list :label_%{%}% 1 nil (cdr *ft2*)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
                  :use ((:instance (:definition w3t::step/r-ctxt-frame)
                                   (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                                   (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                               (list (list :label_%{%}% 1 nil
                                                                           (cons (list :const (list :i32) w) *ft2*))))))))
                        (:instance dlabel6-local-set-gen
                                   (z (list :|%;%| (frozen-store bytes sp pc clen 1 result)
                                            (milawa-callee-frame 6))))))))
