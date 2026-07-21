; eval-graph2tocopo.lisp — Evaluate Graph2Tocopo v2 model using the advice framework.
;
; Registers our server_v2.py as an advice server model, then runs
; eval-models-on-book or eval-models-on-tests to measure Top-1 accuracy.
;
; Usage:
;   1. Start the server:
;        python training_v2/server_v2.py \
;            --model ./models_v7/best_model.pt \
;            --vocab /path/to/preprocessed_v4/vocab.json \
;            --port 8765
;   2. Run this script:
;        cd /home/acl2/books/kestrel/acl2data
;        acl2 < training_v2/eval-graph2tocopo.lisp
;
; Or via shell wrapper: training_v2/scripts/eval-server.sh

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

;; Register our server as a model.
;; The framework will POST checkpoints to http://127.0.0.1:8765/
;; and expects JSON back: [{"type":"use-lemma","object":"CDR-CONS","confidence":0.5,"book_map":{}}]
(table acl2::advice-server :graph2tocopo '("http://127.0.0.1:8765/" "graph2tocopo"))

(cw "~%=== Graph2Tocopo v2 Model Evaluation ===~%")

;; Quick test on a single easy book:
(eval-models-on-book
  "/home/acl2/books/kestrel/utilities/acl2-count.lisp"
  :all 10 t nil nil nil
  (help::make-model-info-alist :all (w state))
  40 :goal-partial 1 state)

(cw "~%=== Done ===~%")
