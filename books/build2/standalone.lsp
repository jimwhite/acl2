; ACL2 Build2 System - Standalone Loader
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This file can be loaded directly into raw Common Lisp (SBCL, CCL, etc.)
; without going through ACL2 first. This is useful for bootstrapping.

(in-package "COMMON-LISP-USER")

;; ============================================================================
;; Package definition
;; ============================================================================

(defpackage "BUILD2"
  (:use "COMMON-LISP")
  (:export
   ;; Configuration
   "*ACL2-EXECUTABLE*"
   "*ACL2-SYSTEM-BOOKS*"
   "*IMAGES-DIR*"
   "*WRITE-PORT-FILES*"
   "*VERBOSE*"
   "*DEBUG*"
   "*NUM-JOBS*"
   "*KEEP-GOING*"
   
   ;; Data structures
   "MAKE-CERT-PARAMS"
   "CERT-PARAMS-P"
   "CHANGE-CERT-PARAMS"
   "MAKE-BOOK-DEP"
   "BOOK-DEP-P"
   "BOOK-DEP->PATH"
   "BOOK-DEP->LOCALP"
   "MAKE-CERTINFO"
   "CERTINFO-P"
   "CHANGE-CERTINFO"
   "CERTINFO->BOOKDEPS"
   "CERTINFO->PORTDEPS"
   "CERTINFO->SRCDEPS"
   "CERTINFO->OTHERDEPS"
   "CERTINFO->PARAMS"
   "MAKE-DEPDB"
   "DEPDB-P"
   
   ;; Main interface
   "BUILD-TARGETS"
   "ANALYZE-TARGETS"
   "PRINT-DEPS"
   "CERTIFY-BOOK2"
   "MAIN"
   
   ;; Utilities
   "CANONICAL-PATH"
   "LISP-TO-CERT2"
   "CERT2-TO-LISP"
   "SCAN-FILE-RAW"))

(in-package "BUILD2")

;; ============================================================================
;; Minimal data structure definitions (without ACL2's defaggregate)
;; ============================================================================

;; cert-params structure
(defstruct (cert-params (:conc-name cert-params->))
  (acl2x nil)
  (acl2xskip nil)
  (pcert nil)
  (reloc-stub nil)
  (ansi-only nil)
  (ccl-only nil)
  (non-allegro nil)
  (non-cmucl nil)
  (non-gcl nil)
  (non-lispworks nil)
  (non-sbcl nil)
  (non-acl2r nil)
  (non-acl2p nil)
  (uses-acl2r nil)
  (uses-abc nil)
  (uses-glucose nil)
  (uses-ipasir nil)
  (uses-smtlink nil)
  (uses-stp nil)
  (uses-quicklisp nil)
  (uses-cpp nil)
  (acl2-image nil))

(defun cert-params-p (x)
  (cert-params-p x))

(defun change-cert-params (params &key
                                  (acl2x nil acl2x-p)
                                  (acl2xskip nil acl2xskip-p)
                                  (pcert nil pcert-p)
                                  (reloc-stub nil reloc-stub-p)
                                  (ansi-only nil ansi-only-p)
                                  (ccl-only nil ccl-only-p)
                                  (non-allegro nil non-allegro-p)
                                  (non-cmucl nil non-cmucl-p)
                                  (non-gcl nil non-gcl-p)
                                  (non-lispworks nil non-lispworks-p)
                                  (non-sbcl nil non-sbcl-p)
                                  (non-acl2r nil non-acl2r-p)
                                  (non-acl2p nil non-acl2p-p)
                                  (uses-acl2r nil uses-acl2r-p)
                                  (uses-abc nil uses-abc-p)
                                  (uses-glucose nil uses-glucose-p)
                                  (uses-ipasir nil uses-ipasir-p)
                                  (uses-smtlink nil uses-smtlink-p)
                                  (uses-stp nil uses-stp-p)
                                  (uses-quicklisp nil uses-quicklisp-p)
                                  (uses-cpp nil uses-cpp-p)
                                  (acl2-image nil acl2-image-p))
  (make-cert-params
   :acl2x (if acl2x-p acl2x (cert-params->acl2x params))
   :acl2xskip (if acl2xskip-p acl2xskip (cert-params->acl2xskip params))
   :pcert (if pcert-p pcert (cert-params->pcert params))
   :reloc-stub (if reloc-stub-p reloc-stub (cert-params->reloc-stub params))
   :ansi-only (if ansi-only-p ansi-only (cert-params->ansi-only params))
   :ccl-only (if ccl-only-p ccl-only (cert-params->ccl-only params))
   :non-allegro (if non-allegro-p non-allegro (cert-params->non-allegro params))
   :non-cmucl (if non-cmucl-p non-cmucl (cert-params->non-cmucl params))
   :non-gcl (if non-gcl-p non-gcl (cert-params->non-gcl params))
   :non-lispworks (if non-lispworks-p non-lispworks (cert-params->non-lispworks params))
   :non-sbcl (if non-sbcl-p non-sbcl (cert-params->non-sbcl params))
   :non-acl2r (if non-acl2r-p non-acl2r (cert-params->non-acl2r params))
   :non-acl2p (if non-acl2p-p non-acl2p (cert-params->non-acl2p params))
   :uses-acl2r (if uses-acl2r-p uses-acl2r (cert-params->uses-acl2r params))
   :uses-abc (if uses-abc-p uses-abc (cert-params->uses-abc params))
   :uses-glucose (if uses-glucose-p uses-glucose (cert-params->uses-glucose params))
   :uses-ipasir (if uses-ipasir-p uses-ipasir (cert-params->uses-ipasir params))
   :uses-smtlink (if uses-smtlink-p uses-smtlink (cert-params->uses-smtlink params))
   :uses-stp (if uses-stp-p uses-stp (cert-params->uses-stp params))
   :uses-quicklisp (if uses-quicklisp-p uses-quicklisp (cert-params->uses-quicklisp params))
   :uses-cpp (if uses-cpp-p uses-cpp (cert-params->uses-cpp params))
   :acl2-image (if acl2-image-p acl2-image (cert-params->acl2-image params))))

;; book-dep structure
(defstruct (book-dep (:conc-name book-dep->))
  (path "")
  (localp nil))

(defun book-dep-p (x)
  (book-dep-p x))

(defun book-dep-listp (x)
  (and (listp x) (every #'book-dep-p x)))

(defun book-dep-list-paths (deps)
  (mapcar #'book-dep->path deps))

;; certinfo structure
(defstruct (certinfo (:conc-name certinfo->))
  (bookdeps nil)
  (portdeps nil)
  (srcdeps nil)
  (otherdeps nil)
  (image nil)
  (params (make-cert-params))
  (include-dirs nil)
  (local-include-dirs nil)
  (defines nil)
  (local-defines nil))

(defun certinfo-p (x)
  (certinfo-p x))

(defun change-certinfo (info &key
                             (bookdeps nil bookdeps-p)
                             (portdeps nil portdeps-p)
                             (srcdeps nil srcdeps-p)
                             (otherdeps nil otherdeps-p)
                             (image nil image-p)
                             (params nil params-p)
                             (include-dirs nil include-dirs-p)
                             (local-include-dirs nil local-include-dirs-p)
                             (defines nil defines-p)
                             (local-defines nil local-defines-p))
  (make-certinfo
   :bookdeps (if bookdeps-p bookdeps (certinfo->bookdeps info))
   :portdeps (if portdeps-p portdeps (certinfo->portdeps info))
   :srcdeps (if srcdeps-p srcdeps (certinfo->srcdeps info))
   :otherdeps (if otherdeps-p otherdeps (certinfo->otherdeps info))
   :image (if image-p image (certinfo->image info))
   :params (if params-p params (certinfo->params info))
   :include-dirs (if include-dirs-p include-dirs (certinfo->include-dirs info))
   :local-include-dirs (if local-include-dirs-p local-include-dirs (certinfo->local-include-dirs info))
   :defines (if defines-p defines (certinfo->defines info))
   :local-defines (if local-defines-p local-defines (certinfo->local-defines info))))

;; depdb structure
(defstruct (depdb (:conc-name depdb->))
  (certdeps nil)
  (sources nil)
  (others nil)
  (stack nil)
  (evcache nil)
  (tscache nil)
  (pcert-all nil))

(defun depdb-p (x)
  (depdb-p x))

(defun change-depdb (db &key
                        (certdeps nil certdeps-p)
                        (sources nil sources-p)
                        (others nil others-p)
                        (stack nil stack-p)
                        (evcache nil evcache-p)
                        (tscache nil tscache-p)
                        (pcert-all nil pcert-all-p))
  (make-depdb
   :certdeps (if certdeps-p certdeps (depdb->certdeps db))
   :sources (if sources-p sources (depdb->sources db))
   :others (if others-p others (depdb->others db))
   :stack (if stack-p stack (depdb->stack db))
   :evcache (if evcache-p evcache (depdb->evcache db))
   :tscache (if tscache-p tscache (depdb->tscache db))
   :pcert-all (if pcert-all-p pcert-all (depdb->pcert-all db))))

(defun get-certinfo (cert-path depdb)
  (cdr (assoc cert-path (depdb->certdeps depdb) :test #'equal)))

(defun put-certinfo (cert-path info depdb)
  (change-depdb depdb
                :certdeps (acons cert-path info (depdb->certdeps depdb))))

;; ============================================================================
;; Load the rest of the implementation
;; ============================================================================

(defvar *build2-dir*
  (make-pathname :directory (pathname-directory *load-truename*)))

(defun load-build2-file (name)
  (load (merge-pathnames name *build2-dir*)))

;; Load in dependency order
;; Note: scan.lisp defines scan-file-lines which is pure Lisp
;; The raw files add file I/O capabilities

;; First, define the string utilities from scan.lisp
(defun whitespace-char-p (c)
  (member c '(#\Space #\Tab #\Newline #\Return)))

(defun skip-whitespace (str pos)
  (loop while (and (< pos (length str))
                   (whitespace-char-p (char str pos)))
        do (incf pos))
  pos)

(defun find-char (str ch pos)
  (position ch str :start pos))

(defun find-string (str target pos)
  (search target str :start2 pos))

(defun extract-string-literal (str pos)
  (when (and (< pos (length str))
             (char= (char str pos) #\"))
    (let ((end (find-char str #\" (1+ pos))))
      (when end
        (cons (subseq str (1+ pos) end) (1+ end))))))

(defun extract-symbol-chars (str start pos)
  (loop while (and (< pos (length str))
                   (not (whitespace-char-p (char str pos)))
                   (not (member (char str pos) '(#\( #\) #\" #\;))))
        do (incf pos))
  (if (> pos start)
      (cons (subseq str start pos) pos)
    nil))

(defun extract-symbol (str pos)
  (let ((pos (skip-whitespace str pos)))
    (when (< pos (length str))
      (extract-symbol-chars str pos pos))))

(defun line-has-comment-before (str pos)
  (let ((semi-pos (find-char str #\; 0)))
    (and semi-pos (< semi-pos pos))))

;; Now load the raw implementation files
(load-build2-file "scan-raw.lsp")
(load-build2-file "depgraph-raw.lsp")
(load-build2-file "certify-raw.lsp")
(load-build2-file "scheduler-raw.lsp")

;; Load the main entry point
(load-build2-file "cert2.lsp")

(format t "~%BUILD2 system loaded.~%")
(format t "Use (build2:main '(\"target.lisp\")) to certify books.~%")
(format t "Or run: ./cert2 target.lisp~%")
