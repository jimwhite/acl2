; J2 dispatcher building blocks: the if-chain comparison and the return/block/label steps.
;
(in-package "MILAWA-WASM")
(include-book "ops-add")

(defun dcfg (z instrs) (list :|%;%| z instrs))

(defun dframe (op a b)
  (ir-frame-with-locals
   (list (list (list :const (list :i32) op))
         (list (list :const (list :i32) a))
         (list (list :const (list :i32) b)))))

(defun dz (op a b) (list :|%;%| *ir-store* (dframe op a b)))

(defthm d-local-get
  (equal (w3t::step (dcfg (dz op a b) (list (list :local.get 0))))
         (list (dcfg (dz op a b) (list (list :const (list :i32) op)))))
  :hints (("Goal"
           :in-theory (enable dcfg dz dframe ir-frame-with-locals)
           :expand ((w3t::step (dcfg (dz op a b) (list (list :local.get 0)))))
           :do-not-induct t)))

(defthm ieq-value
  (implies (unsigned-byte-p 32 v)
           (equal (w3t::$ieq_ 32 v j)
                  (if (equal v j) 1 0)))
  :hints (("Goal" :in-theory (enable w3t::$ieq_ w3t::$bool))))

(defthm d-relop-false
  (implies (and (unsigned-byte-p 32 op) (not (equal op j)))
           (equal (w3t::step
                   (dcfg (dz op a b)
                         (list (list :const (list :i32) op)
                               (list :const (list :i32) j)
                               (list :relop (list :i32) (list :eq)))))
                  (list (dcfg (dz op a b)
                              (list (list :const (list :i32) 0))))))
  :hints (("Goal"
           :in-theory (enable dcfg dz dframe ir-frame-with-locals ieq-value
                              w3t::val-p w3t::num_-p w3t::inn-p
                              w3t::in-p w3t::un-p)
           :expand ((w3t::step
                     (dcfg (dz op a b)
                           (list (list :const (list :i32) op)
                                 (list :const (list :i32) j)
                                 (list :relop (list :i32) (list :eq))))))
           :do-not-induct t)))

(defthm d-ifelse-false
  (implies (true-listp br)
           (equal (w3t::step
                   (dcfg z
                         (list (list :const (list :i32) 0)
                               (list :ifelse (quote (:_result nil)) br nil))))
                  (list (dcfg z
                              (list (list :block (quote (:_result nil))
                                          nil))))))
  :hints (("Goal"
           :in-theory (enable dcfg)
           :expand ((w3t::step
                     (dcfg z
                           (list (list :const (list :i32) 0)
                                 (list :ifelse (quote (:_result nil)) br nil)))))
           :do-not-induct t)))

(defthm d-block
  (implies (true-listp br)
           (equal (w3t::step
                   (dcfg z (list (list :block (quote (:_result nil)) br))))
                  (list (dcfg z (list (list :label_%{%}% 0 nil br))))))
  :hints (("Goal"
           :in-theory (enable dcfg)
           :expand ((w3t::step
                     (dcfg z (list (list :block (quote (:_result nil)) br)))))
           :do-not-induct t)))

(defthm d-label-nil
  (equal (w3t::step (dcfg z (list (list :label_%{%}% 0 nil nil))))
         (list (dcfg z nil)))
  :hints (("Goal"
           :in-theory (enable dcfg)
           :expand ((w3t::step (dcfg z (list (list :label_%{%}% 0 nil nil)))))
           :do-not-induct t)))

(defun cmp (j br)
  (list (list :local.get 0)
        (list :const (list :i32) j)
        (list :relop (list :i32) (list :eq))
        (list :ifelse (quote (:_result nil)) br nil)))

