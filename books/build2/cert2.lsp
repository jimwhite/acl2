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

(defvar *verbose* nil
  "Verbose output flag.")

(defvar *certifying* (make-hash-table :test 'equal)
  "Hash table tracking books currently being certified (cycle detection).")

(defvar *certified* (make-hash-table :test 'equal)
  "Hash table of books already certified this session.")

;;; ============================================================================
;;; Dependency scanning using proper Lisp reader
;;; ============================================================================

(defun read-forms-from-file (filename)
  "Read all Lisp forms from FILENAME using the standard reader.
   Returns list of forms, or NIL on error."
  (handler-case
      (with-open-file (stream filename :direction :input
                                       :if-does-not-exist nil)
        (when stream
          (let ((*package* (find-package "ACL2"))
                (*read-eval* nil))  ; Safety: don't evaluate during read
            (loop for form = (read stream nil :eof)
                  until (eq form :eof)
                  collect form))))
    (error () nil)))

(defun extract-include-books (form)
  "Extract include-book info from FORM. Returns list of (path localp dir-keyword)."
  (when (consp form)
    (case (car form)
      ;; Direct include-book
      (acl2::include-book
       (when (and (cdr form) (stringp (cadr form)))
         (let* ((path (cadr form))
                (rest (cddr form))
                (dir-pos (position :dir rest))
                (dir-val (and dir-pos (nth (1+ dir-pos) rest))))
           (list (list path nil (when (eq dir-val :system) :system))))))
      ;; Local wrapper
      (acl2::local
       (when (cdr form)
         (let ((inner-results (extract-include-books (cadr form))))
           ;; Mark all as local
           (mapcar (lambda (r) (list (first r) t (third r))) inner-results))))
      ;; Recurse into progn, encapsulate, etc.
      ((acl2::progn acl2::encapsulate)
       (loop for subform in (cdr form)
             append (extract-include-books subform)))
      (otherwise nil))))

(defun scan-file-for-deps (filename)
  "Scan FILENAME for include-book dependencies using Lisp reader.
   Returns list of (path localp dir-keyword)."
  (let ((forms (read-forms-from-file filename)))
    (loop for form in forms
          append (extract-include-books form))))

;;; ============================================================================
;;; Path resolution
;;; ============================================================================

(defun resolve-book-path (base-dir book-name dir-keyword)
  "Resolve BOOK-NAME relative to BASE-DIR.
   If DIR-KEYWORD is :SYSTEM, resolve relative to system books.
   Returns absolute path without extension."
  (let* ((name (if (and (> (length book-name) 5)
                        (string-equal ".lisp" (subseq book-name (- (length book-name) 5))))
                   (subseq book-name 0 (- (length book-name) 5))
                 book-name))
         (base-str (namestring (or base-dir *system-books-dir*)))
         (sys-str (namestring *system-books-dir*)))
    ;; Ensure base-str ends with /
    (unless (char= (char base-str (1- (length base-str))) #\/)
      (setf base-str (concatenate 'string base-str "/")))
    (unless (char= (char sys-str (1- (length sys-str))) #\/)
      (setf sys-str (concatenate 'string sys-str "/")))
    (cond
      ;; :dir :system - relative to system books
      ((eq dir-keyword :system)
       (pathname (concatenate 'string sys-str name)))
      ;; Absolute path
      ((and (> (length name) 0) (char= (char name 0) #\/))
       (pathname name))
      ;; Relative path - resolve relative to base-dir
      (t
       (pathname (concatenate 'string base-str name))))))

;;; ============================================================================
;;; Command-line interface
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
  (let* ((book-str (namestring book-path))
         (acl2-file (concatenate 'string book-str ".acl2"))
         (has-acl2 (probe-file acl2-file)))
    (with-output-to-string (s)
      ;; Load .acl2 file if it exists (sets up package, includes, etc.)
      (when has-acl2
        (format s "(ld ~S)~%" acl2-file))
      ;; Certify the book
      (format s "(certify-book ~S ? t)~%" book-str)
      ;; Exit  
      (format s "(good-bye)~%"))))

(defun run-acl2-certify (book-path)
  "Run ACL2 to certify BOOK-PATH. Returns T on success, NIL on failure."
  (let* ((script (make-certify-script book-path))
         (acl2 (or *acl2-executable* "acl2"))
         (book-str (namestring book-path))
         (log-file (concatenate 'string book-str ".cert.out")))
    (when *verbose*
      (format t "  Running: ~A~%" acl2)
      (format t "  Log: ~A~%" log-file))
    ;; Run ACL2 with the script, output to log file
    (with-open-file (log-stream log-file :direction :output 
                                         :if-exists :supersede
                                         :if-does-not-exist :create)
      (let* ((process (sb-ext:run-program 
                       acl2
                       nil
                       :input (make-string-input-stream script)
                       :output log-stream
                       :error :output
                       :wait t
                       :environment (list "ACL2_CUSTOMIZATION=NONE")))
             (exit-code (sb-ext:process-exit-code process)))
        (zerop exit-code)))))

;;; ============================================================================
;;; Dependency-aware certification
;;; ============================================================================

(defun book-up-to-date-p (book-path)
  "Check if BOOK-PATH.cert exists and is newer than BOOK-PATH.lisp."
  (let* ((book-str (namestring book-path))
         (lisp-file (concatenate 'string book-str ".lisp"))
         (cert-file (concatenate 'string book-str ".cert"))
         (lisp-date (and (probe-file lisp-file) (file-write-date lisp-file)))
         (cert-date (and (probe-file cert-file) (file-write-date cert-file))))
    (and lisp-date cert-date (>= cert-date lisp-date))))

(defun certify-book-with-deps (book-path)
  "Certify BOOK-PATH after first certifying all its dependencies.
   Returns T on success, NIL on failure."
  (let ((book-str (namestring book-path)))
    ;; Check for cycles
    (when (gethash book-str *certifying*)
      (format t "Error: Circular dependency detected involving ~A~%" book-str)
      (return-from certify-book-with-deps nil))
    
    ;; Already done this session?
    (when (gethash book-str *certified*)
      (when *verbose*
        (format t "  ~A (already certified this session)~%" book-str))
      (return-from certify-book-with-deps t))
    
    ;; Check if source exists
    (let ((lisp-file (concatenate 'string book-str ".lisp")))
      (unless (probe-file lisp-file)
        (format t "Error: Source file not found: ~A~%" lisp-file)
        (return-from certify-book-with-deps nil))
      
      ;; Mark as being certified (for cycle detection)
      (setf (gethash book-str *certifying*) t)
      
      (unwind-protect
          (progn
            ;; Scan for dependencies
            (let* ((deps (scan-file-for-deps lisp-file))
                   ;; Get directory containing this book
                   (base-dir (let ((last-slash (position #\/ book-str :from-end t)))
                               (if last-slash
                                   (pathname (subseq book-str 0 (1+ last-slash)))
                                 *system-books-dir*))))
              ;; Certify each dependency first
              (dolist (dep deps)
                (destructuring-bind (dep-name localp dir-keyword) dep
                  (declare (ignore localp))
                  (let ((dep-path (resolve-book-path base-dir dep-name dir-keyword)))
                    (unless (certify-book-with-deps dep-path)
                      (format t "Error: Failed to certify dependency ~A~%" dep-path)
                      (return-from certify-book-with-deps nil)))))
              
              ;; Now certify this book if needed
              (cond
                ((book-up-to-date-p book-path)
                 (when *verbose*
                   (format t "  ~A (up to date)~%" book-str))
                 (setf (gethash book-str *certified*) t)
                 t)
                (t
                 (format t "Certifying ~A...~%" book-str)
                 (let ((success (run-acl2-certify book-path)))
                   (if success
                       (progn
                         (format t "  Success: ~A~%" book-str)
                         (setf (gethash book-str *certified*) t)
                         t)
                     (progn
                       (format t "  FAILED: ~A~%" book-str)
                       nil)))))))
        ;; Cleanup: remove from certifying set
        (remhash book-str *certifying*)))))

(defun process-books (books)
  "Process a list of books, return T if all succeed."
  (every (lambda (book)
           (handler-case
               ;; Ensure we have a proper path relative to books dir
               (let* ((book-str (if (pathnamep book) (namestring book) book))
                      (sys-str (namestring *system-books-dir*)))
                 ;; Ensure sys-str ends with /
                 (unless (and (> (length sys-str) 0)
                              (char= (char sys-str (1- (length sys-str))) #\/))
                   (setf sys-str (concatenate 'string sys-str "/")))
                 (let ((book-path 
                        (if (and (> (length book-str) 0)
                                 (char= (char book-str 0) #\/))
                            (pathname book-str)
                          (pathname (concatenate 'string sys-str book-str)))))
                   (certify-book-with-deps book-path)))
             (error (e)
               (format t "Error processing ~A: ~A~%" book e)
               nil)))
         books))

(defun build2-cli-fn (args acl2-path books-dir)
  "Main entry point for the cert2 command-line tool.
   ARGS is a list of command-line arguments (strings).
   ACL2-PATH is the path to the ACL2 executable.
   BOOKS-DIR is the path to the system books directory.
   Returns 0 on success, non-zero on failure."
  (handler-case
      (progn
        (setf *acl2-executable* acl2-path)
        (setf *system-books-dir* (pathname books-dir))
        (setf *certifying* (make-hash-table :test 'equal))
        (setf *certified* (make-hash-table :test 'equal))
        (multiple-value-bind (books options)
            (parse-args args)
          ;; Handle help
          (when (cdr (assoc :help options))
            (print-usage)
            (return-from build2-cli-fn 0))
          ;; Set verbose
          (setf *verbose* (cdr (assoc :verbose options)))
          ;; Must have at least one book
          (when (null books)
            (format t "Error: No books specified.~%")
            (print-usage)
            (return-from build2-cli-fn 1))
          ;; Process books
          (if (process-books books) 0 1)))
    (error (e)
      (format t "~%Fatal error: ~A~%" e)
      1)))
