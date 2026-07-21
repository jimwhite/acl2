; eval-test-set.lisp — Evaluate Graph2Tocopo v2 on the test set.
;
; Tests the model on hinted theorems from books in our test split.
; Each theorem's hints are broken, the model generates a fix,
; and ACL2 tries the recommendation to see if it proves the theorem.
;
; Usage:
;   1. Start the server: python training_v2/server_v2.py ...
;   2. Run: acl2 < training_v2/eval-test-set.lisp
;
; Or: bash training_v2/scripts/eval-server.sh
;     (edit to use eval-test-set.lisp instead of eval-graph2tocopo.lisp)

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

;; Register our server model
(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 Test Set Evaluation ===~%")

;; Test on books from our test split with hinted theorems.
;; Use :all to test every hinted theorem in each book.
(eval-models-on-books
  '(("kestrel/utilities/acl2-count.lisp" . :all)
    ("kestrel/utilities/assoc-keyword.lisp" . :all)
    ("kestrel/utilities/myif.lisp" . :all))
  "/home/acl2/books"
  10        ; num-recs-per-model
  t         ; print
  nil       ; debug
  nil nil   ; step-limit, time-limit
  (help::make-model-info-alist :all (w state))
  40        ; model-query-timeout
  :goal-partial  ; breakage-plan
  0         ; done-book-count
  3         ; total-book-count
  nil       ; result-alist-acc
  1         ; rand seed
  state)

(cw "~%=== Done ===~%")
