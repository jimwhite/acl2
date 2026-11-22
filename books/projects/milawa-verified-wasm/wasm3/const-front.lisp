; L1, the CONST path: the front through the callee's first four positions.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; CONST-JOIN leaves the run at CONST-TAIL-AFTER-ENTRY, the call entry; the
; callee steps in CONST-STEPS are stated at the generic run-level state
; CONST-TAIL-CALLEE-STATE.  The bridge below is the one spelling step between
; them: the entry state is the generic state with the callee's original body.
;
; Then CONST-FRONT-37..40 add the four callee steps to the 36-step advance:
;
;   36  the call entry
;   37  read global 1          (dbody0)
;   38  sub                    (dbody1)
;   39  read global 2          (dbody2)
;   40  mul                    (dbody3)
;
; Each is a `steps-fuel-succ-of-a-step` instance at the state the previous
; advance leaves, so the composition itself is cheap; the expensive proofs
; are the four step facts in CONST-STEPS.
;
; Measured: 5 events, the bridge and the four advances; certification is
; seconds (the steps are already proved in const-steps).

(in-package "MILAWA-WASM")

(include-book "const-join")
(include-book "const-steps")

(defthm const-tail-after-entry-is-callee-state
  (equal (const-tail-after-entry bytes sp pc clen result w)
         (const-tail-callee-state bytes sp pc clen result w
                                  (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))
  :hints (("Goal" :in-theory (enable const-tail-after-entry
                                     const-tail-callee-state))))

(defthm const-front-37
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (unsigned-byte-p 32 (dadd pc))
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 37 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r
                                    (const-tail-callee-state bytes sp pc clen result w
                                                             (dbody0 (dadd pc))))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-36 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-callee-state bytes sp pc clen result w
                                                        (quote ((:GLOBAL.GET 1) (:CONST (:I32) 4096) (:BINOP (:I32) (:SUB)) (:GLOBAL.GET 2) (:CONST (:I32) 4) (:BINOP (:I32) (:MUL)) (:RELOP (:I32) (:LT (:U)))))))
                            (c+ (const-tail-callee-state bytes sp pc clen result w
                                                         (dbody0 (dadd pc)))))
                 const-tail-read1-step
                 const-tail-after-entry-is-callee-state))))

(defthm const-front-38
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (unsigned-byte-p 32 (dadd pc))
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 38 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r
                                    (const-tail-callee-state bytes sp pc clen result w
                                                             (dbody1 (dadd pc))))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-37 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-callee-state bytes sp pc clen result w
                                                        (dbody0 (dadd pc))))
                            (c+ (const-tail-callee-state bytes sp pc clen result w
                                                         (dbody1 (dadd pc)))))
                 const-tail-sub-step))))

(defthm const-front-39
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (unsigned-byte-p 32 (dadd pc))
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 39 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r
                                    (const-tail-callee-state bytes sp pc clen result w
                                                             (dbody2 (dadd pc) clen)))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-38 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-callee-state bytes sp pc clen result w
                                                        (dbody1 (dadd pc))))
                            (c+ (const-tail-callee-state bytes sp pc clen result w
                                                         (dbody2 (dadd pc) clen))))
                 const-tail-read2-step))))

(defthm const-front-40
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (unsigned-byte-p 32 (dadd pc))
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 40 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r
                                    (const-tail-callee-state bytes sp pc clen result w
                                                             (dbody3 (dadd pc) clen)))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-39 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-callee-state bytes sp pc clen result w
                                                        (dbody2 (dadd pc) clen)))
                            (c+ (const-tail-callee-state bytes sp pc clen result w
                                                         (dbody3 (dadd pc) clen))))
                 const-tail-mul-step))))

(defthm const-front-41
  (implies (and (unsigned-byte-p 32 pc) (unsigned-byte-p 32 clen)
                (unsigned-byte-p 32 w)
                (unsigned-byte-p 32 (dadd pc))
                (equal (dltu (dsub pc) (dmul clen)) 1)
                (<= (+ pc 4) (len bytes))
                (equal (take 4 (nthcdr pc bytes)) (mvm-word-to-bytes w))
                (not (equal w 0))
                (equal w 1)
                (equal (w3t::$local (list :|%;%| (const-front-store bytes sp pc clen result w)
                                          (w3t::$fof (const-front-store bytes sp pc clen result w)))
                                    0)
                       (list (list :const (list :i32) w))))
           (equal (w3t::steps/%fuel (+ 41 r) (mvm-abs-abstract bytes sp pc clen 1 result))
                  (w3t::steps/%fuel r
                                    (const-tail-ltu-state bytes sp pc clen result w
                                                          (const-tail-ltu-output-body pc clen)))))
  :hints (("Goal"
           :in-theory (disable w3t::step w3t::steps/%fuel)
           :use ((:instance const-front-40 (r (+ 1 r)))
                 (:instance steps-fuel-succ-of-a-step
                            (n r)
                            (c (const-tail-ltu-state bytes sp pc clen result w
                                                     (const-tail-ltu-input-body pc clen)))
                            (c+ (const-tail-ltu-state bytes sp pc clen result w
                                                      (const-tail-ltu-output-body pc clen))))
                 const-tail-ltu-step
                 const-tail-ltu-bridge))))
