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

; This build has no package-locks module; acl2.lisp's #+emscripten branch
; assumes locks are a no-op, but ECL's own Lisp code still calls these at the
; first prompt.  See wasm/acl2-wasm.lsp.
(dolist (name '("LOCK-PACKAGE" "UNLOCK-PACKAGE"))
  (let ((sym (find-symbol name "EXT")))
    (when (and sym (not (fboundp sym)))
      (setf (symbol-function sym)
            (lambda (&rest args) (declare (ignore args)) nil)))))

; Let LOAD find compiled files that are wasm modules.  ECL maps ".fasc" to the
; bytecodes loader, so sniff the wasm magic and send modules to SI::LOAD-BINARY
; (the dlopen path, which needs the DYLINK=1 build).  Must be installed before
; INIT.LISP, because ACL2.LISP loads ACL2-FNS itself.  See wasm/acl2-wasm.lsp.
(defun acl2-web-module-p (file)
  (handler-case
      (with-open-file (s file :element-type '(unsigned-byte 8))
        (and (= (or (read-byte s nil -1) -1) 0)
             (= (or (read-byte s nil -1) -1) 97)      ; #\a
             (= (or (read-byte s nil -1) -1) 115)     ; #\s
             (= (or (read-byte s nil -1) -1) 109)))   ; #\m
    (error () nil)))

(defun acl2-web-load-fasc (file verbose print external-format)
  (if (acl2-web-module-p file)
      (si::load-binary file verbose print external-format)
      (si::load-bytecodes file verbose print external-format)))

(when (fboundp 'si::load-binary)
  (let ((hook (assoc "fasc" ext::*load-hooks* :test #'equal)))
    (if hook
        (setf (cdr hook) #'acl2-web-load-fasc)
        (push (cons "fasc" #'acl2-web-load-fasc) ext::*load-hooks*))))

(format t "~&[acl2] loading init.lisp and the compiled sources~%")
(finish-output)

(load "init.lisp")
(in-package "ACL2")
(load-acl2)

; The bundle ships ACL2-EXEC-AOT.FASC, a module holding the executable
; counterparts, built from the same sources (wasm/aot-book.sh).  ACL2's own
; staleness check compares file dates, which mean nothing in a filesystem the
; page just filled, so take the file as shipped and let the bundle manifest be
; the thing that guarantees the pairing.
(when (and (probe-file "acl2-exec-aot.fasc")
           (fboundp 'acl2-*1*-aot-file))
  (setq *acl2-*1*-aot-file* "acl2-exec-aot")
  (format t "~&[acl2] using the shipped *1* module~%")
  (finish-output))

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
