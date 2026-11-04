; ACL2 bootstrap driver for the WebAssembly (Emscripten) build of ECL.
;
; This is the wasm analogue of nsaved_acl2.lsp, which SAVE-ACL2-IN-ECL writes
; for native ECL builds.  There is no image to dump, so every start loads the
; compiled ACL2 files and re-runs INITIALIZE-ACL2.
;
; Differences from the native ECL driver:
;
;  * The native (C) compiler does not exist in this ECL: the build uses
;    --with-cmp=no.  The bytecodes compiler is the only compiler, and it must
;    stay installed for ACL2's on-the-fly COMPILE and COMPILE-FILE calls.
;  * The source directory is taken from the ACL2_WASM_DIR environment
;    variable, since a wasm module has no meaningful notion of "the directory
;    containing this script".
;  * Package locks are disabled globally in acl2.lisp for :emscripten, because
;    the package-locks module is written with C-INLINE forms.

(in-package "CL-USER")

(setq *load-verbose* nil)

(defparameter cl-user::*acl2-wasm-dir*
  (or (ext:getenv "ACL2_WASM_DIR")
      (error "ACL2_WASM_DIR is not set; it should name the ACL2 source directory.")))

(defparameter cl-user::*acl2-wasm-invocation-dir* (ext:getcwd))

(ext:chdir cl-user::*acl2-wasm-dir*)

; ECL's default frame-stack limit (2048 frames) is exhausted by DEFCONST of a
; large quoted constant and by proof-builder work.
(ext:set-limit 'ext:frame-stack 262144)

; Note that the C stack limit is left alone.  It defaults to the whole stack
; region the module was linked with (see wasm/build-ecl-wasm.sh), which is what
; we want, and it is also larger than MOST-POSITIVE-FIXNUM here, so it cannot
; be passed through EXT:SET-LIMIT on this (30-bit fixnum) build.

(load "init.lisp")
(in-package "ACL2")
(load-acl2)

; ACL2's initialization prints over a megabyte.  Redirect its standard
; character output channel and ECL's standard streams while it runs.  The
; channel indirection is ECL-specific: ACL2 writes through the stream stored
; in the ACL2-OUTPUT-CHANNEL::STANDARD-CHARACTER-OUTPUT-0 entry of
; *OPEN-OUTPUT-CHANNEL-KEY*.

(defparameter cl-user::*acl2-wasm-real-standard-co*
  (common-lisp:get 'acl2-output-channel::standard-character-output-0
                   *open-output-channel-key*))

(setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                       *open-output-channel-key*)
      (make-broadcast-stream))

(ext:install-bytecodes-compiler)

(unwind-protect
    (let ((*standard-output* (make-broadcast-stream))
          (*error-output* (make-broadcast-stream))
          (*trace-output* (make-broadcast-stream)))
      (initialize-acl2 'include-book))
  (setf (common-lisp:get 'acl2-output-channel::standard-character-output-0
                         *open-output-channel-key*)
        cl-user::*acl2-wasm-real-standard-co*))

(ext:chdir cl-user::*acl2-wasm-invocation-dir*)

(acl2-default-restart)
