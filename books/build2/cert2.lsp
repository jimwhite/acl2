; ACL2 Build2 System - CLI Entry Point
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file is loaded directly by the cert2 shell script in raw Lisp mode.

(in-package "BUILD2")

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

(defun certify-one-book (book-path verbose)
  "Certify a single book. Returns T on success, NIL on failure."
  (let* ((lisp-file (concatenate 'string book-path ".lisp"))
         (cert-file (concatenate 'string book-path ".cert")))
    (when verbose
      (format t "~%Checking ~A...~%" book-path))
    ;; Check if source exists
    (unless (file-exists-p-raw lisp-file)
      (format t "Error: Source file not found: ~A~%" lisp-file)
      (return-from certify-one-book nil))
    ;; Check if already up-to-date
    (let ((lisp-date (file-write-date-raw lisp-file))
          (cert-date (file-write-date-raw cert-file)))
      (when (and cert-date lisp-date (>= cert-date lisp-date))
        (when verbose
          (format t "  Already up-to-date.~%"))
        (return-from certify-one-book t)))
    ;; For now, just report what we would do
    (format t "  Needs certification: ~A~%" book-path)
    (format t "  (Full certification not yet implemented - use cert.pl for now)~%")
    t))

(defun process-books (books verbose)
  "Process a list of books, return T if all succeed."
  (if (null books)
      t
    (let ((this-ok (certify-one-book (car books) verbose))
          (rest-ok (process-books (cdr books) verbose)))
      (and this-ok rest-ok))))

(defun build2-cli-fn (args)
  "Main entry point for the cert2 command-line tool.
   ARGS is a list of command-line arguments (strings).
   Returns 0 on success, non-zero on failure."
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
