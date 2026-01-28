; JSON-LD Tests - Theorem Driven Development
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This book contains test theorems verifying the JSON-LD serialization
; functions satisfy their required specifications.

(in-package "BUILD2")

(include-book "jsonld-vocab")

;;;============================================================================
;;; Test Forms
;;;============================================================================

;; Example defun for testing
(defconst *test-defun-form*
  '(defun append (x y)
     (declare (xargs :guard (true-listp x)))
     (if (endp x)
         y
       (cons (car x) (append (cdr x) y)))))

;; Example defthm for testing
(defconst *test-defthm-form*
  '(defthm append-assoc
     (equal (append (append x y) z)
            (append x (append y z)))))

;; Example defthm with hints
(defconst *test-defthm-hints-form*
  '(defthm len-append
     (equal (len (append x y))
            (+ (len x) (len y)))
     :hints (("Goal" :induct (append x y)))))

;; Example defmacro
(defconst *test-defmacro-form*
  '(defmacro my-and (x y)
     `(if ,x ,y nil)))

;; Example encapsulate
(defconst *test-encapsulate-form*
  '(encapsulate
    ((foo (x) t))
    (local (defun foo (x) x))
    (defthm foo-type (booleanp (foo x)))))

;;;============================================================================
;;; Form Type Detection Tests
;;;============================================================================

(defthm test-form-type-defun
  (equal (form-type-keyword *test-defun-form*) :defun)
  :hints (("Goal" :in-theory (enable form-type-keyword)))
  :rule-classes nil)

(defthm test-form-type-defthm
  (equal (form-type-keyword *test-defthm-form*) :defthm)
  :hints (("Goal" :in-theory (enable form-type-keyword)))
  :rule-classes nil)

(defthm test-form-type-defmacro
  (equal (form-type-keyword *test-defmacro-form*) :defmacro)
  :hints (("Goal" :in-theory (enable form-type-keyword)))
  :rule-classes nil)

(defthm test-form-type-encapsulate
  (equal (form-type-keyword *test-encapsulate-form*) :encapsulate)
  :hints (("Goal" :in-theory (enable form-type-keyword)))
  :rule-classes nil)

;;;============================================================================
;;; Name Extraction Tests
;;;============================================================================

(defthm test-get-name-defun
  (equal (get-defined-name *test-defun-form*) 'append)
  :hints (("Goal" :in-theory (enable get-defined-name form-type-keyword)))
  :rule-classes nil)

(defthm test-get-name-defthm
  (equal (get-defined-name *test-defthm-form*) 'append-assoc)
  :hints (("Goal" :in-theory (enable get-defined-name form-type-keyword)))
  :rule-classes nil)

(defthm test-get-name-defmacro
  (equal (get-defined-name *test-defmacro-form*) 'my-and)
  :hints (("Goal" :in-theory (enable get-defined-name form-type-keyword)))
  :rule-classes nil)

;;;============================================================================
;;; Defun Parsing Tests
;;;============================================================================

(defthm test-parse-defun-formals
  (equal (parse-defun-formals *test-defun-form*) '(x y))
  :hints (("Goal" :in-theory (enable parse-defun-formals)))
  :rule-classes nil)

;; Test that body is extracted (after declares)
(defthm test-parse-defun-body-structure
  (consp (parse-defun-body *test-defun-form*))
  :hints (("Goal" :in-theory (enable parse-defun-body skip-declares)))
  :rule-classes nil)

;;;============================================================================
;;; Defthm Parsing Tests  
;;;============================================================================

(defthm test-parse-defthm-term-structure
  (consp (parse-defthm-term *test-defthm-form*))
  :hints (("Goal" :in-theory (enable parse-defthm-term)))
  :rule-classes nil)

(defthm test-parse-defthm-hints
  (consp (parse-defthm-hints *test-defthm-hints-form*))
  :hints (("Goal" :in-theory (enable parse-defthm-hints get-keyword-value)))
  :rule-classes nil)

;;;============================================================================
;;; Symbol Collection Tests
;;;============================================================================

(defthm test-collect-symbols-includes-all
  (let ((syms (collect-form-symbols '(foo bar baz) nil)))
    (and (member-eq 'foo syms)
         (member-eq 'bar syms)
         (member-eq 'baz syms)))
  :hints (("Goal" :in-theory (enable collect-form-symbols acl2-symbolp)))
  :rule-classes nil)

(defthm test-collect-symbols-nested
  (let ((syms (collect-form-symbols '(if (foo x) (bar y) (baz z)) nil)))
    (and (member-eq 'if syms)
         (member-eq 'foo syms)
         (member-eq 'bar syms)
         (member-eq 'baz syms)
         (member-eq 'x syms)
         (member-eq 'y syms)
         (member-eq 'z syms)))
  :hints (("Goal" :in-theory (enable collect-form-symbols acl2-symbolp)))
  :rule-classes nil)

(defthm test-collect-symbols-no-keywords
  (let ((syms (collect-form-symbols '(:foo :bar x) nil)))
    (and (not (member-eq :foo syms))
         (not (member-eq :bar syms))
         (member-eq 'x syms)))
  :hints (("Goal" :in-theory (enable collect-form-symbols acl2-symbolp)))
  :rule-classes nil)

;;;============================================================================
;;; JSON-LD Form Structure Tests
;;;============================================================================

(defthm test-make-jsonld-form-structure
  (let ((jf (make-jsonld-form "test#foo" "acl2:Defun" "FOO" "(defun foo ())"
                              nil nil)))
    (alistp jf))
  :hints (("Goal" :in-theory (enable make-jsonld-form)))
  :rule-classes nil)

(defthm test-jsonld-accessors
  (let ((jf (make-jsonld-form "test#foo" "acl2:Defun" "FOO" "(defun foo ())"
                              nil '("BAR" "BAZ"))))
    (and (equal (jsonld-form->id jf) "test#foo")
         (equal (jsonld-form->type jf) "acl2:Defun")
         (equal (jsonld-form->name jf) "FOO")
         (equal (jsonld-form->source-form jf) "(defun foo ())")
         (equal (jsonld-form->references jf) '("BAR" "BAZ"))))
  :hints (("Goal" :in-theory (enable make-jsonld-form
                                     jsonld-form->id
                                     jsonld-form->type
                                     jsonld-form->name
                                     jsonld-form->source-form
                                     jsonld-form->references)))
  :rule-classes nil)

;;;============================================================================
;;; Integration Tests: form-to-jsonld
;;;============================================================================

;; Test that form-to-jsonld produces correct type for defun
(defthm test-form-to-jsonld-defun-type
  (equal (jsonld-form->type (form-to-jsonld *test-defun-form* "test-file"))
         "acl2:Defun")
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     form-type-keyword
                                     form-type-to-jsonld-type
                                     jsonld-form->type
                                     make-jsonld-form)))
  :rule-classes nil)

;; Test that form-to-jsonld produces correct type for defthm
(defthm test-form-to-jsonld-defthm-type
  (equal (jsonld-form->type (form-to-jsonld *test-defthm-form* "test-file"))
         "acl2:Defthm")
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     form-type-keyword
                                     form-type-to-jsonld-type
                                     jsonld-form->type
                                     make-jsonld-form)))
  :rule-classes nil)

;; Test that form-to-jsonld extracts correct name
(defthm test-form-to-jsonld-defun-name
  (equal (jsonld-form->name (form-to-jsonld *test-defun-form* "test-file"))
         "APPEND")
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     form-type-keyword
                                     get-defined-name
                                     jsonld-form->name
                                     make-jsonld-form)))
  :rule-classes nil)

;; Test that references are collected
(defthm test-form-to-jsonld-has-references
  (consp (jsonld-form->references (form-to-jsonld *test-defun-form* "test-file")))
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     collect-form-symbols
                                     symbol-list-to-string-list
                                     acl2-symbolp
                                     jsonld-form->references
                                     make-jsonld-form)))
  :rule-classes nil)

;;;============================================================================
;;; Property Preservation Theorems
;;;============================================================================

;; These theorems establish that serialization preserves semantic information

(defthm form-to-jsonld-preserves-name-when-present
  (implies (get-defined-name form)
           (equal (jsonld-form->name (form-to-jsonld form file-id))
                  (symbol-name (get-defined-name form))))
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     jsonld-form->name
                                     make-jsonld-form))))

;; References include body symbols (for non-trivial forms)
;; This is a key property: the externalized form tracks what it depends on

(defthm references-are-string-list
  (implies (stringp file-id)
           (string-listp (jsonld-form->references (form-to-jsonld form file-id))))
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     jsonld-form->references
                                     make-jsonld-form
                                     symbol-list-to-string-list
                                     collect-form-symbols))))

;; ID is constructed from file-id and name
(defthm id-contains-file-id
  (implies (and (stringp file-id)
                (> (length file-id) 0))
           (let ((id (jsonld-form->id (form-to-jsonld form file-id))))
             (equal (subseq id 0 (length file-id)) file-id)))
  :hints (("Goal" :in-theory (enable form-to-jsonld
                                     jsonld-form->id
                                     make-jsonld-form))))
