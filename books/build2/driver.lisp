; ACL2 Build2 System - Build Driver
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Core build logic - dependency graph and certification ordering.

(in-package "BUILD2")

(include-book "scan")

;; Include raw Lisp for file I/O
; (include-raw "io-raw.lsp" :do-not-compile t)

;;; ============================================================================
;;; Stub functions (will be replaced by raw Lisp at runtime)
;;; ============================================================================

;; These stubs allow the file to certify in logic mode.
;; At runtime, the raw Lisp versions will be used.

(defstub read-file-lines-raw (filename) t)
(defstub file-write-date-raw (filename) t)
(defstub file-exists-p-raw (filename) t)

;;; ============================================================================
;;; Dependency graph building
;;; ============================================================================

;; Read a book's source and extract its dependencies
(defun get-book-deps (book-path state)
  "Get dependencies for BOOK-PATH (without extension).
   Returns (mv deps state) where deps is a book-dep-list."
  (declare (xargs :guard (stringp book-path)
                  :stobjs state
                  :mode :program))
  (let* ((lisp-file (concatenate 'string book-path ".lisp"))
         (lines (read-file-lines-raw lisp-file)))
    (mv (if lines (scan-lines-for-deps lines) nil)
        state)))

;;; ============================================================================
;;; Build ordering - simple topological sort
;;; ============================================================================

;; For now, a simple approach: given a list of books to build,
;; return them in an order that respects dependencies.
;; This is a minimal placeholder.

(defun books-needing-cert (book-paths state)
  "Filter BOOK-PATHS to those needing certification.
   A book needs cert if its .cert doesn't exist or is older than .lisp."
  (declare (xargs :guard (string-listp book-paths)
                  :stobjs state
                  :mode :program))
  (if (atom book-paths)
      (mv nil state)
    (let* ((book (car book-paths))
           (lisp-file (concatenate 'string book ".lisp"))
           (cert-file (concatenate 'string book ".cert"))
           (lisp-date (file-write-date-raw lisp-file))
           (cert-date (file-write-date-raw cert-file))
           (needs-cert (or (not cert-date)
                           (not lisp-date)
                           (< cert-date lisp-date))))
      (mv-let (rest-needs state)
        (books-needing-cert (cdr book-paths) state)
        (mv (if needs-cert
                (cons book rest-needs)
              rest-needs)
            state)))))
