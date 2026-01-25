; ACL2 Build2 System - Main Entry Point
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Usage: echo '(ld "books/build2/cert2.lsp") (build2-main "target.lisp")' | ./saved_acl2
; Or:    ./books/build2/cert2 target.lisp

(in-package "ACL2")

;; ============================================================================
;; Exit to raw Lisp to define the BUILD2 package and load implementation
;; ============================================================================

(defttag :build2)

(progn!
 (set-raw-mode t)
 
 ;; Define BUILD2 package if not already defined
 (unless (find-package "BUILD2")
   (defpackage "BUILD2"
     (:use "COMMON-LISP")
     (:export
      ;; Configuration
      "*ACL2-EXECUTABLE*" "*ACL2-SYSTEM-BOOKS*" "*VERBOSE*" "*DEBUG*"
      ;; Main interface
      "BUILD-TARGETS" "ANALYZE-TARGETS" "PRINT-DEPS" "MAIN"
      ;; Utilities
      "LISP-TO-CERT2" "CANONICAL-PATH")))
 
 ;; Load the implementation files
 (let ((build2-dir (make-pathname 
                    :directory (pathname-directory 
                                (or *load-truename* 
                                    *compile-file-pathname*
                                    (truename "./"))))))
   (labels ((load-build2-file (name)
              (let ((path (merge-pathnames name build2-dir)))
                (format t "Loading ~A~%" path)
                (load path))))
     (load-build2-file "scan-raw.lsp")
     (load-build2-file "depgraph-raw.lsp") 
     (load-build2-file "certify-raw.lsp")
     (load-build2-file "scheduler-raw.lsp")))
 
 (format t "~%BUILD2 system loaded.~%")
 
 (set-raw-mode nil))

;; ============================================================================
;; ACL2 interface functions
;; ============================================================================

(defun build2-main-fn (targets jobs keep-going no-build verbose)
  "Internal function - runs in raw mode."
  (declare (xargs :mode :program))
  (progn!
   (set-raw-mode t)
   (let ((result (build2::build-targets 
                  (if (stringp targets) (list targets) targets)
                  :jobs jobs
                  :keep-going keep-going
                  :no-build no-build
                  :verbose verbose)))
     (set-raw-mode nil)
     result)))

(defmacro build2-main (targets &key (jobs '1) keep-going no-build verbose)
  "Main entry point for build2 from ACL2.
   TARGETS is a string or list of .lisp or .cert2 file paths to build.
   JOBS is the number of parallel certification jobs.
   KEEP-GOING if T, continue after failures.
   NO-BUILD if T, just analyze and print what would be built.
   VERBOSE if T, print detailed progress."
  `(build2-main-fn ,targets ,jobs ,keep-going ,no-build ,verbose))

(defun build2-analyze-fn (targets verbose)
  "Internal - analyze dependencies."
  (declare (xargs :mode :program))
  (progn!
   (set-raw-mode t)
   (let ((build2::*verbose* verbose))
     (let ((result (build2::analyze-targets
                    (if (stringp targets) (list targets) targets))))
       (set-raw-mode nil)
       result))))

(defmacro build2-analyze (targets &key verbose)
  "Analyze dependencies for TARGETS without building.
   Returns the list of certificates in build order."
  `(build2-analyze-fn ,targets ,verbose))

(defun build2-deps-fn (target)
  "Internal - print dependencies."
  (declare (xargs :mode :program))
  (progn!
   (set-raw-mode t)
   (build2::analyze-targets (list target))
   (let ((cert-path (if (search ".lisp" target)
                        (build2::lisp-to-cert2 (build2::canonical-path target))
                      (build2::canonical-path target))))
     (build2::print-deps cert-path))
   (set-raw-mode nil)
   t))

(defmacro build2-deps (target)
  "Print dependencies for a single TARGET."
  `(build2-deps-fn ,target))

;; ============================================================================  
;; Command-line interface (for use with cert2 shell script)
;; ============================================================================

(defun build2-cli-fn (args)
  "Process command-line arguments and run build2."
  (declare (xargs :mode :program))
  (progn!
   (set-raw-mode t)
   (let ((exit-code (build2::main args)))
     (set-raw-mode nil)
     exit-code)))

;; For convenience when using interactively
(defmacro cert2 (&rest targets)
  "Convenience macro for certifying books.
   Usage: (cert2 \"book1.lisp\" \"book2.lisp\")"
  `(build2-main-fn 
    (list ,@(loop for targ in targets 
                  collect (if (stringp targ) targ `',targ)))
    1 nil nil t))
