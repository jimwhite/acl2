; L1, layer 4: the context rules, where the proof reasons about nesting.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; A function body does not execute at the top of a configuration: it executes
; inside a :LABEL_ or :FRAME_ admin.  So even a single instruction needs a step
; that goes INTO that nesting and comes back out:
;
;   step (label n body)  =  re-wrap (step body)
;
; That is one of the four "context" rules of the semantics (ctxt-instrs,
; ctxt-label, ctxt-frame, ctxt-handler), and this book is the first one of them.
;
; WHY THIS LAYER IS DIFFERENT.  Layers 1-3 were about what an instruction means.
; This layer is about WHICH RULE FIRES, and that turns out to be the hard part,
; because STEP is a long chain of
;
;   (let ((r (STEP/R-X c))) (if r r (next)))
;
; and on a symbolic configuration ACL2 cannot decide any STEP/R-X, so it splits on
; each in turn instead of walking the chain.  Two measurements fixed on that:
;
;   * `enable` does not help.  These rule functions carry
;     (xargs :ruler-extenders :all) and a measure over WRT::%SIZE, so the rewriter
;     will not open them unless the measure provably decreases; enabling
;     STEP/R-CTXT-INSTRS, STEP/PREFIX7 and STEP/SEARCH21 changed the prover step
;     count not at all (215 before, 215 after).
;
;   * `:expand` does.  One forced unfolding per level, with the concrete guards
;     reducing as they go, and the level beneath it expanded by a :free pattern.
;
; The first lemma below is the *negative* fact that has to be established before
; any positive one: on a configuration whose only element is a label, the
; ctxt-instrs rule does not apply -- it would try to step the label itself, at the
; same %SIZE, which its own guard forbids.  With that as a rewrite rule the chain
; above it can be walked.
;
; HOW THE CHAIN IS WALKED.  STEP's rules are tried in order; for our shapes every
; rule before ctxt-label fails.  Rather than prove thirty negations, the two
; lemmas here show the pattern and the shape that works: state the negative fact
; for the rule that would otherwise fire, then expand STEP once and let the
; rewrite rule kill that branch.

(in-package "MILAWA-WASM")

(include-book "frames")
(include-book "size")

;; ---------------------------------------------------------------------------
;; Which rule fires: the negative fact
;; ---------------------------------------------------------------------------

; On a configuration whose instructions are a single label, ctxt-instrs must not
; apply: it steps "inside the instruction sequence" by taking a contiguous run and
; requiring the run to be strictly smaller, and the only run available is the
; whole list.
(defthm no-ctxt-instrs-on-a-lone-label
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :label_%{%}% 1 nil (list (list :local.get 0))))))
         nil)
  :hints (("Goal" :expand ((w3t::step/r-ctxt-instrs
                            (list :|%;%| z
                                  (list (list :label_%{%}% 1 nil
                                              (list (list :local.get 0))))))
                           (:free (k lo hi i t9 zz a0)
                                  (w3t::step/search21 k lo hi i t9 zz a0))))))

;; ---------------------------------------------------------------------------
;; The context lemma: a step inside a label is a step of the whole configuration
;; ---------------------------------------------------------------------------

; The body is one local.get, whose value is whatever local 0 holds; the answer is
; the same configuration with the label's body replaced by the pushed value.
;
; This is the composition law the whole instruction library rests on: it is what
; lets a chain of single-instruction lemmas be lifted out of the nesting, and it
; is stated for the nesting depth one.  The other three context rules have the
; same shape, and ctxt-frame will be the one that matters for a call.
(defthm step-in-label-local-get
  (equal (w3t::step
          (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                (list (list :label_%{%}% 1 nil (list (list :local.get 0))))))
         (list (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                     (list (list :label_%{%}% 1 nil (list l0))))))
  :hints (("Goal" :expand ((w3t::step
                            (list :|%;%| (mvm-abs-z-locals bytes (mvm-locals l0 l1 l2 l3))
                                  (list (list :label_%{%}% 1 nil
                                              (list (list :local.get 0))))))))))

;; ---------------------------------------------------------------------------
;; The frame context rule: a step inside a :FRAME_ admin
;; ---------------------------------------------------------------------------

; A call is entered by pushing a :FRAME_ admin whose frame holds the callee's
; locals, and the body then runs inside it.  So this is the nesting a call needs,
; and it is deeper than the label case: (frame n F (label k nil body)).
;
; The rule is worth reading closely, because its bookkeeping is not symmetric:
;
;   * the INNER configuration it steps is (:;% (:;% S F') instr*) -- the store S
;     together with F-prime, the frame carried by the admin, because that is the
;     frame whose locals the body reads;
;   * the RESULT carries the OUTER frame: (:;% (:;% S' F) ((:FRAME_ n F'' instr'*))).
;
; So the store updates flow outward while the frame flows inward, and a lemma
; that gets that the wrong way round is false rather than unprovable -- which is
; exactly the sort of thing that is cheaper to state and let ACL2 refute than to
; reason about.

; The negative fact again, now general in BODY: whichever body hangs under the
; frame, the only run ctxt-instrs could take is the whole instruction list.
(defthm no-ctxt-instrs-on-a-lone-frame
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :frame_%{%}% n f body))))
         nil)
  :hints (("Goal" :expand ((w3t::step/r-ctxt-instrs
                            (list :|%;%| z (list (list :frame_%{%}% n f body))))
                           (:free (k lo hi i t9 zz a0)
                                  (w3t::step/search21 k lo hi i t9 zz a0))))))

; And the same for the label, generalised the same way, for the same reason: the
; two context lemmas below both need it.
(defthm no-ctxt-instrs-on-a-lone-label-general
  (equal (w3t::step/r-ctxt-instrs
          (list :|%;%| z (list (list :label_%{%}% n is0 body))))
         nil)
  :hints (("Goal" :expand ((w3t::step/r-ctxt-instrs
                            (list :|%;%| z (list (list :label_%{%}% n is0 body))))
                           (:free (k lo hi i t9 zz a0)
                                  (w3t::step/search21 k lo hi i t9 zz a0))))))

; The frame context lemma: one step inside the frame is one step of the body
; inside its label, re-wrapped.  The store is carried through unchanged by
; local.get, so the outer Z comes back as it went in -- which is why this
; statement is checkable by eye.
(defthm step-in-frame-local-get
  (equal (w3t::step
          (list :|%;%| (list :|%;%| store outer-frame)
                (list (list :frame_%{%}% 1
                            (frame-with-locals (mvm-locals l0 l1 l2 l3))
                            (list (list :label_%{%}% 1 nil
                                        (list (list :local.get 0))))))))
         (list (list :|%;%| (list :|%;%| store outer-frame)
                     (list (list :frame_%{%}% 1
                                 (frame-with-locals (mvm-locals l0 l1 l2 l3))
                                 (list (list :label_%{%}% 1 nil
                                             (list l0))))))))
  :hints (("Goal" :expand ((w3t::step
                            (list :|%;%| (list :|%;%| store outer-frame)
                                  (list (list :frame_%{%}% 1
                                              (frame-with-locals (mvm-locals l0 l1 l2 l3))
                                              (list (list :label_%{%}% 1 nil
                                                          (list (list :local.get 0))))))))))))

;; ---------------------------------------------------------------------------
;; Layer 6, measured: what entering a call produces
;; ---------------------------------------------------------------------------
;
; The call rule (Step/call_ref-func) is the next floor, and its output shape is
; the one thing worth fixing before writing the lemma.  Measured, by stepping the
; entry configuration of the artifact and printing the shape rather than the
; values:
;
;   (step (INVOKE store 6 nil))
;     = ((:FRAME_ 1 F ((:LABEL_ 1 is0 BODY))))
;
; with, in words:
;
;   * the store UNCHANGED -- a call is not a side effect on the store, it is a
;     change of which frame is current;
;   * the OUTER frame unchanged, and it has no locals, which is why the module's
;     body cannot touch the host's frame;
;   * F, the callee's frame, with exactly FOUR locals -- the four the module's
;     step declares ($op $imm $a $b) and no parameters;
;   * BODY, the callee's code, taken from the store's :CODE field, so it is a
;     CONSTANT of the artifact and every instruction lemma above applies to it;
;   * the label's arity marker 1 and the frame's 1, both from the function's
;     result type (step returns one i32).
;
; So the call lemma's statement is "the entry configuration steps to a
; frame-and-label admin around the artifact's own code", and everything above
; this book already says what happens inside that admin.  What remains is to
; write the right-hand side out, which means writing the callee's four locals and
; its body as terms rather than as literals -- the body alone is two hundred
; lines, and a lemma that quotes it would be unreadable and would have to be
; regenerated whenever the module changed.  The helpers are the obstacle:

(defun milawa-func-code (i)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%get-field (nth i (w3t::%get-field *milawa-verified-store* :funcs)) :code))

(defun milawa-func-module (i)
  (declare (xargs :guard t :verify-guards nil))
  (w3t::%get-field (nth i (w3t::%get-field *milawa-verified-store* :funcs)) :module))

(defun milawa-func-body (i)
  (declare (xargs :guard t :verify-guards nil))
  (cadddr (milawa-func-code i)))
