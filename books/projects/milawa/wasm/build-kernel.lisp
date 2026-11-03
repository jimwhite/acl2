;;;; Cross-compile milawa.lsp for the wasm32-unknown-emscripten target.
;;;;
;;;; This is run by wasm/build.sh with the host ECL that build.sh builds from
;;;; the same source tree; see MILAWA-WASM.md.  It reads its paths from the
;;;; environment:
;;;;
;;;;   MILAWA_WASM_BUILD        output directory (gets milawa.o)
;;;;   MILAWA_WASM_TARGET_INFO  ecl-wasm/target-info.lsp
;;;;   MILAWA_WASM_KERNEL       path to milawa.lsp
;;;;
;;;; The object is linked into the checker program by build.sh, which also
;;;; extracts the module's init function name (it contains a hash).

(in-package "CL-USER")

(require :cmp)

(defun wasm-env (name)
  (or (ext:getenv name)
      (error "~A is not set; run this through wasm/build.sh." name)))

(defparameter *build*       (wasm-env "MILAWA_WASM_BUILD"))
(defparameter *target-info* (wasm-env "MILAWA_WASM_TARGET_INFO"))
(defparameter *source*      (wasm-env "MILAWA_WASM_KERNEL"))
(defparameter *driver*      (wasm-env "MILAWA_WASM_DRIVER"))

;; compile-file does not execute (import ...) at compile time, but the reader
;; switches to the MILAWA package part way through milawa.lsp.  Create the
;; package with the same imports first, so that the symbols read during
;; compilation are the ones a source load would produce (in particular NIL and
;; T are CL symbols, not MILAWA's own).
(defpackage "MILAWA" (:use))
(import '(nil t quote if equal consp cons symbolp let let* list list* and or
          cond lambda)
        "MILAWA")

;; Make defun-comp expand to a plain DEFUN, so the target compiler compiles the
;; definitions into the object instead of deferring them to a compiler that
;; does not exist in the target image.
(pushnew :milawa-cross-compiling *features*)

(format t ";; Cross-compiling ~A using ~A~%" *source* *target-info*)

(with-compilation-unit (:target (c:read-target-info *target-info*))
  (compile-file *source*
                :system-p t
                :output-file (concatenate 'string *build* "/milawa.o"))
  ;; The C driver calls MILAWA-WASM-RUN from this file.
  (compile-file *driver*
                :system-p t
                :output-file (concatenate 'string *build* "/run.o")))

(format t ";; Wrote ~A/milawa.o and ~A/run.o~%" *build* *build*)
(si:quit)
