(in-package "MILAWA-WASM")

(include-book "oob")

; L1, the running branch: the CONST (opcode 1) tail.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The CONST test's true branch leaves the tail
;
;   (:CALL 3) (:TESTOP eqz) (:IFELSE abort NIL) (:GLOBAL.GET 1) (:LOAD ...)
;   (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST 4) (:BINOP ADD) (:GLOBAL.SET 1)
;   (:LOCAL.GET 1) (:CALL 0) (:CONST 1) (:RETURN)
;
; at the head of function 6's label body.  This book starts its execution at
; the body level (z = iz6, the callee frame 6 record): the call to $in_code
; (function 3) is split by the ctxt search's lone-call slice (dcall3-lone,
; dconst-tail-spure/read/ctxt/step) and the (ref.func_addr 3) (call_ref ...)
; pair's entry pushes the callee admin (dconst-tail-entry-ctxt, using running's
; rstep-call-entry-3 at the same frozen-callee-z).  The callee's execution and
; the rest of the tail follow.


(defthm dcall3-lone
  (equal (w3t::step (icfg (iz6 bytes sp pc clen result) (list (list :call 3))))
         (list (icfg (iz6 bytes sp pc clen result)
                     (list (list :ref.func_addr 3) *t3*)))))

(defthm dconst-tail-read
  (equal (w3t::step_read/split
          (icfg (iz6 bytes sp pc clen result)
                (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                        (list (list :ifelse (list :_result nil)
                                    (list (list :call 4) (list :return)) nil)
                              (list :global.get 1)))))
         nil))



(defthm dconst-tail-spure
  (equal (w3t::step_pure
          (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                  (list (list :ifelse (list :_result nil)
                              (list (list :call 4) (list :return)) nil)
                        (list :global.get 1))))
         nil)
  :hints (("Goal" :in-theory (disable w3t::step_pure)
           :use ((:instance (:definition w3t::step_pure)
                            (w3t::%a0 (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                              (list (list :ifelse (list :_result nil)
                                                          (list (list :call 4) (list :return)) nil)
                                                    (list :global.get 1)))))))))

(defthm dconst-tail-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result)
                (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                        (list (list :ifelse (list :_result nil)
                                    (list (list :call 4) (list :return)) nil)
                              (list :global.get 1)))))
         (list
          (icfg (iz6 bytes sp pc clen result)
                (cons (list :ref.func_addr 3)
                      (cons *t3*
                            (append (list (list :testop (list :i32) (list :eqz)))
                                    (list (list :ifelse (list :_result nil)
                                                (list (list :call 4) (list :return)) nil)
                                          (list :global.get 1))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                                    (list (list :ifelse (list :_result nil)
                                                                (list (list :call 4) (list :return)) nil)
                                                          (list :global.get 1))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                             (list (list :ifelse (list :_result nil)
                                                         (list (list :call 4) (list :return)) nil)
                                                   (list :global.get 1)))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                              (list (list :ifelse (list :_result nil)
                                                          (list (list :call 4) (list :return)) nil)
                                                    (list :global.get 1))))
                            (w3t::%t9 0)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                                    (list (list :ifelse (list :_result nil)
                                                                (list (list :call 4) (list :return)) nil)
                                                          (list :global.get 1))))))
                 dcall3-lone))))



(defthm dconst-tail-step
  (equal (w3t::step
          (icfg (iz6 bytes sp pc clen result)
                (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                        (list (list :ifelse (list :_result nil)
                                    (list (list :call 4) (list :return)) nil)
                              (list :global.get 1)))))
         (list
          (icfg (iz6 bytes sp pc clen result)
                (cons (list :ref.func_addr 3)
                      (cons *t3*
                            (append (list (list :testop (list :i32) (list :eqz)))
                                    (list (list :ifelse (list :_result nil)
                                                (list (list :call 4) (list :return)) nil)
                                          (list :global.get 1))))))))
  :hints (("Goal" :in-theory (disable w3t::step)
           :expand ((w3t::step
                     (icfg (iz6 bytes sp pc clen result)
                           (append (list (list :call 3) (list :testop (list :i32) (list :eqz)))
                                   (list (list :ifelse (list :_result nil)
                                               (list (list :call 4) (list :return)) nil)
                                         (list :global.get 1))))))
           :use (dconst-tail-spure dconst-tail-read dconst-tail-ctxt))))

(defthm dconst-tail-entry-ctxt
  (equal (w3t::step/r-ctxt-instrs
          (icfg (iz6 bytes sp pc clen result)
                (cons (list :ref.func_addr 3)
                      (cons *t3*
                            (append (list (list :testop (list :i32) (list :eqz)))
                                    (list (list :ifelse (list :_result nil)
                                                (list (list :call 4) (list :return)) nil)
                                          (list :global.get 1)))))))
         (list
          (icfg (iz6 bytes sp pc clen result)
                (append (milawa-callee-admin 3)
                        (append (list (list :testop (list :i32) (list :eqz)))
                                (list (list :ifelse (list :_result nil)
                                            (list (list :call 4) (list :return)) nil)
                                      (list :global.get 1)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs)
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cons (list :ref.func_addr 3)
                                                  (cons *t3*
                                                        (append (list (list :testop (list :i32) (list :eqz)))
                                                                (list (list :ifelse (list :_result nil)
                                                                            (list (list :call 4) (list :return)) nil)
                                                                      (list :global.get 1))))))))
                 (:instance (:definition w3t::step/prefix7)
                            (w3t::%s (cons (list :ref.func_addr 3)
                                           (cons *t3*
                                                 (append (list (list :testop (list :i32) (list :eqz)))
                                                         (list (list :ifelse (list :_result nil)
                                                                     (list (list :call 4) (list :return)) nil)
                                                               (list :global.get 1)))))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 1)
                            (w3t::%t6 (cons (list :ref.func_addr 3)
                                            (cons *t3*
                                                  (append (list (list :testop (list :i32) (list :eqz)))
                                                          (list (list :ifelse (list :_result nil)
                                                                      (list (list :call 4) (list :return)) nil)
                                                                (list :global.get 1))))))
                            (w3t::%t9 1)
                            (w3t::z (iz6 bytes sp pc clen result))
                            (w3t::%a0 (icfg (iz6 bytes sp pc clen result)
                                            (cons (list :ref.func_addr 3)
                                                  (cons *t3*
                                                        (append (list (list :testop (list :i32) (list :eqz)))
                                                                (list (list :ifelse (list :_result nil)
                                                                            (list (list :call 4) (list :return)) nil)
                                                                      (list :global.get 1))))))))
                 (:instance rstep-call-entry-3 (status 1))))))

