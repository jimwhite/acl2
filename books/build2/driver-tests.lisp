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
