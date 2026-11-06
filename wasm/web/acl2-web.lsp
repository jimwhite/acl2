; ACL2 bootstrap driver for the *browser* (MEMFS) build of wasm ECL.
;
; Same shape as wasm/acl2-wasm.lsp, with two differences: the ACL2 tree is
; preloaded at /acl2 (there is no working directory to inherit), and progress
; markers are printed so the page can show what is happening during the
; multi-minute boot-strap.
;
; The harness calls:  callMain(['--load', '/acl2/web-acl2.lsp', '--'])

(in-package "CL-USER")

(setq *load-verbose* nil)

; The wasm build has 30-bit fixnums, which ACL2 accepts only if
; ACL2_SMALL_FIXNUMS is set; wasm/acl2-wasm exports it for Node, but a page has
; no environment to inherit, so set it here.  ACL2_SNAPSHOT_INFO=NONE likewise
; avoids ACL2 trying to run git for a commit hash.
(ext:setenv "ACL2_SMALL_FIXNUMS" "1")
(ext:setenv "ACL2_SNAPSHOT_INFO" "NONE")

(defparameter cl-user::*acl2-web-dir* "/acl2")

(format t "~&[acl2] chdir ~a~%" cl-user::*acl2-web-dir*)
(finish-output)

(ext:chdir cl-user::*acl2-web-dir*)

; ECL's default frame-stack limit (2048 frames) is exhausted by DEFCONST of a
; large quoted constant and by proof-builder work.
(ext:set-limit 'ext:frame-stack 262144)

(format t "~&[acl2] loading init.lisp and the compiled sources~%")
(finish-output)

(load "init.lisp")
(in-package "ACL2")
(load-acl2)

(format t "~&[acl2] compiled sources loaded; suppressing boot-strap output~%")
(finish-output)

; ACL2's initialization prints over a megabyte.  Redirect its standard
; character output channel and ECL's standard streams while it runs.
(defparameter cl-user::*acl2-web-real-standard-co*
  (common-lisp:get 'acl2-output-channel::standard-character-output-0
                   *open-output-channel-key*))

(setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                       *open-output-channel-key*)
      (make-broadcast-stream))

(ext:install-bytecodes-compiler)

(format t "~&[acl2] initializing (this is the long part)~%")
(finish-output)

(unwind-protect
    (let ((*standard-output* (make-broadcast-stream))
          (*error-output* (make-broadcast-stream))
          (*trace-output* (make-broadcast-stream)))
      (initialize-acl2 'include-book))
  (setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                         *open-output-channel-key*)
        cl-user::*acl2-web-real-standard-co*))

(format t "~&[acl2] initialization done; entering the loop~%")
(finish-output)

; Reads the demo script from stdin (the harness supplies it as a string).
(acl2-default-restart)
