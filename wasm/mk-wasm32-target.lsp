;;;; mk-wasm32-target.lsp -- turn the wasm ECL's own target-info into one that
;;;; produces *loadable modules*.
;;;;
;;;; Background
;;;; ----------
;;;; ECL's `compile-file' accepts `:target <file>', an alist mapping compiler
;;;; configuration symbols to values (`c::get-target-info'/`c::write-target-info'
;;;; in src/cmp/cmputil.lsp; `compile-with-target-info' in src/cmp/cmpmain.lsp
;;;; progv-binds every pair around the compilation).  A native ECL writes one
;;;; for itself while it builds its Lisp library -- and so does the wasm build
;;;; of build-ecl-wasm.sh, which runs `build/compile.lsp' inside the wasm
;;;; ecl_min under Node.  That file is the authoritative description of the
;;;; wasm target: it is where the 30-bit fixnum, the 32-bit `long' and the
;;;; emcc invocation come from.
;;;;
;;;; What it does not describe is *linking a module that can be loaded into a
;;;; running ECL*: the wasm build has no dynamic loader, so `cmp' recorded
;;;; empty `*ld-shared-flags*' and an unreachable `*ld-libs*'.  This script
;;;; fills those in with the Emscripten side-module recipe (see
;;;; wasm/dylink-poc/README.md) and makes the output extension `.wasm'.
;;;;
;;;; Usage (host ECL, which is the one with the Lisp->C compiler):
;;;;
;;;;   ecl -norc -load wasm/mk-wasm32-target.lsp -eval '(wasm-target:main)'
;;;;
;;;; Defaults: read /opt/eclwasm/ecl-node/target-info.lsp, write
;;;; /tmp/wasm32.target.  Then, in the host ECL:
;;;;
;;;;   (compile-file "book.lisp" :target "/tmp/wasm32.target")
;;;;
;;;; which emits book.c, book.o and book.wasm; the last one is a side module
;;;; whose entry point is `__ecl_init_fas_CODE', i.e. exactly what
;;;; `si::load-binary' looks for, so the wasm ECL can `(load "book.wasm")'
;;;; once it is built with -sMAIN_MODULE=2 and ENABLE_DLOPEN.

(defpackage #:wasm-target
  (:use #:cl)
  (:export #:main))

(in-package #:wasm-target)

;;; Reading the target-info constructs `c::machine'/`c::host-type' structures
;;; and printing them calls back into cmp, so the compiler has to be present.
;;; (The COMPILER package exists in a bare ECL, but its contents do not.)
(require :cmp)

;;; Flags for `emcc' when the output is a module to be dlopen'ed into the
;;; already-running ECL rather than a program of its own:
;;;   -sSIDE_MODULE=2   produce a side module, importing from the main one and
;;;                     exporting only what is asked for
;;;   -Wl,--export=__ecl_init_fas_CODE
;;;                     the one symbol that has to be visible: `si_load_binary'
;;;                     dlsym's `_ecl_library_default_entry()', which for a
;;;                     :fasl module is INIT_PREFIX "CODE" with INIT_PREFIX
;;;                     "__ecl_init_fas_" (c/ffi/libraries.d, and
;;;                     compute-init-name in cmp/cmpbackend-cxx/cmpc-init-name.lsp
;;;                     for kind :fasl).  The name is fixed, since
;;;                     init-function-name is only randomised for :object.
;;;                     (`-sEXPORTED_FUNCTIONS=___ecl_init_fas_CODE' works too,
;;;                     but needs one extra leading underscore: those names are
;;;                     the JS ones.)
;;;   -fwasm-exceptions ... -sSUPPORT_LONGJMP=wasm
;;;                     must match the main module (ECL's condition system is
;;;                     setjmp/longjmp; mismatched EH aborts at load time).
;;;   -sERROR_ON_UNDEFINED_SYMBOLS=0
;;;                     everything (cl_env_p, ecl_aref_unsafe, ...) is an
;;;                     import from the main module, by design
(defparameter *side-module-flags*
  (concatenate 'string
               "-shared -sSIDE_MODULE=2 -Wl,--export=__ecl_init_fas_CODE"
               " -fwasm-exceptions -mllvm -wasm-use-legacy-eh=false"
               " -sSUPPORT_LONGJMP=wasm -sALLOW_MEMORY_GROWTH=1"
               " -sERROR_ON_UNDEFINED_SYMBOLS=0"))

;;; A side module's object code has to be position independent: without -fPIC
;;; wasm-ld rejects the module with
;;;   relocation R_WASM_MEMORY_ADDR_LEB cannot be used against symbol `VV';
;;;   recompile with -fPIC
;;; (`VV' is the vector of constants every compiled Lisp file has.)  Note the
;;; failure is silent-ish: link without the --export flag and you get a
;;; 336-byte, symbol-less module instead of an error.
(defparameter *side-module-cc-flags* " -fPIC")

;;; Features to drop from the target's list.  :cross is an artifact of the
;;; build (compile.lsp ran with it set); the wasm ECL at run time does not have
;;; it.  Everything else (30-bit fixnum, :emscripten, :uint64-t, :unicode, ...)
;;; is genuine and must stay.
(defparameter *drop-features* '(:cross :ecl-bytecmp))

(defun set-target (alist symbol value)
  (let ((pair (assoc symbol alist)))
    (unless pair
      (error "Target info has no entry for ~s" symbol))
    (setf (cdr pair) value)))

(defun mk-target-info (base &key (side-module t))
  (let ((alist (with-open-file (s base)
                 (with-standard-io-syntax (read s)))))
    (when side-module
      (set-target alist 'c::*ld-shared-flags* *side-module-flags*)
      (set-target alist 'c::*ld-bundle-flags* *side-module-flags*)
      ;; No libraries: a side module links against the main module's exports.
      (set-target alist 'c::*ld-libs* "")
      (set-target alist 'c::*ld-flags* "")
      (set-target alist 'c::*ld-program-flags* "")
      (set-target alist 'c::*cc-flags*
                  (concatenate 'string
                               (cdr (assoc 'c::*cc-flags* alist))
                               *side-module-cc-flags*))
      (set-target alist 'c::+shared-library-extension+ "wasm")
      (set-target alist 'c::+shared-library-format+ "lib~a.wasm"))
    (set-target alist 'cl:*features*
                (set-difference (cdr (assoc 'cl:*features* alist))
                                *drop-features*))
    alist))

(defun main (&optional (base "/opt/eclwasm/ecl-node/target-info.lsp")
               (output "/tmp/wasm32.target")
               (side-module t))
  (let ((alist (mk-target-info base :side-module side-module)))
    (with-open-file (s output :direction :output :if-exists :supersede)
      (with-standard-io-syntax
        (let ((*print-circle* t))
          (format s "~S~%" alist))))
    (format t "~&wrote ~a (~d bytes)~%" output
            (with-open-file (s output) (file-length s)))
    (let* ((machine (cdr (assoc 'c::*machine* alist)))
           (types (c::machine-host-type-hash machine))
           (bits (lambda (name)
                   (let ((r (gethash name types)))
                     (and r (c::host-type-bits r))))))
      (format t "~&  target ~a, fixnum ~d bits, long ~d bits, output extension ~s~%"
              (cdr (assoc 'c::*target-identifier* alist))
              (funcall bits :fixnum) (funcall bits :long)
              (cdr (assoc 'c::+shared-library-extension+ alist))))
    (format t "~&  ld-shared-flags: ~s~%"
            (cdr (assoc 'c::*ld-shared-flags* alist)))
    output))
