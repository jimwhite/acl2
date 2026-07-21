; eval-graph2tocopo.lisp — Evaluate Graph2Tocopo v2 model using the advice framework.
;
; Run via: bash training_v2/scripts/eval-server.sh

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(table acl2::advice-server :graph2tocopo '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 Model Evaluation ===~%")

(eval-models-on-tests
  '(
    ("kestrel/utilities/acl2-count.lisp" . <=-of-acl2-count-of-nthcdr)
    ("kestrel/utilities/acl2-count.lisp" . <=-of-acl2-count-of-nthcdr-linear)
    )
  "/home/acl2/books"
  :models :all
  :num-tests 2
  :num-recs-per-model 10
  :print t)

(cw "~%=== Done ===~%")
