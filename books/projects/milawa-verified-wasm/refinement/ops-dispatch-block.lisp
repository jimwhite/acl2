; The (:_result nil) block type and its redex arity, for the dispatcher block step.
;
(in-package "MILAWA-WASM")
(include-book "ops-ifz-label")

(defthm blocktype-result-nil
  (equal (w3t::$blocktype_ z (quote (:_result nil)))
         '(:%->_%% nil nil nil))
  :hints (("Goal" :in-theory (enable w3t::$blocktype_))))

(defthm redex-arity-block-nil
  (equal (we::redex-arity (list :block (quote (:_result nil)) b) z vals)
         0)
  :hints (("Goal"
           :in-theory (enable we::redex-arity blocktype-result-nil))))
