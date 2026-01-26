; ACL2 Build2 System - Types Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "types")
(include-book "std/testing/assert-equal" :dir :system)

;; ============================================================================
;; Tests for book-dep
;; ============================================================================

;; Construction
(defthm test-book-dep-construction-1
  (book-dep-p (make-book-dep :path "foo" :localp nil))
  :rule-classes nil)

(defthm test-book-dep-construction-2
  (book-dep-p (make-book-dep :path "bar/baz" :localp t))
  :rule-classes nil)

;; Accessors
(defthm test-book-dep-accessors
  (let ((dep (make-book-dep :path "test" :localp t)))
    (and (equal (book-dep->path dep) "test")
         (equal (book-dep->localp dep) t)))
  :rule-classes nil)

;; Change
(defthm test-book-dep-change
  (let* ((dep (make-book-dep :path "old" :localp nil))
         (new-dep (change-book-dep dep :path "new")))
    (and (equal (book-dep->path new-dep) "new")
         (equal (book-dep->localp new-dep) nil)))
  :rule-classes nil)

;; ============================================================================
;; Tests for book-dep-list
;; ============================================================================

(defthm test-book-dep-list-nil
  (book-dep-list-p nil)
  :rule-classes nil)

(defthm test-book-dep-list-single
  (book-dep-list-p (list (make-book-dep :path "a" :localp nil)))
  :rule-classes nil)

(defthm test-book-dep-list-multiple
  (book-dep-list-p (list (make-book-dep :path "a" :localp nil)
                         (make-book-dep :path "b" :localp t)))
  :rule-classes nil)

(defthm test-book-dep-list-not
  (not (book-dep-list-p (list "not a dep")))
  :rule-classes nil)

;; ============================================================================
;; Tests for certinfo
;; ============================================================================

(defthm test-certinfo-empty
  (certinfo-p (make-certinfo :bookdeps nil :srcdeps nil))
  :rule-classes nil)

(defthm test-certinfo-with-data
  (let ((info (make-certinfo 
               :bookdeps (list (make-book-dep :path "foo" :localp nil))
               :srcdeps '("helper.lsp"))))
    (and (certinfo-p info)
         (equal (len (certinfo->bookdeps info)) 1)
         (equal (certinfo->srcdeps info) '("helper.lsp"))))
  :rule-classes nil)

;; ============================================================================
;; Tests for certinfo-alist
;; ============================================================================

(defthm test-certinfo-alist-nil
  (certinfo-alist-p nil)
  :rule-classes nil)

(defthm test-certinfo-alist-entries
  (let ((alist (list (cons "book1" (make-certinfo :bookdeps nil :srcdeps nil))
                     (cons "book2" (make-certinfo :bookdeps nil :srcdeps '("x.lsp"))))))
    (and (certinfo-alist-p alist)
         (equal (len alist) 2)))
  :rule-classes nil)
