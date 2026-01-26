; ACL2 Build2 System - Driver Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "driver")

;; ============================================================================
;; Tests for helper functions
;; ============================================================================

;; Test that scan-lines-for-deps (from scan.lisp) works correctly
;; in the context of the driver

(defthm test-driver-integration-scan
  (let ((deps (scan-lines-for-deps
               '("; Header comment"
                 "(in-package \"ACL2\")"
                 ""
                 "(include-book \"std/lists/top\" :dir :system)"
                 "(include-book \"local-helper\")"
                 "(local (include-book \"local-only\"))"
                 ""
                 "(defun my-fn (x) x)"))))
    (and (equal (len deps) 3)
         (equal (book-dep->path (first deps)) "std/lists/top")
         (equal (book-dep->path (second deps)) "local-helper")
         (equal (book-dep->path (third deps)) "local-only")
         (not (book-dep->localp (first deps)))
         (not (book-dep->localp (second deps)))
         (book-dep->localp (third deps))))
  :rule-classes nil)

;; Test that book-dep-list-p recognizes valid lists
(defthm test-driver-book-dep-list
  (book-dep-list-p
   (scan-lines-for-deps
    '("(include-book \"a\")"
      "(include-book \"b\")")))
  :rule-classes nil)

;; ============================================================================
;; Test string concatenation for path building
;; ============================================================================

(defthm test-lisp-file-path
  (equal (concatenate 'string "foo/bar" ".lisp")
         "foo/bar.lisp")
  :rule-classes nil)

(defthm test-cert-file-path
  (equal (concatenate 'string "foo/bar" ".cert")
         "foo/bar.cert")
  :rule-classes nil)
