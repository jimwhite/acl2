; L1, the running branch: the halt branch's first call.
;
; Copyright (C) 2026 Kookamara LLC
;
; See the LICENSE file distributed with ACL2.

; The halt block's label body starts with (:CALL 2), the $depth call.  This
; book takes that call through its three opening steps: the read split
; (:CALL 2 -> (:REF.FUNC_ADDR 2) + the call_ref type), the call entry (into
; function 2's frame, label and body), and the same two steps inside the
; HALT BLOCK's wasm label.  The call must run at the CALLEE pair -- the frame
; rule has already swapped function 6's frame in -- because the type lookup
; goes through the frame's module; at the entry pair the module is the empty
; entry module.
;
; Two proof techniques are needed and are recorded for the rest of the
; branches:
;
;   * The call ENTRY does not reduce by plain evaluation: the step dispatcher
;     reaches step/r-ctxt-instrs and stalls on the read rule's symbolic guard.
;     running.lisp's no-ctxt-instrs-on-call-3 is the template -- state the
;     context rule's failure on the (ref.func_addr + call_ref) pair with an
;     :expand of the context rule and a :free expansion of search21 -- and
;     then the entry is the step with that fact :used and step :expanded.
;
;   * Inside the wasm label the inner step is itself a context step.  With
;     step enabled the label rule's body unfolds the inner step to
;     step/r-ctxt-instrs, so the fact to hand it is the CONTEXT fact
;     (dctxt-call2), not the step fact; with step disabled the outer step
;     cannot unfold to the label rule at all (the residual goal is the raw
;     label step).

(in-package "MILAWA-WASM")

(include-book "dispatch-tests")

(defun dcallee-pair (bytes sp pc clen result w)
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
          1 (list :const (list :i32) (dadd pc))))))

(defthm dctxt-call2 (equal (w3t::step/r-ctxt-instrs (list :|%;%| (dcallee-pair bytes sp pc clen result w) (caddr *d-ifelse*))) (list (list :|%;%| (dcallee-pair bytes sp pc clen result w) (cons (list :ref.func_addr 2) (cons *t3* (cdr (caddr *d-ifelse*))))))) :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd w3t::$binop_) :use ((:instance w3t::step/r-ctxt-instrs (w3t::%a0 (list :|%;%| (dcallee-pair bytes sp pc clen result w) (caddr *d-ifelse*)))) (:instance w3t::step/prefix7 (w3t::%s (caddr *d-ifelse*))) (:instance w3t::step/search21 (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0) (w3t::%t6 (caddr *d-ifelse*)) (w3t::%t9 0) (w3t::z (dcallee-pair bytes sp pc clen result w)) (w3t::%a0 (list :|%;%| (dcallee-pair bytes sp pc clen result w) (caddr *d-ifelse*)))) dcall2-split))))

(defthm dstep-call2 (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (caddr *d-ifelse*))) (list (list :|%;%| (dcallee-pair bytes sp pc clen result w) (cons (list :ref.func_addr 2) (cons *t3* (cdr (caddr *d-ifelse*))))))) :hints (("Goal" :in-theory (disable dcallee-pair) :use (dctxt-call2) :expand ((w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (caddr *d-ifelse*)))))))

(defthm dwlabel-call2 (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 0 nil (caddr *d-ifelse*))))) (list (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 0 nil (cons (list :ref.func_addr 2) (cons *t3* (cdr (caddr *d-ifelse*))))))))) :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dcallee-pair) :use ((:instance w3t::step/r-ctxt-label (w3t::%a0 (list :|%;%| (dcallee-pair bytes sp pc clen result w) (list (list :label_%{%}% 0 nil (caddr *d-ifelse*)))))) dctxt-call2))))

;; The call entry, via the no-ctxt fact.

(defthm no-ctxt-instrs-on-call-2
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%|
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
                (list (list :ref.func_addr 2) *t3*)))
         nil)
  :hints (("Goal"
           :expand ((w3t::step/r-ctxt-instrs
                     (list :|%;%|
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
                           (list (list :ref.func_addr 2) *t3*)))
                    (:free (k lo hi i t9 zz a0)
                           (w3t::step/search21 k lo hi i t9 zz a0))))))


(defun dcallee-pair (bytes sp pc clen result w)
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
          1 (list :const (list :i32) (dadd pc))))))


(defthm dcall2-entry
  (equal (w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                          (list (list :ref.func_addr 2) *t3*)))
         (list (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                     (milawa-callee-admin 2))))
  :hints (("Goal" :in-theory (disable dadd w3t::$binop_)
                  :use ((:instance no-ctxt-instrs-on-call-2))
                  :expand ((w3t::step (list :|%;%| (dcallee-pair bytes sp pc clen result w)
                                            (list (list :ref.func_addr 2) *t3*)))))))
