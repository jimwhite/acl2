; L1, layer 8: the whole of one step, and what is left of it.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The layers below this one each prove a piece of one spec step:
; instructions.lisp the pure opcodes, reads.lisp the global reads, frames.lisp
; the local reads, context.lisp and calls.lisp and returns.lisp the descent
; through labels and frames.  This book starts assembling them into whole steps,
; and records exactly where the assembly stops.
;
; WHAT THE SEMANTICS ACTUALLY DOES, which took a wrong assumption to find.  I had
; assumed `step/r-ctxt-instrs` is NIL on a configuration whose instruction list
; has no context in it, so that the descent would fall through to the pure and
; read rules.  It is not.  Reading the generated semantics
; (`4_3-execution_instructions.lisp`) settles it:
;
;   (defun step/r-ctxt-instrs (a0)
;     ... (let* ((%t9 (step/prefix7 %t6)))          ; leading values
;           (and (< %t9 (len %t6))
;                (step/search21 %t9 0 %t9 %t6 %t9 z a0))))
;
; `step/prefix7` counts the leading values; `step/search21` walks k down from
; that count, and at each k it takes one instruction, wraps it in a
; context-free configuration and calls `step` on it.  So `step/r-ctxt-instrs` is
; the function that FINDS THE INSTRUCTION TO STEP NEXT, and puts the surrounding
; values back with `append`:
;
;   (:;% z' (append (step/iter20 values) (append instrs' rest)))
;
; Two consequences, both load-bearing.  First, an instruction lemma of the
; layer-1/layer-2 shape -- values before, instruction last -- is exactly what
; `step/ctxt-instrs` consumes, so those layers are the right ingredients and no
; separate interface is needed.  Second, the fact the search needs at the bottom
; of every descent is `(step (:;% z (list instr)))`, a step of a ONE-INSTRUCTION
; configuration.  That is what this book proves, for the instruction that every
; body in this module starts with.
;
; WHY THE STORE HAS TO BE THE ABSTRACT ONE.  With `z` a plain variable the spec's
; global lookup cannot be reduced at all -- the answer would have to be phrased in
; terms of the store's internal record structure, which is exactly what
; abs.lisp's `milawa-global` abstracts away.  With `(mvm-abs-z-abstract ...)` the
; value comes back as the parameter `STATUS`, so the lemma is a fact about the
; program rather than about the spec's representation.  Measured: 21,597 prover
; steps for the `step/r-read` form, 21,668 for the whole `step`.

(in-package "ACL2")

(include-book "returns")

; The read rule on its own, which is the second thing `step` tries.
(defthm step-r-read-of-global-get-3
  (equal (w3t::step/r-read
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 3))))
         (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                     (list (list :const (list :i32) status))))))

; And the whole step: `step/r-pure` does not apply, so `step/r-read` is what
; answers.  This is the bottom of every descent through this module's bodies.
(defthm step-of-global-get-3
  (equal (w3t::step
          (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                (list (list :global.get 3))))
         (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                     (list (list :const (list :i32) status))))))

; THE SEARCH REFUSES A LONE INSTRUCTION, which is the thing that made the first
; few attempts at the lemma below unprovable rather than merely hard.  The
; `search21` body requires
;
;   (or (not (equal val-star nil)) (not (equal instr-1-star nil)))
;
; -- there must be a value before the instruction, or an instruction after it.
; An instruction alone in its list is not stepped by `step/r-ctxt-instrs` at all.
; So `rest` has to be non-empty, and a first attempt without that hypothesis was
; chasing a false statement.
;
; The arithmetic the search also needs, and which ACL2 did not have, is small and
; now here: `acl2-count` of a cons is positive.  (Note, because it is easy to get
; wrong: the natural companion `(equal (equal (acl2-count x) 0) (not (consp x)))`
; is FALSE in ACL2 -- symbols count by the length of their names -- so the
; one-directional linear rule is the right thing to state.)

(defthm acl2-count-positive-when-consp
  (implies (consp x) (< 0 (acl2-count x)))
  :rule-classes :linear)

(defthm take-one-of-cons
  (equal (take 1 (cons a b)) (list a)))

; The head instruction of the flat configuration, stepped.  This is the bottom of
; every descent through this module's bodies, with the rest of the body left
; symbolic: 228,142 prover steps, and the result is the value the read produced,
; appended by the search to what came after the instruction.
;
; The value is `status` -- the module's own parameter -- rather than anything
; about the spec's record structure, because the store is the abstract one.
(defthm ctxt-instrs-steps-global-get-3
  (implies (and (consp rest) (true-listp rest))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                         (cons (list :global.get 3) rest)))
                  (list (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                              (cons (list :const (list :i32) status) rest)))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                            (cons (list :global.get 3) rest))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :global.get 3) rest))
                            (w3t::%t9 0)
                            (w3t::z (mvm-abs-z-abstract bytes sp pc clen status result))
                            (w3t::%a0 (list :|%;%| (mvm-abs-z-abstract bytes sp pc clen status result)
                                            (cons (list :global.get 3) rest))))))))

; And the same law in the form the chain needs it: the store left SYMBOLIC, with
; the one-instruction step it relies on as a hypothesis.  This is the load-bearing
; rule of the whole chain -- every position of every body is an instance of it --
; and it proves: 302,816 prover steps.
;
; The hypothesis is what makes this work with a symbolic store.  Without it, the
; search's inner `(step (:;% z (list instr)))` cannot be reduced (the answer would
; have to be phrased in the spec's record structure), which is why the version
; above pins the abstract store.  With it, the rule is parametric in the store and
; composes with `step-of-global-get-3`, whose conclusion becomes the hypothesis.
(defthm ctxt-instrs-steps-the-head
  (implies (and (consp rest)
                (true-listp rest)
                (equal (w3t::step
                        (list :|%;%| z (list (list :global.get 3))))
                       (list (list :|%;%| z
                                   (list (list :const (list :i32)
                                               (milawa-global 3 z)))))))
           (equal (w3t::step/r-ctxt-instrs
                   (list :|%;%| z (cons (list :global.get 3) rest)))
                  (list (list :|%;%| z
                              (cons (list :const (list :i32)
                                          (milawa-global 3 z))
                                    rest)))))
  :hints (("Goal"
           :use ((:instance (:definition w3t::step/r-ctxt-instrs)
                            (w3t::%a0 (list :|%;%| z (cons (list :global.get 3) rest))))
                 (:instance (:definition w3t::step/search21)
                            (w3t::%k 0) (w3t::%lo 0) (w3t::%hi 0)
                            (w3t::%t6 (cons (list :global.get 3) rest))
                            (w3t::%t9 0)
                            (w3t::z z)
                            (w3t::%a0 (list :|%;%| z (cons (list :global.get 3) rest))))))))

; NEXT.  With these rules in the theory, the flat configuration of a body steps by
; rewriting, and the chain's remaining work is the descent above it: the frame
; rule (a `:definition` instance -- see SUMMARY.md, `:expand` cannot reach it).
