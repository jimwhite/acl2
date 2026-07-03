; test-htclient-make-event.lisp — Query k-NN server via post-light from make-event.
;
; Uses the exact same includes and calling pattern as eval-models-on-book.
;
; Key learnings for calling post-light from make-event:
;  1. kwds must be doublet-listp — proper lists, NOT dotted pairs.
;     Broken:  '((:connect-timeout . 5) (:read-timeout . 5))
;     Working: `((:connect-timeout ,n) (:read-timeout ,n))
;     Working: (list (list :connect-timeout 5) (list :read-timeout 5))
;  2. Do NOT use (set-guard-checking :none) — it breaks include-raw dispatch.
;  3. Use the framework's own help::post-and-parse-response-as-json — it
;     handles kwds correctly via backtick.
;  4. The calling function must be :mode :program and use b* for state.
;  5. Return (mv nil `(value-triple ',parsed-json) state) — note the quote
;     before the parsed JSON to prevent ACL2 from evaluating it.
;
; Prerequisite: k-NN server on port 8765.
; Run:
;   cd /home/acl2/books/kestrel/acl2data/postprocess
;   unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
;   acl2 < test-htclient-make-event.lisp

(in-package "ACL2")

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

(defun test-knn-call (state)
  (declare (xargs :stobjs state :mode :program))
  (b* (((mv erp response state)
        (help::post-and-parse-response-as-json
         "http://127.0.0.1:8765/predict"
         10
         '(("n" . "3") ("use-group" . "knn") ("ck0" . "(EQUAL X X)"))
         nil
         state))
       ((when erp) (mv erp nil state)))
    (mv nil `(value-triple ',response) state)))

(make-event (test-knn-call state))

