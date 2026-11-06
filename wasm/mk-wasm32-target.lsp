;;;; mk-wasm32-target.lsp -- write the wasm32 cross-compilation target-info.
;;;;
;;;; Usage (host ECL, after `make install' of the wasm target):
;;;;
;;;;   ecl -norc -load wasm/mk-wasm32-target.lsp -eval '(wasm-target:main)'
;;;;
;;;; Defaults: read $WORK/ecl-node/target-info.lsp, write /tmp/wasm32.target
;;;; (the target-info file) and /tmp/wasm32.delta (the wasm-specific values as
;;;; a readable plist, for wasm/aot-acl2.lsp).  Then, in this ECL or any other
;;;; one that can read that file:
;;;;
;;;;   (compile-file "book.lisp" :target "/tmp/wasm32.target")
;;;;
;;;; which emits book.c, book.o and book.fas, the last a wasm side module whose
;;;; entry point is `__ecl_init_fas_CODE' -- i.e. exactly what
;;;; `si::load-binary' looks for, so a wasm ECL built with DYLINK=1 can
;;;; `(load "book.fas")'.
;;;;
;;;; Where the base target-info comes from: ECL's `compile-file' takes
;;;; `:target <target-info>', an alist written by `c::write-target-info' that
;;;; `compile-with-target-info' progv-binds around the compilation.  A native
;;;; ECL writes one for itself while it builds its Lisp library -- and so does
;;;; the wasm build, because `build/compile.lsp' runs inside the wasm ecl_min
;;;; under Node.  That file is the authoritative description of the target: it
;;;; is where the 30-bit fixnum, the 32-bit `long', emcc and the wasm feature
;;;; list come from.  All this script adds is what a *loadable module* needs
;;;; (see wasm/wasm32-target.lsp) and the removal of the build-only :cross.
;;;;
;;;; The one thing the wasm build cannot describe is a module that can be
;;;; loaded into a running ECL, because it has no dynamic loader of its own:
;;;; `cmp' recorded empty `*ld-shared-flags*' and unreachable `*ld-libs*'.
;;;; Those, and -fPIC, are ours.

(load (merge-pathnames "wasm32-target.lsp"
                       (or *load-pathname*
                           #p"/workspaces/acl2-ecl/wasm/mk-wasm32-target.lsp")))

(in-package #:wasm-target)

(defun main (&optional (base "/opt/eclwasm/ecl-node/target-info.lsp")
               (output "/tmp/wasm32.target")
               (delta-file "/tmp/wasm32.delta")
               (include-dir "/opt/eclwasm/ecl-node/")
               (emsdk "/opt/emsdk")
               (side-module t))
  (require :cmp)
  ;; Reading the base needs cmp: the machine and host-type structures have to
  ;; exist, and printing them calls back into it.
  (let* ((alist (with-open-file (s base)
                  (with-standard-io-syntax (read s))))
         (features (cdr (assoc 'cl:*features* alist)))
         (delta (delta features include-dir emsdk :side-module side-module)))
    (apply-overrides alist delta)
    (with-open-file (s output :direction :output :if-exists :supersede)
      (with-standard-io-syntax
        (let ((*print-circle* t))
          (format s "(~%")
          (dolist (pair alist)
            (format s " (~S . ~a)~%"
                    (car pair)
                    (if (eq (car pair) 'c::*machine*)
                        (machine-form)
                        (prin1-to-string (cdr pair)))))
          (format s ")~%"))))
    (write-delta delta delta-file)
    (format t "~&wrote ~a (~d bytes) and ~a~%"
            output (with-open-file (s output) (file-length s)) delta-file)
    (format t "~&  target ~a, fixnum ~d bits, long ~d bits, extension ~s~%"
            (cdr (assoc 'c::*target-identifier* alist))
            (c::host-type-bits (gethash
                                :fixnum
                                (c::machine-host-type-hash
                                 (cdr (assoc 'c::*machine* alist)))))
            (c::host-type-bits (gethash
                                :long
                                (c::machine-host-type-hash
                                 (cdr (assoc 'c::*machine* alist)))))
            (getf delta :shared-extension))
    (format t "~&  ld-shared-flags: ~s~%" (getf delta :ld-shared-flags))
    output))
