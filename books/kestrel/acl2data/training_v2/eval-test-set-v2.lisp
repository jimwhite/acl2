; eval-test-set-v2.lisp — Evaluate Graph2Tocopo v2 on diverse test books.
;
; Picks books from different directories with non-trivial training data.

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

;; Register our server model
(table acl2::advice-server :graph2tocopo
       '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 Test Set Evaluation (v2) ===~%")

(eval-models-on-books
  '(
    ;; rtl books — many hinted theorems
    ("rtl/rel4/support/fadd.lisp" . :all)
    ("rtl/rel11/rel9-rtl-pkg/arithmetic/fp2.lisp" . :all)
    ("rtl/rel4/support/cat.lisp" . :all)
    ("rtl/rel4/support/encode.lisp" . :all)
    ("rtl/rel4/support/bitn-proofs.lisp" . :all)
    ("rtl/rel4/support/mod4.lisp" . :all)
    ;; textbook — simpler, should be easier
    ("textbook/chap10/insertion-sort.lisp" . :all)
    ;; kestrel
    ("kestrel/alists-light/acons-unique.lisp" . :all)
    ("kestrel/arm/encodings.lisp" . :all)
    ;; finite-set-theory
    ("finite-set-theory/total-ordering.lisp" . :all)
    ;; coi
    ("coi/super-ihs/fast.lisp" . :all)
    ("coi/super-ihs/lshu.lisp" . :all)
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
  12        ; total-book-count
  nil       ; result-alist-acc
  1         ; rand seed
  state)

(cw "~%=== Done ===~%")
