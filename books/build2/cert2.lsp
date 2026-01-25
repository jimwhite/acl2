; ACL2 Build2 System - Main Entry Point
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This is the main driver script for cert2.
; Load this file in ACL2 or raw Lisp to run the certification system.

;; ============================================================================
;; Package setup
;; ============================================================================

(in-package "ACL2")

;; We need to be in raw Lisp for most of this
(defun run-cert2 ()
  "Main entry point - called from ACL2."
  (value :q)  ; Exit ACL2 loop
  (run-cert2-raw))

;; ============================================================================
;; Raw Lisp implementation
;; ============================================================================

(in-package "ACL2")

#+acl2-loop-only
(defun run-cert2-raw () nil)

#-acl2-loop-only
(progn

(defpackage "BUILD2"
  (:use "COMMON-LISP")
  (:export "BUILD-TARGETS" "ANALYZE-TARGETS" "PRINT-DEPS"
           "*ACL2-EXECUTABLE*" "*ACL2-SYSTEM-BOOKS*" "*VERBOSE*" "*DEBUG*"))

;; Load the implementation files
(defvar *build2-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defun load-build2-file (name)
  (load (merge-pathnames name *build2-dir*)))

;; Note: In actual use, we'd load the certified .lisp files
;; For bootstrapping, we load the raw Lisp files directly
(load-build2-file "scan-raw.lsp")
(load-build2-file "depgraph-raw.lsp")
(load-build2-file "certify-raw.lsp")
(load-build2-file "scheduler-raw.lsp")

(in-package "BUILD2")

;; ============================================================================
;; Command-line argument parsing
;; ============================================================================

(defun parse-args (args)
  "Parse command-line arguments.
   Returns a plist of options and a list of target files."
  (let ((options (list :jobs 1
                       :keep-going nil
                       :no-build nil
                       :verbose nil
                       :debug nil
                       :help nil
                       :acl2 nil
                       :acl2-books nil))
        (targets nil))
    (loop while args do
      (let ((arg (pop args)))
        (cond
          ((or (string= arg "-h") (string= arg "--help"))
           (setf (getf options :help) t))
          
          ((or (string= arg "-j") (string= arg "--jobs"))
           (setf (getf options :jobs)
                 (parse-integer (pop args))))
          
          ((or (string= arg "-k") (string= arg "--keep-going"))
           (setf (getf options :keep-going) t))
          
          ((or (string= arg "-n") (string= arg "--no-build"))
           (setf (getf options :no-build) t))
          
          ((or (string= arg "-v") (string= arg "--verbose"))
           (setf (getf options :verbose) t))
          
          ((string= arg "--debug")
           (setf (getf options :debug) t))
          
          ((or (string= arg "-a") (string= arg "--acl2"))
           (setf (getf options :acl2) (pop args)))
          
          ((or (string= arg "-b") (string= arg "--acl2-books"))
           (setf (getf options :acl2-books) (pop args)))
          
          ;; Anything else is a target
          (t (push arg targets)))))
    
    (values options (nreverse targets))))

(defun print-help ()
  "Print help message."
  (format t "~%cert2 - ACL2 Book Certification System~%~%")
  (format t "Usage: cert2 [options] <targets...>~%~%")
  (format t "Options:~%")
  (format t "  -h, --help          Show this help message~%")
  (format t "  -j, --jobs N        Run N parallel jobs (default: 1)~%")
  (format t "  -k, --keep-going    Continue after failures~%")
  (format t "  -n, --no-build      Just show what would be built~%")
  (format t "  -v, --verbose       Verbose output~%")
  (format t "  --debug             Enable debug output~%")
  (format t "  -a, --acl2 PATH     Path to ACL2 executable~%")
  (format t "  -b, --acl2-books DIR  Path to ACL2 system books~%")
  (format t "~%")
  (format t "Targets can be .lisp files or .cert2 files.~%")
  (format t "~%")
  (format t "This system produces .cert2 files to avoid conflicts with~%")
  (format t "the existing cert.pl system.~%"))

;; ============================================================================
;; Main function
;; ============================================================================

(defun main (args)
  "Main entry point for cert2."
  (multiple-value-bind (options targets) (parse-args args)
    
    ;; Handle help
    (when (getf options :help)
      (print-help)
      (return-from main 0))
    
    ;; Check for targets
    (when (null targets)
      (format *error-output* "Error: No targets specified~%")
      (format *error-output* "Use --help for usage information~%")
      (return-from main 1))
    
    ;; Set global options
    (setf *acl2-executable* (or (getf options :acl2)
                                (uiop:getenv "ACL2")
                                "acl2"))
    (setf *acl2-system-books* (or (getf options :acl2-books)
                                  (uiop:getenv "ACL2_SYSTEM_BOOKS")))
    (setf *verbose* (getf options :verbose))
    (setf *debug* (getf options :debug))
    
    ;; Register system books directory
    (when *acl2-system-books*
      (register-include-book-dir :system *acl2-system-books*))
    
    ;; Run the build
    (if (build-targets targets
                       :jobs (getf options :jobs)
                       :keep-going (getf options :keep-going)
                       :no-build (getf options :no-build)
                       :verbose (getf options :verbose))
        0   ; Success
      1)))  ; Failure

(defun run-cert2-raw ()
  "Entry point from ACL2."
  ;; Get command-line arguments
  ;; The exact method depends on the Lisp implementation
  (let ((args
         #+sbcl (cdr sb-ext:*posix-argv*)
         #+ccl (cdr ccl:*command-line-argument-list*)
         #-(or sbcl ccl) nil))
    (let ((exit-code (main args)))
      #+sbcl (sb-ext:exit :code exit-code)
      #+ccl (ccl:quit exit-code)
      #-(or sbcl ccl) exit-code)))

) ; end progn for #-acl2-loop-only
