; ACL2 Build2 System - Dependency Graph
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file implements dependency graph construction and build order computation.
; We leverage the centaur/depgraph library for topological sorting.

(in-package "BUILD2")

(include-book "types")
(include-book "scan")
(include-book "centaur/depgraph/top" :dir :system)
(include-book "oslib/catpath" :dir :system)

;; ============================================================================
;; Path resolution utilities
;; ============================================================================

(define resolve-book-path ((name stringp)
                           (dir maybe-stringp)
                           (basedir stringp)
                           (include-dirs keyword-string-alistp))
  :returns (path stringp)
  :short "Resolve a book name to a canonical path."
  :long "<p>Handles :dir arguments like :system by looking them up
in the include-dirs alist.</p>"
  
  (b* (((when (null dir))
        ;; No :dir, relative to basedir
        (oslib::catpath basedir name))
       
       ;; Look up the directory keyword
       (kw (intern dir "KEYWORD"))
       (dir-path (cdr (assoc-eq kw include-dirs)))
       
       ((when dir-path)
        ;; Found in include-dirs
        (oslib::catpath dir-path name))
       
       ;; Fallback: treat as relative to basedir
       ;; (In practice this shouldn't happen for well-formed books)
       (oslib::catpath basedir name)))

(define lisp-to-cert2 ((path stringp))
  :returns (cert-path stringp)
  :short "Convert a .lisp path to .cert2 path."
  (b* ((len (length path))
       ((when (and (>= len 5)
                   (equal (subseq path (- len 5) len) ".lisp")))
        (str::cat (subseq path 0 (- len 5)) ".cert2")))
    ;; No .lisp extension, just append .cert2
    (str::cat path ".cert2")))

;; ============================================================================
;; Processing scanned events into certinfo
;; ============================================================================

(define process-include-book-event ((event scan-event-include-book-p)
                                    (basedir stringp)
                                    (include-dirs keyword-string-alistp))
  :returns (dep book-dep-p)
  :short "Convert an include-book event to a book-dep."
  (b* ((name (scan-event-include-book->name event))
       (dir (scan-event-include-book->dir event))
       (localp (scan-event-include-book->localp event))
       (path (resolve-book-path name dir basedir include-dirs))
       (cert-path (lisp-to-cert2 (str::cat path ".lisp"))))
    (make-book-dep :path cert-path :localp localp)))

(define process-cert-param-event ((event scan-event-cert-param-p)
                                  (params cert-params-p))
  :returns (new-params cert-params-p)
  :short "Update cert-params based on a cert_param event."
  (b* ((name (str::downcase-string (scan-event-cert-param->name event)))
       (value (scan-event-cert-param->value event))
       (truep (or (equal value "") 
                  (equal (str::downcase-string value) "t")
                  (equal value "1"))))
    (cond
     ((equal name "acl2x")
      (change-cert-params params :acl2x truep))
     ((equal name "acl2xskip")
      (change-cert-params params :acl2xskip truep))
     ((equal name "pcert")
      (change-cert-params params :pcert truep))
     ((equal name "reloc-stub")
      (change-cert-params params :reloc-stub truep))
     ((equal name "ansi-only")
      (change-cert-params params :ansi-only truep))
     ((equal name "ccl-only")
      (change-cert-params params :ccl-only truep))
     ((equal name "non-allegro")
      (change-cert-params params :non-allegro truep))
     ((equal name "non-cmucl")
      (change-cert-params params :non-cmucl truep))
     ((equal name "non-gcl")
      (change-cert-params params :non-gcl truep))
     ((equal name "non-lispworks")
      (change-cert-params params :non-lispworks truep))
     ((equal name "non-sbcl")
      (change-cert-params params :non-sbcl truep))
     ((equal name "non-acl2r")
      (change-cert-params params :non-acl2r truep))
     ((equal name "non-acl2p")
      (change-cert-params params :non-acl2p truep))
     ((equal name "uses-acl2r")
      (change-cert-params params :uses-acl2r truep))
     ((equal name "uses-glucose")
      (change-cert-params params :uses-glucose truep))
     ((equal name "uses-ipasir")
      (change-cert-params params :uses-ipasir truep))
     ((equal name "uses-abc")
      (change-cert-params params :uses-abc truep))
     ((equal name "uses-smtlink")
      (change-cert-params params :uses-smtlink truep))
     ((equal name "uses-stp")
      (change-cert-params params :uses-stp truep))
     ((equal name "uses-quicklisp")
      (change-cert-params params :uses-quicklisp truep))
     ((equal name "uses-cpp")
      (change-cert-params params :uses-cpp truep))
     (t params))))

(define events-to-certinfo-aux ((events scan-event-list-p)
                                (basedir stringp)
                                (include-dirs keyword-string-alistp)
                                (bookdeps book-dep-list-p)
                                (otherdeps string-listp)
                                (srcdeps string-listp)
                                (params cert-params-p))
  :returns (mv (bookdeps book-dep-list-p :hyp :guard)
               (otherdeps string-listp :hyp :guard)
               (srcdeps string-listp :hyp :guard)
               (params cert-params-p :hyp :guard)
               (new-dirs keyword-string-alistp :hyp :guard))
  :short "Process a list of events accumulating into certinfo fields."
  
  (if (endp events)
      (mv bookdeps otherdeps srcdeps params include-dirs)
    (b* ((event (car events))
         ((mv bookdeps otherdeps srcdeps params include-dirs)
          (cond
           ;; Include-book adds a book dependency
           ((scan-event-include-book-p event)
            (b* ((dep (process-include-book-event event basedir include-dirs)))
              (mv (cons dep bookdeps) otherdeps srcdeps params include-dirs)))
           
           ;; Depends-on adds an other dependency
           ((scan-event-depends-on-p event)
            (b* ((path (scan-event-depends-on->path event)))
              (mv bookdeps (cons path otherdeps) srcdeps params include-dirs)))
           
           ;; Loads adds a source dependency  
           ((scan-event-loads-p event)
            (b* ((path (scan-event-loads->path event)))
              (mv bookdeps otherdeps (cons path srcdeps) params include-dirs)))
           
           ;; Cert-param updates params
           ((scan-event-cert-param-p event)
            (b* ((params (process-cert-param-event event params)))
              (mv bookdeps otherdeps srcdeps params include-dirs)))
           
           ;; Add-include-book-dir updates the directory mapping
           ((scan-event-add-include-book-dir-p event)
            (b* ((kw (scan-event-add-include-book-dir->keyword event))
                 (path (scan-event-add-include-book-dir->path event))
                 (full-path (oslib::catpath basedir path)))
              (mv bookdeps otherdeps srcdeps params 
                  (cons (cons kw full-path) include-dirs))))
           
           ;; Other events (ifdef, etc.) - skip for now
           ;; TODO: Handle ifdef/ifndef properly
           (t (mv bookdeps otherdeps srcdeps params include-dirs)))))
      (events-to-certinfo-aux (cdr events) basedir include-dirs
                              bookdeps otherdeps srcdeps params))))

(define events-to-certinfo ((events scan-event-list-p)
                            (basedir stringp)
                            (include-dirs keyword-string-alistp))
  :returns (info certinfo-p)
  :short "Convert scanned events to a certinfo structure."
  (b* (((mv bookdeps otherdeps srcdeps params new-dirs)
        (events-to-certinfo-aux events basedir include-dirs
                                nil nil nil (make-cert-params))))
    (make-certinfo
     :bookdeps (reverse bookdeps)
     :otherdeps (reverse otherdeps)
     :srcdeps (reverse srcdeps)
     :params params
     :include-dirs new-dirs)))

;; ============================================================================
;; Building the dependency graph
;; ============================================================================

(define certinfo-to-dep-alist ((info certinfo-p))
  :returns (deps string-listp)
  :short "Extract the list of dependency paths from a certinfo."
  (b* ((bookdeps (certinfo->bookdeps info)))
    (if (endp bookdeps)
        nil
      (cons (book-dep->path (car bookdeps))
            (certinfo-to-dep-alist 
             (change-certinfo info :bookdeps (cdr bookdeps)))))))

(define depdb-to-graph ((db depdb-p))
  :returns (graph alistp)
  :short "Convert a depdb to a dependency graph for toposort."
  :long "<p>The graph format expected by depgraph is an alist mapping
each node to a list of nodes it depends on.</p>"
  
  (b* ((books (depdb->books db)))
    (if (endp books)
        nil
      (b* ((entry (car books))
           (book-path (car entry))
           (info (cdr entry))
           (deps (certinfo-to-dep-alist info)))
        (cons (cons book-path deps)
              (depdb-to-graph 
               (change-depdb db :books (cdr books))))))))

;; ============================================================================
;; Compute build order using depgraph:toposort
;; ============================================================================

(define compute-build-order ((db depdb-p))
  :returns (mv (successp booleanp)
               (result true-listp))
  :short "Compute the build order for books in the database."
  :long "<p>Uses depgraph:toposort to compute a topological ordering.
On success, returns (mv t order) where order is a list of book paths
in dependency order (dependencies come before dependents).
On failure (cycle detected), returns (mv nil cycle) where cycle is
a list showing the dependency cycle.</p>"
  
  (b* ((graph (depdb-to-graph db)))
    (depgraph::toposort graph)))

;; ============================================================================
;; Theorems about dependency graph properties
;; ============================================================================

;; Build order respects dependencies when toposort succeeds
(defthm compute-build-order-valid
  (implies (mv-nth 0 (compute-build-order db))
           (depgraph::topologically-ordered-p 
            (mv-nth 1 (compute-build-order db))
            (depdb-to-graph db)))
  :hints (("Goal" :in-theory (enable compute-build-order))))

;; Build order contains all books when successful
(defthm compute-build-order-complete
  (implies (mv-nth 0 (compute-build-order db))
           (set-equiv (mv-nth 1 (compute-build-order db))
                      (strip-cars (depdb->books db))))
  :hints (("Goal" :in-theory (enable compute-build-order depdb-to-graph))))
