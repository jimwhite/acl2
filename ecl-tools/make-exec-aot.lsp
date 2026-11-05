; -*- Mode: Lisp -*-

; Build acl2-exec-aot.fas: the executable counterparts (the *1* functions) of
; all :logic mode functions, compiled ahead of time with ECL's native compiler,
; so that initialization can load them instead of regenerating and compiling
; them.  See ECL-PORT-NOTES.md and ACL2-*1*-AOT-FILE in interface-raw.lisp.
;
; Usage, from the ACL2 source directory, after `make compile`:
;
;   /opt/ecl-26.5.5/bin/ecl -norc -load ecl-tools/make-exec-aot.lsp
;
; It runs a full initialize-acl2 (about 6 s), keeps the file that
; compile-uncompiled-*1*-defuns writes (TMP1.lisp, about 1,600 definitions),
; renames it to acl2-exec-aot.lisp, compiles that with the C compiler (about
; 30 s), and writes acl2-exec-aot.stamp, which records the host Lisp so that
; the launcher can refuse a file built elsewhere.  The result is specific to
; this host Lisp and this version of the ACL2 sources; the launcher also
; refuses it if any source is newer.

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

; Remember the file name that COMPILE-UNCOMPILED-*1*-DEFUNS is given, so that
; we can find the definitions it writes, and keep that file: the boot-strap
; resets the state globals, so KEEP-TMP-FILES cannot simply be set beforehand.

(defvar cl-user::*exec-aot-source-file* nil)

(let ((orig (symbol-function 'compile-uncompiled-*1*-defuns)))
  (setf (symbol-function 'compile-uncompiled-*1*-defuns)
        (lambda (&rest args)
          (setq cl-user::*exec-aot-source-file* (car args))
          (f-put-global 'keep-tmp-files t *the-live-state*)
          (apply orig args))))

(let ((*standard-output* (make-broadcast-stream))
      (*error-output* (make-broadcast-stream))
      (*trace-output* (make-broadcast-stream)))
  (initialize-acl2 'include-book))

(unless (and cl-user::*exec-aot-source-file*
             (probe-file (concatenate 'string
                                      cl-user::*exec-aot-source-file*
                                      ".lisp")))
  (error "Did not find the file of executable counterparts."))

(with-open-file (in (concatenate 'string cl-user::*exec-aot-source-file* ".lisp")
                    :direction :input)
  (with-open-file (out "acl2-exec-aot.lisp"
                       :direction :output
                       :if-exists :supersede)
    (loop for line = (read-line in nil nil)
          while line
          do (write-line line out))))

(with-open-file (str "acl2-exec-aot.stamp"
                     :direction :output
                     :if-exists :supersede)
  (let ((*print-pretty* nil))
    (prin1 (lisp-implementation-version) str))
  (terpri str))

(ext:install-c-compiler)

(let ((t0 (get-internal-real-time)))
  (compile-file "acl2-exec-aot.lisp")
  (format t "~&compile-file: ~,2f s~%"
          (/ (float (- (get-internal-real-time) t0))
             internal-time-units-per-second)))

(unless (probe-file "acl2-exec-aot.fas")
  (error "Compilation of acl2-exec-aot.lisp failed."))

(format t "~&Wrote acl2-exec-aot.fas and acl2-exec-aot.stamp (~a).~%"
        (lisp-implementation-version))

(ext:quit 0)
