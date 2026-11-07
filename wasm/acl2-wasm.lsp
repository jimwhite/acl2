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

; This build has no package-locks module -- it is written with C-INLINE forms,
; so ECL's Emscripten configuration leaves it out -- and ACL2 copes by setting
; SI::*IGNORE-PACKAGE-LOCKS* (see the #+emscripten branch in acl2.lisp).  But
; ECL's own Lisp-level code, and modules compiled by a host ECL that does have
; locks, can still call these two functions, and the first prompt dies with
; "The function EXT:LOCK-PACKAGE is undefined".  Define them as no-ops, which is
; what the rest of the build already assumes.
(dolist (name '("LOCK-PACKAGE" "UNLOCK-PACKAGE"))
  (let ((sym (find-symbol name "EXT")))
    (when (and sym (not (fboundp sym)))
      (setf (symbol-function sym)
            (lambda (&rest args) (declare (ignore args)) nil)))))

; Let LOAD find compiled files that are wasm modules.  ECL dispatches on the
; file type through EXT::*LOAD-HOOKS* ((type . handler) ...), and the bytecodes
; compiler maps ".fasc" to SI::LOAD-BYTECODES because that is what it writes.
; A module deliberately keeps the ".fasc" name -- ACL2 asks for "<file>.fasc" --
; but is a wasm side module, so sniff the wasm magic (\0asm) and send those to
; SI::LOAD-BINARY, the dlopen path.  Bytecode files still go to the bytecodes
; loader, so a tree with a mixture of the two works.
;
; This has to happen *before* INIT.LISP, not after: ACL2.LISP loads ACL2-FNS
; on its own, and with wasm/aot-book.sh ACL2's own files are modules too (see
; WASM-PORT-NOTES.md, "Native wasm code for ACL2's own sources").
;
; These are top-level DEFUNs rather than a LABELS: this file is compiled, and a
; closure over a LABELS-local function ends up calling it as a global.
(defun acl2-wasm-module-p (file)
  (handler-case
      (with-open-file (s file :element-type '(unsigned-byte 8))
        (and (= (or (read-byte s nil -1) -1) 0)
             (= (or (read-byte s nil -1) -1) 97)      ; #\a
             (= (or (read-byte s nil -1) -1) 115)     ; #\s
             (= (or (read-byte s nil -1) -1) 109)))   ; #\m
    (error () nil)))

(defun acl2-wasm-load-fasc (file verbose print external-format)
  (if (acl2-wasm-module-p file)
      (si::load-binary file verbose print external-format)
      (si::load-bytecodes file verbose print external-format)))

(when (fboundp 'si::load-binary)
  (let ((hook (assoc "fasc" ext::*load-hooks* :test #'equal)))
    (if hook
        (setf (cdr hook) #'acl2-wasm-load-fasc)
        (push (cons "fasc" #'acl2-wasm-load-fasc) ext::*load-hooks*))))

(load "init.lisp")
(in-package "ACL2")
(load-acl2)

; Use the ahead-of-time executable counterparts when they are up to date.  The
; boot-strap then loads ACL2-EXEC-AOT.FASC -- a wasm module, built from
; ACL2-EXEC-AOT.LISP by wasm/aot-book.sh -- instead of regenerating and
; compiling the 1,622 *1* definitions of TMP1.lisp, and every *1* function
; EV-FNCALL runs afterwards is native wasm code rather than bytecode
; (WASM-PORT-NOTES.md, "Options for cutting the ~361 s startup").  The check
; for staleness is ACL2's own: ACL2-*1*-AOT-FILE compares the stamp with
; (LISP-IMPLEMENTATION-VERSION) and the sources with the compiled file.
;
; ACL2_WASM_NO_EXEC_AOT=1 turns it off, which is how the two runs in the notes
; were measured against each other.
(when (let ((s (ext:getenv "ACL2_WASM_NO_EXEC_AOT")))
        (not (and s
                  (not (equal s ""))
                  (not (equal (string-upcase s) "NIL")))))
  (setq *acl2-*1*-aot-file*
        (and (fboundp 'acl2-*1*-aot-file) (acl2-*1*-aot-file)))
  (format t "~&;; *1* ahead-of-time file: ~s~%"
          (if *acl2-*1*-aot-file* "acl2-exec-aot (used)" "none (regenerating)"))
  (force-output))

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

; Keep the expansion file that CERTIFY-BOOK writes (<book>@expansion.lsp), so
; that wasm/aot-books.lsp can cross-compile it into a wasm module afterwards.
; ACL2 does this itself from ACL2_SAVE_EXPANSION, but only on its first entry
; to the ACL2 loop, which in this driver happens in ACL2-DEFAULT-RESTART below;
; setting the global here as well makes it independent of that.

(when (let ((s (ext:getenv "ACL2_SAVE_EXPANSION")))
        (and s
             (not (equal s ""))
             (not (equal (string-upcase s) "NIL"))))
  (f-put-global 'save-expansion-file t *the-live-state*)
  (format t "~&;; ACL2_SAVE_EXPANSION: certify-book keeps <book>@expansion.lsp~%")
  (force-output))

(acl2-default-restart)
