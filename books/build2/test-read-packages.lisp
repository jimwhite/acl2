;;; Test file for reading Lisp files with dynamic package creation
;;; Run with: sbcl --load test-read-packages.lisp

(defpackage :test-read-packages
  (:use :cl))

(in-package :test-read-packages)

;; Create ACL2 package if it doesn't exist (needed for reading ACL2 books)
(unless (find-package "ACL2")
  (make-package "ACL2" :use '("COMMON-LISP")))

(defvar *verbose* t)

(defun ensure-package-exists (name)
  "Create package NAME if it does not exist."
  (let ((name-str (string name)))
    (or (find-package name-str)
        (progn
          (when *verbose*
            (format t "Creating package: ~A~%" name-str))
          (make-package name-str :use '("COMMON-LISP"))))))

(defun read-lisp-file-with-packages (filename)
  "Read a lisp file, creating packages as needed.
   Restarts from beginning if new packages are created."
  (format t "~%Reading: ~A~%" filename)
  (let ((created-packages nil)
        (max-retries 10))
    (loop for attempt from 1 to max-retries do
      (setf created-packages nil)
      (handler-case
          (with-open-file (in filename :direction :input)
            (let ((*package* (find-package "ACL2"))
                  (*read-eval* nil)
                  (forms nil))
              (loop
                (let ((form (read in nil :eof)))
                  (if (eq form :eof)
                      (return-from read-lisp-file-with-packages (nreverse forms))
                      (progn
                        (push form forms)
                        ;; Handle in-package
                        (when (and (consp form) 
                                   (member (car form) '(in-package acl2::in-package cl:in-package)))
                          (let ((pkg-name (string (cadr form))))
                            (ensure-package-exists pkg-name)
                            (setf *package* (find-package pkg-name))))))))))
        (sb-int:simple-reader-package-error (c)
          (let ((pkg-name (sb-kernel::package-error-package c)))
            (format t "  Package error: ~A - creating and retrying...~%" pkg-name)
            (ensure-package-exists pkg-name)
            (push pkg-name created-packages)))
        (error (c)
          (format t "  Error: ~A~%" c)
          (return-from read-lisp-file-with-packages nil)))
      ;; If we get here, we caught a package error and need to retry
      (unless created-packages
        (return-from read-lisp-file-with-packages nil)))
    ;; Exceeded max retries
    (format t "  Exceeded max retries~%")
    nil))

(defun test-read-file (path)
  "Test reading a file and report results."
  (let ((forms (read-lisp-file-with-packages path)))
    (if forms
        (format t "  SUCCESS: Read ~D forms~%" (length forms))
        (format t "  FAILED: Could not read forms~%"))
    forms))

;;; Run tests
(format t "~%=== Testing package-aware file reading ===~%")

;; Test 1: Simple ACL2 file
(test-read-file "/workspaces/acl2/books/arithmetic-2/floor-mod/floor-mod.lisp")

;; Test 2: File with custom package (FTY)
(test-read-file "/workspaces/acl2/books/centaur/fty/fty-alist.lisp")

;; Test 3: File with STD package
(test-read-file "/workspaces/acl2/books/std/lists/list-defuns.lisp")

;; Test 4: File with multiple package references
(test-read-file "/workspaces/acl2/books/std/strings/cat.lisp")

;; Test 5: Complex file with many dependencies
(test-read-file "/workspaces/acl2/books/centaur/fty/deftypes.lisp")

(format t "~%=== Tests complete ===~%")
