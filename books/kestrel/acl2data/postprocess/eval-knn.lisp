; eval-knn.lisp — Evaluate k-NN proof-fix model using the advice framework.
;
; Working pattern for calling server models from eval-models-on-book:
;   1. Register server: (table acl2::advice-server :name '("URL" "model-str"))
;      URL must include full path (e.g., http://host:port/predict).
;   2. Include kestrel/helpers/eval-models (pulls in post-light + json-parser).
;   3. Call eval-models-on-book with :all models — framework queries all
;      built-in models then server models automatically.
;   4. Server must respond with JSON objects: {type, object, confidence, book_map}
;      See *rec-to-symbol-alist* in kestrel/helpers/recommendations.lisp for
;      valid type strings (e.g., "use-lemma", "add-enable-hint").
;   5. Server MUST send Content-Length + Connection: close headers, or dexador
;      will timeout on second and subsequent requests.
;   6. Unset http_proxy/HTTP_PROXY before running (see eval-knn.sh).
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
