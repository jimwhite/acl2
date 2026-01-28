; Tests for JSON-LD Vocabulary
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "jsonld-vocab")

;;;============================================================================
;;; Unit Tests
;;;============================================================================

;; Test constants are well-formed
(defthm test-type-defun-is-string
  (stringp *type-defun*)
  :rule-classes nil)

(defthm test-type-defthm-is-string
  (stringp *type-defthm*)
  :rule-classes nil)

(defthm test-type-defmacro-is-string
  (stringp *type-defmacro*)
  :rule-classes nil)

;; Test classify-form-type on known forms
(defthm test-classify-defun
  (equal (classify-form-type 'defun) :defun)
  :rule-classes nil)

(defthm test-classify-defthm
  (equal (classify-form-type 'defthm) :defthm)
  :rule-classes nil)

(defthm test-classify-defmacro
  (equal (classify-form-type 'defmacro) :defmacro)
  :rule-classes nil)

(defthm test-classify-defconst
  (equal (classify-form-type 'defconst) :defconst)
  :rule-classes nil)

(defthm test-classify-unknown-returns-nil
  (equal (classify-form-type 'unknown-form) nil)
  :rule-classes nil)

;; Test symbol collection from simple list
(defthm test-collect-symbols-basic
  (let ((result (collect-symbols-from-form '(foo bar baz) nil)))
    (and (member-eq 'foo result)
         (member-eq 'bar result)
         (member-eq 'baz result)))
  :hints (("Goal" :in-theory (enable collect-symbols-from-form acl2-symbol-p)))
  :rule-classes nil)

(defthm test-collect-symbols-nested
  (let ((result (collect-symbols-from-form '(defun foo (x) (+ x 1)) nil)))
    (and (member-eq 'defun result)
         (member-eq 'foo result)
         (member-eq 'x result)
         (member-eq '+ result)))
  :hints (("Goal" :in-theory (enable collect-symbols-from-form acl2-symbol-p)))
  :rule-classes nil)

;; Test make-property creates valid property
(defthm test-make-property-valid
  (jsonld-property-p (make-property "key" "value"))
  :hints (("Goal" :in-theory (enable make-property)))
  :rule-classes nil)

;; Test get-form-name extracts names correctly
(defthm test-get-form-name-defun
  (equal (get-form-name '(defun foo (x) x)) "FOO")
  :rule-classes nil)

(defthm test-get-form-name-defthm
  (equal (get-form-name '(defthm my-theorem (equal x x))) "MY-THEOREM")
  :rule-classes nil)

;; Test form-to-jsonld produces valid jsonld-form
(defthm test-form-to-jsonld-valid
  (jsonld-form-p (form-to-jsonld '(defun foo (x) x) "test-book"))
  :rule-classes nil)

(defthm test-form-to-jsonld-has-correct-type
  (equal (jsonld-form->type (form-to-jsonld '(defun foo (x) x) "test-book"))
         "acl2:Defun")
  :rule-classes nil)

(defthm test-form-to-jsonld-has-correct-name
  (equal (jsonld-form->name (form-to-jsonld '(defun foo (x) x) "test-book"))
         "FOO")
  :rule-classes nil)

;; Test jsonld-form-to-json produces string
(defthm test-jsonld-form-to-json-is-string
  (stringp (jsonld-form-to-json (form-to-jsonld '(defun foo (x) x) "test-book")))
  :rule-classes nil)
