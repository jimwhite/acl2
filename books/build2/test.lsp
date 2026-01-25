; ACL2 Build2 System - Test Script
; Copyright (C) 2026
;
; Run this file with: sbcl --load test.lsp
; or from ACL2: :q then (load "test.lsp")

(in-package "COMMON-LISP-USER")

(format t "~%=== BUILD2 Test Suite ===~%~%")

;; Load the standalone system
(let ((*default-pathname-defaults* 
       (make-pathname :directory (pathname-directory *load-truename*))))
  (load "standalone.lsp"))

(in-package "BUILD2")

;; ============================================================================
;; Test: Line scanning
;; ============================================================================

(format t "~%--- Test: Line Scanning ---~%")

(defun test-scan-line (description line expected-types)
  "Test that scanning LINE produces events of EXPECTED-TYPES."
  (let* ((events (scan-line line))
         (types (mapcar #'car events)))
    (if (equal types expected-types)
        (format t "PASS: ~A~%" description)
      (format t "FAIL: ~A~%  Line: ~A~%  Expected: ~A~%  Got: ~A~%  Events: ~A~%"
              description line expected-types types events))))

;; Test include-book
(test-scan-line "simple include-book"
                "(include-book \"foo\")"
                '(:include-book))

(test-scan-line "include-book with :dir"
                "(include-book \"std/util/define\" :dir :system)"
                '(:include-book))

(test-scan-line "include-book after comment is ignored"
                "; (include-book \"foo\")"
                '())

(test-scan-line "local include-book"
                "(local (include-book \"foo\"))"
                '(:include-book))

;; Test cert_param
(test-scan-line "cert_param pcert"
                "; cert_param: (pcert)"
                '(:cert-param))

(test-scan-line "cert_param with value"
                "; cert_param: (acl2x=t)"
                '(:cert-param))

(test-scan-line "multiple cert_params"
                "; cert_param: (pcert, ccl-only)"
                '(:cert-param :cert-param))

;; Test depends-on (can be in comment)
(test-scan-line "depends-on in comment"
                "; (depends-on \"data.txt\")"
                '(:depends-on))

(test-scan-line "depends-on with :dir"
                "(depends-on \"config.lsp\" :dir :system)"
                '(:depends-on))

;; Test add-include-book-dir
(test-scan-line "add-include-book-dir"
                "(add-include-book-dir :mylib \"../mylib\")"
                '(:add-include-book-dir))

(test-scan-line "add-include-book-dir! (exported)"
                "(add-include-book-dir! :mylib \"../mylib\")"
                '(:add-include-book-dir!))

;; Test ifdef/endif
(test-scan-line "ifdef"
                "(ifdef \"USE_FEATURE\""
                '(:ifdef))

(test-scan-line "ifndef"
                "(ifndef \"SKIP_FEATURE\""
                '(:ifdef))

(test-scan-line "endif"
                "  :endif)"
                '(:endif))

;; Test ld
(test-scan-line "ld form"
                "(ld \"setup.lsp\")"
                '(:ld))

;; Test loads (can be in comment)
(test-scan-line "loads in comment"
                "; (loads \"helper.lsp\")"
                '(:loads))

;; ============================================================================
;; Test: Path utilities
;; ============================================================================

(format t "~%--- Test: Path Utilities ---~%")

(defun test-path-conversion (description input-path expected-output func)
  (let ((result (funcall func input-path)))
    (if (string= result expected-output)
        (format t "PASS: ~A~%" description)
      (format t "FAIL: ~A~%  Input: ~A~%  Expected: ~A~%  Got: ~A~%"
              description input-path expected-output result))))

(test-path-conversion "lisp-to-cert2"
                      "/path/to/book.lisp"
                      "/path/to/book.cert2"
                      #'lisp-to-cert2)

(test-path-conversion "cert2-to-lisp"
                      "/path/to/book.cert2"
                      "/path/to/book.lisp"
                      #'cert2-to-lisp)

;; ============================================================================
;; Test: Real file scanning
;; ============================================================================

(format t "~%--- Test: Real File Scanning ---~%")

;; Create a test file
(let ((test-file "/tmp/test-book.lisp"))
  (with-open-file (stream test-file :direction :output :if-exists :supersede)
    (format stream "; cert_param: (pcert)~%")
    (format stream "(in-package \"ACL2\")~%")
    (format stream "(include-book \"std/util/define\" :dir :system)~%")
    (format stream "(local (include-book \"std/testing/assert\" :dir :system))~%")
    (format stream "; (depends-on \"data.txt\")~%")
    (format stream "(defun foo (x) x)~%"))
  
  (let ((events (scan-file-raw test-file)))
    (format t "Scanned ~A events from test file:~%" (length events))
    (dolist (ev events)
      (format t "  ~A~%" ev))
    
    ;; Check expected events
    (let ((expected-count 4)) ; cert-param, 2 include-books, depends-on
      (if (= (length events) expected-count)
          (format t "PASS: Found expected number of events (~A)~%" expected-count)
        (format t "FAIL: Expected ~A events, got ~A~%" expected-count (length events)))))
  
  ;; Clean up
  (delete-file test-file))

;; ============================================================================
;; Test: Event cache
;; ============================================================================

(format t "~%--- Test: Event Cache ---~%")

(let ((test-file "/tmp/test-cache.lisp")
      (cache-file "/tmp/test-cache.dat"))
  
  ;; Create test file
  (with-open-file (stream test-file :direction :output :if-exists :supersede)
    (format stream "(include-book \"foo\")~%"))
  
  ;; Scan it (should populate cache)
  (clear-event-cache)
  (let ((events1 (scan-file-raw test-file)))
    ;; Scan again (should use cache)
    (let ((events2 (scan-file-raw test-file)))
      (if (equal events1 events2)
          (format t "PASS: Cache returns same events~%")
        (format t "FAIL: Cache returned different events~%"))))
  
  ;; Save and reload cache
  (save-event-cache cache-file)
  (clear-event-cache)
  (load-event-cache cache-file)
  
  (let ((events3 (scan-file-raw test-file)))
    (if (= (length events3) 1)
        (format t "PASS: Cache persistence works~%")
      (format t "FAIL: Cache persistence issue~%")))
  
  ;; Clean up
  (delete-file test-file)
  (delete-file cache-file))

;; ============================================================================
;; Summary
;; ============================================================================

(format t "~%=== Tests Complete ===~%~%")
