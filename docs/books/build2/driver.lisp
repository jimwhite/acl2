; ACL2 Build2 System - Build Driver
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Core build logic - dependency graph and certification ordering.
; This file contains only pure logic functions that can be verified.
; The actual file I/O and ACL2 invocation is in cert2.lsp (raw Lisp).

(in-package "BUILD2")

(include-book "scan")

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
;;; TODO: Dependency graph building and build ordering
;;; These functions require file I/O and will be implemented in cert2.lsp
;;; ============================================================================
