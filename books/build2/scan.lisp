; ACL2 Build2 System - Dependency Scanner
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Simple dependency scanner - extracts include-book forms from source files.

(in-package "BUILD2")

(include-book "types")
(include-book "std/strings/top" :dir :system)

;; ============================================================================
;; String utilities
;; ============================================================================

;; Simple character search in string starting at position i
(defun find-char (s c i)
  (declare (xargs :guard (and (stringp s) (characterp c) (natp i))
                  :measure (nfix (- (length s) (nfix i)))))
  (let ((i (nfix i)))
    (cond ((>= i (length s)) nil)
          ((eql (char s i) c) i)
          (t (find-char s c (+ 1 i))))))

(defthm find-char-type
  (or (natp (find-char s c i))
      (null (find-char s c i)))
  :rule-classes :type-prescription)

(defthm find-char-bound
  (implies (find-char s c i)
           (< (find-char s c i) (length s)))
  :rule-classes :linear)

(defthm find-char-lower-bound
  (implies (find-char s c i)
           (<= (nfix i) (find-char s c i)))
  :rule-classes :linear)

;; Extract a quoted string starting at position i (which should be #\")
(defun extract-quoted-string (s i)
  (declare (xargs :guard (and (stringp s) (natp i))))
  (let* ((len (length s))
         (i (nfix i)))
    (cond ((>= i len) (mv nil i))
          ((not (eql (char s i) #\")) (mv nil i))
          (t (let* ((start (+ 1 i))
                    (end (find-char s #\" start)))
               (if end
                   (mv (subseq s start end) (+ 1 end))
                 (mv nil i)))))))

;; ============================================================================
;; Parse include-book from a line
;; ============================================================================

(defun parse-include-book (line)
  (declare (xargs :guard (stringp line)))
  (let* ((trimmed (str::trim line))
         (trimmed-len (length trimmed))
         ;; Check for local wrapper - must have at least 7 chars: "(local "
         (localp (and (>= trimmed-len 7)
                      (str::strprefixp "(local" trimmed)))
         (work (if localp
                   (str::trim (subseq trimmed 6 trimmed-len))
                 trimmed)))
    ;; Must start with (include-book
    (if (not (str::strprefixp "(include-book" work))
        nil
      (let ((quote-pos (find-char work #\" 0)))
        (if (not quote-pos)
            nil
          (mv-let (name end-pos)
            (extract-quoted-string work quote-pos)
            (declare (ignore end-pos))
            (if name
                (make-book-dep :path name :localp localp)
              nil)))))))

(defthm parse-include-book-type
  (implies (parse-include-book line)
           (book-dep-p (parse-include-book line)))
  :rule-classes (:rewrite :type-prescription))

;; ============================================================================
;; Scan lines for dependencies
;; ============================================================================

(defun scan-lines-for-deps (lines)
  (declare (xargs :guard (string-listp lines)))
  (if (atom lines)
      nil
    (let ((dep (parse-include-book (car lines)))
          (rest (scan-lines-for-deps (cdr lines))))
      (if dep
          (cons dep rest)
        rest))))

(defthm scan-lines-for-deps-type
  (book-dep-list-p (scan-lines-for-deps lines)))
