; ACL2 Build2 System - Data Structures
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Core data structures for basic book certification.

(in-package "BUILD2")

(include-book "centaur/fty/top" :dir :system)

;; ============================================================================
;; Book dependency - just path and whether it's local
;; ============================================================================

(fty::defprod book-dep
  :short "A dependency on another book."
  ((path   stringp "Path to the book (without .lisp extension).")
   (localp booleanp :default nil "Was this inside LOCAL?"))
  :tag :book-dep)

(fty::deflist book-dep-list
  :elt-type book-dep
  :true-listp t)

;; ============================================================================
;; Certinfo - what we need to know to certify a book
;; ============================================================================

(fty::defprod certinfo
  :short "Information needed to certify a book."
  ((bookdeps book-dep-list-p :default nil
             "Books this book depends on (from include-book).")
   (srcdeps string-listp :default nil
            "Source files (.lisp, .acl2 files)."))
  :tag :certinfo)

;; ============================================================================
;; Alist mapping book paths to certinfo
;; ============================================================================

(fty::defalist certinfo-alist
  :key-type stringp
  :val-type certinfo
  :true-listp t)
