; eval-knn.lisp — Evaluate k-NN proof-fix model using the advice framework.
;
; Prerequisites:
;   1. k-NN server running on port 8765
;   2. eval-models book certified
;
; Run via eval-knn.sh:
;   cd /home/acl2/books/kestrel/acl2data/postprocess
;   bash eval-knn.sh

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

;; Register the k-NN server model with the advice framework.
;; Format: (table acl2::advice-server :model-name '("URL" "model-string"))
(table acl2::advice-server :knn '("http://127.0.0.1:8765/predict" "knn"))

(cw "~%=== k-NN Model Evaluation ===~%")

(eval-models-on-book
  "/home/acl2/books/kestrel/utilities/acl2-count.lisp"
  :all 10 t nil nil nil
  (help::make-model-info-alist :all (w state))
  40 :goal-partial 1 state)

(cw "~%=== Done ===~%")
