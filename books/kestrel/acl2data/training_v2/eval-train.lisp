; eval-train.lisp — Evaluate on training-set books where model gets exact matches.

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 — Training Set Eval ===~%")

(eval-models-on-books
  '(
    ("acl2s/defdata/records.lisp" . :all)               ;; 160 correct
    ("acl2s/defdata/library-support.lisp" . :all)        ;; 141 correct
    ("acl2s/cgen/basis.lisp" . :all)                     ;;  56 correct
    ("acl2s/defdata/defdata-util.lisp" . :all)           ;;  16 correct
    ("acl2s/defdata/num-list-fns.lisp" . :all)           ;;  13 correct
    ("acl2s/defdata/random-state-basis1.lisp" . :all)    ;;  13 correct
    ("acl2s/cgen/utilities.lisp" . :all)                 ;;   8 correct
    ("acl2s/cons-size.lisp" . :all)                      ;;   8 correct
    ("acl2s/cgen/build-enumcalls.lisp" . :all)           ;;   6 correct
    ("acl2s/defdata/mv-proof.lisp" . :all)               ;;   6 correct
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
