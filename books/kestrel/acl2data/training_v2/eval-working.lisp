; eval-working.lisp — Test books where model's Top-1 prediction matches ground truth.

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 — Testing Known-Correct Predictions ===~%")

(eval-models-on-books
  '(
    ("centaur/vl2014/expr.lisp" . :all)               ;; 396 correct
    ("centaur/esim/tutorial/intro.lisp" . :all)        ;; 194 correct
    ("centaur/lispfloat/ops-logic.lisp" . :all)        ;;  56 correct
    ("centaur/sv/cosims/cosims.lisp" . :all)           ;;  36 correct
    ("centaur/esim/tutorial/booth-support.lisp" . :all) ;;  21 correct
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
  5         ; total-book-count
  nil       ; result-alist-acc
  1         ; rand seed
  state)

(cw "~%=== Done ===~%")
