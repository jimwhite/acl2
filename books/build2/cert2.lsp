; ACL2 Build2 System - CLI Entry Point
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file is loaded directly by the cert2 shell script in raw Lisp mode.

(in-package "BUILD2")

;;; ============================================================================
;;; Global configuration
;;; ============================================================================

(defvar *acl2-executable* nil
  "Path to ACL2 executable, set by shell script.")

(defvar *system-books-dir* nil
  "Path to ACL2 system books directory.")

;;; ============================================================================
;;; Command-line interface (runs in raw Lisp)
;;; ============================================================================

(defun print-usage ()
  (format t "~%Usage: cert2 [options] book1 [book2 ...]~%")
  (format t "~%Certify ACL2 books.~%")
  (format t "~%Options:~%")
  (format t "  -h, --help      Show this help message~%")
  (format t "  -j N            Use N parallel jobs (not yet implemented)~%")
  (format t "  -v, --verbose   Verbose output~%")
  (format t "~%Books should be specified without the .lisp extension.~%")
  (format t "~%Example:~%")
  (format t "  cert2 arithmetic/top std/lists/top~%~%"))

(defun parse-args-helper (args books options)
  "Helper for parse-args using recursion instead of loop."
  (if (null args)
      (values (nreverse books) options)
    (let ((arg (car args))
          (rest (cdr args)))
      (cond
       ((or (string= arg "-h") (string= arg "--help"))
        (parse-args-helper rest books (acons :help t options)))
       ((or (string= arg "-v") (string= arg "--verbose"))
        (parse-args-helper rest books (acons :verbose t options)))
       ((string= arg "-j")
        (if rest
            (parse-args-helper (cdr rest) books 
                               (acons :jobs (parse-integer (car rest) :junk-allowed t) options))
          (parse-args-helper rest books options)))
       ((and (> (length arg) 0) (char= (char arg 0) #\-))
        (format t "Warning: Unknown option: ~A~%" arg)
        (parse-args-helper rest books options))
       (t
        (parse-args-helper rest (cons arg books) options))))))

(defun parse-args (args)
  "Parse command-line arguments.
   Returns (values books options) where options is an alist."
  (parse-args-helper args nil nil))

;;; ============================================================================
;;; ACL2 invocation for certification
;;; ============================================================================

(defun make-certify-script (book-path)
  "Create the ACL2 script to certify BOOK-PATH.
   Handles .acl2 file if present."
  (let* ((acl2-file (concatenate 'string book-path ".acl2"))
         (has-acl2 (probe-file acl2-file)))
    (with-output-to-string (s)
      ;; Load .acl2 file if it exists (sets up package, includes, etc.)
      (when has-acl2
        (format s "(ld ~S)~%" acl2-file))
      ;; Certify the book
      (format s "(certify-book ~S ? t)~%" book-path)
      ;; Exit
      (format s "(quit)~%"))))

(defun run-acl2-certify (book-path verbose)
  "Run ACL2 to certify BOOK-PATH. Returns T on success, NIL on failure."
  (let* ((script (make-certify-script book-path))
         (acl2 (or *acl2-executable* "acl2")))
    (when verbose
      (format t "  Running: ~A~%" acl2)
      (format t "  Script: ~A~%" script))
    ;; Run ACL2 with the script
    (let* ((process (sb-ext:run-program 
                     acl2
                     nil
                     :input (make-string-input-stream script)
                     :output t
                     :error :output
                     :wait t
                     :environment (list (format nil "ACL2_CUSTOMIZATION=NONE"))))
           (exit-code (sb-ext:process-exit-code process)))
      (zerop exit-code))))

(defun certify-one-book (book-path verbose)
  "Certify a single book. Returns T on success, NIL on failure."
  (let* ((lisp-file (concatenate 'string book-path ".lisp"))
         (cert-file (concatenate 'string book-path ".cert")))
    (when verbose
      (format t "~%Checking ~A...~%" book-path))
    ;; Check if source exists
    (unless (probe-file lisp-file)
      (format t "Error: Source file not found: ~A~%" lisp-file)
      (return-from certify-one-book nil))
    ;; Check if already up-to-date
    (let ((lisp-date (file-write-date lisp-file))
          (cert-date (ignore-errors (file-write-date cert-file))))
      (when (and cert-date lisp-date (>= cert-date lisp-date))
        (when verbose
          (format t "  Already up-to-date.~%"))
        (return-from certify-one-book t)))
    ;; Actually certify the book
    (format t "Certifying ~A...~%" book-path)
    (let ((success (run-acl2-certify book-path verbose)))
      (if success
          (format t "  Success.~%")
        (format t "  FAILED.~%"))
      success)))

(defun process-books (books verbose)
  "Process a list of books, return T if all succeed."
  (if (null books)
      t
    (let ((this-ok (certify-one-book (car books) verbose))
          (rest-ok (process-books (cdr books) verbose)))
      (and this-ok rest-ok))))

(defun build2-cli-fn (args acl2-path)
  "Main entry point for the cert2 command-line tool.
   ARGS is a list of command-line arguments (strings).
   ACL2-PATH is the path to the ACL2 executable.
   Returns 0 on success, non-zero on failure."
  (setf *acl2-executable* acl2-path)
  (multiple-value-bind (books options)
      (parse-args args)
    ;; Handle help
    (when (cdr (assoc :help options))
      (print-usage)
      (return-from build2-cli-fn 0))
    ;; Must have at least one book
    (when (null books)
      (format t "Error: No books specified.~%")
      (print-usage)
      (return-from build2-cli-fn 1))
    ;; Process books
    (let ((verbose (cdr (assoc :verbose options))))
      (if (process-books books verbose) 0 1))))
