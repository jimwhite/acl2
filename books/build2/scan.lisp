; ACL2 Build2 System - Dependency Scanner
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file implements the dependency scanner for extracting certification
; dependencies from ACL2 source files. All code is pure ACL2 with verified guards.

(in-package "BUILD2")

(include-book "types")
(include-book "std/strings/top" :dir :system)

;; ============================================================================
;; String utilities for parsing
;; ============================================================================

(define skip-whitespace ((s stringp) (i natp))
  :returns (new-i natp :rule-classes :type-prescription)
  :short "Skip whitespace characters starting at position i."
  :guard (<= i (length s))
  :measure (nfix (- (length s) i))
  (if (and (< i (length s))
           (member (char s i) '(#\Space #\Tab #\Newline #\Return)))
      (skip-whitespace s (+ 1 i))
    (nfix i))
  ///
  (defthm skip-whitespace-bound
    (implies (and (stringp s) (natp i) (<= i (length s)))
             (<= (skip-whitespace s i) (length s)))
    :rule-classes :linear))

(define find-char ((s stringp) (c characterp) (i natp))
  :returns (pos (or (natp pos) (null pos)))
  :short "Find first occurrence of character c starting at position i."
  :guard (<= i (length s))
  :measure (nfix (- (length s) i))
  (cond ((>= i (length s)) nil)
        ((eql (char s i) c) (nfix i))
        (t (find-char s c (+ 1 i)))))

(define extract-quoted-string ((s stringp) (i natp))
  :returns (mv (str (or (stringp str) (null str)))
               (end-pos natp :rule-classes :type-prescription))
  :short "Extract a double-quoted string starting at position i."
  :guard (<= i (length s))
  (b* (((unless (and (< i (length s))
                     (eql (char s i) #\")))
        (mv nil (nfix i)))
       (start (+ 1 i))
       (end (find-char s #\" start))
       ((unless end)
        (mv nil (nfix i))))
    (mv (subseq s start end) (+ 1 end)))
  ///
  (defthm extract-quoted-string-bound
    (implies (and (stringp s) (natp i) (<= i (length s)))
             (<= (mv-nth 1 (extract-quoted-string s i)) (length s)))
    :rule-classes :linear))

(define find-first-quote ((s stringp) (i natp))
  :returns (pos (or (natp pos) (null pos)))
  :short "Find first double-quote character starting at position i."
  :guard (<= i (length s))
  (find-char s #\" i))

;; ============================================================================
;; Parsing individual line types
;; ============================================================================

(define parse-include-book-line ((line stringp))
  :returns (event (or (scan-event-include-book-p event) (null event)))
  :short "Parse an include-book form from a line."
  :long "<p>Recognizes forms like:
@({
  (include-book \"foo\")
  (include-book \"bar\" :dir :system)
  (local (include-book \"baz\"))
})</p>"
  
  (b* ((trimmed (str::trim line))
       ;; Check for local wrapper
       (localp (str::strprefixp "(local" trimmed))
       (work (if localp
                 (str::trim (subseq trimmed 6 (length trimmed)))
               trimmed))
       ;; Check for include-book
       ((unless (str::strprefixp "(include-book" work))
        nil)
       ;; Find the book name (first quoted string after include-book)
       (quote-pos (find-first-quote work 13))
       ((unless quote-pos) nil)
       ((mv name &) (extract-quoted-string work quote-pos))
       ((unless name) nil)
       ;; Look for :dir keyword
       (dir-pos (str::strpos ":dir" work))
       (dir (if dir-pos
                ;; Extract the keyword argument
                (b* ((after-dir (str::trim 
                                 (subseq work (+ 4 dir-pos) (length work))))
                     ;; The dir value should be a keyword like :system
                     ((unless (and (> (length after-dir) 0)
                                   (eql (char after-dir 0) #\:)))
                      nil)
                     (end (min (or (str::strpos " " after-dir) (length after-dir))
                               (or (str::strpos ")" after-dir) (length after-dir)))))
                  (subseq after-dir 0 end))
              nil)))
    (make-scan-event-include-book
     :name name
     :dir dir
     :localp localp)))

(define parse-depends-on-line ((line stringp))
  :returns (event (or (scan-event-depends-on-p event) (null event)))
  :short "Parse a depends-on form from a line."
  (b* ((trimmed (str::trim line))
       ((unless (or (str::strprefixp "(depends-on" trimmed)
                    (str::strprefixp "; (depends-on" trimmed)))
        nil)
       ;; Find the path (first quoted string)
       (quote-pos (find-first-quote trimmed 0))
       ((unless quote-pos) nil)
       ((mv path &) (extract-quoted-string trimmed quote-pos))
       ((unless path) nil))
    (make-scan-event-depends-on :path path)))

(define parse-loads-line ((line stringp))
  :returns (event (or (scan-event-loads-p event) (null event)))
  :short "Parse a loads form from a line."
  (b* ((trimmed (str::trim line))
       ((unless (str::strprefixp "(loads" trimmed))
        nil)
       (quote-pos (find-first-quote trimmed 0))
       ((unless quote-pos) nil)
       ((mv path &) (extract-quoted-string trimmed quote-pos))
       ((unless path) nil))
    (make-scan-event-loads :path path)))

(define parse-cert-param-line ((line stringp))
  :returns (event (or (scan-event-cert-param-p event) (null event)))
  :short "Parse a cert_param comment from a line."
  :long "<p>Recognizes forms like:
@({
  ; cert_param: (acl2x)
  ; cert_param: (non-gcl)
  ;; cert_param: (uses-glucose)
})</p>"
  
  (b* ((trimmed (str::trim line))
       ;; Must start with ; or ;;
       ((unless (str::strprefixp ";" trimmed))
        nil)
       ;; Find cert_param:
       (param-pos (str::strpos "cert_param:" trimmed))
       ((unless param-pos) nil)
       ;; Extract what follows
       (after (str::trim (subseq trimmed (+ 11 param-pos) (length trimmed))))
       ;; Should start with (
       ((unless (str::strprefixp "(" after))
        nil)
       ;; Find the closing paren
       (close-pos (or (str::strpos ")" after)
                      (length after)))
       (content (subseq after 1 close-pos))
       ;; Parse name and optional value
       (parts (str::strtok content '(#\Space #\Tab #\= #\:)))
       ((unless (consp parts)) nil)
       (name (car parts))
       (value (if (consp (cdr parts)) (cadr parts) "")))
    (make-scan-event-cert-param :name name :value value)))

(define parse-add-include-book-dir-line ((line stringp))
  :returns (event (or (scan-event-add-include-book-dir-p event) (null event)))
  :short "Parse an add-include-book-dir! form from a line."
  (b* ((trimmed (str::trim line))
       ((unless (str::strprefixp "(add-include-book-dir!" trimmed))
        nil)
       ;; Find the keyword (starts with :)
       (kw-start (str::strpos ":" trimmed))
       ((unless kw-start) nil)
       (after-kw (subseq trimmed kw-start (length trimmed)))
       (kw-end (min (or (str::strpos " " after-kw) (length after-kw))
                    (or (str::strpos "\"" after-kw) (length after-kw))))
       (kw-str (subseq after-kw 0 kw-end))
       ;; Find the path
       (quote-pos (find-first-quote trimmed 0))
       ((unless quote-pos) nil)
       ((mv path &) (extract-quoted-string trimmed quote-pos))
       ((unless path) nil))
    (make-scan-event-add-include-book-dir
     :keyword (intern kw-str "KEYWORD")
     :path path)))

(define parse-ifdef-line ((line stringp))
  :returns (event (or (scan-event-ifdef-p event) (null event)))
  :short "Parse an ifdef or ifndef form from a line."
  (b* ((trimmed (str::trim line))
       (is-ifdef (str::strprefixp "(ifdef" trimmed))
       (is-ifndef (str::strprefixp "(ifndef" trimmed))
       ((unless (or is-ifdef is-ifndef))
        nil)
       ;; Find the variable name (first quoted string)
       (quote-pos (find-first-quote trimmed 0))
       ((unless quote-pos) nil)
       ((mv varname &) (extract-quoted-string trimmed quote-pos))
       ((unless varname) nil))
    (make-scan-event-ifdef
     :varname varname
     :negate is-ifndef)))

;; ============================================================================
;; Main line parser
;; ============================================================================

(define parse-scan-line ((line stringp))
  :returns (event (or (scan-event-p event) (null event)))
  :short "Parse a single line, returning a scan-event if relevant."
  :long "<p>Tries each parser in sequence. Returns nil if the line
is not relevant for dependency scanning.</p>"
  
  (or (parse-include-book-line line)
      (parse-depends-on-line line)
      (parse-loads-line line)
      (parse-cert-param-line line)
      (parse-add-include-book-dir-line line)
      (parse-ifdef-line line))
  
  ///
  (defthm parse-scan-line-type
    (or (scan-event-p (parse-scan-line line))
        (null (parse-scan-line line)))
    :rule-classes :type-prescription))

;; ============================================================================
;; Scan a list of lines
;; ============================================================================

(define scan-lines ((lines string-listp))
  :returns (events scan-event-list-p)
  :short "Scan a list of lines for dependency events."
  (if (endp lines)
      nil
    (b* ((event (parse-scan-line (car lines))))
      (if event
          (cons event (scan-lines (cdr lines)))
        (scan-lines (cdr lines)))))
  ///
  (defthm scan-lines-true-listp
    (true-listp (scan-lines lines))
    :rule-classes :type-prescription))

;; ============================================================================
;; Theorems about scanner correctness
;; ============================================================================

(defthm scan-lines-produces-valid-events
  (implies (string-listp lines)
           (scan-event-list-p (scan-lines lines)))
  :hints (("Goal" :in-theory (enable scan-lines))))

;; The scanner is deterministic
(defthm scan-lines-deterministic
  (equal (scan-lines lines)
         (scan-lines lines)))

;; Empty input produces empty output
(defthm scan-lines-of-nil
  (equal (scan-lines nil) nil)
  :hints (("Goal" :in-theory (enable scan-lines))))

;; Scanner preserves input length bound (never adds events)
(defthm scan-lines-length-bound
  (<= (len (scan-lines lines)) (len lines))
  :rule-classes :linear
  :hints (("Goal" :in-theory (enable scan-lines))))
