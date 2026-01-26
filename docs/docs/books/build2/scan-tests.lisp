; ACL2 Build2 System - Scanner Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "scan")

;; ============================================================================
;; Tests for find-char
;; ============================================================================

(defthm test-find-char-1
  (equal (find-char "hello" #\e 0) 1)
  :rule-classes nil)

(defthm test-find-char-2
  (equal (find-char "hello" #\l 0) 2)
  :rule-classes nil)

(defthm test-find-char-3
  (equal (find-char "hello" #\l 3) 3)
  :rule-classes nil)

(defthm test-find-char-4
  (equal (find-char "hello" #\o 0) 4)
  :rule-classes nil)

(defthm test-find-char-not-found
  (equal (find-char "hello" #\x 0) nil)
  :rule-classes nil)

(defthm test-find-char-past-start
  (equal (find-char "hello" #\h 1) nil)
  :rule-classes nil)

(defthm test-find-char-empty
  (equal (find-char "" #\a 0) nil)
  :rule-classes nil)

;; ============================================================================
;; Tests for extract-quoted-string
;; ============================================================================

(defthm test-extract-quoted-string-basic
  (equal (mv-list 2 (extract-quoted-string "\"foo\"" 0))
         '("foo" 5))
  :rule-classes nil)

(defthm test-extract-quoted-string-middle
  (equal (mv-list 2 (extract-quoted-string "abc\"bar\"xyz" 3))
         '("bar" 8))
  :rule-classes nil)

(defthm test-extract-quoted-string-empty
  (equal (mv-list 2 (extract-quoted-string "\"\"" 0))
         '("" 2))
  :rule-classes nil)

(defthm test-extract-quoted-string-no-quotes
  (equal (mv-list 2 (extract-quoted-string "no quotes" 0))
         '(nil 0))
  :rule-classes nil)

(defthm test-extract-quoted-string-unclosed
  (equal (mv-list 2 (extract-quoted-string "\"unclosed" 0))
         '(nil 0))
  :rule-classes nil)

;; ============================================================================
;; Tests for parse-include-book
;; ============================================================================

;; Basic include-book
(defthm test-parse-basic-include-book
  (let ((dep (parse-include-book "(include-book \"foo\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")
         (not (book-dep->localp dep))))
  :rule-classes nil)

;; Include-book with :dir
(defthm test-parse-include-book-with-dir
  (let ((dep (parse-include-book "(include-book \"std/lists/top\" :dir :system)")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "std/lists/top")
         (not (book-dep->localp dep))))
  :rule-classes nil)

;; Local include-book
(defthm test-parse-local-include-book
  (let ((dep (parse-include-book "(local (include-book \"helper\"))")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "helper")
         (book-dep->localp dep)))
  :rule-classes nil)

;; With leading whitespace
(defthm test-parse-include-book-whitespace
  (let ((dep (parse-include-book "  (include-book \"bar\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "bar")))
  :rule-classes nil)

;; Not an include-book
(defthm test-parse-not-include-book-defun
  (equal (parse-include-book "(defun foo (x) x)") nil)
  :rule-classes nil)

(defthm test-parse-not-include-book-comment
  (equal (parse-include-book "; comment") nil)
  :rule-classes nil)

(defthm test-parse-not-include-book-empty
  (equal (parse-include-book "") nil)
  :rule-classes nil)

;; ============================================================================
;; Tests for scan-lines-for-deps
;; ============================================================================

(defthm test-scan-lines-for-deps
  (let ((deps (scan-lines-for-deps
               '("(in-package \"ACL2\")"
                 "(include-book \"foo\")"
                 "; comment"
                 "(local (include-book \"bar\"))"
                 "(defun test (x) x)"
                 "(include-book \"baz\" :dir :system)"))))
    (and (equal (len deps) 3)
         (equal (book-dep->path (first deps)) "foo")
         (not (book-dep->localp (first deps)))
         (equal (book-dep->path (second deps)) "bar")
         (book-dep->localp (second deps))
         (equal (book-dep->path (third deps)) "baz")
         (not (book-dep->localp (third deps)))))
  :rule-classes nil)

;; Empty input
(defthm test-scan-lines-for-deps-nil
  (equal (scan-lines-for-deps nil) nil)
  :rule-classes nil)

(defthm test-scan-lines-for-deps-no-includes
  (equal (scan-lines-for-deps '("no includes here")) nil)
  :rule-classes nil)
