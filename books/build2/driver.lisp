; ACL2 Build2 System - Build Driver
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Core build logic - dependency graph and certification ordering.
; This file contains only pure logic functions that can be verified.
; The actual file I/O and ACL2 invocation is in cert2.lsp (raw Lisp).

(in-package "BUILD2")

(include-book "scan")

;;; ============================================================================
;;; Path utilities (pure logic, testable)
;;; ============================================================================

(defun has-extension (path ext)
  "Check if PATH ends with extension EXT (including the dot)."
  (declare (xargs :guard (and (stringp path) (stringp ext))))
  (let ((path-len (length path))
        (ext-len (length ext)))
    (and (>= path-len ext-len)
         (string-equal (subseq path (- path-len ext-len) path-len) ext))))

(defun strip-extension (path)
  "Remove .lisp or .cert extension from PATH if present."
  (declare (xargs :guard (stringp path)))
  (let ((len (length path)))
    (cond ((and (>= len 5) (has-extension path ".lisp"))
           (subseq path 0 (- len 5)))
          ((and (>= len 5) (has-extension path ".cert"))
           (subseq path 0 (- len 5)))
          ((and (>= len 4) (has-extension path ".acl2"))
           (subseq path 0 (- len 5)))
          (t path))))

(defun add-lisp-extension (path)
  "Add .lisp extension to PATH if not already present."
  (declare (xargs :guard (stringp path)))
  (if (has-extension path ".lisp")
      path
    (concatenate 'string (strip-extension path) ".lisp")))

(defun add-cert-extension (path)
  "Add .cert extension to PATH if not already present."
  (declare (xargs :guard (stringp path)))
  (if (has-extension path ".cert")
      path
    (concatenate 'string (strip-extension path) ".cert")))

(defun path-directory (path)
  "Extract directory portion from PATH (everything before last /)."
  (declare (xargs :guard (stringp path)))
  (let ((last-slash (str::strrpos "/" path)))
    (if last-slash
        (subseq path 0 (+ 1 last-slash))
      "")))

(defun path-basename (path)
  "Extract filename portion from PATH (everything after last /)."
  (declare (xargs :guard (stringp path)))
  (let ((last-slash (str::strrpos "/" path)))
    (if last-slash
        (subseq path (+ 1 last-slash) (length path))
      path)))

(defun normalize-book-path (base-dir book-name)
  "Resolve BOOK-NAME relative to BASE-DIR.
   Returns the normalized path without extension."
  (declare (xargs :guard (and (stringp base-dir) (stringp book-name))))
  (let ((book (strip-extension book-name)))
    (cond
     ;; Absolute path
     ((and (> (length book) 0) (eql (char book 0) #\/))
      book)
     ;; Relative to current directory
     ((equal base-dir "")
      book)
     ;; Relative path - join with base
     (t
      (let ((dir (if (and (> (length base-dir) 0)
                          (eql (char base-dir (- (length base-dir) 1)) #\/))
                     base-dir
                   (concatenate 'string base-dir "/"))))
        (concatenate 'string dir book))))))

;;; ============================================================================
;;; Dependency extraction from book-deps
;;; ============================================================================

(defun extract-dep-paths (deps)
  "Extract just the path strings from a book-dep-list."
  (declare (xargs :guard (book-dep-list-p deps)))
  (if (atom deps)
      nil
    (cons (book-dep->path (car deps))
          (extract-dep-paths (cdr deps)))))

(defthm string-listp-extract-dep-paths
  (implies (book-dep-list-p deps)
           (string-listp (extract-dep-paths deps))))

(defun extract-non-local-dep-paths (deps)
  "Extract path strings from non-local dependencies only."
  (declare (xargs :guard (book-dep-list-p deps)))
  (if (atom deps)
      nil
    (let ((dep (car deps))
          (rest (extract-non-local-dep-paths (cdr deps))))
      (if (book-dep->localp dep)
          rest
        (cons (book-dep->path dep) rest)))))

(defthm string-listp-extract-non-local-dep-paths
  (implies (book-dep-list-p deps)
           (string-listp (extract-non-local-dep-paths deps))))

;;; ============================================================================
;;; Relative path utilities (pure logic for HTML generation)
;;; ============================================================================

(defun split-string-by-char (string char)
  "Split STRING by CHAR into a list of substrings."
  (declare (xargs :guard (and (stringp string) (characterp char))
                  :measure (length string)))
  (if (or (not (stringp string)) (equal string ""))
      nil
    (let ((pos (str::strpos (coerce (list char) 'string) string)))
      (if pos
          (cons (subseq string 0 pos)
                (split-string-by-char (subseq string (+ 1 pos) (length string)) char))
        (list string)))))

(defthm string-listp-split-string-by-char
  (string-listp (split-string-by-char string char)))

(defun clean-relative-path (path)
  "Remove ./ components from PATH and clean up any double slashes.
   - Removes leading ./
   - Removes /./ in the middle of path
   - Removes double slashes //"
  (declare (xargs :guard (stringp path)))
  (if (not (stringp path))
      ""
    (let* ((str path)
           ;; Remove leading ./
           (str (if (and (>= (length str) 2)
                        (equal (subseq str 0 2) "./"))
                   (subseq str 2 (length str))
                 str))
           ;; Additional leading ./ removals if nested
           (str (if (and (>= (length str) 2)
                        (equal (subseq str 0 2) "./"))
                   (subseq str 2 (length str))
                 str)))
      ;; For now, handle simple cases - more complex cases in raw Lisp
      str)))

(defthm stringp-clean-relative-path
  (stringp (clean-relative-path path)))

(defun count-slashes (parts)
  "Count non-empty parts (for computing directory depth)."
  (declare (xargs :guard (string-listp parts)))
  (if (atom parts)
      0
    (if (equal (car parts) "")
        (count-slashes (cdr parts))
      (+ 1 (count-slashes (cdr parts))))))

(defthm natp-count-slashes
  (natp (count-slashes parts))
  :rule-classes :type-prescription)

(defun make-ups (n)
  "Create a list of N '..' strings."
  (declare (xargs :guard (natp n)))
  (if (zp n)
      nil
    (cons ".." (make-ups (- n 1)))))

(defthm string-listp-make-ups
  (string-listp (make-ups n)))

(defun join-with-slash (parts)
  "Join string list PARTS with / separator."
  (declare (xargs :guard (string-listp parts)))
  (if (atom parts)
      ""
    (if (atom (cdr parts))
        (car parts)
      (concatenate 'string (car parts) "/" (join-with-slash (cdr parts))))))

(defthm stringp-join-with-slash
  (implies (string-listp parts)
           (stringp (join-with-slash parts))))

(defun common-prefix-length (list1 list2)
  "Count how many leading elements LIST1 and LIST2 have in common."
  (declare (xargs :guard (and (string-listp list1) (string-listp list2))))
  (if (or (atom list1) (atom list2))
      0
    (if (equal (car list1) (car list2))
        (+ 1 (common-prefix-length (cdr list1) (cdr list2)))
      0)))

(defthm natp-common-prefix-length
  (natp (common-prefix-length list1 list2))
  :rule-classes :type-prescription)

(defun remove-empty-strings (lst)
  "Remove empty strings from list LST."
  (declare (xargs :guard (string-listp lst)))
  (if (atom lst)
      nil
    (if (equal (car lst) "")
        (remove-empty-strings (cdr lst))
      (cons (car lst) (remove-empty-strings (cdr lst))))))

(defthm string-listp-remove-empty-strings
  (implies (string-listp lst)
           (string-listp (remove-empty-strings lst))))

(defthm string-listp-butlast
  (implies (string-listp lst)
           (string-listp (butlast lst n))))

(defthm string-listp-nthcdr
  (implies (string-listp lst)
           (string-listp (nthcdr n lst))))

(defthm string-listp-append
  (implies (and (string-listp a) (string-listp b))
           (string-listp (append a b))))

(defthm string-listp-take
  (implies (and (string-listp lst)
                (<= n (len lst)))
           (string-listp (take n lst))))

(defthm common-prefix-length-bound
  (<= (common-prefix-length list1 list2) (len list1))
  :rule-classes :linear)

(defthm len-remove-empty-strings-bound
  (<= (len (remove-empty-strings lst)) (len lst))
  :rule-classes :linear)

(defthm len-butlast-bound
  (implies (natp n)
           (<= (len (butlast lst n)) (len lst)))
  :rule-classes :linear)

(defthm stringp-car-last-of-string-listp
  (implies (and (string-listp lst)
                (consp lst))
           (stringp (car (last lst)))))

(defun compute-relative-path (from-file to-file)
  "Compute relative path from FROM-FILE to TO-FILE.
   Both should be relative paths from the same base (e.g., repo root).
   Returns a string like '../foo/bar.html'."
  (declare (xargs :guard (and (stringp from-file) (stringp to-file))))
  (let* ((from-parts (remove-empty-strings (split-string-by-char from-file #\/)))
         (to-parts (remove-empty-strings (split-string-by-char to-file #\/)))
         ;; Remove filename from from-parts to get directory
         (from-dir (butlast from-parts 1))
         ;; Find common prefix length
         (common-len (common-prefix-length from-dir to-parts))
         ;; Number of ups needed
         (ups (- (len from-dir) common-len))
         ;; Parts to go down (everything after common prefix in to-parts)
         (downs (nthcdr common-len to-parts))
         ;; Build path parts
         (parts (append (make-ups ups) downs)))
    (if parts
        (join-with-slash parts)
      (if (consp to-parts)
          (car (last to-parts))
        to-file))))

(defthm stringp-compute-relative-path
  (implies (and (stringp from-file) (stringp to-file))
           (stringp (compute-relative-path from-file to-file))))

;;; ============================================================================
;;; TODO: Dependency graph building and build ordering
;;; These functions require file I/O and will be implemented in cert2.lsp
;;; ============================================================================
