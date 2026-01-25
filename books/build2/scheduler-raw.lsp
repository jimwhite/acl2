; ACL2 Build2 System - Parallel Build Scheduler
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This file implements parallel certification using subprocesses.

(in-package "BUILD2")

;; ============================================================================
;; Configuration
;; ============================================================================

(defvar *num-jobs* 1
  "Number of parallel certification jobs to run.")

(defvar *keep-going* nil
  "If T, continue building other books even after failures.")

;; ============================================================================
;; Job tracking
;; ============================================================================

(defstruct build-job
  "A certification job."
  cert-path      ; The .cert2 file to produce
  lisp-path      ; The .lisp source file
  process        ; The subprocess (when running)
  output-file    ; Path to output file
  start-time     ; When the job started
  status)        ; :pending, :running, :success, :failed

(defun make-jobs-from-build-order (build-order)
  "Create build-job structures for each certificate in build order."
  (mapcar (lambda (cert-path)
            (make-build-job
             :cert-path cert-path
             :lisp-path (cert2-to-lisp cert-path)
             :status :pending))
          build-order))

;; ============================================================================
;; Job execution
;; ============================================================================

(defun start-certification-job (job)
  "Start a certification job as a subprocess. Returns the updated job."
  (let* ((lisp-path (build-job-lisp-path job))
         (cert-path (build-job-cert-path job))
         (base-path (subseq cert-path 0 (- (length cert-path) 6)))
         (script-path (concatenate 'string base-path ".cert2-script.lsp"))
         (output-path (concatenate 'string base-path ".cert2.out"))
         (certinfo (or (get-certinfo cert-path *depdb*)
                       (collect-deps-for-book lisp-path)))
         (commands (generate-certify-script lisp-path certinfo :step :certify))
         (image (or (cert-params->acl2-image (certinfo->params certinfo))
                   *acl2-executable*
                   "acl2")))
    
    ;; Write script file
    (with-open-file (stream script-path :direction :output :if-exists :supersede)
      (dolist (cmd commands)
        (format stream "~A~%" cmd)))
    
    ;; Delete old cert files
    (delete-cert-files base-path)
    
    ;; Start subprocess
    (setup-certification-env)
    (let ((process (start-subprocess image script-path output-path)))
      (setf (build-job-process job) process)
      (setf (build-job-output-file job) output-path)
      (setf (build-job-start-time job) (get-universal-time))
      (setf (build-job-status job) :running)
      (when *verbose*
        (format t "[~A] Starting: ~A~%" 
                (format-time (build-job-start-time job))
                (build-job-lisp-path job)))
      job)))

(defun start-subprocess (image script-path output-path)
  "Start an ACL2 subprocess. Returns a process handle."
  #+sbcl
  (sb-ext:run-program "/bin/sh"
                      (list "-c" (format nil "~A < ~A > ~A 2>&1"
                                        image script-path output-path))
                      :search nil
                      :wait nil)
  #+ccl
  (ccl:run-program "/bin/sh"
                   (list "-c" (format nil "~A < ~A > ~A 2>&1"
                                     image script-path output-path))
                   :wait nil)
  #-(or sbcl ccl)
  (error "start-subprocess not implemented for this Lisp"))

(defun check-job-status (job)
  "Check if a running job has completed. Updates and returns the job."
  (let ((process (build-job-process job)))
    (when (and process (eq (build-job-status job) :running))
      (let ((exit-code (get-process-exit-code process)))
        (when exit-code
          ;; Job has completed
          (let* ((base-path (subseq (build-job-cert-path job) 0 
                                    (- (length (build-job-cert-path job)) 6)))
                 (script-path (concatenate 'string base-path ".cert2-script.lsp")))
            ;; Clean up script file
            (unless *debug*
              (when (probe-file script-path)
                (delete-file script-path)))
            
            (if (= exit-code 43)
                (progn
                  (setf (build-job-status job) :success)
                  (when *verbose*
                    (format t "[~A] Completed: ~A (~A seconds)~%"
                            (format-time (get-universal-time))
                            (build-job-lisp-path job)
                            (- (get-universal-time) (build-job-start-time job)))))
              (progn
                (setf (build-job-status job) :failed)
                (format *error-output* "[~A] FAILED: ~A (exit code ~A)~%"
                        (format-time (get-universal-time))
                        (build-job-lisp-path job)
                        exit-code)
                (format *error-output* "  See ~A for details~%"
                        (build-job-output-file job)))))))))
  job)

(defun get-process-exit-code (process)
  "Get the exit code of a process, or NIL if still running."
  #+sbcl
  (let ((status (sb-ext:process-status process)))
    (when (eq status :exited)
      (sb-ext:process-exit-code process)))
  #+ccl
  (multiple-value-bind (status code) (ccl:external-process-status process)
    (when (eq status :exited)
      code))
  #-(or sbcl ccl)
  (error "get-process-exit-code not implemented for this Lisp"))

(defun format-time (universal-time)
  "Format a universal time as HH:MM:SS."
  (multiple-value-bind (sec min hour) (decode-universal-time universal-time)
    (format nil "~2,'0D:~2,'0D:~2,'0D" hour min sec)))

;; ============================================================================
;; Dependency-aware scheduling
;; ============================================================================

(defun job-deps-satisfied-p (job completed-certs)
  "Check if all dependencies of a job are satisfied."
  (let* ((cert-path (build-job-cert-path job))
         (certinfo (get-certinfo cert-path *depdb*)))
    (if certinfo
        (let ((deps (append (book-dep-list-paths (certinfo->bookdeps certinfo))
                           (book-dep-list-paths (certinfo->portdeps certinfo)))))
          (every (lambda (dep) (member dep completed-certs :test #'equal)) deps))
      ;; No certinfo means no deps
      t)))

(defun find-ready-jobs (jobs completed-certs)
  "Find jobs that are ready to run (pending with all deps satisfied)."
  (remove-if-not (lambda (job)
                   (and (eq (build-job-status job) :pending)
                        (job-deps-satisfied-p job completed-certs)))
                 jobs))

(defun count-running (jobs)
  "Count the number of currently running jobs."
  (count :running jobs :key #'build-job-status))

;; ============================================================================
;; Main scheduler loop
;; ============================================================================

(defun run-scheduler (jobs)
  "Run the parallel build scheduler.
   JOBS is a list of build-job structures.
   Returns (values success-count failure-count failed-jobs)."
  (let ((completed-certs nil)
        (success-count 0)
        (failure-count 0)
        (failed-jobs nil))
    
    (loop
      ;; Check status of running jobs
      (dolist (job jobs)
        (when (eq (build-job-status job) :running)
          (check-job-status job)
          (case (build-job-status job)
            (:success
             (push (build-job-cert-path job) completed-certs)
             (incf success-count))
            (:failed
             (push job failed-jobs)
             (incf failure-count)
             (unless *keep-going*
               ;; Wait for running jobs to complete, then exit
               (loop while (> (count-running jobs) 0)
                     do (sleep 0.1)
                        (dolist (j jobs)
                          (when (eq (build-job-status j) :running)
                            (check-job-status j))))
               (return-from run-scheduler
                 (values success-count failure-count (nreverse failed-jobs))))))))
      
      ;; Start new jobs if we have capacity
      (when (< (count-running jobs) *num-jobs*)
        (let ((ready (find-ready-jobs jobs completed-certs)))
          (dolist (job ready)
            (when (< (count-running jobs) *num-jobs*)
              (start-certification-job job)))))
      
      ;; Check if we're done
      (when (and (zerop (count-running jobs))
                 (null (find-ready-jobs jobs completed-certs)))
        ;; Either all done or stuck
        (return-from run-scheduler
          (values success-count failure-count (nreverse failed-jobs))))
      
      ;; Small sleep to avoid busy-waiting
      (sleep 0.1))))

;; ============================================================================
;; High-level interface
;; ============================================================================

(defun certify-books-parallel (build-order)
  "Certify books in parallel according to build order.
   BUILD-ORDER is a list of .cert2 paths in dependency order.
   Returns T if all succeeded, NIL otherwise."
  (let ((jobs (make-jobs-from-build-order build-order)))
    (when *verbose*
      (format t "~%Starting parallel build with ~A jobs...~%" *num-jobs*)
      (format t "Books to certify: ~A~%" (length jobs)))
    
    (multiple-value-bind (success-count failure-count failed-jobs)
        (run-scheduler jobs)
      
      (format t "~%Build complete: ~A succeeded, ~A failed~%" 
              success-count failure-count)
      
      (when failed-jobs
        (format t "~%Failed books:~%")
        (dolist (job failed-jobs)
          (format t "  ~A~%" (build-job-lisp-path job))))
      
      (zerop failure-count))))

(defun build-targets (target-paths &key (jobs 1) keep-going no-build verbose)
  "Main entry point for building targets.
   TARGET-PATHS is a list of .lisp or .cert2 files to build.
   JOBS is the number of parallel jobs.
   KEEP-GOING continues after failures.
   NO-BUILD just prints what would be built.
   VERBOSE prints detailed progress."
  (let ((*num-jobs* jobs)
        (*keep-going* keep-going)
        (*verbose* verbose))
    
    ;; Analyze dependencies
    (when verbose
      (format t "Analyzing dependencies...~%"))
    (let ((build-order (analyze-targets target-paths)))
      
      (when verbose
        (format t "Build order (~A books):~%" (length build-order))
        (dolist (cert build-order)
          (format t "  ~A~%" cert)))
      
      (if no-build
          (progn
            (format t "~%Would build ~A books~%" (length build-order))
            t)
        ;; Actually build
        (if (= jobs 1)
            (null (certify-books-sequential build-order))
          (certify-books-parallel build-order))))))
