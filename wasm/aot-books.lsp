;;;; aot-books.lsp -- cross-compile ACL2 book expansion files into loadable
;;;; WebAssembly modules.
;;;;
;;;; This runs in the *host* ECL (the one with the Lisp->C compiler), because
;;;; the wasm ECL cannot run the C compiler.  It is the second half of a
;;;; two-phase pipeline:
;;;;
;;;;   1. certify the book in the wasm ECL, with ACL2_SAVE_EXPANSION=1 so that
;;;;      certify-book leaves <book>@expansion.lsp behind next to the source
;;;;      (see save-expansion-file and expansion-filename in ACL2);
;;;;   2. run this script on that expansion file.  It writes <book>.fasc, the
;;;;      very file name ACL2 looks for, but as a wasm side module rather than
;;;;      a fasl of bytecode.
;;;;
;;;; Nothing in ACL2 changes: include-book loads the compiled file by name
;;;; (load-compiled -> (load ...)), and a wasm ECL built with DYLINK=1 finds
;;;; <book>.fasc, dlopen()s it, and calls __ecl_init_fas_CODE.  The certificate
;;;; is untouched, because .cert records the *source* hash (book-hash of
;;;; expansion-alist, cert-data and ev-lst), not the compiled file.
;;;;
;;;; Usage, in the host ECL with emcc on PATH:
;;;;
;;;;   ecl -norc -load wasm/aot-books.lsp \
;;;;       -eval '(aot-books "/tmp/wasm32.target" "fasc"
;;;;                         ("books/textbook/chap10/fact@expansion.lsp"))'
;;;;
;;;; The target file comes from wasm/mk-wasm32-target.lsp.

(defpackage #:aot-books
  (:use #:cl)
  (:export #:main #:aot-books #:aot-book #:module-name-for))

(in-package #:aot-books)

(require :cmp)

;;; <book>@expansion.lsp -> <book>.fasc
;;; For a book, ACL2's compiled file is <book>.<compiled-file-extension>; the
;;; extension is read from ACL2 (via books/build/features.sh) and passed in.
(defun module-name-for (expansion-file extension)
  (let* ((p (pathname expansion-file))
         (name (pathname-name p))
         (suffix "@expansion")
         (n (length suffix)))
    (unless (and (> (length name) n)
                 (string= suffix name :start2 (- (length name) n)))
      (error "~a is not a book expansion file (expected <book>@expansion.lsp)"
             expansion-file))
    (make-pathname :name (subseq name 0 (- (length name) n))
                   :type extension
                   :defaults p)))

(defun aot-book (expansion-file target &key (extension "fasc")
                                       (output-file nil)
                                       (verbose *compile-verbose*))
  "Cross-compile EXPANSION-FILE into a wasm module.  Returns the module."
  (let* ((out (or output-file
                  (module-name-for expansion-file extension)))
         (start (get-internal-real-time)))
    ;; Same binding ACL2's acl2-compile-file uses for ECL: a direct C call to a
    ;; function defined earlier in the file would bypass INCLUDE-RAW's
    ;; run-time replacement of that definition.
    (proclaim '(ext:use-direct-c-call nil))
    (unwind-protect
         (progn
           (when verbose
             (format t "~&;; AOT ~a -> ~a~%" expansion-file out))
           (compile-file expansion-file :target target :output-file out)
           (when verbose
             (format t ";;   ~a (~d bytes, ~,2f s)~%"
                     out
                     (with-open-file (s out :element-type '(unsigned-byte 8))
                       (file-length s))
                     (/ (- (get-internal-real-time) start)
                        internal-time-units-per-second)))
           out)
      (proclaim '(ext:use-direct-c-call t)))))

(defun aot-books (target extension expansion-files &key (verbose t))
  (let ((n 0)
        (failed '()))
    (dolist (f expansion-files)
      (handler-case
          (progn (aot-book f target :extension extension :verbose verbose)
                 (incf n))
        (error (e)
          (format t "~&;; AOT FAILED ~a: ~a~%" f e)
          (push f failed))))
    (format t "~&;; AOT: ~d module~:p written, ~d failed~%" n (length failed))
    (values n failed)))

(defun main (&optional (target "/tmp/wasm32.target")
               (extension "fasc")
               (expansion-files '()))
  (aot-books target extension expansion-files))
