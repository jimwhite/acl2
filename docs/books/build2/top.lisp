; ACL2 Build2 System - Top Level
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This is the main entry point for the build system.

(in-package "BUILD2")

(include-book "driver")

;; At this point we have:
;; - types.lisp: FTY types for book-dep, certinfo
;; - scan.lisp: Parsing include-book forms
;; - driver.lisp: Build ordering logic (stubs)
;;
;; To actually run the build system, we need to load the raw Lisp
;; and invoke the main function.

;;; ============================================================================
;;; Main interface
;;; ============================================================================

(defun build-books-stub (book-paths state)
  "Build a list of books. This is a stub for certification.
   The real implementation is in the raw Lisp loader."
  (declare (xargs :guard (string-listp book-paths)
                  :stobjs state
                  :mode :program)
           (ignore book-paths))
  (mv "Build function stub - load raw Lisp for actual functionality" state))

