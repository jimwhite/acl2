(in-package "MILAWA-WASM")

(include-book "abort")

; L1, the running branch: the out-of-code abort at the entry.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; $in_code (function 3) returns 1 when pc is in range and 0 when it is not.
; dispatch.lisp proves the in-code case (comparison 1, the testop's value 0,
; the else branch).  This book takes the out-of-code case: the comparison is 0,
; so the testop eqz pushes 1, the abort ifelse takes its THEN branch, and the
; code ((:CALL 4) (:RETURN)) becomes a block, then a label 0, and then the call
; to $abort (function 4), whose body is ((:CONST 2) (:GLOBAL.SET 3) (:CONST 2)).
;
; The chain so far, all at iz6 (function 6's frame, the frozen store):
;
;   the testop tier      testop-slice-zero, dsearch21-eqz0, dctxt/dstep/
;                        dlabel6/douter-eqz0   (the value 1, hypothesis 0)
;   the ifelse tier      difelse-slice-1 and the four lifts (the THEN branch
;                        becomes (:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN))))
;   the layer-0 steps    dcall4-lone/ctxt/spure/split/step-body (the call's
;                        split inside the label), dlabel0-call, dblock-abort
;   the context lifts    the block and the label-0 entries through label 6 and
;                        frame 6 (eight facts, the dvl-after-ifelse tails)
;   the call's entry     dc4-no-ctxt-2, dc4-entry-2, dc4-ctxt, dc4-step -- the
;                        (ref.func_addr 4) (call_ref ...) pair becomes
;                        (milawa-callee-admin 4), with the (:RETURN) kept after
;
; Next: the callee's execution (the abort book's generic facts re-used at this
; call site) and function 6's final return of 2.



(defthm dcall4-lone
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :call 4))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :ref.func_addr 4) *t3*)))))

(defthm dcall4-ctxt-body
  (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result)
                                        (list (list :call 4) (list :return))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :ref.func_addr 4) *t3* (list :return)))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :call 4) (list :return)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :call 4) (list :return))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (list (list :call 4) (list :return))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :call 4) (list :return)))))
                 (:instance dcall4-lone (bytes bytes) (sp sp) (pc pc) (clen clen) (result result))))))

(defthm dcall4-spure-body
  (equal (w3t::step_pure (list (list :call 4) (list :return))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (list (list :call 4) (list :return))))))))

(defthm dcall4-split-body
  (equal (w3t::step_read/split (icfg (iz6 bytes sp pc clen result)
                                     (list (list :call 4) (list :return))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :call 4) (list :return)))))))))

(defthm dcall4-step-body
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :call 4) (list :return))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :ref.func_addr 4) *t3* (list :return)))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (list (list :call 4) (list :return)))))
           :use (dcall4-spure-body dcall4-split-body dcall4-ctxt-body))))

(defthm dlabel0-call
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :label_%{%}% 0 nil
                                      (list (list :call 4) (list :return))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 0 nil
                                 (list (list :ref.func_addr 4) *t3* (list :return)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 0 nil
                                                        (list (list :call 4) (list :return)))))))
                 dcall4-step-body))))

(defthm dblock-abort
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :block (list :_result nil)
                                      (list (list :call 4) (list :return))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 0 nil
                                 (list (list :call 4) (list :return))))))))

(defthm testop-slice-zero
  (equal (w3t::step (icfg z (list (list :const (list :i32) 0)
                                  (list :testop (list :i32) (list :eqz)))))
         (list (icfg z (list (list :const (list :i32) 1))))))

(defthm dsearch21-eqz0
  (implies (equal (dltu (dsub pc) (dmul clen)) 0)
           (equal (w3t::step/search21 1 0 1
                                       (dvl (dbody4 pc clen)) 1
                                       (iz6 bytes sp pc clen result)
                                       (icfg (iz6 bytes sp pc clen result)
                                             (dvl (dbody4 pc clen))))
                  (list (list :|%;%| (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 1)))))))
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
                 (:instance testop-slice-zero (z (iz6 bytes sp pc clen result)))))))

(defthm dctxt-eqz0
  (implies (equal (dltu (dsub pc) (dmul clen)) 0)
           (equal (w3t::step/r-ctxt-instrs
                   (icfg (iz6 bytes sp pc clen result) (dvl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 1)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl (dbody4 pc clen)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl (dbody4 pc clen))))
                 dsearch21-eqz0))))

(defthm dstep-eqz0
  (implies (equal (dltu (dsub pc) (dmul clen)) 0)
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (dvl (dbody4 pc clen))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (dvl-after-testop (list (dconst 1)))))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-eqz0)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl (dbody4 pc clen))))))))

(defthm dlabel6-eqz0
  (implies (equal (dltu (dsub pc) (dmul clen)) 0)
           (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                                   (list (list :label_%{%}% 1 nil (dvl (dbody4 pc clen))))))
                  (list (icfg (iz6 bytes sp pc clen result)
                              (list (list :label_%{%}% 1 nil
                                          (dvl-after-testop (list (dconst 1)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl (dbody4 pc clen)))))))
                 dstep-eqz0))))

(defthm douter-eqz0
  (implies (equal (dltu (dsub pc) (dmul clen)) 0)
           (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                              (dvl (dbody4 pc clen))))
                  (list (frozen-body-cfg bytes sp pc clen 1 result
                                         (dvl-after-testop (list (dconst 1)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs
                                      dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl (dbody4 pc clen)))))))))
                 (:instance dlabel6-eqz0)))))

(defthm difelse-slice-1
  (equal (w3t::step (list :|%;%| z (cons (list :const '(:i32) 1) '((:IFELSE (:_RESULT NIL) ((:CALL 4) (:RETURN)) NIL)))))
         (list (list :|%;%| z (list '(:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN))))))))

(defthm dctxt-ifelse0 (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1))))) (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN)))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-instrs) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1)))))) (:instance (:definition w3t::step/prefix7) (w3t::%s (dvl-after-testop (list (dconst 1))))) (:instance (:definition w3t::step/search21) (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (dvl-after-testop (list (dconst 1)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1)))))) (:instance (:definition w3t::step/search21) (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1) (w3t::%t6 (dvl-after-testop (list (dconst 1)))) (w3t::%t9 1) (w3t::z (iz6 bytes sp pc clen result)) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1)))))) (:instance fail-lone-ifelse-cons (z (iz6 bytes sp pc clen result))) (:instance difelse-slice-0 (z (iz6 bytes sp pc clen result)))))))

(defthm dstep-ifelse0 (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1))))) (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN)))))))) :hints (("Goal" :in-theory (disable dsub dmul dltu deqz) :use (dctxt-ifelse0) :expand ((w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-testop (list (dconst 1)))))))))

(defthm dlabel6-ifelse0 (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 1))))))) (list (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN)))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-label) (w3t::%a0 (icfg (iz6 bytes sp pc clen result) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 1)))))))) dstep-ifelse0))))

(defthm douter-ifelse0 (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-testop (list (dconst 1))))) (list (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-ifelse (list '(:BLOCK (:_RESULT NIL) ((:CALL 4) (:RETURN)))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs) :use ((:instance (:definition w3t::step/r-ctxt-frame) (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result) (list (list :frame_%{%}% 1 (milawa-callee-frame 6) (list (list :label_%{%}% 1 nil (dvl-after-testop (list (dconst 1)))))))))) (:instance dlabel6-ifelse0)))))

(defthm dctxt-block-abort
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return))))))))
                 (:instance dblock-abort)))))

(defthm dstep-block-abort
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-block-abort)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))))))

(defthm dlabel6-block-abort
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :label_%{%}% 1 nil
                                      (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 1 nil
                                 (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return))))))))))
                 dstep-block-abort))))

(defthm douter-block-abort
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                     (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return)))))))
         (list (frozen-body-cfg bytes sp pc clen 1 result
                                (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl-after-ifelse (list (list :block (list :_result nil) (list (list :call 4) (list :return))))))))))))
                 (:instance dlabel6-block-abort)))))

(defthm dctxt-elabel-abort
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :ref.func_addr 4) *t3* (list :return))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))) (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))
                 (:instance dlabel0-call)))))

(defthm dstep-elabel-abort
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))
         (list (icfg (iz6 bytes sp pc clen result) (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :ref.func_addr 4) *t3* (list :return))))))))
  :hints (("Goal" :in-theory (disable dsub dmul dltu deqz)
           :use (dctxt-elabel-abort)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))))))

(defthm dlabel6-elabel-abort
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :label_%{%}% 1 nil (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :label_%{%}% 1 nil (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :ref.func_addr 4) *t3* (list :return))))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :label_%{%}% 1 nil
                                                        (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))))
                 dstep-elabel-abort))))

(defthm douter-elabel-abort
  (equal (w3t::step (frozen-body-cfg bytes sp pc clen 1 result
                                     (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return)))))))
         (list (frozen-body-cfg bytes sp pc clen 1 result (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :ref.func_addr 4) *t3* (list :return))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (list :|%;%| (frozen-z bytes sp pc clen 1 result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 6)
                                                        (list (list :label_%{%}% 1 nil
                                                                    (dvl-after-ifelse (list (list :label_%{%}% 0 nil (list (list :call 4) (list :return))))))))))))
                 (:instance dlabel6-elabel-abort)))))

(defthm dc4-no-ctxt-2
  (equal (w3t::step/r-ctxt-instrs (icfg (iz6 bytes sp pc clen result)
                                        (list (list :ref.func_addr 4) *t3*)))
         nil)
  :hints (("Goal" :expand ((w3t::step/r-ctxt-instrs
                            (icfg (iz6 bytes sp pc clen result)
                                  (list (list :ref.func_addr 4) *t3*)))
                           (:free (k lo hi i t9 zz a0)
                                  (w3t::step/search21 k lo hi i t9 zz a0))))))

(defthm dc4-entry-2
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :ref.func_addr 4) *t3*)))
         (list (icfg (iz6 bytes sp pc clen result)
                     (milawa-callee-admin 4))))
  :hints (("Goal" :use dc4-no-ctxt-2
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (list (list :ref.func_addr 4) *t3*)))))))

(defthm dc4-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result)
                (list (list :ref.func_addr 4) *t3* (list :return))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (append (milawa-callee-admin 4) (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :ref.func_addr 4) *t3* (list :return)))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (list (list :ref.func_addr 4) *t3* (list :return))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 1) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :ref.func_addr 4) *t3* (list :return)))
                            (w3t::%t9 1)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :ref.func_addr 4) *t3* (list :return)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (list (list :ref.func_addr 4) *t3* (list :return)))
                            (w3t::%t9 1)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :ref.func_addr 4) *t3* (list :return)))))
                 dc4-entry-2))))

(defthm dc4-step
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :ref.func_addr 4) *t3* (list :return))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (append (milawa-callee-admin 4) (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (list (list :ref.func_addr 4) *t3* (list :return)))))
           :use (dc4-ctxt))))

(defthm dframe4-step
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (list (list :frame_%{%}% 1 (milawa-callee-frame 4)
                                      (list (list :label_%{%}% 1 nil *abort-body*))))))
         (list (icfg (list :|%;%|
                           (w3t::$sof
                            (w3t::$with_global
                             (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                   (milawa-callee-frame 4))
                             3 (list :const (list :i32) 2)))
                           (w3t::$fof (iz6 bytes sp pc clen result)))
                     (list (list :frame_%{%}%
                                 1
                                 (w3t::$fof
                                  (w3t::$with_global
                                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                         (milawa-callee-frame 4))
                                   3 (list :const (list :i32) 2)))
                                 (list (list :label_%{%}% 1 nil *abort-body-after*)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (list (list :frame_%{%}% 1 (milawa-callee-frame 4)
                                                        (list (list :label_%{%}% 1 nil *abort-body*)))))))
                 (:instance dlabel-abort-body-gen
                            (z (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                     (milawa-callee-frame 4))))))))

(defthm dcallee4-cont-spure
  (equal (w3t::step_pure (append (milawa-callee-admin 4) (list (list :return)))) nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (append (milawa-callee-admin 4) (list (list :return)))))))))

(defthm dcallee4-cont-split
  (equal (w3t::step_read/split
          (icfg (iz6 bytes sp pc clen result)
                (append (milawa-callee-admin 4) (list (list :return)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (append (milawa-callee-admin 4) (list (list :return))))))))))

(defthm dcallee4-cont-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result)
                (append (milawa-callee-admin 4) (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :label_%{%}% 1 nil *abort-body-after*))))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (append (milawa-callee-admin 4) (list (list :return))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (append (milawa-callee-admin 4) (list (list :return)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (append (milawa-callee-admin 4) (list (list :return))))
                            (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (append (milawa-callee-admin 4) (list (list :return))))))
                 dframe4-step))))

(defthm dcallee4-cont-step
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result)
                          (append (milawa-callee-admin 4) (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :label_%{%}% 1 nil *abort-body-after*))))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step (icfg (iz6 bytes sp pc clen result)
                                     (append (milawa-callee-admin 4) (list (list :return))))))
           :use (dcallee4-cont-spure dcallee4-cont-split dcallee4-cont-ctxt))))

(defthm dframe-label-vals-gen
  (implies (and (equal (w3t::step (icfg (list :|%;%| s fp)
                                       (list (list :label_%{%}% 1 nil
                                                   (list (list :const (list :i32) 2))))))
                        (list (icfg (list :|%;%| s fp)
                                    (list (list :const (list :i32) 2)))))
                (< (w3t::%size (list (list :label_%{%}% 1 nil
                                           (list (list :const (list :i32) 2)))))
                   (w3t::%size (list (list :frame_%{%}% 1 fp
                                           (list (list :label_%{%}% 1 nil
                                                       (list (list :const (list :i32) 2)))))))))
           (equal (w3t::step (icfg (list :|%;%| s f)
                                   (list (list :frame_%{%}% 1 fp
                                               (list (list :label_%{%}% 1 nil
                                                           (list (list :const (list :i32) 2))))))))
                  (list (icfg (list :|%;%| s f)
                              (list (list :frame_%{%}% 1 fp
                                          (list (list :const (list :i32) 2))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-frame)
                            (w3t::%a0 (icfg (list :|%;%| s f)
                                            (list (list :frame_%{%}% 1 fp
                                                        (list (list :label_%{%}% 1 nil
                                                                    (list (list :const (list :i32) 2)))))))))))))

(defthm dcallee4-lv-spure
  (equal (w3t::step_pure
          (append (list (list :frame_%{%}%
                              1
                              (w3t::$fof
                               (w3t::$with_global
                                (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                      (milawa-callee-frame 4))
                                3 (list :const (list :i32) 2)))
                              (list (list :label_%{%}% 1 nil *abort-body-after*))))
                  (list (list :return))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (append (list (list :frame_%{%}%
                                                         1
                                                         (w3t::$fof
                                                          (w3t::$with_global
                                                           (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                                 (milawa-callee-frame 4))
                                                           3 (list :const (list :i32) 2)))
                                                         (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                             (list (list :return)))))))))

(defthm dcallee4-lv-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :label_%{%}% 1 nil *abort-body-after*))))
            (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :const (list :i32) 2))))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                        (list (list :return))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (append
                                      (list (list :frame_%{%}%
                                                  1
                                                  (w3t::$fof
                                                   (w3t::$with_global
                                                    (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                          (milawa-callee-frame 4))
                                                    3 (list :const (list :i32) 2)))
                                                  (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                      (list (list :return)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (append
                                       (list (list :frame_%{%}%
                                                   1
                                                   (w3t::$fof
                                                    (w3t::$with_global
                                                     (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                           (milawa-callee-frame 4))
                                                     3 (list :const (list :i32) 2)))
                                                   (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                       (list (list :return))))
                            (w3t::%t9 0)
                            (w3t::z (list :|%;%|
                                          (w3t::$sof
                                           (w3t::$with_global
                                            (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                  (milawa-callee-frame 4))
                                            3 (list :const (list :i32) 2)))
                                          (w3t::$fof (iz6 bytes sp pc clen result))))
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                        (list (list :return))))))
                 (:instance dframe-label-vals-gen
                            (s (w3t::$sof
                                (w3t::$with_global
                                 (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                       (milawa-callee-frame 4))
                                 3 (list :const (list :i32) 2))))
                            (f (w3t::$fof (iz6 bytes sp pc clen result)))
                            (fp (w3t::$fof
                                 (w3t::$with_global
                                  (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                        (milawa-callee-frame 4))
                                  3 (list :const (list :i32) 2)))))))))

(defthm dcallee4-lv-split
  (equal (w3t::step_read/split
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :label_%{%}% 1 nil *abort-body-after*))))
            (list (list :return)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :label_%{%}% 1 nil *abort-body-after*))))
                                        (list (list :return))))))))))

(defthm dcallee4-lv-step
  (equal (w3t::step
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :label_%{%}% 1 nil *abort-body-after*))))
            (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :const (list :i32) 2))))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step
                     (icfg
                      (list :|%;%|
                            (w3t::$sof
                             (w3t::$with_global
                              (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                    (milawa-callee-frame 4))
                              3 (list :const (list :i32) 2)))
                            (w3t::$fof (iz6 bytes sp pc clen result)))
                      (append
                       (list (list :frame_%{%}%
                                   1
                                   (w3t::$fof
                                    (w3t::$with_global
                                     (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                           (milawa-callee-frame 4))
                                     3 (list :const (list :i32) 2)))
                                   (list (list :label_%{%}% 1 nil *abort-body-after*))))
                       (list (list :return))))))
           :use (dcallee4-lv-spure dcallee4-lv-split dcallee4-lv-ctxt))))

(defthm dcallee4-fv-spure
  (equal (w3t::step_pure
          (append (list (list :frame_%{%}%
                              1
                              (w3t::$fof
                               (w3t::$with_global
                                (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                      (milawa-callee-frame 4))
                                3 (list :const (list :i32) 2)))
                              (list (list :const (list :i32) 2))))
                  (list (list :return))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (append (list (list :frame_%{%}%
                                                         1
                                                         (w3t::$fof
                                                          (w3t::$with_global
                                                           (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                                 (milawa-callee-frame 4))
                                                           3 (list :const (list :i32) 2)))
                                                         (list (list :const (list :i32) 2))))
                                             (list (list :return)))))))))

(defthm dcallee4-fv-split
  (equal (w3t::step_read/split
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :const (list :i32) 2))))
            (list (list :return)))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_read/split)
           :use ((:instance (:definition w3t::step_read/split)
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :const (list :i32) 2))))
                                        (list (list :return))))))))))

(defthm dcallee4-fv-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :const (list :i32) 2))))
            (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :const (list :i32) 2))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :const (list :i32) 2))))
                                        (list (list :return))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (append
                                      (list (list :frame_%{%}%
                                                  1
                                                  (w3t::$fof
                                                   (w3t::$with_global
                                                    (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                          (milawa-callee-frame 4))
                                                    3 (list :const (list :i32) 2)))
                                                  (list (list :const (list :i32) 2))))
                                      (list (list :return)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (append
                                       (list (list :frame_%{%}%
                                                   1
                                                   (w3t::$fof
                                                    (w3t::$with_global
                                                     (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                           (milawa-callee-frame 4))
                                                     3 (list :const (list :i32) 2)))
                                                   (list (list :const (list :i32) 2))))
                                       (list (list :return))))
                            (w3t::%t9 0)
                            (w3t::z (list :|%;%|
                                          (w3t::$sof
                                           (w3t::$with_global
                                            (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                  (milawa-callee-frame 4))
                                            3 (list :const (list :i32) 2)))
                                          (w3t::$fof (iz6 bytes sp pc clen result))))
                            (w3t::%a0 (icfg
                                       (list :|%;%|
                                             (w3t::$sof
                                              (w3t::$with_global
                                               (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                     (milawa-callee-frame 4))
                                               3 (list :const (list :i32) 2)))
                                             (w3t::$fof (iz6 bytes sp pc clen result)))
                                       (append
                                        (list (list :frame_%{%}%
                                                    1
                                                    (w3t::$fof
                                                     (w3t::$with_global
                                                      (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                                            (milawa-callee-frame 4))
                                                      3 (list :const (list :i32) 2)))
                                                    (list (list :const (list :i32) 2))))
                                        (list (list :return))))))
                 (:instance dstep-frame-vals
                            (z (list :|%;%|
                                     (w3t::$sof
                                      (w3t::$with_global
                                       (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                             (milawa-callee-frame 4))
                                       3 (list :const (list :i32) 2)))
                                     (w3t::$fof (iz6 bytes sp pc clen result))))
                            (fp (w3t::$fof
                                 (w3t::$with_global
                                  (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                        (milawa-callee-frame 4))
                                  3 (list :const (list :i32) 2)))))))))

(defthm dcallee4-fv-step
  (equal (w3t::step
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :frame_%{%}%
                        1
                        (w3t::$fof
                         (w3t::$with_global
                          (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                (milawa-callee-frame 4))
                          3 (list :const (list :i32) 2)))
                        (list (list :const (list :i32) 2))))
            (list (list :return)))))
         (list
          (icfg
           (list :|%;%|
                 (w3t::$sof
                  (w3t::$with_global
                   (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                         (milawa-callee-frame 4))
                   3 (list :const (list :i32) 2)))
                 (w3t::$fof (iz6 bytes sp pc clen result)))
           (append
            (list (list :const (list :i32) 2))
            (list (list :return))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step
                     (icfg
                      (list :|%;%|
                            (w3t::$sof
                             (w3t::$with_global
                              (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                    (milawa-callee-frame 4))
                              3 (list :const (list :i32) 2)))
                            (w3t::$fof (iz6 bytes sp pc clen result)))
                      (append
                       (list (list :frame_%{%}%
                                   1
                                   (w3t::$fof
                                    (w3t::$with_global
                                     (list :|%;%| (w3t::$sof (iz6 bytes sp pc clen result))
                                           (milawa-callee-frame 4))
                                     3 (list :const (list :i32) 2)))
                                   (list (list :const (list :i32) 2))))
                       (list (list :return))))))
           :use (dcallee4-fv-spure dcallee4-fv-split dcallee4-fv-ctxt))))
