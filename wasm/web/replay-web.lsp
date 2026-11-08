; World-image replay driver for the *browser* (MEMFS) build of wasm ECL.
;
; wasm/world-replay.lsp is written for Node and takes its directory from the
; environment; a page has no environment to inherit, so this wrapper sets the
; variables the way wasm/web/acl2-web.lsp does for the boot-strap driver, and
; then runs the same file the Node runs use.  Keeping one copy of the replay
; logic matters: the steps it performs are the ones a replay has to perform.
;
; The harness calls ECL_PAGE_START once and then ECL_PAGE_LOAD on this file
; (src/c/main.d).  It never calls MAIN, so there is no top level to reach and
; no SECOND entry into a shut-down ECL: forms arrive later through
; ECL_PAGE_EVAL, which runs them with CL-USER::PAGE-EVAL-STRING below.

(in-package "CL-USER")

(setq *load-verbose* nil)

; The wasm build has 30-bit fixnums, which ACL2 accepts only if
; ACL2_SMALL_FIXNUMS is set; ACL2_SNAPSHOT_INFO=NONE keeps ACL2 from running git
; for a commit hash.
(ext:setenv "ACL2_SMALL_FIXNUMS" "1")
(ext:setenv "ACL2_SNAPSHOT_INFO" "NONE")

(unless (ext:getenv "ACL2_SLOW_ALIST_ACTION")
  (ext:setenv "ACL2_SLOW_ALIST_ACTION" "off"))
(ext:setenv "ACL2_WASM_DIR" "/acl2")
(ext:setenv "ACL2_WASM_INVOCATION_DIR" "/acl2")
; No ACL2 read-eval-print loop: the page calls ECL_PAGE_EVAL for each form
; instead, and the loop would exit ECL at end of input.  See src/c/main.d.
(ext:setenv "ACL2_NO_LP" "1")
(unless (ext:getenv "ACL2_WORLD_IMAGE")
  (ext:setenv "ACL2_WORLD_IMAGE" "/acl2/world-image.ser"))

(format t "~&[replay] installing ~a~%" (ext:getenv "ACL2_WORLD_IMAGE"))
(finish-output)

(load "/acl2/wasm/world-replay.lsp")
