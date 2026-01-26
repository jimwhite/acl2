; ACL2 Build2 System - Driver Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "driver")

;; ============================================================================
;; Tests for has-extension
;; ============================================================================

(defthm test-has-extension-lisp
  (has-extension "foo.lisp" ".lisp")
  :rule-classes nil)

(defthm test-has-extension-cert
  (has-extension "foo.cert" ".cert")
  :rule-classes nil)

(defthm test-has-extension-with-path
  (has-extension "dir/subdir/foo.lisp" ".lisp")
  :rule-classes nil)

(defthm test-has-extension-no-match
  (not (has-extension "foo.lisp" ".cert"))
  :rule-classes nil)

(defthm test-has-extension-too-short
  (not (has-extension "foo" ".lisp"))
  :rule-classes nil)

(defthm test-has-extension-empty
  (not (has-extension "" ".lisp"))
  :rule-classes nil)

;; ============================================================================
;; Tests for strip-extension
;; ============================================================================

(defthm test-strip-extension-lisp
  (equal (strip-extension "foo.lisp") "foo")
  :rule-classes nil)

(defthm test-strip-extension-cert
  (equal (strip-extension "foo.cert") "foo")
  :rule-classes nil)

(defthm test-strip-extension-with-path
  (equal (strip-extension "dir/subdir/bar.lisp") "dir/subdir/bar")
  :rule-classes nil)

(defthm test-strip-extension-no-ext
  (equal (strip-extension "foo") "foo")
  :rule-classes nil)

(defthm test-strip-extension-dot-in-name
  (equal (strip-extension "foo.bar.lisp") "foo.bar")
  :rule-classes nil)

;; ============================================================================
;; Tests for add-lisp-extension
;; ============================================================================

(defthm test-add-lisp-extension-bare
  (equal (add-lisp-extension "foo") "foo.lisp")
  :rule-classes nil)

(defthm test-add-lisp-extension-already-has
  (equal (add-lisp-extension "foo.lisp") "foo.lisp")
  :rule-classes nil)

(defthm test-add-lisp-extension-has-cert
  (equal (add-lisp-extension "foo.cert") "foo.lisp")
  :rule-classes nil)

(defthm test-add-lisp-extension-with-path
  (equal (add-lisp-extension "dir/bar") "dir/bar.lisp")
  :rule-classes nil)

;; ============================================================================
;; Tests for add-cert-extension
;; ============================================================================

(defthm test-add-cert-extension-bare
  (equal (add-cert-extension "foo") "foo.cert")
  :rule-classes nil)

(defthm test-add-cert-extension-already-has
  (equal (add-cert-extension "foo.cert") "foo.cert")
  :rule-classes nil)

(defthm test-add-cert-extension-has-lisp
  (equal (add-cert-extension "foo.lisp") "foo.cert")
  :rule-classes nil)

;; ============================================================================
;; Tests for path-directory
;; ============================================================================

(defthm test-path-directory-simple
  (equal (path-directory "dir/file") "dir/")
  :rule-classes nil)

(defthm test-path-directory-nested
  (equal (path-directory "a/b/c/file.lisp") "a/b/c/")
  :rule-classes nil)

(defthm test-path-directory-no-dir
  (equal (path-directory "file.lisp") "")
  :rule-classes nil)

(defthm test-path-directory-trailing-slash
  (equal (path-directory "dir/subdir/") "dir/subdir/")
  :rule-classes nil)

;; ============================================================================
;; Tests for path-basename
;; ============================================================================

(defthm test-path-basename-simple
  (equal (path-basename "dir/file.lisp") "file.lisp")
  :rule-classes nil)

(defthm test-path-basename-nested
  (equal (path-basename "a/b/c/file.lisp") "file.lisp")
  :rule-classes nil)

(defthm test-path-basename-no-dir
  (equal (path-basename "file.lisp") "file.lisp")
  :rule-classes nil)

;; ============================================================================
;; Tests for normalize-book-path
;; ============================================================================

(defthm test-normalize-relative
  (equal (normalize-book-path "mydir" "foo") "mydir/foo")
  :rule-classes nil)

(defthm test-normalize-relative-with-slash
  (equal (normalize-book-path "mydir/" "foo") "mydir/foo")
  :rule-classes nil)

(defthm test-normalize-strips-extension
  (equal (normalize-book-path "dir" "foo.lisp") "dir/foo")
  :rule-classes nil)

(defthm test-normalize-absolute
  (equal (normalize-book-path "dir" "/abs/path/book") "/abs/path/book")
  :rule-classes nil)

(defthm test-normalize-empty-base
  (equal (normalize-book-path "" "foo") "foo")
  :rule-classes nil)

(defthm test-normalize-nested
  (equal (normalize-book-path "base" "sub/dir/book") "base/sub/dir/book")
  :rule-classes nil)

;; ============================================================================
;; Tests for extract-dep-paths
;; ============================================================================

(defthm test-extract-dep-paths-empty
  (equal (extract-dep-paths nil) nil)
  :rule-classes nil)

(defthm test-extract-dep-paths-single
  (equal (extract-dep-paths (list (make-book-dep :path "foo" :localp nil)))
         '("foo"))
  :rule-classes nil)

(defthm test-extract-dep-paths-multiple
  (equal (extract-dep-paths 
          (list (make-book-dep :path "a" :localp nil)
                (make-book-dep :path "b" :localp t)
                (make-book-dep :path "c" :localp nil)))
         '("a" "b" "c"))
  :rule-classes nil)

;; ============================================================================
;; Tests for extract-non-local-dep-paths
;; ============================================================================

(defthm test-extract-non-local-empty
  (equal (extract-non-local-dep-paths nil) nil)
  :rule-classes nil)

(defthm test-extract-non-local-all-local
  (equal (extract-non-local-dep-paths
          (list (make-book-dep :path "a" :localp t)
                (make-book-dep :path "b" :localp t)))
         nil)
  :rule-classes nil)

(defthm test-extract-non-local-mixed
  (equal (extract-non-local-dep-paths
          (list (make-book-dep :path "a" :localp nil)
                (make-book-dep :path "b" :localp t)
                (make-book-dep :path "c" :localp nil)))
         '("a" "c"))
  :rule-classes nil)

(defthm test-extract-non-local-none-local
  (equal (extract-non-local-dep-paths
          (list (make-book-dep :path "a" :localp nil)
                (make-book-dep :path "b" :localp nil)))
         '("a" "b"))
  :rule-classes nil)

;; ============================================================================
;; Integration: scan + extract
;; ============================================================================

(defthm test-scan-and-extract
  (equal (extract-dep-paths
          (scan-lines-for-deps
           '("(include-book \"a\")"
             "(include-book \"b\")")))
         '("a" "b"))
  :rule-classes nil)

(defthm test-scan-and-extract-non-local
  (equal (extract-non-local-dep-paths
          (scan-lines-for-deps
           '("(include-book \"a\")"
             "(local (include-book \"hidden\"))"
             "(include-book \"b\")")))
         '("a" "b"))
  :rule-classes nil)

;; ============================================================================
;; Tests for split-string-by-char
;; ============================================================================

(defthm test-split-string-basic
  (equal (split-string-by-char "a/b/c" #\/)
         '("a" "b" "c"))
  :rule-classes nil)

(defthm test-split-string-single
  (equal (split-string-by-char "foo" #\/)
         '("foo"))
  :rule-classes nil)

(defthm test-split-string-leading-slash
  (equal (split-string-by-char "/a/b" #\/)
         '("" "a" "b"))
  :rule-classes nil)

(defthm test-split-string-trailing-slash
  ;; Trailing slash results in only the parts before it
  ;; (no empty string at end because implementation stops at end of string)
  (equal (split-string-by-char "a/b/" #\/)
         '("a" "b"))
  :rule-classes nil)

(defthm test-split-string-empty
  (equal (split-string-by-char "" #\/)
         nil)
  :rule-classes nil)

;; ============================================================================
;; Tests for clean-relative-path
;; ============================================================================

(defthm test-clean-relative-path-leading-dot
  (equal (clean-relative-path "./foo/bar")
         "foo/bar")
  :rule-classes nil)

(defthm test-clean-relative-path-no-dot
  (equal (clean-relative-path "foo/bar")
         "foo/bar")
  :rule-classes nil)

(defthm test-clean-relative-path-double-dot
  (equal (clean-relative-path "././foo")
         "foo")
  :rule-classes nil)

;; ============================================================================
;; Tests for compute-relative-path
;; ============================================================================

(defthm test-compute-relative-path-same-dir
  (equal (compute-relative-path "dir/a.html" "dir/b.html")
         "b.html")
  :rule-classes nil)

(defthm test-compute-relative-path-sibling-dirs
  (equal (compute-relative-path "dir1/a.html" "dir2/b.html")
         "../dir2/b.html")
  :rule-classes nil)

(defthm test-compute-relative-path-nested-to-parent
  (equal (compute-relative-path "dir/sub/a.html" "dir/b.html")
         "../b.html")
  :rule-classes nil)

(defthm test-compute-relative-path-parent-to-nested
  (equal (compute-relative-path "dir/a.html" "dir/sub/b.html")
         "sub/b.html")
  :rule-classes nil)

(defthm test-compute-relative-path-deep-to-root
  (equal (compute-relative-path "a/b/c/d.html" "e.html")
         "../../../e.html")
  :rule-classes nil)

(defthm test-compute-relative-path-root-to-deep
  (equal (compute-relative-path "a.html" "x/y/z.html")
         "x/y/z.html")
  :rule-classes nil)

(defthm test-compute-relative-path-books-to-root
  ;; From books/arithmetic/top.html to axioms.html at root
  (equal (compute-relative-path "books/arithmetic/top.html" "axioms.html")
         "../../axioms.html")
  :rule-classes nil)

(defthm test-compute-relative-path-root-to-books
  ;; From axioms.html at root to books/arithmetic/top.html
  (equal (compute-relative-path "axioms.html" "books/arithmetic/top.html")
         "books/arithmetic/top.html")
  :rule-classes nil)

;; ============================================================================
;; Tests for helper functions
;; ============================================================================

(defthm test-make-ups
  (equal (make-ups 3)
         '(".." ".." ".."))
  :rule-classes nil)

(defthm test-make-ups-zero
  (equal (make-ups 0)
         nil)
  :rule-classes nil)

(defthm test-join-with-slash
  (equal (join-with-slash '("a" "b" "c"))
         "a/b/c")
  :rule-classes nil)

(defthm test-join-with-slash-single
  (equal (join-with-slash '("foo"))
         "foo")
  :rule-classes nil)

(defthm test-join-with-slash-empty
  (equal (join-with-slash nil)
         "")
  :rule-classes nil)

(defthm test-common-prefix-length-full
  (equal (common-prefix-length '("a" "b" "c") '("a" "b" "c"))
         3)
  :rule-classes nil)

(defthm test-common-prefix-length-partial
  (equal (common-prefix-length '("a" "b" "c") '("a" "b" "d"))
         2)
  :rule-classes nil)

(defthm test-common-prefix-length-none
  (equal (common-prefix-length '("x" "y") '("a" "b"))
         0)
  :rule-classes nil)

(defthm test-common-prefix-length-empty
  (equal (common-prefix-length nil '("a" "b"))
         0)
  :rule-classes nil)
