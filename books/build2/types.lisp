; ACL2 Build2 System - Data Structures
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file defines the core data structures for the build2 certification
; system. All structures are pure ACL2 with verified guards.

(in-package "BUILD2")

(include-book "std/util/define" :dir :system)
(include-book "std/util/defaggregate" :dir :system)
(include-book "std/util/deflist" :dir :system)
(include-book "std/strings/cat" :dir :system)

;; ============================================================================
;; Helper recognizers
;; ============================================================================

(define maybe-stringp (x)
  :returns (bool booleanp)
  :parents (certinfo)
  :short "Recognizer for nil or a string."
  (or (null x) (stringp x))
  ///
  (defthm maybe-stringp-compound-recognizer
    (implies (maybe-stringp x)
             (or (null x) (stringp x)))
    :rule-classes :compound-recognizer))

(define keyword-string-alistp (x)
  :returns (bool booleanp)
  :parents (certinfo)
  :short "Recognizer for alists mapping keywords to strings."
  (if (atom x)
      (null x)
    (and (consp (car x))
         (keywordp (caar x))
         (stringp (cdar x))
         (keyword-string-alistp (cdr x))))
  ///
  (defthm keyword-string-alistp-of-cons
    (equal (keyword-string-alistp (cons a x))
           (and (consp a)
                (keywordp (car a))
                (stringp (cdr a))
                (keyword-string-alistp x)))))

;; ============================================================================
;; Certification Parameters
;; ============================================================================

(std::defaggregate cert-params
  :parents (certinfo)
  :short "Parameters controlling how a book is certified."
  :long "<p>These parameters come from @('; cert_param:') directives in
source files. Some parameters (like @('ansi-only')) propagate to books
that include this book.</p>"
  
  ;; Certification workflow options
  ((acl2x       booleanp :default nil
                "Use two-pass certification (acl2x workflow).")
   (acl2xskip   booleanp :default nil  
                "Skip proofs during acl2x expansion pass.")
   (pcert       booleanp :default nil
                "Use provisional certification.")
   (reloc-stub  booleanp :default nil
                "This is a relocation stub (minimal wrapper).")
   
   ;; Lisp implementation restrictions (propagate to includers)
   (ansi-only     booleanp :default nil
                  "Requires ANSI Common Lisp (excludes GCL CLTL1).")
   (ccl-only      booleanp :default nil
                  "Only works on CCL.")
   (non-allegro   booleanp :default nil
                  "Does not work on Allegro CL.")
   (non-cmucl     booleanp :default nil
                  "Does not work on CMUCL.")
   (non-gcl       booleanp :default nil
                  "Does not work on GCL.")
   (non-lispworks booleanp :default nil
                  "Does not work on LispWorks.")
   (non-sbcl      booleanp :default nil
                  "Does not work on SBCL.")
   
   ;; ACL2 variant restrictions
   (non-acl2r     booleanp :default nil
                  "Does not work with ACL2(r) (real arithmetic).")
   (non-acl2p     booleanp :default nil  
                  "Does not work with ACL2(p) (parallel).")
   (uses-acl2r    booleanp :default nil
                  "Requires ACL2(r).")
   
   ;; External tool requirements (propagate to includers)
   (uses-glucose   booleanp :default nil
                   "Requires the Glucose SAT solver.")
   (uses-ipasir    booleanp :default nil
                   "Requires the IPASIR SAT solver interface.")
   (uses-abc       booleanp :default nil
                   "Requires the ABC logic synthesis tool.")
   (uses-smtlink   booleanp :default nil
                   "Requires SMTLink (Z3 integration).")
   (uses-stp       booleanp :default nil
                   "Requires the STP solver.")
   (uses-quicklisp booleanp :default nil
                   "Requires Quicklisp.")
   (uses-cpp       booleanp :default nil
                   "Requires a C preprocessor.")
   
   ;; Custom ACL2 image
   (acl2-image  maybe-stringp :default nil
                "Path to custom ACL2 image to use."))
  
  :tag :cert-params)

;; ============================================================================
;; Book dependency
;; ============================================================================

(std::defaggregate book-dep
  :parents (certinfo)
  :short "A dependency on another book."
  :long "<p>Represents an @('include-book') or similar dependency.
The @('localp') flag indicates whether this was a local include.</p>"
  
  ((path   stringp "Canonical path to the book (without extension).")
   (localp booleanp :default nil
           "Was this include-book inside LOCAL?"))
  
  :tag :book-dep)

(std::deflist book-dep-list
  :parents (certinfo)
  :short "A list of book dependencies."
  :elt-type book-dep
  :true-listp t)

;; ============================================================================
;; Scanned event types
;; ============================================================================

;; Events recognized by the scanner. These represent lines of interest
;; in source files that affect certification dependencies.

(std::defaggregate scan-event-include-book
  :short "An include-book form was found."
  ((name stringp "The book name argument.")
   (dir  maybe-stringp :default nil "The :dir argument if present.")
   (localp booleanp :default nil "Was this inside LOCAL?"))
  :tag :include-book)

(std::defaggregate scan-event-depends-on  
  :short "A depends-on form was found."
  ((path stringp "The file path."))
  :tag :depends-on)

(std::defaggregate scan-event-loads
  :short "A loads form was found."
  ((path stringp "The file path."))
  :tag :loads)

(std::defaggregate scan-event-cert-param
  :short "A cert_param comment was found."
  ((name   stringp "Parameter name.")
   (value  stringp "Parameter value (or empty)."))
  :tag :cert-param)

(std::defaggregate scan-event-add-include-book-dir
  :short "An add-include-book-dir! form was found."
  ((keyword keywordp "The directory keyword.")
   (path    stringp  "The directory path."))
  :tag :add-include-book-dir)

(std::defaggregate scan-event-ifdef
  :short "An ifdef/ifndef form was found."
  ((varname stringp   "The environment variable name.")
   (negate  booleanp  "True for ifndef, false for ifdef."))
  :tag :ifdef)

;; Union type for all scan events
(define scan-event-p (x)
  :returns (bool booleanp)
  :short "Recognizer for any scan event."
  (or (scan-event-include-book-p x)
      (scan-event-depends-on-p x)
      (scan-event-loads-p x)
      (scan-event-cert-param-p x)
      (scan-event-add-include-book-dir-p x)
      (scan-event-ifdef-p x)))

(std::deflist scan-event-list
  :elt-type scan-event-p
  :true-listp t)

;; ============================================================================
;; Certinfo - complete info about a book
;; ============================================================================

(std::defaggregate certinfo
  :parents (certinfo)
  :short "Complete certification information for a single book."
  :long "<p>This aggregates all the information needed to certify a book:
its dependencies, parameters, and include-book directory mappings.</p>"
  
  ((bookdeps book-dep-list-p :default nil
             "Books this book depends on (from include-book).")
   
   (portdeps book-dep-list-p :default nil
             "Books included by the portcullis (.acl2 file).")
   
   (srcdeps string-listp :default nil
            "Source file dependencies (.lisp, .acl2 files).")
   
   (otherdeps string-listp :default nil
              "Other file dependencies (from depends-on).")
   
   (params cert-params-p :default (make-cert-params)
           "Certification parameters.")
   
   (include-dirs keyword-string-alistp :default nil
                 "Include-book directory mappings."))
  
  :tag :certinfo)

;; ============================================================================
;; Depdb - database of all book certification info
;; ============================================================================

(define certinfo-alist-p (x)
  :returns (bool booleanp)
  :short "Alist mapping book paths to certinfo structures."
  (if (atom x)
      (null x)
    (and (consp (car x))
         (stringp (caar x))
         (certinfo-p (cdar x))
         (certinfo-alist-p (cdr x))))
  ///
  (defthm certinfo-alist-p-of-cons
    (equal (certinfo-alist-p (cons a x))
           (and (consp a)
                (stringp (car a))
                (certinfo-p (cdr a))
                (certinfo-alist-p x)))))

(std::defaggregate depdb
  :parents (certinfo)
  :short "Database of book certification information."
  :long "<p>Maps canonical book paths to their certinfo structures.
This is the central data structure for dependency analysis.</p>"
  
  ((books certinfo-alist-p :default nil
          "Alist mapping book paths to certinfo.")
   
   (basedir stringp :default ""
            "Base directory for the book tree."))
  
  :tag :depdb)

;; ============================================================================
;; Theorems about data structure properties
;; ============================================================================

(defthm cert-params-p-of-make-cert-params
  (cert-params-p (make-cert-params)))

(defthm certinfo-p-of-make-certinfo
  (certinfo-p (make-certinfo)))

(defthm depdb-p-of-make-depdb
  (depdb-p (make-depdb)))

;; ============================================================================
;; Cert-params merging (for propagating restrictions from dependencies)
;; ============================================================================

(define merge-cert-params ((p1 cert-params-p)
                           (p2 cert-params-p))
  :returns (merged cert-params-p)
  :short "Merge cert-params, propagating restrictions."
  :long "<p>When a book B includes a book A with restrictions, B must
also satisfy those restrictions. This function computes the merged
parameters by OR-ing the boolean restrictions.</p>"
  
  (make-cert-params
   ;; Workflow options don't propagate
   :acl2x      (cert-params->acl2x p1)
   :acl2xskip  (cert-params->acl2xskip p1)
   :pcert      (cert-params->pcert p1)
   :reloc-stub (cert-params->reloc-stub p1)
   ;; Lisp restrictions propagate
   :ansi-only     (or (cert-params->ansi-only p1)
                      (cert-params->ansi-only p2))
   :ccl-only      (or (cert-params->ccl-only p1)
                      (cert-params->ccl-only p2))
   :non-allegro   (or (cert-params->non-allegro p1)
                      (cert-params->non-allegro p2))
   :non-cmucl     (or (cert-params->non-cmucl p1)
                      (cert-params->non-cmucl p2))
   :non-gcl       (or (cert-params->non-gcl p1)
                      (cert-params->non-gcl p2))
   :non-lispworks (or (cert-params->non-lispworks p1)
                      (cert-params->non-lispworks p2))
   :non-sbcl      (or (cert-params->non-sbcl p1)
                      (cert-params->non-sbcl p2))
   ;; ACL2 variant restrictions propagate
   :non-acl2r     (or (cert-params->non-acl2r p1)
                      (cert-params->non-acl2r p2))
   :non-acl2p     (or (cert-params->non-acl2p p1)
                      (cert-params->non-acl2p p2))
   :uses-acl2r    (or (cert-params->uses-acl2r p1)
                      (cert-params->uses-acl2r p2))
   ;; External tool requirements propagate
   :uses-glucose   (or (cert-params->uses-glucose p1)
                       (cert-params->uses-glucose p2))
   :uses-ipasir    (or (cert-params->uses-ipasir p1)
                       (cert-params->uses-ipasir p2))
   :uses-abc       (or (cert-params->uses-abc p1)
                       (cert-params->uses-abc p2))
   :uses-smtlink   (or (cert-params->uses-smtlink p1)
                       (cert-params->uses-smtlink p2))
   :uses-stp       (or (cert-params->uses-stp p1)
                       (cert-params->uses-stp p2))
   :uses-quicklisp (or (cert-params->uses-quicklisp p1)
                       (cert-params->uses-quicklisp p2))
   :uses-cpp       (or (cert-params->uses-cpp p1)
                       (cert-params->uses-cpp p2))
   ;; Custom image doesn't propagate
   :acl2-image  (cert-params->acl2-image p1)))
  
(defthm merge-cert-params-type
  (cert-params-p (merge-cert-params p1 p2)))

;; Merging is commutative for the propagating fields
(defthm merge-cert-params-ansi-only-commutative
  (equal (cert-params->ansi-only (merge-cert-params p1 p2))
         (cert-params->ansi-only (merge-cert-params p2 p1)))
  :hints (("Goal" :in-theory (enable merge-cert-params))))
