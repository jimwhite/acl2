; test-post-light.lisp — Verify htclient::post-light can reach the k-NN server.
;
; Calls post-light from raw Lisp (:q) — the only context where it works
; standalone.  For post-light from make-event (the eval-models context),
; see test-htclient-make-event.lisp which uses the framework's
; help::post-and-parse-response-as-json.
;
; Key learnings:
;  - kwds must be doublet-listp: (list (list :connect-timeout 10) (list :read-timeout 10))
;  - NOT dotted pairs: '((:connect-timeout . 10) (:read-timeout . 10)) — guard violation!
;  - Do NOT use (set-guard-checking :none)
;
; Usage:
;   cd /home/acl2/books/kestrel/acl2data/postprocess
;   env -u http_proxy -u HTTP_PROXY acl2 < test-post-light.lisp

(in-package "ACL2")

(include-book "kestrel/htclient/post-light" :dir :system :ttags :all)
(include-book "kestrel/json-parser/parse-json" :dir :system :ttags :all)

;; post-light only works from :q (raw Lisp) when called directly.
;; For make-event calls, use help::post-and-parse-response-as-json
;; (see test-htclient-make-event.lisp).
:q
(let ((result
        (multiple-value-bind (erp response)
            (htclient::post-light "http://127.0.0.1:8765/predict"
              '(("n" . "3")
                ("use-group" . "knn")
                ("ck0" . "(EQUAL X X)"))
              *the-live-state*
              ;; kwds must be doublet-listp (proper lists, not dotted pairs):
              (list (list :connect-timeout 10) (list :read-timeout 10)))
          (if erp
              (format nil "ERROR: ~a" erp)
            response))))
  (format t "Server response (~d bytes): ~a~%"
          (length result)
          (subseq result 0 (min 300 (length result)))))
(lp)

(cw "~%=== Done ===~%")
