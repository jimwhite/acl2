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
;;; Path utilities (pure logic, testable)
;;; ============================================================================

(defun has-extension (path ext)
  "Check if PATH ends with extension EXT (including the dot)."
  (declare (xargs :guard (and (stringp path) (stringp ext))))
  (let ((path-len (length path))
        (ext-len (length ext)))
    (and (>= path-len ext-len)
         (string-equal (subseq path (- path-len ext-len) path-len) ext))))

(defun strip-extension (path)
  "Remove .lisp or .cert extension from PATH if present."
  (declare (xargs :guard (stringp path)))
  (let ((len (length path)))
    (cond ((and (>= len 5) (has-extension path ".lisp"))
           (subseq path 0 (- len 5)))
          ((and (>= len 5) (has-extension path ".cert"))
           (subseq path 0 (- len 5)))
          ((and (>= len 4) (has-extension path ".acl2"))
           (subseq path 0 (- len 5)))
          (t path))))

(defun add-lisp-extension (path)
  "Add .lisp extension to PATH if not already present."
  (declare (xargs :guard (stringp path)))
  (if (has-extension path ".lisp")
      path
    (concatenate 'string (strip-extension path) ".lisp")))

(defun add-cert-extension (path)
  "Add .cert extension to PATH if not already present."
  (declare (xargs :guard (stringp path)))
  (if (has-extension path ".cert")
      path
    (concatenate 'string (strip-extension path) ".cert")))

(defun path-directory (path)
  "Extract directory portion from PATH (everything before last /)."
  (declare (xargs :guard (stringp path)))
  (let ((last-slash (str::strrpos "/" path)))
    (if last-slash
        (subseq path 0 (+ 1 last-slash))
      "")))

(defun path-basename (path)
  "Extract filename portion from PATH (everything after last /)."
  (declare (xargs :guard (stringp path)))
  (let ((last-slash (str::strrpos "/" path)))
    (if last-slash
        (subseq path (+ 1 last-slash) (length path))
      path)))

(defun normalize-book-path (base-dir book-name)
  "Resolve BOOK-NAME relative to BASE-DIR.
   Returns the normalized path without extension."
  (declare (xargs :guard (and (stringp base-dir) (stringp book-name))))
  (let ((book (strip-extension book-name)))
    (cond
     ;; Absolute path
     ((and (> (length book) 0) (eql (char book 0) #\/))
      book)
     ;; Relative to current directory
     ((equal base-dir "")
      book)
     ;; Relative path - join with base
     (t
      (let ((dir (if (and (> (length base-dir) 0)
                          (eql (char base-dir (- (length base-dir) 1)) #\/))
                     base-dir
                   (concatenate 'string base-dir "/"))))
        (concatenate 'string dir book))))))

;;; ============================================================================
;;; Dependency extraction from book-deps
;;; ============================================================================

(defun extract-dep-paths (deps)
  "Extract just the path strings from a book-dep-list."
  (declare (xargs :guard (book-dep-list-p deps)))
  (if (atom deps)
      nil
    (cons (book-dep->path (car deps))
          (extract-dep-paths (cdr deps)))))

(defthm string-listp-extract-dep-paths
  (implies (book-dep-list-p deps)
           (string-listp (extract-dep-paths deps))))

(defun extract-non-local-dep-paths (deps)
  "Extract path strings from non-local dependencies only."
  (declare (xargs :guard (book-dep-list-p deps)))
  (if (atom deps)
      nil
    (let ((dep (car deps))
          (rest (extract-non-local-dep-paths (cdr deps))))
      (if (book-dep->localp dep)
          rest
        (cons (book-dep->path dep) rest)))))

(defthm string-listp-extract-non-local-dep-paths
  (implies (book-dep-list-p deps)
           (string-listp (extract-non-local-dep-paths deps))))

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
