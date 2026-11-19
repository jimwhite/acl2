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

(in-package "ACL2")

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
