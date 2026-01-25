; ACL2 Build2 System - Top-level Book
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This book includes all the certifiable ACL2 portions of the build2 system
; and provides the main entry points for certification.

(in-package "BUILD2")

;; ============================================================================
;; Include the pure ACL2 modules  
;; ============================================================================

;; Data types and structures
(include-book "types")

;; Dependency scanner
(include-book "scan")

;; Dependency graph and build ordering
(include-book "depgraph")

;; Certification logic
(include-book "certify")

;; For raw Lisp loading
(include-book "tools/include-raw" :dir :system)

;; ============================================================================
;; Version
;; ============================================================================

(defconst *build2-version* "0.1.0")

(define build2-version ()
  :returns (version stringp)
  *build2-version*)

;; ============================================================================
;; Main analysis functions (pure ACL2)
;; ============================================================================

(define analyze-book-deps ((book-path stringp)
                           (lines string-listp)
                           (basedir stringp)
                           (include-dirs keyword-string-alistp))
  :returns (info certinfo-p)
  :short "Analyze a book's dependencies from its source lines."
  (b* ((events (scan-lines lines)))
    (events-to-certinfo events basedir include-dirs)))

;; ============================================================================
;; Loading raw Lisp for OS interaction
;; ============================================================================

;; The following uses ACL2's trust tag mechanism to load raw Lisp code
;; for operations that require OS interaction (file timestamps, subprocess
;; execution, etc.)

(defttag :build2)

;; This will be loaded in the execution environment
;; (include-raw "io-raw.lsp")

;; ============================================================================
;; Exported interface
;; ============================================================================

;; The main entry points are:
;;
;; For analyzing dependencies (pure ACL2):
;;   (scan-lines lines) - Extract events from source lines
;;   (events-to-certinfo events basedir dirs) - Convert to certinfo
;;   (compute-build-order db) - Compute topological build order
;;   (filter-books-needing-cert books db timestamps) - Find what needs building
;;   (make-build-plan books db) - Create build plan
;;
;; For running certifications (requires raw Lisp):
;;   Loaded via io-raw.lsp:
;;   - get-all-timestamps-raw
;;   - run-acl2-subprocess-raw
;;   - start-certification-job-raw
;;   etc.

;; ============================================================================
;; Summary of the verification architecture
;; ============================================================================

;; The build2 system is structured to maximize verifiable ACL2 code:
;;
;; VERIFIED (pure ACL2 with theorems):
;; - Data structures (types.lisp): cert-params, book-dep, certinfo, depdb
;; - Scanner (scan.lisp): Line parsing, event extraction
;; - Dependency graph (depgraph.lisp): Graph construction, toposort
;; - Certification logic (certify.lisp): Rebuild determination, plan creation
;;
;; UNVERIFIED (raw CL for OS interaction):  
;; - io-raw.lsp: File timestamps, subprocess execution
;;
;; Key theorems proven:
;; - scan-lines-produces-valid-events: Scanner output is well-formed
;; - compute-build-order-valid: Toposort produces valid dependency order
;; - book-needs-cert-sound: Rebuild decision is sound (never skip needed rebuilds)

