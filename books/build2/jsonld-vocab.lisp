; JSON-LD Vocabulary and Serialization for ACL2 World Externalization
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This book defines data structures and functions for converting ACL2 forms
; to JSON-LD representation, supporting both executable S-expression strings
; and structured RDF for queries/inference.

(in-package "BUILD2")

;; Use the FTY library for proper type definitions
(include-book "centaur/fty/top" :dir :system)
(include-book "std/strings/top" :dir :system)
(include-book "std/util/bstar" :dir :system)
(include-book "std/util/define" :dir :system)

;;;============================================================================
;;; JSON-LD Vocabulary Constants
;;;============================================================================

;; Namespace prefixes
(defconst *acl2-vocab-base*
  "https://www.cs.utexas.edu/users/moore/acl2/vocab#")

(defconst *xsd-prefix*
  "http://www.w3.org/2001/XMLSchema#")

;; Type URIs - these map ACL2 form types to JSON-LD @type values
(defconst *type-defun* "acl2:Defun")
(defconst *type-defthm* "acl2:Defthm")
(defconst *type-defmacro* "acl2:Defmacro")
(defconst *type-defconst* "acl2:Defconst")
(defconst *type-defaxiom* "acl2:Defaxiom")
(defconst *type-encapsulate* "acl2:Encapsulate")
(defconst *type-mutual-recursion* "acl2:MutualRecursion")
(defconst *type-include-book* "acl2:IncludeBook")
(defconst *type-in-theory* "acl2:InTheory")
(defconst *type-event* "acl2:Event")

;;;============================================================================
;;; JSON-LD Data Structures using FTY
;;;============================================================================

;; A property is a key-value pair where both are strings
;; Using FTY's defprod for a proper product type
(fty::defprod jsonld-property
  ((key stringp :rule-classes :type-prescription)
   (value stringp :rule-classes :type-prescription))
  :tag :jsonld-property)

;; A list of properties
(fty::deflist jsonld-property-list
  :elt-type jsonld-property
  :true-listp t)

;; Define our own string-list type for FTY compatibility
;; (str::string-list-p doesn't have a fixing function registered with FTY)
(fty::deflist string-list
  :elt-type string
  :true-listp t
  :elementp-of-nil nil)

;; The main JSON-LD form structure
;; This represents a single ACL2 form externalized as JSON-LD
(fty::defprod jsonld-form
  ((id stringp :rule-classes :type-prescription
       "The @id - unique URI for this definition")
   (type stringp :rule-classes :type-prescription
         "The @type - e.g. acl2:Defun, acl2:Defthm")
   (name stringp :rule-classes :type-prescription
         "The defined symbol name")
   (source-form stringp :rule-classes :type-prescription
                "Original S-expression as string for CL execution")
   (properties jsonld-property-list-p
               "Type-specific properties (formals, body, term, etc.)")
   (references string-list-p
               "List of referenced symbol names for RDF links"))
  :tag :jsonld-form)

;;;============================================================================
;;; Form Type Detection
;;;============================================================================

;; Form type enumeration using FTY deftagsum would be ideal,
;; but for simplicity we use keywords with a simple recognizer

(define form-type-keyword-p (x)
  :returns (bool booleanp)
  :parents (jsonld-vocab)
  :short "Recognizer for valid form type keywords."
  (and (keywordp x)
       (if (member-eq x '(:defun :defun-sk :defthm :defmacro :defconst
                          :defaxiom :encapsulate :mutual-recursion
                          :include-book :in-theory :local nil))
           t
         nil)))

(define classify-form-type ((form-car symbolp))
  :returns (type-kw (or (form-type-keyword-p type-kw) (null type-kw))
                    :hints (("Goal" :in-theory (enable form-type-keyword-p))))
  :parents (jsonld-vocab)
  :short "Classify a form based on its CAR symbol."
  (b* ((name (symbol-name form-car)))
    (cond
     ((or (equal name "DEFUN") (equal name "DEFUND")) :defun)
     ((equal name "DEFUN-SK") :defun-sk)
     ((or (equal name "DEFTHM") (equal name "DEFTHMD")) :defthm)
     ((equal name "DEFMACRO") :defmacro)
     ((equal name "DEFCONST") :defconst)
     ((equal name "DEFAXIOM") :defaxiom)
     ((equal name "ENCAPSULATE") :encapsulate)
     ((equal name "MUTUAL-RECURSION") :mutual-recursion)
     ((equal name "INCLUDE-BOOK") :include-book)
     ((equal name "IN-THEORY") :in-theory)
     ((equal name "LOCAL") :local)
     ((equal name "DEFRULE") :defthm)   ; std/util defrule
     ((equal name "DEFINE") :defun)     ; std/util define
     (t nil))))

(define form-type-to-jsonld-type ((type-kw (or (form-type-keyword-p type-kw) 
                                                (null type-kw))))
  :returns (jsonld-type stringp :rule-classes :type-prescription)
  :parents (jsonld-vocab)
  :short "Convert form type keyword to JSON-LD type string."
  (case type-kw
    (:defun *type-defun*)
    (:defun-sk *type-defun*)
    (:defthm *type-defthm*)
    (:defmacro *type-defmacro*)
    (:defconst *type-defconst*)
    (:defaxiom *type-defaxiom*)
    (:encapsulate *type-encapsulate*)
    (:mutual-recursion *type-mutual-recursion*)
    (:include-book *type-include-book*)
    (:in-theory *type-in-theory*)
    (:local *type-event*)
    (otherwise *type-event*)))

;;;============================================================================
;;; Symbol Collection (for reference tracking)
;;;============================================================================

(define acl2-symbol-p (x)
  :returns (bool booleanp)
  :short "Check if X is an ACL2 symbol (not keyword, not nil)."
  :enabled t
  (and (symbolp x)
       (not (keywordp x))
       (not (null x))))

(define collect-symbols-from-form (form (acc symbol-listp))
  :returns (syms symbol-listp :hyp (symbol-listp acc))
  :measure (acl2-count form)
  :hints (("Goal" :in-theory (enable acl2-symbol-p)))
  :short "Recursively collect all ACL2 symbols from a form."
  (cond
   ((null form) acc)
   ((acl2-symbol-p form)
    (if (member-eq form acc) acc (cons form acc)))
   ((atom form) acc)
   (t (collect-symbols-from-form 
       (cdr form)
       (collect-symbols-from-form (car form) acc)))))

(define symbols-to-string-list ((syms symbol-listp))
  :returns (strs string-list-p)
  :short "Convert a symbol list to a string list of symbol names."
  (if (endp syms)
      nil
    (cons (symbol-name (car syms))
          (symbols-to-string-list (cdr syms)))))

;;;============================================================================
;;; Property Construction Helpers
;;;============================================================================

(define make-property ((key stringp) (value stringp))
  :returns (prop jsonld-property-p)
  :short "Create a JSON-LD property from key and value strings."
  (make-jsonld-property :key key :value value))

(define add-property-if-present ((key stringp) 
                                  (value-form t)
                                  (acc jsonld-property-list-p))
  :returns (props jsonld-property-list-p :hyp (jsonld-property-list-p acc))
  :short "Add a property to the list if value-form is non-nil."
  :long "<p>The value is converted to a string representation. This is a
placeholder that should use proper pretty-printing in production.</p>"
  (if value-form
      (cons (make-property key 
                           ;; Placeholder: in production, use proper printer
                           (if (stringp value-form) 
                               value-form
                             "(form)"))
            acc)
    acc))

;;;============================================================================
;;; Form to JSON-LD Conversion
;;;============================================================================

(define get-form-name ((form consp))
  :returns (name stringp :rule-classes :type-prescription)
  :short "Extract the defined name from a form (second element, typically)."
  (b* ((rest (cdr form))
       ((unless (consp rest)) "")
       (second (car rest)))
    (cond ((symbolp second) (symbol-name second))
          ((stringp second) second)  ; for include-book
          (t ""))))

(define form-to-jsonld ((form consp) (book-name stringp))
  :returns (jform jsonld-form-p)
  :short "Convert an ACL2 form to a JSON-LD form structure."
  :guard-hints (("Goal" :use ((:instance return-type-of-classify-form-type
                                         (form-car (car form))))))
  (b* ((form-car (car form))
       (type-kw (if (symbolp form-car)
                    (classify-form-type form-car)
                  nil))
       (jsonld-type (form-type-to-jsonld-type type-kw))
       (name (get-form-name form))
       (id (str::cat book-name "#" name))
       ;; Collect referenced symbols
       (syms (collect-symbols-from-form form nil))
       (refs (symbols-to-string-list syms))
       ;; For now, store the whole form as source (placeholder)
       (source-str "(source)"))
    (make-jsonld-form :id id
                      :type jsonld-type
                      :name name
                      :source-form source-str
                      :properties nil
                      :references refs)))

;;;============================================================================
;;; JSON-LD Serialization using bridge::json-encode
;;;============================================================================

;; Use the centaur/bridge library for JSON encoding
(include-book "centaur/bridge/to-json" :dir :system)

(define jsonld-form-to-alist ((jform jsonld-form-p))
  :returns (alist alistp)
  :short "Convert a jsonld-form to an alist suitable for bridge::json-encode."
  (b* (((jsonld-form jform) jform))
    (list (cons "@context" "https://www.cs.utexas.edu/users/moore/acl2/vocab")
          (cons "@id" jform.id)
          (cons "@type" jform.type)
          (cons "acl2:name" jform.name)
          (cons "acl2:sourceForm" jform.source-form)
          (cons "acl2:references" jform.references))))

(define jsonld-form-to-json ((jform jsonld-form-p))
  :returns (json stringp :rule-classes :type-prescription)
  :short "Serialize a jsonld-form to a JSON-LD string."
  (bridge::json-encode (jsonld-form-to-alist jform)))

;;;============================================================================
;;; Additional Type Rules
;;;============================================================================

;; Useful rewrite rule for length preservation
(defthm symbols-to-string-list-preserves-len
  (equal (len (symbols-to-string-list syms))
         (len syms))
  :hints (("Goal" :in-theory (enable symbols-to-string-list))))

;; Additional type-prescription rules for jsonld-form accessors
(defthm jsonld-form-id-is-string
  (implies (jsonld-form-p x)
           (stringp (jsonld-form->id x)))
  :rule-classes :type-prescription)

(defthm jsonld-form-type-is-string
  (implies (jsonld-form-p x)
           (stringp (jsonld-form->type x)))
  :rule-classes :type-prescription)

(defthm jsonld-form-references-is-string-list
  (implies (jsonld-form-p x)
           (string-list-p (jsonld-form->references x)))
  :rule-classes :type-prescription)
