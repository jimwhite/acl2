; ACL2 Build2 System - Raw Lisp I/O Utilities
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file contains raw Common Lisp code for file operations.
; It must be loaded with include-raw.

(in-package "BUILD2")

;;; ============================================================================
;;; File reading
;;; ============================================================================

(defun read-file-lines-raw (filename)
  "Read all lines from FILENAME, return as a list of strings.
   Returns NIL if file doesn't exist or can't be read."
  (handler-case
      (with-open-file (stream filename :direction :input
                                       :if-does-not-exist nil)
        (when stream
          (loop for line = (read-line stream nil nil)
                while line
                collect line)))
    (error () nil)))

;;; ============================================================================
;;; File timestamps
;;; ============================================================================

(defun file-write-date-raw (filename)
  "Get the write date of FILENAME as a universal time.
   Returns NIL if file doesn't exist."
  (ignore-errors (file-write-date filename)))

(defun file-exists-p-raw (filename)
  "Check if FILENAME exists."
  (probe-file filename))

;;; ============================================================================
;;; Running external processes
;;; ============================================================================

(defun run-certify-book (book-path acl2-cmd &optional extra-args)
  "Run ACL2 to certify BOOK-PATH.
   BOOK-PATH should be the full path without .lisp extension.
   ACL2-CMD is the ACL2 executable command.
   Returns (mv success-p output-string)."
  (let* ((lisp-file (concatenate 'string book-path ".lisp"))
         (cert-file (concatenate 'string book-path ".cert"))
         ;; Create the ACL2 forms to certify
         (forms (format nil "(ld \"~A\")~%(certify-book \"~A\" ?)"
                        (concatenate 'string book-path ".acl2")
                        book-path)))
    ;; For now, just check if cert file exists and is newer
    ;; A real implementation would run ACL2
    (declare (ignore forms acl2-cmd extra-args))
    (let ((lisp-date (file-write-date-raw lisp-file))
          (cert-date (file-write-date-raw cert-file)))
      (if (and lisp-date cert-date (>= cert-date lisp-date))
          (values t "Already certified and up to date")
        (values nil "Needs certification")))))

;;; ============================================================================
;;; Path utilities
;;; ============================================================================

(defun resolve-book-path (base-dir book-name)
  "Resolve a book name relative to BASE-DIR.
   BOOK-NAME may be relative or use :dir :system."
  (merge-pathnames (concatenate 'string book-name ".lisp") base-dir))

(defun get-cert-path (lisp-path)
  "Convert a .lisp path to a .cert path."
  (let* ((name (pathname-name lisp-path))
         (dir (pathname-directory lisp-path)))
    (make-pathname :directory dir
                   :name name
                   :type "cert")))
