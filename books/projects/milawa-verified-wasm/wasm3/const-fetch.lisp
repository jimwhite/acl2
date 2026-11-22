(in-package "MILAWA-WASM")

(include-book "const-callee")

; L1, the CONST path's tail, part 4: the caller's fetch, the test, the abort
; ifelse and the empty block/label dissolves, then the pc bump and the
; local.get -- plus the state-changing steps (local.set 1, global.set 1) at
; the PAIR spelling of their result states.
;
; The branch's 13-instruction continuation after the callee is
; (const-rest) = ((:TESTOP ...) (:IFELSE ...) (:GLOBAL.GET 1) (:LOAD ...)
; (:LOCAL.SET 1) (:GLOBAL.GET 1) (:CONST (:I32) 4) (:BINOP (:I32) (:ADD))
; (:GLOBAL.SET 1) (:LOCAL.GET 1) (:CALL 0) (:CONST (:I32) 1) (:RETURN)),
; so after k consumed instructions the body is the k-th cdr of (const-rest)
; (or a cons of the pushed value onto it).  The steps S1..S11 are:
;
;   eqz     (const 0) :: rest            [const-tail, the dvl spelling]
;   ifelse  (block ...) :: cddr          (the abort test takes the else)
;   block   (label 0 nil nil) :: cddr
;   elabel  cddr (the empty branch dissolves)
;   read    (const (dadd pc)) :: cdddr   (global.get 1 = the store's pc)
;   [load  -- the memory step, still open]
;   lset1   const-tail2                  (local.set 1 := W; z -> the pair)
;   get1    (const (dadd pc)) :: cdr const-tail2
;   add     (const (dadd (dadd pc))) :: cdddr const-tail2
;   gset    cddddr const-tail2           (pc := pc+4; z -> the pair)
;   lget    (const W) :: cdr cddddr      (local.get 1)
;
; THE PAIR SPELLING: after a state-changing step the result z is written
; (list :%;% ($sof z) ($fof z)) -- its own pair.  The label lift's and the
; frame rule's z-shape conditions then hold by sof/fof-of-a-pair, and the
; pair facts (run-z1-pair/run-z2-pair, :rule-classes nil) bridge to the
; $with_local/$with_global spellings used by the ctxt facts.  The frame
; lift must take its outer store/frame from the STEP's own z, not from the
; gset: after local.set 1 the run's frame-6 record is the updated one.

(defthm run-z1-pair
  (equal (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable w3t::$with_local w3t::$sof w3t::$fof))))

(defthm run-z2-pair
  (equal (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))) (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable w3t::$with_global w3t::$with_local w3t::$sof w3t::$fof))))

(defthm tail-g1p-ctxt
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (const-tail2)))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd
                                      w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use (tail-g1-ctxt run-z1-pair))))

(defthm tail-adp-ctxt
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd
                                      w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use (tail-ad-ctxt run-z1-pair))))

(defthm tail-lgp-ctxt
  (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W)))
           (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cddddr (const-tail2))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cons (list :const (list :i32) W)
                                                 (cdr (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step/r-ctxt-instrs dadd
                                      w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use (tail-lg-ctxt run-z2-pair))))
; ld test

(defthm tail-if-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) 0) (cdr (const-rest)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) 0) (cdr (const-rest))))))
           :use (tail-ifelse2-ctxt))))

(defthm tail-if-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest))))))))
                 tail-if-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-if-label0-rest
    (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))))))))
                   tail-if-label0)))))

(defthm tail-if-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-if-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-if-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-if-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-if-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-if-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-if-label0-rest tail-if-spure-body tail-if-sread-body
                 tail-if-spure-label tail-if-sread-label tail-if-size))))

(encapsulate ()
  (local (include-book "engine"))
  (defthm tail-if-frame
    (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (disable w3t::step dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) milawa-func-body (:executable-counterpart milawa-func-body) ibody3-after-1 sof-gset-is-frozen-store gset frozen-store mvm-abs-z-abstract milawa-callee-frame (:executable-counterpart milawa-callee-frame) w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global w3t::$s w3t::$f w3t::$store w3t::$frame zrun const-tail2 iz6)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (b (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                              (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*) (r nil)
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
                   (:instance we::not-exit-body-p-of-vals-admin-term-rest
                              (v nil) (i (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) 0) (cdr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (r nil))
                   tail-if-label1)))))
; ---------- tail-blk: the body step at the run's state ----------

(defthm tail-blk-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))
           :use (tail-block2-ctxt))))

(defthm tail-blk-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest))))))))
                 tail-blk-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-blk-label0-rest
    (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))))))))
                   tail-blk-label0)))))

(defthm tail-blk-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-blk-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-blk-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-blk-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-blk-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-blk-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (quote (:BLOCK (:_RESULT NIL) NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-blk-label0-rest tail-blk-spure-body tail-blk-sread-body
                 tail-blk-spure-label tail-blk-sread-label tail-blk-size))))

(encapsulate ()
  (local (include-book "engine"))
  (defthm tail-blk-frame
    (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (disable w3t::step dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) milawa-func-body (:executable-counterpart milawa-func-body) ibody3-after-1 sof-gset-is-frozen-store gset frozen-store mvm-abs-z-abstract milawa-callee-frame (:executable-counterpart milawa-callee-frame) w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global w3t::$s w3t::$f w3t::$store w3t::$frame zrun const-tail2 iz6)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (b (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                              (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*) (r nil)
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
                   (:instance we::not-exit-body-p-of-vals-admin-term-rest
                              (v nil) (i (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:BLOCK (:_RESULT NIL) NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (r nil))
                   tail-blk-label1)))))
; ---------- tail-elb: the body step at the run's state ----------

(defthm tail-elb-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cddr (const-rest)))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))
           :use (tail-elabel2-ctxt))))

(defthm tail-elb-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest))))))))
                 tail-elb-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-elb-label0-rest
    (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cddr (const-rest))))))))
                   tail-elb-label0)))))

(defthm tail-elb-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-elb-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-elb-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-elb-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-elb-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-elb-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (quote (:LABEL_%{%}% 0 NIL NIL)) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-elb-label0-rest tail-elb-spure-body tail-elb-sread-body
                 tail-elb-spure-label tail-elb-sread-label tail-elb-size))))

(encapsulate ()
  (local (include-book "engine"))
  (defthm tail-elb-frame
    (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (disable w3t::step dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) milawa-func-body (:executable-counterpart milawa-func-body) ibody3-after-1 sof-gset-is-frozen-store gset frozen-store mvm-abs-z-abstract milawa-callee-frame (:executable-counterpart milawa-callee-frame) w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global w3t::$s w3t::$f w3t::$store w3t::$frame zrun const-tail2 iz6)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (b (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                              (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*) (r nil)
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
                   (:instance we::not-exit-body-p-of-vals-admin-term-rest
                              (v nil) (i (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons '(:LABEL_%{%}% 0 NIL NIL) (cddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (r nil))
                   tail-elb-label1)))))
; ---------- tail-frd2: the body step at the run's state ----------

(defthm tail-frd2-step
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cddr (const-rest))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cddr (const-rest)))))
           :use (tail-frd-ctxt))))

(defthm tail-frd2-label0
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cddr (const-rest))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cddr (const-rest)))))))
                 tail-frd2-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-frd2-label0-rest
    (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cddr (const-rest))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))))))
                   tail-frd2-label0)))))

(defthm tail-frd2-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-frd2-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-frd2-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-frd2-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-frd2-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-frd2-label1
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-frd2-label0-rest tail-frd2-spure-body tail-frd2-sread-body
                 tail-frd2-spure-label tail-frd2-sread-label tail-frd2-size))))

(defthm tail-frd2-frame
  (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (z1 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                            (b (cons (list :label_%{%}% 0 nil (cddr (const-rest))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-frd2-label1))))
; ---------- tail-g1p: the body step at the run's state ----------

(defthm tail-g1p-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (const-tail2)))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (const-tail2))))
           :use (tail-g1p-ctxt))))

(defthm tail-g1p-label0
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (const-tail2)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (const-tail2))))))
                 tail-g1p-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-g1p-label0-rest
    (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (const-tail2)))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))))))
                   tail-g1p-label0)))))

(defthm tail-g1p-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-g1p-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-g1p-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-g1p-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-g1p-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-g1p-label1
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-g1p-label0-rest tail-g1p-spure-body tail-g1p-sread-body
                 tail-g1p-spure-label tail-g1p-sread-label tail-g1p-size))))

(defthm tail-g1p-frame
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (z1 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                            (b (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-g1p-label1))))
; ---------- tail-adp: the body step at the run's state ----------

(defthm tail-adp-step
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2))))))
           :use (tail-adp-ctxt))))

(defthm tail-adp-label0
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2))))))))
                 tail-adp-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-adp-label0-rest
    (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))))))
                   tail-adp-label0)))))

(defthm tail-adp-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-adp-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-adp-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-adp-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-adp-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-adp-label1
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-adp-label0-rest tail-adp-spure-body tail-adp-sread-body
                 tail-adp-spure-label tail-adp-sread-label tail-adp-size))))

(defthm tail-adp-frame
  (implies (and (unsigned-byte-p 32 (dadd pc)) (unsigned-byte-p 32 clen)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (z1 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                            (b (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-adp-label1))))
; ---------- tail-lgp: the body step at the run's state ----------

(defthm tail-lgp-step
  (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cddddr (const-tail2))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cddddr (const-tail2)))))
           :use (tail-lgp-ctxt))))

(defthm tail-lgp-label0
  (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cddddr (const-tail2))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cddddr (const-tail2)))))))
                 tail-lgp-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-lgp-label0-rest
    (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cddddr (const-tail2))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))))))))
                   tail-lgp-label0)))))

(defthm tail-lgp-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-lgp-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-lgp-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-lgp-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-lgp-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-lgp-label1
  (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) (body (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-lgp-label0-rest tail-lgp-spure-body tail-lgp-sread-body
                 tail-lgp-spure-label tail-lgp-sread-label tail-lgp-size))))

(defthm tail-lgp-frame
  (implies (equal (w3t::$local (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))) 1) (list (list :const (list :i32) W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))))) (z1 (list :|%;%| (w3t::$sof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) 1 (list :const (list :i32) (dadd (dadd pc)))))))
                            (b (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cdr (cddddr (const-tail2))))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-lgp-label1))))

(defthm tail-ls1p-step
  (implies (unsigned-byte-p 32 W) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) W) (cddddr (const-rest)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (const-tail2)))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) W) (cddddr (const-rest))))))
           :use (tail-ls1-ctxt run-z1-pair))))

(defthm tail-ls1p-label0
  (implies (unsigned-byte-p 32 W) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (const-tail2)))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest))))))))
                 tail-ls1p-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-ls1p-label0-rest
    (implies (unsigned-byte-p 32 W) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (const-tail2)))))))
                   tail-ls1p-label0)))))

(defthm tail-ls1p-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-ls1p-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-ls1p-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-ls1p-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-ls1p-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-ls1p-label1
  (implies (unsigned-byte-p 32 W) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body2 (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-ls1p-label0-rest tail-ls1p-spure-body tail-ls1p-sread-body
                 tail-ls1p-spure-label tail-ls1p-sread-label tail-ls1p-size run-z1-pair))))

(defthm tail-ls1p-frame
  (implies (unsigned-byte-p 32 W) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (z1 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                            (b (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (const-tail2)) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-ls1p-label1 run-z1-pair))))
; ---------- tail-gsp: the body step at the run's state ----------

(defthm tail-gsp-step
  (implies (unsigned-byte-p 32 (dadd pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cddddr (const-tail2))))))
  :hints (("Goal" :in-theory (disable w3t::step dsub dmul dltu deqz zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2))))))
           :use (tail-gs-ctxt run-z1-pair run-z2-pair))))

(defthm tail-gsp-label0
  (implies (unsigned-byte-p 32 (dadd pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cddddr (const-tail2))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance (:definition w3t::step/r-ctxt-label)
                            (w3t::%a0 (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2))))))))
                 tail-gsp-step))))

(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-gsp-label0-rest
    (implies (unsigned-byte-p 32 (dadd pc)) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))) (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 0 nil (cddddr (const-tail2))))))))
                   tail-gsp-label0)))))

(defthm tail-gsp-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))

(defthm tail-gsp-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))

(defthm tail-gsp-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))

(defthm tail-gsp-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))

(defthm tail-gsp-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))

(defthm tail-gsp-label1
  (implies (unsigned-byte-p 32 (dadd pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) )
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (body (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))))) (body2 (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-gsp-label0-rest tail-gsp-spure-body tail-gsp-sread-body
                 tail-gsp-spure-label tail-gsp-sread-label tail-gsp-size run-z1-pair run-z2-pair))))

(defthm tail-gsp-frame
  (implies (unsigned-byte-p 32 (dadd pc)) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
         (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step gset w3t::$with_global w3t::$with_local 
                                      frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                      dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :use ((:instance dframe-outer-sep
                            (s (w3t::$sof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (fp (w3t::$fof (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)))))) (f *frozen-entry-frame*)
                            (z0 (list :|%;%| (w3t::$sof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))) (w3t::$fof (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W))))) (z1 (list :|%;%| (w3t::$sof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc))))) (w3t::$fof (w3t::$with_global (w3t::$with_local (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) 1 (list :const (list :i32) W)) 1 (list :const (list :i32) (dadd (dadd pc)))))))
                            (b (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd (dadd pc))) (cdddr (const-tail2)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (b2 (cons (list :label_%{%}% 0 nil (cddddr (const-tail2))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-gsp-label1 run-z1-pair run-z2-pair))))


; ---------------------------------------------------------------------------
; THE LOAD: the memory read at the run's state
; ---------------------------------------------------------------------------
;
; The read (global.get 1) pushed the address (dadd pc); the load then reads
; the word W at it under the memory hypotheses.  The step itself is proved by
; handing in the ctxt fact AND the load's slice fact (the read phase's search
; needs the slice to see the value).  The label-0 lift uses the generic
; recipe; its step_pure/step_read premises need the book's `cal-load'
; trap-search recipes -- the FREE-variable expansions of match135 /
; search141 (`:expand ((:free (x) (step_pure/search141 11 11 11 x)))`) plus
; the `(%tag-lo :RETURN 1 body) = 11` fact, without which the pure
; return-label search runs away past 8M steps.
; ---------- the load: value/hyp spelling, generic label-0 recipe ----------
(defthm tail-load-slice2
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W)))
           (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :const (list :i32) (dadd pc))
                                                    (quote (:load (:i32) nil 0 (:%rec (:align . 2) (:offset . 0)))))))
                  (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :const (list :i32) W)))))))
(defthm tail-ld2-taglo
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (wrt::%tag-lo :RETURN 1 (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) 11))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1))))
(defthm tail-ld2-match
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure/match135 (take 10 (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/match135 x))
                    (:free (x) (take 10 x))))))
(defthm tail-ld2-search
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure/search141 11 11 11 (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure/search141 11 11 11 x)))
           :use (tail-ld2-match))))
(defthm tail-ld2-spure-b
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x))))))
(defthm tail-ld2-sread-b
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_read/split (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((w3t::step_read/split (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))))))
(defthm tail-ld2-spure-l0
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_pure (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((:free (x) (w3t::step_pure x)))
           :use (tail-ld2-taglo tail-ld2-search))))
(defthm tail-ld2-sread-l0
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step_read/split (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))))) nil))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1)
           :expand ((w3t::step_read/split (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))))))))
(defthm tail-ld2-size-b
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (< (w3t::%size (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (w3t::%size (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))))))
  :hints (("Goal" :in-theory (disable w3t::step/r-ctxt-instrs dsub dmul dltu deqz w3t::$binop_ w3t::$nbytes_ w3t::$with_mem w3t::$with_global w3t::$with_local frozen-store iz6 milawa-func-body dconst zlset1))))
(defthm tail-ld2-label0
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))))
                       (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))))))))
  :hints (("Goal" :in-theory (disable w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) w3t::step_pure w3t::step_read/split)
           :use ((:instance label-lift-general-n (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (n 0) (body (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (body2 (cons (list :const (list :i32) W) (cddddr (const-rest))))) tail-ld2-spure-b tail-ld2-sread-b tail-ld2-spure-l0
                 tail-ld2-sread-l0 tail-ld2-size-b tail-ld2-search tail-ld2-taglo
                 tail-ld-ctxt))))
(defthm tail-ld2-step
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) W) (cddddr (const-rest)))))))
  :hints (("Goal" :in-theory (disable w3t::step dadd w3t::$binop_ (:executable-counterpart w3t::$binop_))
           :expand ((w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest))))))
           :use (tail-ld-ctxt tail-load-slice2))))
(defthm tail-ld2-spure-body (equal (w3t::step_pure (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) nil))
(defthm tail-ld2-sread-body
  (equal (w3t::step_read/split (list :|%;%| z (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) nil))
(defthm tail-ld2-spure-label
  (equal (w3t::step_pure (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))) nil))
(defthm tail-ld2-sread-label
  (equal (w3t::step_read/split (list :|%;%| z (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))) nil))
(defthm tail-ld2-size
  (< (w3t::%size (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (w3t::%size (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))
(encapsulate ()
  (local (include-book "engine-flat"))
  (defthm tail-ld2-label0-rest
    (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step/r-ctxt-instrs (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
    :hints (("Goal"
             :in-theory (disable (:definition w3t::step) w3t::step/r-ctxt-instrs dadd
                                     w3t::$binop_ (:executable-counterpart w3t::$binop_)
                                     milawa-func-body (:executable-counterpart milawa-func-body)
                                     ibody3-after-1
                                     sof-gset-is-frozen-store
                                     gset frozen-store mvm-abs-z-abstract
                                     milawa-callee-frame (:executable-counterpart milawa-callee-frame)
                                     w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global
                                     w3t::$s w3t::$f w3t::$store w3t::$frame zrun
                                     const-tail2 iz6)
             :use ((:instance engine-ctxt-from-instr-step
                              (i (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))))
                              (r (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))
                              (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))))))))
                   tail-ld2-label0)))))
(defthm tail-ld2-label1
  (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))
                       (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
  :hints (("Goal" :in-theory (disable w3t::step w3t::step zrun gset w3t::$with_global w3t::$sof w3t::$fof w3t::$s w3t::$f w3t::$store w3t::$frame w3t::$with_local frozen-store iz6 milawa-callee-frame (:executable-counterpart milawa-callee-frame) dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) dsub dmul dltu deqz)
           :use ((:instance label-lift-general (z (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))) (z2 (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (body2 (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))
                 tail-ld2-label0-rest tail-ld2-spure-body tail-ld2-sread-body
                 tail-ld2-spure-label tail-ld2-sread-label tail-ld2-size))))
(encapsulate ()
  (local (include-book "engine"))
  (defthm tail-ld2-frame
    (implies (and (w3t::un-p (dadd pc) 32) (w3t::un-p W 32) (<= (+ (dadd pc) 4) (len bytes)) (equal (take 4 (nthcdr (dadd pc) bytes)) (mvm-word-to-bytes W))) (equal (w3t::step (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))))) (list (list :|%;%| (list :|%;%| (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) *frozen-entry-frame*) (list (list :frame_%{%}% 1 (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w)))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))))
    :rule-classes nil
    :hints (("Goal"
             :in-theory (disable w3t::step dadd w3t::$binop_ (:executable-counterpart w3t::$binop_) milawa-func-body (:executable-counterpart milawa-func-body) ibody3-after-1 sof-gset-is-frozen-store gset frozen-store mvm-abs-z-abstract milawa-callee-frame (:executable-counterpart milawa-callee-frame) w3t::$sof w3t::$fof w3t::$with_local w3t::$with_global w3t::$s w3t::$f w3t::$store w3t::$frame zrun const-tail2 iz6)
             :use ((:instance engine-admin-term-in-block
                              (k :f) (n 1) (x (w3t::$fof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (b (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))))
                              (s (w3t::$sof (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))))) (f *frozen-entry-frame*) (r nil)
                              (inner (list (list :|%;%| (list :|%;%| (w3t::$sof (gset bytes sp pc clen result w)) (w3t::$fof (gset bytes sp pc clen result w))) (list (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) W) (cddddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*))))))))))))))))))))
                   (:instance we::not-exit-body-p-of-vals-admin-term-rest
                              (v nil) (i (list :label_%{%}% 1 nil (cons (list :label_%{%}% 0 nil (cons (list :const (list :i32) (dadd pc)) (cdddr (const-rest)))) (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr *ft2*)))))))))))))))) (r nil))
                   tail-ld2-label1)))))
