; eval-builtin.lisp — Evaluate built-in proof-fix models.
;
; Tests the eval-models framework with built-in (:function) models
; on acl2-count.lisp (8 breakable defthms with :hints).
;
; Run:  acl2 < eval-builtin.lisp
;
; To also test the k-NN server model, first verify connectivity:
;   acl2 < test-post-light.lisp
; Then see eval-knn.lisp (currently blocked by include-raw dispatch
; issue in make-event contexts).

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(cw "~%=== Built-in Model Evaluation ===~%")

(eval-models-on-book
  "/home/acl2/books/kestrel/utilities/acl2-count.lisp"
  :all 10 t nil nil nil
  (help::make-model-info-alist :all (w state))
  40 :goal-partial 1 state)

(cw "~%=== Done ===~%")
