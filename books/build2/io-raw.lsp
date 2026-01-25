; ACL2 Build2 System - Raw Lisp I/O
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file contains raw Common Lisp code for OS interaction that cannot
; be done in pure ACL2. This is the ONLY place where we use raw CL.
;
; Functions provided:
; - get-file-write-time: Get file modification timestamp
; - file-exists-p: Check if file exists
; - run-acl2-subprocess: Run ACL2 certification subprocess
; - get-all-timestamps: Get timestamps for a list of files

(in-package "BUILD2")

;; ============================================================================
;; File timestamp operations (raw Lisp)
;; ============================================================================

(defun get-file-write-time-raw (path)
  "Get the write time of a file as a universal time integer.
   Returns 0 if the file does not exist."
  (declare (type string path))
  (handler-case
      (or (file-write-date path) 0)
    (error () 0)))

(defun file-exists-p-raw (path)
  "Check if a file exists."
  (declare (type string path))
  (handler-case
      (probe-file path)
    (error () nil)))

(defun get-all-timestamps-raw (paths)
  "Get timestamps for a list of paths. Returns an alist."
  (declare (type list paths))
  (loop for path in paths
        collect (cons path (get-file-write-time-raw path))))

;; ============================================================================
;; Subprocess execution (raw Lisp)
;; ============================================================================

(defvar *acl2-program* nil
  "Path to the ACL2 executable. Set before running certifications.")

(defun run-acl2-subprocess-raw (script-commands output-file)
  "Run an ACL2 subprocess with the given commands.
   SCRIPT-COMMANDS is a list of ACL2 command strings.
   OUTPUT-FILE is where to write the output.
   Returns the exit status."
  (declare (type list script-commands)
           (type string output-file))
  
  (let* ((acl2 (or *acl2-program* 
                   (error "BUILD2:*ACL2-PROGRAM* not set")))
         ;; Create the input script
         (script (format nil "~{~A~%~}(good-bye)~%" script-commands)))
    
    ;; Run ACL2 with script on stdin, output to file
    #+sbcl
    (let* ((proc (sb-ext:run-program 
                  "/bin/sh"
                  (list "-c" 
                        (format nil "echo '~A' | ~A > ~A 2>&1"
                                script acl2 output-file))
                  :wait t)))
      (sb-ext:process-exit-code proc))
    
    #+ccl
    (let* ((result (ccl:run-program
                    "/bin/sh"
                    (list "-c"
                          (format nil "echo '~A' | ~A > ~A 2>&1"
                                  script acl2 output-file))
                    :wait t)))
      (ccl:external-process-status result))
    
    #-(or sbcl ccl)
    (error "run-acl2-subprocess-raw not implemented for this Lisp")))

;; ============================================================================  
;; Directory listing (raw Lisp)
;; ============================================================================

(defun list-lisp-files-raw (dir)
  "List all .lisp files in a directory."
  (declare (type string dir))
  (let ((pattern (make-pathname :directory dir
                                :name :wild
                                :type "lisp")))
    (mapcar #'namestring (directory pattern))))

;; ============================================================================
;; Reading file contents (uses ACL2's mechanism)
;; ============================================================================

;; For reading files, we use ACL2's std/io library which has proper
;; guards and theorems. This raw file just handles OS-level operations
;; that ACL2 can't do directly.

;; ============================================================================
;; Environment setup
;; ============================================================================

(defun setup-build-environment-raw ()
  "Set up the build environment. Called before starting certifications."
  ;; Find ACL2 executable
  (unless *acl2-program*
    (let ((acl2 (or #+sbcl (sb-ext:posix-getenv "ACL2")
                    #+ccl (ccl:getenv "ACL2")
                    #-(or sbcl ccl) nil)))
      (when acl2
        (setf *acl2-program* acl2))))
  
  ;; Return success indicator
  (if *acl2-program* t nil))

;; ============================================================================
;; Parallel execution infrastructure
;; ============================================================================

(defvar *max-jobs* 1
  "Maximum number of parallel certification jobs.")

(defvar *running-jobs* nil
  "List of currently running job processes.")

(defstruct build-job
  "A running certification job."
  book-path
  process
  output-file
  start-time)

(defun start-certification-job-raw (book-path commands output-file)
  "Start a certification job as a background process.
   Returns a build-job structure."
  (declare (type string book-path output-file)
           (type list commands))
  
  (let* ((acl2 (or *acl2-program*
                   (error "BUILD2:*ACL2-PROGRAM* not set")))
         (script (format nil "~{~A~%~}(good-bye)~%" commands)))
    
    #+sbcl
    (let ((proc (sb-ext:run-program
                 "/bin/sh"
                 (list "-c"
                       (format nil "echo '~A' | ~A > ~A 2>&1"
                               script acl2 output-file))
                 :wait nil)))  ; Don't wait - run async
      (make-build-job
       :book-path book-path
       :process proc
       :output-file output-file
       :start-time (get-universal-time)))
    
    #+ccl
    (let ((proc (ccl:run-program
                 "/bin/sh"
                 (list "-c"
                       (format nil "echo '~A' | ~A > ~A 2>&1"
                               script acl2 output-file))
                 :wait nil)))
      (make-build-job
       :book-path book-path
       :process proc
       :output-file output-file
       :start-time (get-universal-time)))
    
    #-(or sbcl ccl)
    (error "start-certification-job-raw not implemented for this Lisp")))

(defun job-finished-p-raw (job)
  "Check if a build job has finished."
  (declare (type build-job job))
  #+sbcl
  (not (sb-ext:process-alive-p (build-job-process job)))
  #+ccl
  (multiple-value-bind (status code)
      (ccl:external-process-status (build-job-process job))
    (declare (ignore code))
    (eq status :exited))
  #-(or sbcl ccl)
  t)

(defun job-exit-code-raw (job)
  "Get the exit code of a finished job."
  (declare (type build-job job))
  #+sbcl
  (sb-ext:process-exit-code (build-job-process job))
  #+ccl
  (multiple-value-bind (status code)
      (ccl:external-process-status (build-job-process job))
    (declare (ignore status))
    code)
  #-(or sbcl ccl)
  1)

;; ============================================================================
;; Timestamp caching
;; ============================================================================

(defvar *timestamp-cache* (make-hash-table :test #'equal)
  "Cache of file timestamps to avoid repeated system calls.")

(defun cached-file-write-time (path)
  "Get file write time with caching."
  (or (gethash path *timestamp-cache*)
      (setf (gethash path *timestamp-cache*)
            (get-file-write-time-raw path))))

(defun clear-timestamp-cache ()
  "Clear the timestamp cache."
  (clrhash *timestamp-cache*))
