; -*- Mode: Lisp -*-

; Compile the executable counterparts of all :logic mode functions ahead of
; time, for the experiment described in ECL-PORT-NOTES.md.
;
; Usage, from the ACL2 source directory:
;
;   ACL2_INIT_PROFILE_KEEP_TMP=1 ecl -norc -load ecl-tools/init-profile.lsp
;   cp /tmp/TMP@<pid>@1.lisp acl2-exec-aot.lisp
;   ecl -norc -load ecl-tools/make-exec-aot.lsp
;
; The first step is an ordinary initialization that keeps the file
; compile-uncompiled-*1*-defuns writes (TMP1.lisp, about 1,600 definitions).
; The second compiles that file with ECL's native compiler, after a full
; initialization so that every macro and special used by the generated
; definitions is known, as it is when TMP1.lisp is compiled during the
; boot-strap.
;
; The result, acl2-exec-aot.fas, is loaded by the launcher instead of
; regenerating and compiling those definitions (see *ACL2-*1*-AOT-FILE* in
; interface-raw.lisp).  It is specific to this host Lisp and this version of
; the ACL2 sources.

(in-package "CL-USER")

(setq *load-verbose* nil)

(ext:chdir (or (ext:getenv "ACL2_WASM_DIR")
               (make-pathname
                :directory (butlast (pathname-directory
                                     (truename *load-pathname*)))
                :name nil :type nil)))
(ext:set-limit 'ext:frame-stack 262144)

(load "init.lisp")
(in-package "ACL2")
(load-acl2)
(ext:install-bytecodes-compiler)

(let ((*standard-output* (make-broadcast-stream))
      (*error-output* (make-broadcast-stream))
      (*trace-output* (make-broadcast-stream)))
  (initialize-acl2 'include-book))

(ext:install-c-compiler)

(let ((t0 (get-internal-real-time)))
  (compile-file "acl2-exec-aot.lisp")
  (format t "~&compile-file: ~,2f s~%"
          (/ (float (- (get-internal-real-time) t0))
             internal-time-units-per-second)))

(ext:quit 0)
