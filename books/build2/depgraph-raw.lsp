; ACL2 Build2 System - Raw Lisp Dependency Graph Builder
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This file builds the dependency graph by scanning source files.
; It should be loaded after depgraph.lisp and scan-raw.lsp.

(in-package "BUILD2")

;; ============================================================================
;; Global dependency database
;; ============================================================================

(defvar *depdb* (make-depdb)
  "The global dependency database")

(defun reset-depdb ()
  "Reset the dependency database to empty state."
  (setf *depdb* (make-depdb)))

;; ============================================================================
;; ACL2 file finding
;; ============================================================================

(defun find-acl2-file (lisp-path)
  "Find the .acl2 file for a given .lisp file.
   Checks for book.acl2, then cert.acl2 in the same directory.
   Returns the path or NIL."
  (let* ((base (subseq lisp-path 0 (- (length lisp-path) 5)))
         (book-acl2 (concatenate 'string base ".acl2"))
         (dir (path-dirname lisp-path))
         (cert-acl2 (path-join dir "cert.acl2")))
    (cond
      ((probe-file book-acl2) book-acl2)
      ((probe-file cert-acl2) cert-acl2)
      (t nil))))

(defun find-image-file (lisp-path)
  "Find the .image file for a given .lisp file.
   Checks for book.image, then cert.image in the same directory.
   Returns the image name or NIL."
  (let* ((base (subseq lisp-path 0 (- (length lisp-path) 5)))
         (book-image (concatenate 'string base ".image"))
         (dir (path-dirname lisp-path))
         (cert-image (path-join dir "cert.image")))
    (cond
      ((probe-file book-image)
       (string-trim '(#\Space #\Tab #\Newline #\Return)
                    (car (read-file-lines-raw book-image))))
      ((probe-file cert-image)
       (string-trim '(#\Space #\Tab #\Newline #\Return)
                    (car (read-file-lines-raw cert-image))))
      (t nil))))

;; ============================================================================
;; Event processing
;; ============================================================================

(defun process-events (events certinfo base-dir in-acl2-file ifdef-state)
  "Process a list of events, updating certinfo.
   BASE-DIR is the directory of the source file.
   IN-ACL2-FILE is T if we're processing a .acl2 file.
   IFDEF-STATE is (level . skip-level) for ifdef processing.
   Returns updated certinfo."
  (if (null events)
      certinfo
    (let* ((event (car events))
           (type (car event)))
      ;; Handle ifdef state
      (cond
        ;; ifdef/ifndef
        ((eq type :ifdef)
         (let* ((var (second event))
                (is-ifdef (third event))
                (level (car ifdef-state))
                (skip-level (cdr ifdef-state))
                (new-level (1+ level)))
           (if (> skip-level 0)
               ;; Already skipping
               (process-events (cdr events) certinfo base-dir in-acl2-file
                               (cons new-level skip-level))
             ;; Check condition
             (let* ((defined (assoc-equal var (certinfo->local-defines certinfo)))
                    (cond-true (if is-ifdef defined (not defined))))
               (process-events (cdr events) certinfo base-dir in-acl2-file
                               (cons new-level (if cond-true 0 new-level)))))))
        
        ;; endif
        ((eq type :endif)
         (let* ((level (car ifdef-state))
                (skip-level (cdr ifdef-state))
                (new-level (max 0 (1- level)))
                (new-skip (if (and (> skip-level 0) (= skip-level level))
                              0
                            skip-level)))
           (process-events (cdr events) certinfo base-dir in-acl2-file
                           (cons new-level new-skip))))
        
        ;; Skip if in false ifdef branch
        ((and (cdr ifdef-state) (> (cdr ifdef-state) 0))
         (process-events (cdr events) certinfo base-dir in-acl2-file ifdef-state))
        
        ;; Normal event processing
        (t
         (let ((new-certinfo (process-single-event event certinfo base-dir in-acl2-file)))
           (process-events (cdr events) new-certinfo base-dir in-acl2-file ifdef-state)))))))

(defun process-single-event (event certinfo base-dir in-acl2-file)
  "Process a single event, updating certinfo."
  (let ((type (car event)))
    (case type
      (:include-book
       (let* ((name (second event))
              (dir-kwd (third event))
              (localp (fourth event))
              (no-port (fifth event))
              (full-path (resolve-book-path name dir-kwd
                                            (certinfo->local-include-dirs certinfo)
                                            base-dir)))
         (declare (ignore no-port)) ; TODO: track no-port
         (if full-path
             (let ((cert-path (lisp-to-cert2 full-path))
                   (dep (make-book-dep :path (lisp-to-cert2 full-path)
                                       :localp localp)))
               (if in-acl2-file
                   ;; Add to portdeps
                   (change-certinfo certinfo
                                    :portdeps (cons dep (certinfo->portdeps certinfo)))
                 ;; Add to bookdeps
                 (change-certinfo certinfo
                                  :bookdeps (cons dep (certinfo->bookdeps certinfo)))))
           certinfo)))
      
      (:add-include-book-dir!
       (let* ((dirname (second event))
              (path (third event))
              (kwd (intern (string-upcase dirname) :keyword))
              (full-path (canonical-path (path-join base-dir path))))
         (change-certinfo certinfo
                          :include-dirs (acons kwd full-path (certinfo->include-dirs certinfo))
                          :local-include-dirs (acons kwd full-path (certinfo->local-include-dirs certinfo)))))
      
      (:add-include-book-dir
       (let* ((dirname (second event))
              (path (third event))
              (kwd (intern (string-upcase dirname) :keyword))
              (full-path (canonical-path (path-join base-dir path))))
         (change-certinfo certinfo
                          :local-include-dirs (acons kwd full-path (certinfo->local-include-dirs certinfo)))))
      
      (:depends-on
       (let* ((file (second event))
              (dir-kwd (third event))
              (full-path (resolve-book-path file dir-kwd
                                            (certinfo->local-include-dirs certinfo)
                                            base-dir)))
         (if full-path
             (change-certinfo certinfo
                              :otherdeps (cons full-path (certinfo->otherdeps certinfo)))
           certinfo)))
      
      (:cert-param
       (let* ((key (second event))
              (value (third event))
              (new-params (parse-cert-param-event key value (certinfo->params certinfo))))
         (change-certinfo certinfo :params new-params)))
      
      (:ifdef-define
       (let ((var (second event)))
         (change-certinfo certinfo
                          :defines (acons var t (certinfo->defines certinfo))
                          :local-defines (acons var t (certinfo->local-defines certinfo)))))
      
      (:ifdef-undefine
       (let ((var (second event)))
         (change-certinfo certinfo
                          :defines (acons var nil (certinfo->defines certinfo))
                          :local-defines (acons var nil (certinfo->local-defines certinfo)))))
      
      ;; TODO: handle :loads, :ld, :include-events, :include-src-events
      ;; These require recursive scanning
      
      (otherwise certinfo))))

;; ============================================================================
;; Main dependency collection
;; ============================================================================

(defun collect-deps-for-book (lisp-path)
  "Collect all dependencies for a book. Returns certinfo."
  (let* ((certinfo (make-certinfo))
         (base-dir (path-dirname lisp-path))
         ;; First, process .acl2 file if it exists
         (acl2-file (find-acl2-file lisp-path)))
    
    ;; Process .acl2 file
    (when acl2-file
      (let ((events (scan-file-raw acl2-file)))
        (setf certinfo (change-certinfo certinfo
                                        :srcdeps (cons acl2-file (certinfo->srcdeps certinfo))))
        (setf certinfo (process-events events certinfo base-dir t (cons 0 0)))))
    
    ;; Process the main .lisp file
    (let ((events (scan-file-raw lisp-path)))
      (setf certinfo (change-certinfo certinfo
                                      :srcdeps (cons lisp-path (certinfo->srcdeps certinfo))))
      (setf certinfo (process-events events certinfo base-dir nil (cons 0 0))))
    
    ;; Check for .image file
    (let ((image (find-image-file lisp-path)))
      (when (and image (not (cert-params->acl2-image (certinfo->params certinfo))))
        (setf certinfo (change-certinfo certinfo
                                        :params (change-cert-params (certinfo->params certinfo)
                                                                    :acl2-image image)))))
    
    certinfo))

(defun add-deps-recursive (cert-path &optional (stack nil))
  "Add dependencies for a certificate, recursively processing dependencies.
   Uses *depdb* as the global database."
  ;; Check for cycles
  (when (member cert-path stack :test #'equal)
    (error "Dependency cycle detected: ~A" (cons cert-path stack)))
  
  ;; Check if already processed
  (when (get-certinfo cert-path *depdb*)
    (return-from add-deps-recursive nil))
  
  ;; Get the .lisp file
  (let ((lisp-path (cert2-to-lisp cert-path)))
    (unless (probe-file lisp-path)
      (format *error-output* "Warning: Source file not found: ~A~%" lisp-path)
      (return-from add-deps-recursive nil))
    
    ;; Collect dependencies
    (let ((certinfo (collect-deps-for-book lisp-path)))
      
      ;; Store in database
      (setf *depdb* (put-certinfo cert-path certinfo *depdb*))
      
      ;; Recursively process dependencies
      (let ((new-stack (cons cert-path stack)))
        (dolist (dep (certinfo->bookdeps certinfo))
          (add-deps-recursive (book-dep->path dep) new-stack))
        (dolist (dep (certinfo->portdeps certinfo))
          (add-deps-recursive (book-dep->path dep) new-stack))))))

;; ============================================================================
;; Timestamp collection
;; ============================================================================

(defun collect-timestamps (paths)
  "Collect file timestamps for a list of paths.
   Returns alist of (path . timestamp)."
  (mapcar (lambda (path)
            (cons path (file-timestamp path)))
          paths))

(defun collect-all-timestamps ()
  "Collect timestamps for all files in the dependency database."
  (let ((paths nil))
    ;; Collect all cert paths
    (dolist (entry (depdb->certdeps *depdb*))
      (push (car entry) paths)
      ;; Also collect source deps for each cert
      (let ((certinfo (cdr entry)))
        (when (certinfo-p certinfo)
          (dolist (src (certinfo->srcdeps certinfo))
            (pushnew src paths :test #'equal))
          (dolist (other (certinfo->otherdeps certinfo))
            (pushnew other paths :test #'equal)))))
    (collect-timestamps paths)))

;; ============================================================================
;; High-level interface
;; ============================================================================

(defun analyze-targets (target-paths)
  "Analyze a list of target .lisp or .cert2 files.
   Builds the dependency graph in *depdb*.
   Returns list of cert paths in build order."
  (reset-depdb)
  
  ;; Normalize targets to cert paths
  (let ((cert-paths (mapcar (lambda (path)
                              (if (has-extension path ".lisp")
                                  (lisp-to-cert2 (canonical-path path))
                                (canonical-path path)))
                            target-paths)))
    ;; Build dependency graph
    (dolist (cert cert-paths)
      (add-deps-recursive cert))
    
    ;; Collect timestamps
    (let ((timestamps (collect-all-timestamps)))
      ;; Compute build order
      (compute-build-order cert-paths *depdb* timestamps))))

(defun print-deps (cert-path &optional (stream *standard-output*))
  "Print the dependencies of a certificate."
  (let ((certinfo (get-certinfo cert-path *depdb*)))
    (if certinfo
        (progn
          (format stream "~%Dependencies for ~A:~%" cert-path)
          (format stream "  Source files:~%")
          (dolist (src (certinfo->srcdeps certinfo))
            (format stream "    ~A~%" src))
          (format stream "  Book dependencies:~%")
          (dolist (dep (certinfo->bookdeps certinfo))
            (format stream "    ~A~A~%" 
                    (book-dep->path dep)
                    (if (book-dep->localp dep) " (local)" "")))
          (format stream "  Port dependencies:~%")
          (dolist (dep (certinfo->portdeps certinfo))
            (format stream "    ~A~A~%"
                    (book-dep->path dep)
                    (if (book-dep->localp dep) " (local)" "")))
          (format stream "  Other dependencies:~%")
          (dolist (other (certinfo->otherdeps certinfo))
            (format stream "    ~A~%" other))
          (format stream "  Params: ~A~%" (certinfo->params certinfo)))
      (format stream "No info for ~A~%" cert-path))))
