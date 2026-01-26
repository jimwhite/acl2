; ACL2 Build2 System - Comprehensive Scanner Tests
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; More thorough tests for the scanner, covering edge cases.

(in-package "BUILD2")

(include-book "scan")

;; ============================================================================
;; find-char edge cases
;; ============================================================================

;; Finding at position 0
(defthm test-find-char-at-zero
  (equal (find-char "abc" #\a 0) 0)
  :rule-classes nil)

;; Finding at last position
(defthm test-find-char-at-end
  (equal (find-char "abc" #\c 0) 2)
  :rule-classes nil)

;; Character not in string
(defthm test-find-char-missing
  (equal (find-char "abc" #\z 0) nil)
  :rule-classes nil)

;; Start past the character
(defthm test-find-char-start-past
  (equal (find-char "abc" #\a 1) nil)
  :rule-classes nil)

;; Multiple occurrences - finds first from start
(defthm test-find-char-multiple
  (equal (find-char "abab" #\a 0) 0)
  :rule-classes nil)

(defthm test-find-char-multiple-from-1
  (equal (find-char "abab" #\a 1) 2)
  :rule-classes nil)

;; Start at exact length (edge case)
(defthm test-find-char-start-at-length
  (equal (find-char "abc" #\a 3) nil)
  :rule-classes nil)

;; Start past length
(defthm test-find-char-start-past-length
  (equal (find-char "abc" #\a 10) nil)
  :rule-classes nil)

;; Special characters
(defthm test-find-char-space
  (equal (find-char "a b c" #\Space 0) 1)
  :rule-classes nil)

(defthm test-find-char-quote
  (equal (find-char "a\"b" #\" 0) 1)
  :rule-classes nil)

(defthm test-find-char-paren
  (equal (find-char "(test)" #\( 0) 0)
  :rule-classes nil)

;; ============================================================================
;; extract-quoted-string edge cases  
;; ============================================================================

;; Normal case
(defthm test-extract-normal
  (equal (mv-list 2 (extract-quoted-string "\"hello\"" 0))
         '("hello" 7))
  :rule-classes nil)

;; Empty quoted string
(defthm test-extract-empty-string
  (equal (mv-list 2 (extract-quoted-string "\"\"" 0))
         '("" 2))
  :rule-classes nil)

;; String with spaces
(defthm test-extract-with-spaces
  (equal (mv-list 2 (extract-quoted-string "\"hello world\"" 0))
         '("hello world" 13))
  :rule-classes nil)

;; String with special chars
(defthm test-extract-special-chars
  (equal (mv-list 2 (extract-quoted-string "\"foo/bar\"" 0))
         '("foo/bar" 9))
  :rule-classes nil)

;; Not starting at quote
(defthm test-extract-not-at-quote
  (equal (mv-list 2 (extract-quoted-string "abc\"def\"" 0))
         '(nil 0))
  :rule-classes nil)

;; Starting mid-string at quote
(defthm test-extract-mid-string
  (equal (mv-list 2 (extract-quoted-string "abc\"def\"xyz" 3))
         '("def" 8))
  :rule-classes nil)

;; Unclosed quote
(defthm test-extract-unclosed
  (equal (mv-list 2 (extract-quoted-string "\"unclosed" 0))
         '(nil 0))
  :rule-classes nil)

;; Start past end
(defthm test-extract-past-end
  (equal (mv-list 2 (extract-quoted-string "\"hi\"" 10))
         '(nil 10))
  :rule-classes nil)

;; ============================================================================
;; parse-include-book - comprehensive cases
;; ============================================================================

;; Basic forms
(defthm test-parse-basic
  (let ((dep (parse-include-book "(include-book \"foo\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")
         (not (book-dep->localp dep))))
  :rule-classes nil)

;; With path separators
(defthm test-parse-with-path
  (let ((dep (parse-include-book "(include-book \"std/lists/top\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "std/lists/top")))
  :rule-classes nil)

;; With :dir :system
(defthm test-parse-dir-system
  (let ((dep (parse-include-book "(include-book \"std/util/define\" :dir :system)")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "std/util/define")))
  :rule-classes nil)

;; With :dir :teachpacks  
(defthm test-parse-dir-other
  (let ((dep (parse-include-book "(include-book \"foo\" :dir :teachpacks)")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")))
  :rule-classes nil)

;; Local wrapper
(defthm test-parse-local
  (let ((dep (parse-include-book "(local (include-book \"helper\"))")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "helper")
         (book-dep->localp dep)))
  :rule-classes nil)

;; Local with path
(defthm test-parse-local-with-path
  (let ((dep (parse-include-book "(local (include-book \"tools/flag\"))")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "tools/flag")
         (book-dep->localp dep)))
  :rule-classes nil)

;; Leading whitespace
(defthm test-parse-leading-space
  (let ((dep (parse-include-book "  (include-book \"foo\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")))
  :rule-classes nil)

;; Leading tabs
(defthm test-parse-leading-tabs
  (let ((dep (parse-include-book "		(include-book \"foo\")")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")))
  :rule-classes nil)

;; Trailing content (options)
(defthm test-parse-with-options
  (let ((dep (parse-include-book "(include-book \"foo\" :skip-proofs-okp t)")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")))
  :rule-classes nil)

;; Multiple options
(defthm test-parse-multiple-options
  (let ((dep (parse-include-book "(include-book \"foo\" :dir :system :ttags :all)")))
    (and (book-dep-p dep)
         (equal (book-dep->path dep) "foo")))
  :rule-classes nil)

;; ============================================================================
;; parse-include-book - negative cases (should return nil)
;; ============================================================================

;; Not an include-book
(defthm test-parse-not-include-defun
  (null (parse-include-book "(defun foo (x) x)"))
  :rule-classes nil)

(defthm test-parse-not-include-defthm
  (null (parse-include-book "(defthm my-thm (equal x x))"))
  :rule-classes nil)

;; Comment line
(defthm test-parse-comment
  (null (parse-include-book "; (include-book \"foo\")"))
  :rule-classes nil)

;; Empty line
(defthm test-parse-empty
  (null (parse-include-book ""))
  :rule-classes nil)

;; Whitespace only
(defthm test-parse-whitespace-only
  (null (parse-include-book "   "))
  :rule-classes nil)

;; include-book without quote (malformed)
(defthm test-parse-no-quote
  (null (parse-include-book "(include-book foo)"))
  :rule-classes nil)

;; Partial match - "include-boo"
(defthm test-parse-partial
  (null (parse-include-book "(include-boo \"foo\")"))
  :rule-classes nil)

;; Just the word include-book  
(defthm test-parse-just-word
  (null (parse-include-book "include-book"))
  :rule-classes nil)

;; ============================================================================
;; scan-lines-for-deps - integration tests
;; ============================================================================

;; Typical file header
(defthm test-scan-typical-file
  (let ((deps (scan-lines-for-deps
               '("; My Book"
                 "; Copyright 2026"
                 ""
                 "(in-package \"ACL2\")"
                 ""
                 "(include-book \"std/util/define\" :dir :system)"
                 "(include-book \"std/strings/top\" :dir :system)"
                 "(local (include-book \"std/testing/assert-equal\" :dir :system))"
                 ""
                 "(defun my-fn (x) x)"))))
    (and (equal (len deps) 3)
         (equal (book-dep->path (first deps)) "std/util/define")
         (equal (book-dep->path (second deps)) "std/strings/top")
         (equal (book-dep->path (third deps)) "std/testing/assert-equal")
         (not (book-dep->localp (first deps)))
         (not (book-dep->localp (second deps)))
         (book-dep->localp (third deps))))
  :rule-classes nil)

;; File with only comments
(defthm test-scan-only-comments
  (equal (scan-lines-for-deps
          '("; comment 1"
            "; comment 2"
            "; (include-book \"foo\")"))
         nil)
  :rule-classes nil)

;; File with no includes
(defthm test-scan-no-includes
  (equal (scan-lines-for-deps
          '("(in-package \"ACL2\")"
            "(defun foo (x) x)"
            "(defthm foo-id (equal (foo x) x))"))
         nil)
  :rule-classes nil)

;; Order preservation
(defthm test-scan-order-preserved
  (let ((deps (scan-lines-for-deps
               '("(include-book \"a\")"
                 "(include-book \"b\")"  
                 "(include-book \"c\")"))))
    (and (equal (book-dep->path (first deps)) "a")
         (equal (book-dep->path (second deps)) "b")
         (equal (book-dep->path (third deps)) "c")))
  :rule-classes nil)

;; Mixed local and non-local
(defthm test-scan-mixed-local
  (let ((deps (scan-lines-for-deps
               '("(include-book \"a\")"
                 "(local (include-book \"b\"))"
                 "(include-book \"c\")"
                 "(local (include-book \"d\"))"))))
    (and (equal (len deps) 4)
         (not (book-dep->localp (first deps)))
         (book-dep->localp (second deps))
         (not (book-dep->localp (third deps)))
         (book-dep->localp (fourth deps))))
  :rule-classes nil)
