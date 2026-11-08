; World-image replay driver for the *browser* (MEMFS) build of wasm ECL.
;
; wasm/world-replay.lsp is written for Node and takes its directory from the
; environment; a page has no environment to inherit, so this wrapper sets the
; variables the way wasm/web/acl2-web.lsp does for the boot-strap driver, and
; then runs the same file the Node runs use.  Keeping one copy of the replay
; logic matters: the steps it performs are the ones a replay has to perform.
;
; The harness calls:  callMain(['--load', '/acl2/web-replay.lsp', '--'])

(in-package "CL-USER")

(setq *load-verbose* nil)

; ECL caches its command line, so every CALLMAIN re-loads *this* file with the
; arguments of the first call -- a different --load on a later call is ignored.
; That is why the driver has to be idempotent: the second and later calls are
; the harness asking the already-installed session for its prompt again, with
; the next form waiting on stdin.  See the note in world-replay.lsp where the
; flag is set.
(when (and (boundp 'cl-user::*replay-installed*)
           cl-user::*replay-installed*)
  ; FIND-SYMBOL, not ACL2::LP: the ACL2 package does not exist yet when this
  ; file is first READ, and the reader would fail on the package prefix.
  (funcall (find-symbol "LP" "ACL2"))
  (ext:exit 0))

; The wasm build has 30-bit fixnums, which ACL2 accepts only if
; ACL2_SMALL_FIXNUMS is set; ACL2_SNAPSHOT_INFO=NONE keeps ACL2 from running git
; for a commit hash.
(ext:setenv "ACL2_SMALL_FIXNUMS" "1")
(ext:setenv "ACL2_SNAPSHOT_INFO" "NONE")

(ext:setenv "ACL2_WASM_DIR" "/acl2")
(ext:setenv "ACL2_WASM_INVOCATION_DIR" "/acl2")
(unless (ext:getenv "ACL2_WORLD_IMAGE")
  (ext:setenv "ACL2_WORLD_IMAGE" "/acl2/world-image.ser"))

(format t "~&[replay] installing ~a~%" (ext:getenv "ACL2_WORLD_IMAGE"))
(finish-output)

(load "/acl2/wasm/world-replay.lsp")
