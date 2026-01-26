; ACL2 Build2 System - CLI Entry Point
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file is loaded directly by the cert2 shell script in raw Lisp mode.

(in-package "BUILD2")

;;; ============================================================================
;;; HTML Documentation Generation
;;; ============================================================================
;;;
;;; Generates interactive HTML documentation for ACL2 books with:
;;; - Syntax highlighting and hyperlinked names
;;; - Semantic Web annotations (RDFa)
;;; - Interactive filtering: click on parts of defthm to see only referenced items
;;; - Cross-file navigation via relative links
;;;

;;; ============================================================================
;;; Global configuration
;;; ============================================================================

(defvar *acl2-executable* nil
  "Path to ACL2 executable, set by shell script.")

(defvar *system-books-dir* nil
  "Path to ACL2 system books directory.")

(defvar *verbose* nil
  "Verbose output flag.")

(defvar *certifying* (make-hash-table :test 'equal)
  "Hash table tracking books currently being certified (cycle detection).")

(defvar *certified* (make-hash-table :test 'equal)
  "Hash table of books already certified this session.")

(defvar *generate-html* t
  "Whether to generate HTML documentation during certification.")

;;; ============================================================================
;;; Symbol extraction from forms
;;; ============================================================================

(defun symbolp-acl2 (x)
  "Check if X is a symbol in any package (not a keyword)."
  (and (symbolp x) (not (keywordp x))))

(defun collect-symbols (form &optional acc)
  "Recursively collect all non-keyword symbols from FORM."
  (cond
    ((null form) acc)
    ((symbolp-acl2 form) 
     (if (member form acc) acc (cons form acc)))
    ((consp form)
     (collect-symbols (cdr form) (collect-symbols (car form) acc)))
    (t acc)))

(defun get-defthm-section (keyword rest)
  "Get the value associated with KEYWORD from property list REST."
  (let ((pos (position keyword rest)))
    (when pos (nth (1+ pos) rest))))

(defun parse-defthm-parts (form)
  "Parse a defthm FORM into its constituent parts.
   Returns alist: ((name . sym) (term . form) (hints . form) ...)"
  (when (and (consp form) 
             (member (car form) '(acl2::defthm acl2::defthmd)))
    (let* ((name (cadr form))
           (term (caddr form))
           (rest (cdddr form))
           (hints (get-defthm-section :hints rest))
           (rule-classes (get-defthm-section :rule-classes rest))
           (instructions (get-defthm-section :instructions rest))
           (otf-flg (get-defthm-section :otf-flg rest)))
      (list (cons :name name)
            (cons :term term)
            (cons :hints hints)
            (cons :rule-classes rule-classes)
            (cons :instructions instructions)
            (cons :otf-flg otf-flg)))))

(defun parse-defun-parts (form)
  "Parse a defun/defund FORM into its constituent parts."
  (when (and (consp form)
             (member (car form) '(acl2::defun acl2::defund acl2::defun-sk)))
    (let* ((name (cadr form))
           (args (caddr form))
           (rest (cdddr form))
           ;; Skip docstrings and declarations to find body
           (body-rest rest)
           (decls nil))
      ;; Collect declares
      (loop while (and (consp body-rest)
                       (consp (car body-rest))
                       (member (caar body-rest) '(declare acl2::declare)))
            do (push (car body-rest) decls)
               (setf body-rest (cdr body-rest)))
      (list (cons :name name)
            (cons :args args)
            (cons :declare (nreverse decls))
            (cons :body (car body-rest))))))

(defun get-form-name (form)
  "Extract the defined name from a top-level FORM, if any."
  (when (consp form)
    (case (car form)
      ((acl2::defthm acl2::defthmd acl2::defun acl2::defund 
        acl2::defmacro acl2::defconst acl2::defun-sk
        acl2::defrule acl2::defabbrev)
       (cadr form))
      (acl2::mutual-recursion
       ;; Return first function name
       (when (and (cdr form) (consp (cadr form)))
         (cadadr form)))
      (acl2::encapsulate
       ;; Look for first internal defun/defthm
       (loop for sub in (cddr form)
             when (and (consp sub) 
                       (member (car sub) '(acl2::defun acl2::defthm)))
             return (cadr sub)))
      (otherwise nil))))

(defun get-form-type (form)
  "Get the type of definition FORM."
  (when (consp form)
    (case (car form)
      ((acl2::defthm acl2::defthmd acl2::defrule) :theorem)
      ((acl2::defun acl2::defund acl2::defun-sk) :function)
      (acl2::defmacro :macro)
      (acl2::defconst :constant)
      (acl2::encapsulate :encapsulate)
      (acl2::mutual-recursion :mutual-recursion)
      (acl2::include-book :include-book)
      (acl2::local :local)
      (acl2::in-theory :in-theory)
      (otherwise :other))))

;;; ============================================================================
;;; HTML escaping and formatting
;;; ============================================================================

(defun html-escape (string)
  "Escape special HTML characters in STRING."
  (with-output-to-string (out)
    (loop for char across string do
          (case char
            (#\& (write-string "&amp;" out))
            (#\< (write-string "&lt;" out))
            (#\> (write-string "&gt;" out))
            (#\" (write-string "&quot;" out))
            (#\' (write-string "&#39;" out))
            (otherwise (write-char char out))))))

(defun symbol-to-id (sym)
  "Convert SYMBOL to a valid HTML id string."
  (let ((name (symbol-name sym)))
    (with-output-to-string (out)
      (loop for char across name do
            (cond
              ((alphanumericp char) (write-char (char-downcase char) out))
              ((char= char #\-) (write-char #\- out))
              ((char= char #\_) (write-char #\_ out))
              (t (format out "_~2,'0X" (char-code char))))))))

(defun form-to-string (form)
  "Convert FORM to a pretty-printed string."
  (let ((*print-case* :downcase)
        (*print-pretty* t)
        (*print-right-margin* 80))
    (with-output-to-string (out)
      (write form :stream out))))

;;; ============================================================================
;;; Cross-reference index building  
;;; ============================================================================

(defstruct xref-entry
  "Cross-reference entry for a defined name."
  name           ; The symbol
  form-type      ; :theorem, :function, etc.
  file           ; Source file (relative)
  defined-by     ; List of symbols this definition uses
  used-by        ; List of symbols that use this definition
  parts          ; Alist of parts and their symbols for defthm
  )

(defun build-xref-index (forms filename)
  "Build cross-reference index from FORMS read from FILENAME.
   Returns hash table: symbol -> xref-entry"
  (let ((index (make-hash-table :test 'equal)))
    (dolist (form forms)
      (let ((name (get-form-name form))
            (form-type (get-form-type form)))
        (when name
          (let* ((all-syms (collect-symbols form))
                 (parts (or (parse-defthm-parts form)
                           (parse-defun-parts form)))
                 (entry (make-xref-entry 
                         :name name
                         :form-type form-type
                         :file filename
                         :defined-by (remove name all-syms)
                         :parts (when parts
                                  (mapcar (lambda (p)
                                            (cons (car p) (collect-symbols (cdr p))))
                                          parts)))))
            (setf (gethash (symbol-name name) index) entry)))))
    ;; Build used-by relationships
    (maphash (lambda (name entry)
               (declare (ignore name))
               (dolist (sym (xref-entry-defined-by entry))
                 (let ((target (gethash (symbol-name sym) index)))
                   (when target
                     (pushnew (xref-entry-name entry) 
                              (xref-entry-used-by target))))))
             index)
    index))

;;; ============================================================================
;;; HTML generation - Template loading
;;; ============================================================================

(defvar *build2-dir* nil
  "Directory containing cert2.lsp and template files.")

(defun read-file-contents (filepath)
  "Read entire contents of FILEPATH as a string."
  (with-open-file (stream filepath :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun get-template-path (filename)
  "Get path to template file FILENAME in build2 directory."
  (let ((dir-str (namestring *build2-dir*)))
    ;; Ensure directory ends with /
    (unless (and (> (length dir-str) 0)
                 (char= (char dir-str (1- (length dir-str))) #\/))
      (setf dir-str (concatenate 'string dir-str "/")))
    (pathname (concatenate 'string dir-str filename))))

(defun generate-css ()
  "Load CSS from external file."
  (let ((css-file (get-template-path "cert2.css")))
    (if (probe-file css-file)
        (format nil "~%<style>~%~A~%</style>~%" (read-file-contents css-file))
      ;; Fallback minimal CSS if file not found
      "<style>body{font-family:monospace;}</style>")))

(defun generate-javascript ()
  "Load JavaScript from external file."
  (let ((js-file (get-template-path "cert2.js")))
    (if (probe-file js-file)
        (format nil "~%<script>~%~A~%</script>~%" (read-file-contents js-file))
      ;; Fallback: no JS if file not found
      "")))

(defun generate-html-header (book-name relative-path)
  "Generate HTML header for a book."
  (format nil "<!DOCTYPE html>
<html lang=\"en\" vocab=\"http://schema.org/\" typeof=\"SoftwareSourceCode\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>~A - ACL2 Book</title>
  <meta property=\"name\" content=\"~A\">
  <meta property=\"programmingLanguage\" content=\"ACL2\">
  ~A
</head>
<body>
  <div class=\"filter-status\">
    <span class=\"filter-text\">Filtering...</span>
    <button class=\"clear-filter\">Clear Filter</button>
  </div>
  
  <div class=\"book-header\">
    <h1 property=\"name\">~A</h1>
    <div class=\"path\">~A</div>
  </div>
  
  <main property=\"text\">
" (html-escape book-name) (html-escape book-name)
  (generate-css)
  (html-escape book-name) (html-escape relative-path)))

(defun generate-html-footer ()
  "Generate HTML footer."
  (format nil "
  </main>
  ~A
</body>
</html>" (generate-javascript)))

(defun make-sym-span (sym index local-file)
  "Generate HTML span for a symbol reference.
   INDEX is the xref-index, LOCAL-FILE is current file."
  (let* ((sym-name (symbol-name sym))
         (entry (gethash sym-name index))
         (target-file (and entry (xref-entry-file entry)))
         (is-external (and target-file (not (equal target-file local-file))))
         (class (cond
                  ((and entry (not is-external)) "sym-ref local-def")
                  (is-external "sym-ref external")
                  (t "sym-ref")))
         (file-attr (if is-external
                        (format nil " data-file=\"~A\"" 
                                (html-escape target-file))
                      "")))
    (format nil "<span class=\"~A\" data-sym=\"~A\"~A>~A</span>"
            class
            (html-escape sym-name)
            file-attr
            (html-escape (string-downcase sym-name)))))

(defun format-form-with-links (form index local-file)
  "Format FORM as HTML with symbol links."
  (let* ((form-str (form-to-string form))
         (output (make-string-output-stream))
         (syms-in-form (collect-symbols form)))
    ;; Simple approach: escape the whole thing, then we'd need to parse
    ;; For now, just escape and output
    ;; A more sophisticated version would walk the form tree
    (write-string (html-escape form-str) output)
    (get-output-stream-string output)))

(defun generate-form-html (form index local-file form-idx)
  "Generate HTML for a single FORM."
  (let* ((name (get-form-name form))
         (form-type (get-form-type form))
         (type-str (string-downcase (symbol-name (or form-type :other))))
         (id (if name 
                 (format nil "def-~A" (symbol-to-id name))
               (format nil "form-~A" form-idx)))
         (entry (and name (gethash (symbol-name name) index)))
         (defined-by (if entry 
                        (mapcar #'symbol-name (xref-entry-defined-by entry))
                       nil))
         (used-by (if entry
                     (mapcar #'symbol-name (xref-entry-used-by entry))
                    nil))
         (parts (and entry (xref-entry-parts entry)))
         (form-str (html-escape (form-to-string form))))
    (with-output-to-string (out)
      ;; Form block with RDFa and data attributes
      (format out "<div class=\"form-block ~A\" id=\"~A\"" type-str id)
      (when name
        (format out " data-defines=\"~A\"" (symbol-name name)))
      (when defined-by
        (format out " data-references=\"~{~A~^,~}\"" defined-by))
      (when used-by
        (format out " data-used-by=\"~{~A~^,~}\"" used-by))
      ;; Add part data for defthm
      (dolist (part parts)
        (let ((part-name (car part))
              (part-syms (cdr part)))
          (when (and part-name part-syms (keywordp part-name))
            (format out " data-part-~A=\"~{~A~^,~}\""
                    (string-downcase (symbol-name part-name))
                    (mapcar #'symbol-name part-syms)))))
      (format out " typeof=\"~A\">" 
              (case form-type
                (:theorem "SoftwareSourceCode")
                (:function "SoftwareSourceCode")
                (otherwise "Code")))
      
      ;; Header with name and type
      (format out "~%    <div class=\"form-header\">")
      (when name
        (format out "<span class=\"form-name\" property=\"name\" data-sym=\"~A\">~A</span>"
                (symbol-name name)
                (html-escape (string-downcase (symbol-name name)))))
      (format out "<span class=\"form-type\">~A</span>" type-str)
      (format out "</div>~%")
      
      ;; Part buttons for defthm
      (when (member form-type '(:theorem))
        (format out "    <div class=\"part-buttons\">")
        (dolist (part '(:term :hints :rule-classes :instructions))
          (let ((part-data (assoc part parts)))
            (when (and part-data (cdr part-data))
              (format out "<button class=\"part-btn\" data-part=\"~A\">~A</button>"
                      (string-downcase (symbol-name part))
                      (string-downcase (symbol-name part))))))
        (format out "</div>~%"))
      
      ;; Code
      (format out "    <pre class=\"code\" property=\"text\">~A</pre>~%" form-str)
      
      (format out "  </div>~%~%"))))

(defun extract-all-include-books (forms)
  "Extract all include-book paths from FORMS. Returns list of (path localp dir-keyword)."
  (loop for form in forms
        append (extract-include-books form)))

(defun resolve-include-path (include-info book-path)
  "Resolve INCLUDE-INFO (path localp dir-keyword) relative to BOOK-PATH.
   Returns the relative path for the HTML link (relative to the current HTML file)."
  (destructuring-bind (inc-path localp dir-keyword) include-info
    (declare (ignore localp))
    (let* ((book-str (namestring book-path))
           (book-dir (let ((last-slash (position #\/ book-str :from-end t)))
                       (if last-slash
                           (subseq book-str 0 (1+ last-slash))
                         "")))
           (sys-str (namestring *system-books-dir*)))
      ;; Ensure sys-str ends with /
      (unless (and (> (length sys-str) 0)
                   (char= (char sys-str (1- (length sys-str))) #\/))
        (setf sys-str (concatenate 'string sys-str "/")))
      (cond
        ;; :dir :system - need to compute relative path from current file to system books
        ((eq dir-keyword :system)
         ;; Count directory levels from system books to book-dir
         (let* ((rel-book-dir (if (and (>= (length book-dir) (length sys-str))
                                       (string= sys-str (subseq book-dir 0 (length sys-str))))
                                  (subseq book-dir (length sys-str))
                                ""))
                (depth (count #\/ rel-book-dir))
                (up-dirs (with-output-to-string (s)
                           (dotimes (i depth) (write-string "../" s)))))
           (concatenate 'string up-dirs inc-path)))
        ;; Relative path - just use it directly (it's already relative to current file)
        (t inc-path)))))

(defun generate-includes-section (forms book-path)
  "Generate HTML for the included books section."
  (let* ((includes (extract-all-include-books forms))
         ;; Remove duplicates (keep first occurrence)
         (seen (make-hash-table :test 'equal))
         (unique-includes 
          (loop for inc in includes
                for path = (first inc)
                unless (gethash path seen)
                collect inc
                do (setf (gethash path seen) t))))
    (when unique-includes
      (with-output-to-string (out)
        (format out "  <div class=\"includes-section\">~%")
        (format out "    <h2>Included Books</h2>~%")
        (format out "    <div class=\"includes-list\">~%")
        (dolist (inc unique-includes)
          (destructuring-bind (inc-path localp dir-keyword) inc
            (let* ((resolved (resolve-include-path inc book-path))
                   (html-path (concatenate 'string resolved ".html"))
                   (display-name (let ((last-slash (position #\/ inc-path :from-end t)))
                                   (if last-slash
                                       (subseq inc-path (1+ last-slash))
                                     inc-path)))
                   (class (if localp "include-link local" "include-link")))
              (format out "      <a class=\"~A\" href=\"~A\" title=\"~A\">~A</a>~%"
                      class
                      (html-escape html-path)
                      (html-escape inc-path)
                      (html-escape display-name)))))
        (format out "    </div>~%")
        (format out "  </div>~%~%")))))

(defun generate-book-html (forms book-path)
  "Generate complete HTML for a book from its FORMS.
   Returns HTML string."
  (let* ((book-str (namestring book-path))
         (book-name (car (last (pathname-directory book-path))))
         (relative-path (enough-namestring book-path *system-books-dir*))
         (index (build-xref-index forms relative-path)))
    (with-output-to-string (out)
      (write-string (generate-html-header 
                     (or (pathname-name book-path) book-name)
                     relative-path) out)
      ;; Add includes section
      (let ((includes-html (generate-includes-section forms book-path)))
        (when includes-html
          (write-string includes-html out)))
      (loop for form in forms
            for idx from 0
            do (write-string (generate-form-html form index relative-path idx) out))
      (write-string (generate-html-footer) out))))

(defun write-book-html (book-path)
  "Generate and write HTML documentation for BOOK-PATH."
  (let* ((book-str (namestring book-path))
         (lisp-file (concatenate 'string book-str ".lisp"))
         (html-file (concatenate 'string book-str ".html"))
         (forms (read-forms-from-file lisp-file)))
    (when forms
      (let ((html (generate-book-html forms book-path)))
        (with-open-file (out html-file :direction :output
                                       :if-exists :supersede
                                       :if-does-not-exist :create)
          (write-string html out))
        (when *verbose*
          (format t "  Generated: ~A~%" html-file))
        t))))

;;; ============================================================================
;;; Dependency scanning using proper Lisp reader
;;; ============================================================================

(defun read-forms-from-file (filename)
  "Read all Lisp forms from FILENAME using the standard reader.
   Returns list of forms, or NIL on error."
  (handler-case
      (with-open-file (stream filename :direction :input
                                       :if-does-not-exist nil)
        (when stream
          (let ((*package* (find-package "ACL2"))
                (*read-eval* nil))  ; Safety: don't evaluate during read
            (loop for form = (read stream nil :eof)
                  until (eq form :eof)
                  collect form))))
    (error () nil)))

(defun extract-include-books (form)
  "Extract include-book info from FORM. Returns list of (path localp dir-keyword)."
  (when (consp form)
    (case (car form)
      ;; Direct include-book
      (acl2::include-book
       (when (and (cdr form) (stringp (cadr form)))
         (let* ((path (cadr form))
                (rest (cddr form))
                (dir-pos (position :dir rest))
                (dir-val (and dir-pos (nth (1+ dir-pos) rest))))
           (list (list path nil (when (eq dir-val :system) :system))))))
      ;; Local wrapper
      (acl2::local
       (when (cdr form)
         (let ((inner-results (extract-include-books (cadr form))))
           ;; Mark all as local
           (mapcar (lambda (r) (list (first r) t (third r))) inner-results))))
      ;; Recurse into progn, encapsulate, etc.
      ((acl2::progn acl2::encapsulate)
       (loop for subform in (cdr form)
             append (extract-include-books subform)))
      (otherwise nil))))

(defun scan-file-for-deps (filename)
  "Scan FILENAME for include-book dependencies using Lisp reader.
   Returns list of (path localp dir-keyword)."
  (let ((forms (read-forms-from-file filename)))
    (loop for form in forms
          append (extract-include-books form))))

;;; ============================================================================
;;; Path resolution
;;; ============================================================================

(defun resolve-book-path (base-dir book-name dir-keyword)
  "Resolve BOOK-NAME relative to BASE-DIR.
   If DIR-KEYWORD is :SYSTEM, resolve relative to system books.
   Returns absolute path without extension."
  (let* ((name (if (and (> (length book-name) 5)
                        (string-equal ".lisp" (subseq book-name (- (length book-name) 5))))
                   (subseq book-name 0 (- (length book-name) 5))
                 book-name))
         (base-str (namestring (or base-dir *system-books-dir*)))
         (sys-str (namestring *system-books-dir*)))
    ;; Ensure base-str ends with /
    (unless (char= (char base-str (1- (length base-str))) #\/)
      (setf base-str (concatenate 'string base-str "/")))
    (unless (char= (char sys-str (1- (length sys-str))) #\/)
      (setf sys-str (concatenate 'string sys-str "/")))
    (cond
      ;; :dir :system - relative to system books
      ((eq dir-keyword :system)
       (pathname (concatenate 'string sys-str name)))
      ;; Absolute path
      ((and (> (length name) 0) (char= (char name 0) #\/))
       (pathname name))
      ;; Relative path - resolve relative to base-dir
      (t
       (pathname (concatenate 'string base-str name))))))

;;; ============================================================================
;;; Command-line interface
;;; ============================================================================

(defun print-usage ()
  (format t "~%Usage: cert2 [options] book1 [book2 ...]~%")
  (format t "~%Certify ACL2 books and generate HTML documentation.~%")
  (format t "~%Options:~%")
  (format t "  -h, --help      Show this help message~%")
  (format t "  -j N            Use N parallel jobs (not yet implemented)~%")
  (format t "  -v, --verbose   Verbose output~%")
  (format t "  --no-html       Skip HTML documentation generation~%")
  (format t "~%Books should be specified without the .lisp extension.~%")
  (format t "~%Example:~%")
  (format t "  cert2 arithmetic/top std/lists/top~%~%"))

(defun parse-args-helper (args books options)
  "Helper for parse-args using recursion instead of loop."
  (if (null args)
      (values (nreverse books) options)
    (let ((arg (car args))
          (rest (cdr args)))
      (cond
       ((or (string= arg "-h") (string= arg "--help"))
        (parse-args-helper rest books (acons :help t options)))
       ((or (string= arg "-v") (string= arg "--verbose"))
        (parse-args-helper rest books (acons :verbose t options)))
       ((string= arg "--no-html")
        (parse-args-helper rest books (acons :no-html t options)))
       ((string= arg "-j")
        (if rest
            (parse-args-helper (cdr rest) books 
                               (acons :jobs (parse-integer (car rest) :junk-allowed t) options))
          (parse-args-helper rest books options)))
       ((and (> (length arg) 0) (char= (char arg 0) #\-))
        (format t "Warning: Unknown option: ~A~%" arg)
        (parse-args-helper rest books options))
       (t
        (parse-args-helper rest (cons arg books) options))))))

(defun parse-args (args)
  "Parse command-line arguments.
   Returns (values books options) where options is an alist."
  (parse-args-helper args nil nil))

;;; ============================================================================
;;; ACL2 invocation for certification
;;; ============================================================================

(defun make-certify-script (book-path)
  "Create the ACL2 script to certify BOOK-PATH.
   Handles .acl2 file if present."
  (let* ((book-str (namestring book-path))
         (acl2-file (concatenate 'string book-str ".acl2"))
         (has-acl2 (probe-file acl2-file)))
    (with-output-to-string (s)
      ;; Load .acl2 file if it exists (sets up package, includes, etc.)
      (when has-acl2
        (format s "(ld ~S)~%" acl2-file))
      ;; Certify the book
      (format s "(certify-book ~S ? t)~%" book-str)
      ;; Exit  
      (format s "(good-bye)~%"))))

(defun run-acl2-certify (book-path)
  "Run ACL2 to certify BOOK-PATH. Returns T on success, NIL on failure."
  (let* ((script (make-certify-script book-path))
         (acl2 (or *acl2-executable* "acl2"))
         (book-str (namestring book-path))
         (log-file (concatenate 'string book-str ".cert.out")))
    (when *verbose*
      (format t "  Running: ~A~%" acl2)
      (format t "  Log: ~A~%" log-file))
    ;; Run ACL2 with the script, output to log file
    (with-open-file (log-stream log-file :direction :output 
                                         :if-exists :supersede
                                         :if-does-not-exist :create)
      (let* ((process (sb-ext:run-program 
                       acl2
                       nil
                       :input (make-string-input-stream script)
                       :output log-stream
                       :error :output
                       :wait t
                       :environment (list "ACL2_CUSTOMIZATION=NONE")))
             (exit-code (sb-ext:process-exit-code process)))
        (zerop exit-code)))))

;;; ============================================================================
;;; Dependency-aware certification
;;; ============================================================================

(defun book-up-to-date-p (book-path)
  "Check if BOOK-PATH.cert exists and is newer than BOOK-PATH.lisp."
  (let* ((book-str (namestring book-path))
         (lisp-file (concatenate 'string book-str ".lisp"))
         (cert-file (concatenate 'string book-str ".cert"))
         (lisp-date (and (probe-file lisp-file) (file-write-date lisp-file)))
         (cert-date (and (probe-file cert-file) (file-write-date cert-file))))
    (and lisp-date cert-date (>= cert-date lisp-date))))

(defun certify-book-with-deps (book-path)
  "Certify BOOK-PATH after first certifying all its dependencies.
   Returns T on success, NIL on failure."
  (let ((book-str (namestring book-path)))
    ;; Check for cycles
    (when (gethash book-str *certifying*)
      (format t "Error: Circular dependency detected involving ~A~%" book-str)
      (return-from certify-book-with-deps nil))
    
    ;; Already done this session?
    (when (gethash book-str *certified*)
      (when *verbose*
        (format t "  ~A (already certified this session)~%" book-str))
      (return-from certify-book-with-deps t))
    
    ;; Check if source exists
    (let ((lisp-file (concatenate 'string book-str ".lisp")))
      (unless (probe-file lisp-file)
        (format t "Error: Source file not found: ~A~%" lisp-file)
        (return-from certify-book-with-deps nil))
      
      ;; Mark as being certified (for cycle detection)
      (setf (gethash book-str *certifying*) t)
      
      (unwind-protect
          (progn
            ;; Scan for dependencies
            (let* ((deps (scan-file-for-deps lisp-file))
                   ;; Get directory containing this book
                   (base-dir (let ((last-slash (position #\/ book-str :from-end t)))
                               (if last-slash
                                   (pathname (subseq book-str 0 (1+ last-slash)))
                                 *system-books-dir*))))
              ;; Certify each dependency first
              (dolist (dep deps)
                (destructuring-bind (dep-name localp dir-keyword) dep
                  (declare (ignore localp))
                  (let ((dep-path (resolve-book-path base-dir dep-name dir-keyword)))
                    (unless (certify-book-with-deps dep-path)
                      (format t "Error: Failed to certify dependency ~A~%" dep-path)
                      (return-from certify-book-with-deps nil)))))
              
              ;; Now certify this book if needed
              (cond
                ((book-up-to-date-p book-path)
                 (when *verbose*
                   (format t "  ~A (up to date)~%" book-str))
                 ;; Generate HTML even for up-to-date books if HTML missing
                 (when *generate-html*
                   (let ((html-file (concatenate 'string book-str ".html")))
                     (unless (probe-file html-file)
                       (write-book-html book-path))))
                 (setf (gethash book-str *certified*) t)
                 t)
                (t
                 (format t "Certifying ~A...~%" book-str)
                 (let ((success (run-acl2-certify book-path)))
                   (if success
                       (progn
                         (format t "  Success: ~A~%" book-str)
                         ;; Generate HTML documentation
                         (when *generate-html*
                           (write-book-html book-path))
                         (setf (gethash book-str *certified*) t)
                         t)
                     (progn
                       (format t "  FAILED: ~A~%" book-str)
                       nil)))))))
        ;; Cleanup: remove from certifying set
        (remhash book-str *certifying*)))))

(defun process-books (books)
  "Process a list of books, return T if all succeed."
  (every (lambda (book)
           (handler-case
               ;; Ensure we have a proper path relative to books dir
               (let* ((book-str (if (pathnamep book) (namestring book) book))
                      (sys-str (namestring *system-books-dir*)))
                 ;; Ensure sys-str ends with /
                 (unless (and (> (length sys-str) 0)
                              (char= (char sys-str (1- (length sys-str))) #\/))
                   (setf sys-str (concatenate 'string sys-str "/")))
                 (let ((book-path 
                        (if (and (> (length book-str) 0)
                                 (char= (char book-str 0) #\/))
                            (pathname book-str)
                          (pathname (concatenate 'string sys-str book-str)))))
                   (certify-book-with-deps book-path)))
             (error (e)
               (format t "Error processing ~A: ~A~%" book e)
               nil)))
         books))

(defun build2-cli-fn (args acl2-path books-dir)
  "Main entry point for the cert2 command-line tool.
   ARGS is a list of command-line arguments (strings).
   ACL2-PATH is the path to the ACL2 executable.
   BOOKS-DIR is the path to the system books directory.
   Returns 0 on success, non-zero on failure."
  (handler-case
      (progn
        (setf *acl2-executable* acl2-path)
        (setf *system-books-dir* (pathname books-dir))
        ;; Set build2 dir for finding template files (CSS, JS)
        (let ((dir-str (if (pathnamep books-dir) (namestring books-dir) books-dir)))
          (unless (char= (char dir-str (1- (length dir-str))) #\/)
            (setf dir-str (concatenate 'string dir-str "/")))
          (setf *build2-dir* (pathname (concatenate 'string dir-str "build2/"))))
        (setf *certifying* (make-hash-table :test 'equal))
        (setf *certified* (make-hash-table :test 'equal))
        (multiple-value-bind (books options)
            (parse-args args)
          ;; Handle help
          (when (cdr (assoc :help options))
            (print-usage)
            (return-from build2-cli-fn 0))
          ;; Set verbose
          (setf *verbose* (cdr (assoc :verbose options)))
          ;; Set HTML generation (on by default)
          (setf *generate-html* (not (cdr (assoc :no-html options))))
          ;; Must have at least one book
          (when (null books)
            (format t "Error: No books specified.~%")
            (print-usage)
            (return-from build2-cli-fn 1))
          ;; Process books
          (if (process-books books) 0 1)))
    (error (e)
      (format t "~%Fatal error: ~A~%" e)
      1)))
