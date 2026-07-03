; test-knn-server.lisp — Query k-NN server via sys-call+ + curl (fallback approach).
;
; SUPERSEDED by test-htclient-make-event.lisp which uses the framework's
; help::post-and-parse-response-as-json (post-light → dexador).
;
; This file remains as a reference: if dexador has issues in your SBCL
; build, sys-call+ + curl is a reliable fallback that works from make-event.
;
; Prerequisite: k-NN server running on port 8765.
; Run:
;   cd /home/acl2/books/kestrel/acl2data/postprocess
;   unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
;   acl2 < test-knn-server.lisp
; Run:
;   cd /home/acl2/books/kestrel/acl2data/postprocess
;   unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
;   acl2 < test-knn-server.lisp

(in-package "ACL2")
(defttag :knn-test)

(include-book "kestrel/helpers/eval-models" :dir :system :ttags :all)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Query the k-NN server via curl and parse JSON response
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(cw "~%=== Querying k-NN server ===~%")

(defun knn-query-fn (state)
  (declare (xargs :stobjs state :mode :program))
  (b* (((mv erp raw state)
        (sys-call+ "curl"
                   '("-s" "-X" "POST"
                     "http://127.0.0.1:8765/predict"
                     "-d" "n=3&use-group=knn&broken-theorem=(EQUAL X X)")
                   state))
       ((when erp) (mv erp nil state))
       ((mv erp parsed) (acl2::parse-string-as-json raw))
       ((when erp) (mv erp nil state)))
    (mv nil `(value-triple ',parsed) state)))

(make-event (knn-query-fn state))

(cw "~%=== Done ===~%")
