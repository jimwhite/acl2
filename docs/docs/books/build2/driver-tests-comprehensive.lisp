; ACL2 Build2 System - Comprehensive Driver Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "driver")

;; ============================================================================
;; More edge cases for has-extension
;; ============================================================================

;; A string that is exactly ".lisp" DOES end with ".lisp"
(defthm test-has-ext-exactly-ext-length
  (has-extension ".lisp" ".lisp")
  :rule-classes nil)

(defthm test-has-ext-one-more-than-ext
  (has-extension "a.lisp" ".lisp")
  :rule-classes nil)

(defthm test-has-ext-similar-but-wrong
  (not (has-extension "foo.lispx" ".lisp"))
  :rule-classes nil)

(defthm test-has-ext-acl2
  (has-extension "foo.acl2" ".acl2")
  :rule-classes nil)

;; ============================================================================
;; Edge cases for strip-extension
;; ============================================================================

(defthm test-strip-ext-acl2
  (equal (strip-extension "foo.acl2") "foo")
  :rule-classes nil)

(defthm test-strip-ext-unknown
  ;; Unknown extension not stripped
  (equal (strip-extension "foo.txt") "foo.txt")
  :rule-classes nil)

(defthm test-strip-ext-multiple-dots
  (equal (strip-extension "foo.bar.baz.lisp") "foo.bar.baz")
  :rule-classes nil)

(defthm test-strip-ext-empty
  (equal (strip-extension "") "")
  :rule-classes nil)

(defthm test-strip-ext-hidden-file-lisp
  (equal (strip-extension ".hidden.lisp") ".hidden")
  :rule-classes nil)

;; ============================================================================
;; Edge cases for path-directory
;; ============================================================================

(defthm test-path-dir-empty
  (equal (path-directory "") "")
  :rule-classes nil)

(defthm test-path-dir-root
  (equal (path-directory "/file.lisp") "/")
  :rule-classes nil)

(defthm test-path-dir-absolute
  (equal (path-directory "/a/b/c.lisp") "/a/b/")
  :rule-classes nil)

;; ============================================================================
;; Edge cases for path-basename
;; ============================================================================

(defthm test-path-basename-empty
  (equal (path-basename "") "")
  :rule-classes nil)

(defthm test-path-basename-slash-only
  (equal (path-basename "/") "")
  :rule-classes nil)

(defthm test-path-basename-root-file
  (equal (path-basename "/file") "file")
  :rule-classes nil)

;; ============================================================================
;; Edge cases for normalize-book-path
;; ============================================================================

(defthm test-normalize-book-empty-both
  (equal (normalize-book-path "" "") "")
  :rule-classes nil)

(defthm test-normalize-book-strips-cert
  (equal (normalize-book-path "dir" "foo.cert") "dir/foo")
  :rule-classes nil)

(defthm test-normalize-book-absolute-with-ext
  (equal (normalize-book-path "ignored" "/abs/book.lisp") "/abs/book")
  :rule-classes nil)

(defthm test-normalize-book-no-double-slash
  (equal (normalize-book-path "dir/" "sub/book") "dir/sub/book")
  :rule-classes nil)

(defthm test-normalize-book-empty-book
  (equal (normalize-book-path "dir" "") "dir/")
  :rule-classes nil)

;; ============================================================================
;; Tests for add-lisp-extension edge cases
;; ============================================================================

(defthm test-add-lisp-strips-acl2-adds-lisp
  (equal (add-lisp-extension "foo.acl2") "foo.lisp")
  :rule-classes nil)

(defthm test-add-lisp-with-path-and-cert
  (equal (add-lisp-extension "dir/sub/bar.cert") "dir/sub/bar.lisp")
  :rule-classes nil)

;; ============================================================================
;; Tests for add-cert-extension edge cases
;; ============================================================================

(defthm test-add-cert-strips-acl2
  (equal (add-cert-extension "foo.acl2") "foo.cert")
  :rule-classes nil)

(defthm test-add-cert-with-path
  (equal (add-cert-extension "dir/sub/bar") "dir/sub/bar.cert")
  :rule-classes nil)

;; ============================================================================
;; Complex integration: realistic book scanning scenarios
;; ============================================================================

;; Scenario: A typical book with mixed dependencies
(defthm test-realistic-book-1
  (let* ((lines '("; Top-level utilities"
                  "(in-package \"MY-PKG\")"
                  ""
                  "; System books"
                  "(include-book \"std/util/define\" :dir :system)"
                  "(include-book \"std/lists/top\" :dir :system)"
                  ""
                  "; Local project books"
                  "(include-book \"util/helpers\")"
                  "(local (include-book \"util/local-lemmas\"))"
                  ""
                  "(define foo (x) x)"))
         (deps (scan-lines-for-deps lines))
         (all-paths (extract-dep-paths deps))
         (non-local (extract-non-local-dep-paths deps)))
    (and (equal (len deps) 4)
         (equal all-paths '("std/util/define" "std/lists/top" 
                           "util/helpers" "util/local-lemmas"))
         (equal non-local '("std/util/define" "std/lists/top" "util/helpers"))))
  :rule-classes nil)

;; Scenario: Book with only local includes (no non-local deps)
(defthm test-all-local-book
  (let* ((lines '("(local (include-book \"a\"))"
                  "(local (include-book \"b\"))"
                  "(local (include-book \"c\"))"))
         (deps (scan-lines-for-deps lines))
         (non-local (extract-non-local-dep-paths deps)))
    (and (equal (len deps) 3)
         (null non-local)))
  :rule-classes nil)

;; Scenario: Empty book (no includes)
(defthm test-empty-book
  (let* ((lines '("; Just a comment"
                  "(in-package \"ACL2\")"
                  "(defun f (x) x)"))
         (deps (scan-lines-for-deps lines)))
    (null deps))
  :rule-classes nil)

;; ============================================================================
;; Path normalization with realistic paths
;; ============================================================================

(defthm test-normalize-system-book
  (equal (normalize-book-path "/home/user/acl2/books" "std/lists/top")
         "/home/user/acl2/books/std/lists/top")
  :rule-classes nil)

(defthm test-normalize-project-book
  (equal (normalize-book-path "/projects/myproj/books" "util/helpers")
         "/projects/myproj/books/util/helpers")
  :rule-classes nil)

(defthm test-normalize-deeply-nested
  (equal (normalize-book-path "/base" "a/b/c/d/e/book")
         "/base/a/b/c/d/e/book")
  :rule-classes nil)

;; ============================================================================
;; Property: extract-dep-paths returns correct length
;; ============================================================================

(defthm test-extract-dep-paths-length-0
  (equal (len (extract-dep-paths nil)) 0)
  :rule-classes nil)

(defthm test-extract-dep-paths-length-1
  (equal (len (extract-dep-paths (list (make-book-dep :path "a" :localp nil)))) 1)
  :rule-classes nil)

(defthm test-extract-dep-paths-length-5
  (equal (len (extract-dep-paths
               (list (make-book-dep :path "a" :localp nil)
                     (make-book-dep :path "b" :localp t)
                     (make-book-dep :path "c" :localp nil)
                     (make-book-dep :path "d" :localp t)
                     (make-book-dep :path "e" :localp nil))))
         5)
  :rule-classes nil)

;; ============================================================================
;; Property: extract-non-local-dep-paths returns subset
;; ============================================================================

(defthm test-non-local-subset-check
  (let* ((deps (list (make-book-dep :path "a" :localp nil)
                     (make-book-dep :path "b" :localp t)
                     (make-book-dep :path "c" :localp nil)
                     (make-book-dep :path "d" :localp t)))
         (all (extract-dep-paths deps))
         (non-local (extract-non-local-dep-paths deps)))
    (and (<= (len non-local) (len all))
         (subsetp-equal non-local all)))
  :rule-classes nil)

;; ============================================================================
;; Round-trip: strip then add extension
;; ============================================================================

(defthm test-roundtrip-lisp
  (equal (add-lisp-extension (strip-extension "foo.lisp")) "foo.lisp")
  :rule-classes nil)

(defthm test-roundtrip-cert
  (equal (add-cert-extension (strip-extension "foo.cert")) "foo.cert")
  :rule-classes nil)

(defthm test-roundtrip-bare
  (equal (add-lisp-extension (strip-extension "foo")) "foo.lisp")
  :rule-classes nil)

;; ============================================================================
;; Path directory + basename reconstruction
;; ============================================================================

(defthm test-path-reconstruction
  (equal (concatenate 'string 
                      (path-directory "a/b/c.lisp")
                      (path-basename "a/b/c.lisp"))
         "a/b/c.lisp")
  :rule-classes nil)

(defthm test-path-reconstruction-no-dir
  (equal (concatenate 'string 
                      (path-directory "file.lisp")
                      (path-basename "file.lisp"))
         "file.lisp")
  :rule-classes nil)

(defthm test-path-reconstruction-root
  (equal (concatenate 'string 
                      (path-directory "/file.lisp")
                      (path-basename "/file.lisp"))
         "/file.lisp")
  :rule-classes nil)
