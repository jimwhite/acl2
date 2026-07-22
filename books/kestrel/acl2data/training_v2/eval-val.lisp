; eval-val.lisp — Evaluate on validation-set books.
; These are books NOT seen during training.

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 — Validation Set Eval ===~%")

(eval-models-on-books
  '(
    ;; arithmetic-2/meta — small, self-contained
    ("arithmetic-2/meta/integerp.lisp" . :all)
    ("arithmetic-2/meta/expt.lisp" . :all)
    ("arithmetic-2/meta/numerator-and-denominator.lisp" . :all)
    ;; centaur/nrev — small list utilities
    ("centaur/nrev/fast.lisp" . :all)
    ;; kestrel/arithmetic-light — small arithmetic lemmas
    ("kestrel/arithmetic-light/ash.lisp" . :all)
    ("kestrel/arithmetic-light/ceiling.lisp" . :all)
    ;; kestrel/evaluators — evaluator tests
    ("kestrel/evaluators/if-eval.lisp" . :all)
    ;; kestrel/htclient — HTTP client tests
    ("kestrel/htclient/post-light.lisp" . :all)
    ;; centaur/fty — fine-grained typedefs
    ("centaur/fty/baselists.lisp" . :all)
    ("centaur/fty/deftypes.lisp" . :all)
    )
  "/home/acl2/books"
  10        ; num-recs-per-model
  t         ; print
  nil       ; debug
  nil nil   ; step-limit, time-limit
  (help::make-model-info-alist :all (w state))
  40        ; model-query-timeout
  :goal-partial  ; breakage-plan
  0         ; done-book-count
  10        ; total-book-count
  nil       ; result-alist-acc
  1         ; rand seed
  state)

(cw "~%=== Done ===~%")
