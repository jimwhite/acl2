; ACL2 Build2 System - Dependency Graph Construction
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "BUILD2")

(include-book "certinfo")

;; ============================================================================
;; Dependency graph traversal
;; ============================================================================

;; The dependency graph is built by traversing from target books,
;; recursively discovering their dependencies via scanning.

;; This file defines the pure/logical aspects of graph traversal.
;; The actual scanning uses raw Lisp code from scan-raw.lsp.

;; ============================================================================
;; Topological sort for build order
;; ============================================================================

;; We need to build books in an order such that all dependencies are
;; built before their dependents. This is a topological sort.

(defun collect-all-deps (cert-path depdb visited)
  "Collect all transitive dependencies of a certificate.
   Returns (mv visited dep-list) where dep-list is in reverse topological order."
  (declare (xargs :guard (and (stringp cert-path)
                              (depdb-p depdb)
                              (alistp visited))))
  (if (assoc-equal cert-path visited)
      ;; Already visited
      (mv visited nil)
    (let* ((visited (acons cert-path t visited))
           (certinfo (get-certinfo cert-path depdb)))
      (if (null certinfo)
          ;; No info for this cert - it's a leaf or unknown
          (mv visited (list cert-path))
        ;; Process all book dependencies first
        (mv-let (visited deps)
          (collect-all-deps-list 
           (book-dep-list-paths (certinfo->bookdeps certinfo))
           depdb visited)
          ;; Also process port dependencies
          (mv-let (visited more-deps)
            (collect-all-deps-list
             (book-dep-list-paths (certinfo->portdeps certinfo))
             depdb visited)
            (mv visited (append deps more-deps (list cert-path)))))))))

(defun book-dep-list-paths (deps)
  "Extract just the paths from a list of book-dep structures"
  (declare (xargs :guard (book-dep-listp deps)))
  (if (atom deps)
      nil
    (cons (book-dep->path (car deps))
          (book-dep-list-paths (cdr deps)))))

(defun collect-all-deps-list (cert-paths depdb visited)
  "Collect dependencies for a list of certificates."
  (declare (xargs :guard (and (string-listp cert-paths)
                              (depdb-p depdb)
                              (alistp visited))))
  (if (atom cert-paths)
      (mv visited nil)
    (mv-let (visited deps1)
      (collect-all-deps (car cert-paths) depdb visited)
      (mv-let (visited deps-rest)
        (collect-all-deps-list (cdr cert-paths) depdb visited)
        (mv visited (append deps1 deps-rest))))))

;; ============================================================================
;; Cycle detection
;; ============================================================================

(defun check-cycle (cert-path stack)
  "Check if cert-path is already in the traversal stack (indicates cycle).
   Returns the cycle path if found, nil otherwise."
  (declare (xargs :guard (and (stringp cert-path)
                              (string-listp stack))))
  (if (member-equal cert-path stack)
      ;; Found a cycle - return the path from cert-path back to itself
      (cons cert-path (ldiff stack (member-equal cert-path stack)))
    nil))

;; ============================================================================
;; Up-to-date checking
;; ============================================================================

;; A certificate is up-to-date if:
;; 1. The .cert2 file exists
;; 2. The .cert2 file is newer than the .lisp file
;; 3. The .cert2 file is newer than all source dependencies
;; 4. The .cert2 file is newer than all certificate dependencies

;; These checks are done in raw Lisp since they require file system access.
;; Here we define the logical structure.

(defun cert-needs-rebuild-p (cert-path certinfo timestamps)
  "Check if a certificate needs rebuilding based on timestamps.
   TIMESTAMPS is an alist mapping paths to modification times.
   Returns T if rebuild is needed."
  (declare (xargs :guard (and (stringp cert-path)
                              (certinfo-p certinfo)
                              (alistp timestamps))))
  (let ((cert-time (cdr (assoc-equal cert-path timestamps))))
    (or 
     ;; Cert doesn't exist
     (null cert-time)
     (< cert-time 0)
     ;; Check source deps
     (some-newer-p (certinfo->srcdeps certinfo) cert-time timestamps)
     ;; Check other deps
     (some-newer-p (certinfo->otherdeps certinfo) cert-time timestamps)
     ;; Check book deps
     (some-newer-p (book-dep-list-paths (certinfo->bookdeps certinfo))
                   cert-time timestamps)
     ;; Check port deps
     (some-newer-p (book-dep-list-paths (certinfo->portdeps certinfo))
                   cert-time timestamps))))

(defun some-newer-p (paths cert-time timestamps)
  "Check if any path in PATHS has a timestamp newer than CERT-TIME."
  (declare (xargs :guard (and (string-listp paths)
                              (rationalp cert-time)
                              (alistp timestamps))))
  (if (atom paths)
      nil
    (let ((path-time (cdr (assoc-equal (car paths) timestamps))))
      (or (and path-time (> path-time cert-time))
          (some-newer-p (cdr paths) cert-time timestamps)))))

;; ============================================================================
;; Build order computation
;; ============================================================================

;; Given a set of target certificates, compute the build order:
;; 1. Collect all transitive dependencies
;; 2. Filter to those needing rebuild
;; 3. Topologically sort

(defun compute-build-order (targets depdb timestamps)
  "Compute the list of certificates to build, in dependency order.
   TARGETS is a list of certificate paths to build.
   Returns list of cert paths in build order (deps before dependents)."
  (declare (xargs :guard (and (string-listp targets)
                              (depdb-p depdb)
                              (alistp timestamps))))
  (mv-let (visited all-deps)
    (collect-all-deps-list targets depdb nil)
    (declare (ignore visited))
    ;; Remove duplicates while preserving order
    (remove-dups-preserving-order 
     ;; Filter to those needing rebuild
     (filter-needs-rebuild all-deps depdb timestamps))))

(defun remove-dups-preserving-order (lst)
  "Remove duplicates from LST, keeping first occurrence."
  (declare (xargs :guard (true-listp lst)))
  (remove-dups-aux lst nil))

(defun remove-dups-aux (lst seen)
  (declare (xargs :guard (and (true-listp lst) (true-listp seen))))
  (if (atom lst)
      nil
    (if (member-equal (car lst) seen)
        (remove-dups-aux (cdr lst) seen)
      (cons (car lst)
            (remove-dups-aux (cdr lst) (cons (car lst) seen))))))

(defun filter-needs-rebuild (certs depdb timestamps)
  "Filter CERTS to only those that need rebuilding."
  (declare (xargs :guard (and (string-listp certs)
                              (depdb-p depdb)
                              (alistp timestamps))))
  (if (atom certs)
      nil
    (let ((certinfo (get-certinfo (car certs) depdb)))
      (if (or (null certinfo)
              (cert-needs-rebuild-p (car certs) certinfo timestamps))
          (cons (car certs)
                (filter-needs-rebuild (cdr certs) depdb timestamps))
        (filter-needs-rebuild (cdr certs) depdb timestamps)))))

;; ============================================================================
;; Parallel build scheduling
;; ============================================================================

;; For parallel builds, we need to track which books are "ready" to build
;; (all dependencies satisfied) vs "blocked" (waiting on dependencies).

(defun find-ready-books (pending completed)
  "Find books in PENDING whose dependencies are all in COMPLETED.
   PENDING is alist of (cert-path . certinfo).
   COMPLETED is alist of completed cert-paths.
   Returns list of ready cert-paths."
  (declare (xargs :guard (and (alistp pending) (alistp completed))))
  (if (atom pending)
      nil
    (let* ((cert-path (caar pending))
           (certinfo (cdar pending))
           (deps (when (certinfo-p certinfo)
                   (book-dep-list-paths (certinfo->bookdeps certinfo)))))
      (if (all-completed-p deps completed)
          (cons cert-path
                (find-ready-books (cdr pending) completed))
        (find-ready-books (cdr pending) completed)))))

(defun all-completed-p (deps completed)
  "Check if all DEPS are in COMPLETED alist."
  (declare (xargs :guard (and (string-listp deps) (alistp completed))))
  (if (atom deps)
      t
    (and (assoc-equal (car deps) completed)
         (all-completed-p (cdr deps) completed))))
