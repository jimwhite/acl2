; ACL2 Build2 System - Raw Lisp Certification Driver
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This file handles the actual certification of individual books.
; It replaces make_cert_help.pl and make_cert.lsp from the Perl system.

(in-package "BUILD2")

;; ============================================================================
;; Configuration
;; ============================================================================

(defvar *acl2-executable* nil
  "Path to the ACL2 executable to use for certification.")

(defvar *acl2-system-books* nil
  "Path to the ACL2 system books directory.")

(defvar *images-dir* nil
  "Directory containing saved ACL2 images.")

(defvar *write-port-files* t
  "Whether to write .port2 files during certification.")

(defvar *verbose* nil
  "Print verbose output during certification.")

(defvar *debug* nil
  "Enable debug output.")

;; ============================================================================
;; Environment setup
;; ============================================================================

(defun setup-certification-env ()
  "Set up environment variables for certification."
  ;; Disable ACL2 customization files
  (setf (uiop:getenv "ACL2_CUSTOMIZATION") "NONE")
  ;; Enable port file writing if requested
  (when *write-port-files*
    (setf (uiop:getenv "ACL2_WRITE_PORT") "t"))
  ;; Set up system books path
  (when *acl2-system-books*
    (setf (uiop:getenv "ACL2_SYSTEM_BOOKS") *acl2-system-books*)))

;; ============================================================================
;; Certificate file management  
;; ============================================================================

(defun delete-cert-files (base-path)
  "Delete all certificate-related files for a book."
  (dolist (ext '(".cert2" ".pcert02" ".pcert12" ".acl2x2" ".port2"
                 ".cert2.time" ".cert2.out"))
    (let ((path (concatenate 'string base-path ext)))
      (when (probe-file path)
        (delete-file path)))))

(defun cert2-exists-p (base-path)
  "Check if the .cert2 file exists."
  (probe-file (concatenate 'string base-path ".cert2")))

;; ============================================================================
;; Port file loading commands
;; ============================================================================

(defun generate-port-loads (certinfo)
  "Generate LD commands to load .port2 files for included books.
   Returns a list of strings to be written to the certification script."
  (let ((commands nil))
    (dolist (dep (certinfo->bookdeps certinfo))
      (let* ((cert-path (book-dep->path dep))
             ;; Convert .cert2 to .port2
             (port-path (concatenate 'string
                                     (subseq cert-path 0 (- (length cert-path) 6))
                                     ".port2")))
        ;; Use ld with :ld-missing-input-ok t so it's not an error if port doesn't exist
        (push (format nil "(ld ~S :ld-missing-input-ok t :ld-always-skip-top-level-locals t :ld-error-action :return)"
                      port-path)
              commands)))
    (nreverse commands)))

;; ============================================================================
;; ACL2 script generation
;; ============================================================================

(defun generate-certify-script (lisp-path certinfo &key (step :certify))
  "Generate the ACL2 commands to certify a book.
   STEP can be :certify, :pcertify, :convert, :complete, :acl2x"
  (let* ((base-path (subseq lisp-path 0 (- (length lisp-path) 5)))
         (book-name (path-basename base-path))
         (book-dir (path-dirname base-path))
         (acl2-file (find-acl2-file lisp-path))
         (params (certinfo->params certinfo))
         (commands nil))
    
    ;; Initial setup
    (push "(value :q)" commands)  ; Exit the read-eval-print loop
    (push "(in-package \"ACL2\")" commands)
    (push "(lp)" commands)  ; Re-enter ACL2 loop
    
    ;; Error handling
    (push "(set-debugger-enable :bt)" commands)
    (push "(set-ld-error-action '(:exit 1) state)" commands)
    
    ;; Handle two-pass certification
    (when (and (eq step :acl2x) (cert-params->acl2x params))
      (if (cert-params->acl2xskip params)
          (push "(set-write-acl2x '(t) state)" commands)  ; skip-proofs
        (push "(set-write-acl2x t state)" commands)))
    
    ;; Change to book directory
    (push (format nil "(cbd ~S)" book-dir) commands)
    
    ;; Load .acl2 file contents (minus any certify-book forms)
    (when acl2-file
      (push (format nil "; Commands from ~A" acl2-file) commands)
      (let ((acl2-contents (read-acl2-file-commands acl2-file)))
        (dolist (cmd acl2-contents)
          (push cmd commands))))
    
    ;; Skip reset prehistory
    (push "(assign skip-reset-prehistory t)" commands)
    
    ;; Load port files for dependencies
    (let ((port-loads (generate-port-loads certinfo)))
      (when port-loads
        (push "; Load port files for dependencies" commands)
        (dolist (ld port-loads)
          (push ld commands))))
    
    ;; The actual certify-book command
    (let ((certify-cmd
           (case step
             (:certify
              (format nil "(certify-book ~S ? t)" book-name))
             (:pcertify
              (format nil "(certify-book ~S ? t :pcert :create)" book-name))
             (:convert
              (format nil "(certify-book ~S ? t :pcert :convert)" book-name))
             (:complete
              (format nil "(certify-book ~S ? t :pcert :complete)" book-name))
             (:acl2x
              (format nil "(certify-book ~S ? t)" book-name))
             (t
              (format nil "(certify-book ~S ? t)" book-name)))))
      
      ;; Add acl2x flag if we're in the second pass
      (when (and (eq step :certify) (cert-params->acl2x params))
        (setf certify-cmd
              (format nil "(certify-book ~S ? t :acl2x t)" book-name)))
      
      (push certify-cmd commands))
    
    ;; Exit successfully
    (push "(good-bye 43)" commands)  ; 43 is the success exit code
    
    ;; Return commands in correct order
    (nreverse commands)))

(defun read-acl2-file-commands (acl2-file)
  "Read commands from a .acl2 file, filtering out certify-book forms.
   Returns list of command strings."
  (let ((commands nil)
        (lines (read-file-lines-raw acl2-file)))
    (dolist (line lines)
      ;; Skip empty lines and comments
      (let ((trimmed (string-trim '(#\Space #\Tab) line)))
        (unless (or (string= trimmed "")
                    (and (> (length trimmed) 0) (char= (char trimmed 0) #\;))
                    ;; Skip certify-book - we generate our own
                    (search "(certify-book" (string-downcase trimmed)))
          (push line commands))))
    (nreverse commands)))

;; ============================================================================
;; Single book certification
;; ============================================================================

(defun certify-book2 (lisp-path &key (step :certify) force)
  "Certify a single book.
   LISP-PATH is the path to the .lisp file.
   STEP is :certify, :pcertify, :convert, :complete, or :acl2x.
   FORCE if T, recertify even if up-to-date.
   Returns T on success, NIL on failure."
  
  (let* ((canonical-path (canonical-path lisp-path))
         (base-path (subseq canonical-path 0 (- (length canonical-path) 5)))
         (cert-path (concatenate 'string base-path ".cert2")))
    
    ;; Check if file exists
    (unless (probe-file canonical-path)
      (format *error-output* "Error: Source file not found: ~A~%" canonical-path)
      (return-from certify-book2 nil))
    
    ;; Collect dependencies
    (let ((certinfo (collect-deps-for-book canonical-path)))
      
      ;; Check if already up-to-date (unless forcing)
      (unless force
        (let ((timestamps (collect-timestamps
                          (list* cert-path
                                 (certinfo->srcdeps certinfo)))))
          (unless (cert-needs-rebuild-p cert-path certinfo timestamps)
            (when *verbose*
              (format t "~A is up to date~%" cert-path))
            (return-from certify-book2 t))))
      
      ;; Delete old cert files
      (delete-cert-files base-path)
      
      ;; Generate certification script
      (let* ((commands (generate-certify-script canonical-path certinfo :step step))
             (script-path (concatenate 'string base-path ".cert2-script.lsp"))
             (output-path (concatenate 'string base-path ".cert2.out"))
             (image (or (cert-params->acl2-image (certinfo->params certinfo))
                       *acl2-executable*
                       "acl2")))
        
        ;; Write script file
        (with-open-file (stream script-path :direction :output :if-exists :supersede)
          (dolist (cmd commands)
            (format stream "~A~%" cmd)))
        
        (when *verbose*
          (format t "Certifying ~A with ~A~%" canonical-path image))
        
        ;; Run ACL2
        (setup-certification-env)
        (let* ((cmd (format nil "~A < ~A > ~A 2>&1"
                           image script-path output-path))
               (exit-code (run-shell-command cmd)))
          
          ;; Clean up script file
          (unless *debug*
            (when (probe-file script-path)
              (delete-file script-path)))
          
          ;; Check result
          (if (= exit-code 43)
              (progn
                (when *verbose*
                  (format t "Successfully certified ~A~%" cert-path))
                t)
            (progn
              (format *error-output* "Failed to certify ~A (exit code ~A)~%" 
                      canonical-path exit-code)
              (format *error-output* "See ~A for details~%" output-path)
              nil)))))))

(defun run-shell-command (cmd)
  "Run a shell command and return its exit code."
  ;; This is implementation-dependent
  #+sbcl
  (nth-value 2 (sb-ext:run-program "/bin/sh" (list "-c" cmd)
                                    :search nil
                                    :wait t
                                    :input nil
                                    :output nil))
  #+ccl
  (nth-value 1 (ccl:external-process-status
                (ccl:run-program "/bin/sh" (list "-c" cmd)
                                :wait t
                                :input nil
                                :output nil)))
  #+allegro
  (excl:run-shell-command cmd :wait t)
  #-(or sbcl ccl allegro)
  (error "run-shell-command not implemented for this Lisp"))

;; ============================================================================
;; Batch certification
;; ============================================================================

(defun certify-books-sequential (cert-paths)
  "Certify a list of books sequentially.
   CERT-PATHS should be in dependency order.
   Returns list of failed cert paths."
  (let ((failed nil))
    (dolist (cert-path cert-paths)
      (let ((lisp-path (cert2-to-lisp cert-path)))
        (unless (certify-book2 lisp-path)
          (push cert-path failed))))
    (nreverse failed)))
