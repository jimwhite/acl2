; ACL2 Build2 System - Certificate Info Data Structures
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "std/util/define" :dir :system)
(include-book "std/util/defaggregate" :dir :system)
(include-book "std/alists/alist-defuns" :dir :system)

;; ============================================================================
;; Cert-param structure
;; ============================================================================

;; Certification parameters that can be set via ; cert_param: directives
;; These control how a book is certified and what requirements it has.

(std::defaggregate cert-params
  ((acl2x       booleanp :default nil) ; Use two-pass certification
   (acl2xskip   booleanp :default nil) ; Skip proofs during acl2x pass
   (pcert       booleanp :default nil) ; Use provisional certification
   (reloc-stub  booleanp :default nil) ; This is a relocation stub
   ;; Lisp implementation restrictions (propagate to includers)
   (ansi-only     booleanp :default nil)
   (ccl-only      booleanp :default nil)
   (non-allegro   booleanp :default nil)
   (non-cmucl     booleanp :default nil)
   (non-gcl       booleanp :default nil)
   (non-lispworks booleanp :default nil)
   (non-sbcl      booleanp :default nil)
   (non-acl2r     booleanp :default nil)
   (non-acl2p     booleanp :default nil)
   (uses-acl2r    booleanp :default nil)
   ;; External tool requirements (propagate to includers)
   (uses-abc       booleanp :default nil)
   (uses-glucose   booleanp :default nil)
   (uses-ipasir    booleanp :default nil)
   (uses-smtlink   booleanp :default nil)
   (uses-stp       booleanp :default nil)
   (uses-quicklisp booleanp :default nil)
   (uses-cpp       booleanp :default nil)
   ;; Custom image
   (acl2-image  maybe-stringp :default nil))
  :tag :cert-params)

(defun maybe-stringp (x)
  (declare (xargs :guard t))
  (or (null x) (stringp x)))

;; ============================================================================
;; Include-book dependency
;; ============================================================================

;; Represents a dependency on another book
(std::defaggregate book-dep
  ((path   stringp)           ; Canonical path to the .cert2 file
   (localp booleanp :default nil)) ; Was this a local include-book?
  :tag :book-dep)

(defun book-dep-listp (x)
  (declare (xargs :guard t))
  (if (atom x)
      (null x)
    (and (book-dep-p (car x))
         (book-dep-listp (cdr x)))))

;; ============================================================================
;; Certinfo - information about a single book
;; ============================================================================

;; This is the main data structure holding all information about a book
;; needed for certification.

(std::defaggregate certinfo
  (;; Book dependencies (other .cert2 files this book depends on)
   (bookdeps book-dep-listp :default nil)
   
   ;; Portcullis dependencies (books included by the .acl2 file)
   (portdeps book-dep-listp :default nil)
   
   ;; Source file dependencies (.lisp, .acl2 files)
   (srcdeps string-listp :default nil)
   
   ;; Other file dependencies (from depends-on forms)
   (otherdeps string-listp :default nil)
   
   ;; ACL2 image to use for certification
   (image maybe-stringp :default nil)
   
   ;; Certification parameters
   (params cert-params-p :default (make-cert-params))
   
   ;; Include-book directories (from add-include-book-dir!)
   ;; Alist mapping keyword symbols to directory paths
   (include-dirs alistp :default nil)
   
   ;; Local include-book directories (includes non-exported ones)
   (local-include-dirs alistp :default nil)
   
   ;; Ifdef defines (from ifdef-define directives)
   (defines alistp :default nil)
   
   ;; Local ifdef defines  
   (local-defines alistp :default nil))
  :tag :certinfo)

;; ============================================================================
;; Depdb - the dependency database
;; ============================================================================

;; Maps book paths to their certinfo structures and tracks global state
;; during dependency scanning.

(std::defaggregate depdb
  (;; Main mapping: canonical cert path -> certinfo
   ;; This is an alist for now; could use a faster structure later
   (certdeps alistp :default nil)
   
   ;; Set of all source files encountered (as alist for set membership)
   (sources alistp :default nil)
   
   ;; Set of all "other" dependencies (non-book files)
   (others alistp :default nil)
   
   ;; Stack for cycle detection during DFS traversal
   (stack string-listp :default nil)
   
   ;; Event cache: maps source file path to (events . timestamp)
   (evcache alistp :default nil)
   
   ;; Timestamp cache: maps file path to timestamp (for up-to-date checks)
   (tscache alistp :default nil)
   
   ;; Global setting: use pcert for all books?
   (pcert-all booleanp :default nil))
  :tag :depdb)

;; ============================================================================
;; Helper functions
;; ============================================================================

(defun add-source (path depdb)
  "Add a source file to the depdb's sources set"
  (declare (xargs :guard (and (stringp path) (depdb-p depdb))))
  (change-depdb depdb
                :sources (acons path t (depdb->sources depdb))))

(defun add-other (path depdb)
  "Add an 'other' dependency to the depdb"
  (declare (xargs :guard (and (stringp path) (depdb-p depdb))))
  (change-depdb depdb
                :others (acons path t (depdb->others depdb))))

(defun get-certinfo (cert-path depdb)
  "Look up certinfo for a book by its cert path"
  (declare (xargs :guard (and (stringp cert-path) (depdb-p depdb))))
  (cdr (assoc-equal cert-path (depdb->certdeps depdb))))

(defun put-certinfo (cert-path info depdb)
  "Store certinfo for a book"
  (declare (xargs :guard (and (stringp cert-path) 
                              (certinfo-p info)
                              (depdb-p depdb))))
  (change-depdb depdb
                :certdeps (acons cert-path info (depdb->certdeps depdb))))

;; ============================================================================
;; Cert-params propagation
;; ============================================================================

;; Some cert-params need to propagate from included books to the includer.
;; For example, if book A uses-glucose and book B includes A, then B also
;; needs uses-glucose to be satisfied.

(defun merge-propagating-params (parent-params child-params)
  "Merge propagating cert-params from child into parent"
  (declare (xargs :guard (and (cert-params-p parent-params)
                              (cert-params-p child-params))))
  (change-cert-params parent-params
    ;; Lisp restrictions propagate
    :ansi-only     (or (cert-params->ansi-only parent-params)
                       (cert-params->ansi-only child-params))
    :ccl-only      (or (cert-params->ccl-only parent-params)
                       (cert-params->ccl-only child-params))
    :non-allegro   (or (cert-params->non-allegro parent-params)
                       (cert-params->non-allegro child-params))
    :non-cmucl     (or (cert-params->non-cmucl parent-params)
                       (cert-params->non-cmucl child-params))
    :non-gcl       (or (cert-params->non-gcl parent-params)
                       (cert-params->non-gcl child-params))
    :non-lispworks (or (cert-params->non-lispworks parent-params)
                       (cert-params->non-lispworks child-params))
    :non-sbcl      (or (cert-params->non-sbcl parent-params)
                       (cert-params->non-sbcl child-params))
    :non-acl2r     (or (cert-params->non-acl2r parent-params)
                       (cert-params->non-acl2r child-params))
    :non-acl2p     (or (cert-params->non-acl2p parent-params)
                       (cert-params->non-acl2p child-params))
    :uses-acl2r    (or (cert-params->uses-acl2r parent-params)
                       (cert-params->uses-acl2r child-params))
    ;; External tool requirements propagate
    :uses-abc       (or (cert-params->uses-abc parent-params)
                        (cert-params->uses-abc child-params))
    :uses-glucose   (or (cert-params->uses-glucose parent-params)
                        (cert-params->uses-glucose child-params))
    :uses-ipasir    (or (cert-params->uses-ipasir parent-params)
                        (cert-params->uses-ipasir child-params))
    :uses-smtlink   (or (cert-params->uses-smtlink parent-params)
                        (cert-params->uses-smtlink child-params))
    :uses-stp       (or (cert-params->uses-stp parent-params)
                        (cert-params->uses-stp child-params))
    :uses-quicklisp (or (cert-params->uses-quicklisp parent-params)
                        (cert-params->uses-quicklisp child-params))
    :uses-cpp       (or (cert-params->uses-cpp parent-params)
                        (cert-params->uses-cpp child-params))
    ;; pcert also propagates
    :pcert          (or (cert-params->pcert parent-params)
                        (cert-params->pcert child-params))))
