; ACL2 Build2 System - Raw Lisp Dependency Scanner
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This file contains the raw Common Lisp implementation of file scanning.
; It should be loaded after scan.lisp is certified.

(in-package "BUILD2")

;; ============================================================================
;; File I/O for scanning
;; ============================================================================

(defun read-file-lines-raw (filename)
  "Read all lines from a file. Returns list of strings or NIL on error."
  (handler-case
      (with-open-file (stream filename :direction :input
                                       :if-does-not-exist nil)
        (when stream
          (loop for line = (read-line stream nil nil)
                while line
                collect line)))
    (error (c)
      (format *error-output* "Error reading ~A: ~A~%" filename c)
      nil)))

(defun file-timestamp (filename)
  "Get the modification timestamp of a file, or -1 if it doesn't exist."
  (handler-case
      (let ((stat (file-write-date filename)))
        (if stat stat -1))
    (error () -1)))

;; ============================================================================
;; Event cache management  
;; ============================================================================

;; The event cache maps filenames to (events . timestamp) pairs.
;; If the file's current timestamp matches the cached timestamp,
;; we can reuse the cached events.

(defvar *event-cache* (make-hash-table :test 'equal)
  "Cache mapping filename -> (events . timestamp)")

(defun get-cached-events (filename)
  "Get cached events for a file if still valid. Returns events or NIL."
  (let* ((cached (gethash filename *event-cache*))
         (current-ts (file-timestamp filename)))
    (when (and cached
               (= (cdr cached) current-ts)
               (>= current-ts 0))
      (car cached))))

(defun cache-events (filename events)
  "Cache events for a file with its current timestamp."
  (let ((ts (file-timestamp filename)))
    (when (>= ts 0)
      (setf (gethash filename *event-cache*)
            (cons events ts)))
    events))

(defun clear-event-cache ()
  "Clear the entire event cache."
  (clrhash *event-cache*))

;; ============================================================================
;; String parsing utilities
;; ============================================================================

(defun whitespace-char-p (c)
  "Check if character is whitespace"
  (member c '(#\Space #\Tab #\Newline #\Return)))

(defun skip-whitespace (str pos)
  "Skip whitespace characters starting at pos, return new position"
  (loop while (and (< pos (length str))
                   (whitespace-char-p (char str pos)))
        do (incf pos))
  pos)

(defun find-char-in-string (str ch pos)
  "Find first occurrence of ch in str starting at pos, return position or nil"
  (position ch str :start pos))

(defun line-has-comment-before (str pos)
  "Check if there's a semicolon before pos in the line"
  (let ((semi-pos (position #\; str)))
    (and semi-pos (< semi-pos pos))))

(defun extract-string-literal (str pos)
  "Extract a double-quoted string starting at pos. Returns (string . end-pos) or nil"
  (when (and (< pos (length str))
             (char= (char str pos) #\"))
    (let ((end (position #\" str :start (1+ pos))))
      (when end
        (cons (subseq str (1+ pos) end) (1+ end))))))

(defun extract-symbol (str pos)
  "Extract a Lisp symbol starting at pos. Returns (symbol-string . end-pos) or nil"
  (let ((pos (skip-whitespace str pos)))
    (when (< pos (length str))
      (let ((end pos))
        (loop while (and (< end (length str))
                         (not (whitespace-char-p (char str end)))
                         (not (member (char str end) '(#\( #\) #\" #\;))))
              do (incf end))
        (when (> end pos)
          (cons (subseq str pos end) end))))))

;; ============================================================================
;; Form parsing
;; ============================================================================

(defun parse-include-book (line pos)
  "Parse an include-book form starting after '(include-book'.
   Returns (:include-book name dir-kwd localp no-port) or nil."
  (let* ((pos (skip-whitespace line pos))
         (name-result (extract-string-literal line pos)))
    (when name-result
      (let* ((name (car name-result))
             (pos (skip-whitespace line (cdr name-result)))
             (dir-kwd nil))
        ;; Look for :dir keyword
        (when (and (< (+ pos 4) (length line))
                   (string-equal (subseq line pos (min (+ pos 4) (length line))) ":dir"))
          (let* ((pos2 (skip-whitespace line (+ pos 4)))
                 (kwd-result (extract-symbol line pos2)))
            (when kwd-result
              (setf dir-kwd (car kwd-result))
              (setf pos (cdr kwd-result)))))
        ;; Check for no_port comment
        (let ((no-port (search "no_port" line :start2 pos))
              ;; Check for local marker
              (local-marker (search "(local" line))
              (ib-pos (search "(include-book" line)))
          (list :include-book name dir-kwd
                (and local-marker ib-pos (< local-marker ib-pos))
                (if no-port t nil)))))))

(defun parse-add-include-book-dir (line pos exported)
  "Parse add-include-book-dir[!] form.
   Returns (:add-include-book-dir[!] dirname path) or nil."
  (let* ((pos (skip-whitespace line pos))
         (kwd-result (extract-symbol line pos)))
    (when kwd-result
      (let* ((dirname (car kwd-result))
             (pos (skip-whitespace line (cdr kwd-result)))
             (path-result (extract-string-literal line pos)))
        (when path-result
          (list (if exported :add-include-book-dir! :add-include-book-dir)
                dirname (car path-result)))))))

(defun parse-depends-on (line pos)
  "Parse depends-on form. Returns (:depends-on file dir-kwd) or nil."
  (let* ((pos (skip-whitespace line pos))
         (file-result (extract-string-literal line pos)))
    (when file-result
      (let* ((file (car file-result))
             (pos (skip-whitespace line (cdr file-result)))
             (dir-kwd nil))
        (when (and (< (+ pos 4) (length line))
                   (string-equal (subseq line pos (min (+ pos 4) (length line))) ":dir"))
          (let* ((pos2 (skip-whitespace line (+ pos 4)))
                 (kwd-result (extract-symbol line pos2)))
            (when kwd-result
              (setf dir-kwd (car kwd-result)))))
        (list :depends-on file dir-kwd)))))

(defun parse-loads-form (line pos event-type)
  "Parse loads/ld/include-events/include-src-events form."
  (let* ((pos (skip-whitespace line pos))
         (file-result (extract-string-literal line pos)))
    (when file-result
      (let* ((file (car file-result))
             (pos (skip-whitespace line (cdr file-result)))
             (dir-kwd nil))
        (when (and (< (+ pos 4) (length line))
                   (string-equal (subseq line pos (min (+ pos 4) (length line))) ":dir"))
          (let* ((pos2 (skip-whitespace line (+ pos 4)))
                 (kwd-result (extract-symbol line pos2)))
            (when kwd-result
              (setf dir-kwd (car kwd-result)))))
        (list event-type file dir-kwd)))))

(defun parse-cert-param-value (str pos)
  "Parse a single cert_param key=value. Returns ((key . value) . new-pos) or nil."
  (let ((pos (skip-whitespace str pos)))
    (when (< pos (length str))
      (let ((key-end pos))
        (loop while (and (< key-end (length str))
                         (not (member (char str key-end) '(#\= #\, #\) #\Space))))
              do (incf key-end))
        (when (> key-end pos)
          (let* ((key (subseq str pos key-end))
                 (pos (skip-whitespace str key-end)))
            (if (and (< pos (length str)) (char= (char str pos) #\=))
                ;; Has a value
                (let* ((pos (skip-whitespace str (1+ pos)))
                       (val-end pos))
                  (loop while (and (< val-end (length str))
                                   (not (member (char str val-end) '(#\, #\) #\Space))))
                        do (incf val-end))
                  (cons (cons key (subseq str pos val-end))
                        (skip-whitespace str val-end)))
              ;; No value
              (cons (cons key "t") pos))))))))

(defun parse-cert-params (str pos)
  "Parse cert_param values from ; cert_param: (key=val, key2, ...).
   Returns list of (key . value) pairs."
  (let ((pos (skip-whitespace str pos)))
    ;; Skip opening paren if present
    (when (and (< pos (length str)) (char= (char str pos) #\())
      (incf pos))
    (let ((params nil))
      (loop
        (let ((result (parse-cert-param-value str pos)))
          (unless result
            (return (nreverse params)))
          (push (car result) params)
          (setf pos (cdr result))
          ;; Skip comma
          (when (and (< pos (length str)) (char= (char str pos) #\,))
            (incf pos)))))))

(defun parse-ifdef (line pos is-ifdef)
  "Parse ifdef/ifndef form. Returns (:ifdef var is-ifdef) or nil."
  (let* ((pos (skip-whitespace line pos))
         (var-result (or (extract-string-literal line pos)
                        (extract-symbol line pos))))
    (when var-result
      (list :ifdef (car var-result) is-ifdef))))

;; ============================================================================
;; Line scanning
;; ============================================================================

(defun scan-line (line)
  "Scan a single line for dependency-affecting events. Returns list of events."
  (let ((events nil)
        (line-lower (string-downcase line)))
    
    ;; Check for cert_param comment
    (let ((cp-pos (search "cert_param:" line-lower)))
      (when cp-pos
        (let ((params (parse-cert-params line (+ cp-pos 11))))
          (dolist (p params)
            (push (list :cert-param (car p) (cdr p)) events)))))
    
    ;; Check for cert_env comment  
    (let ((ce-pos (search "cert_env:" line-lower)))
      (when ce-pos
        (let ((params (parse-cert-params line (+ ce-pos 9))))
          (dolist (p params)
            (push (list :cert-env (car p) (cdr p)) events)))))
    
    ;; Check for include-book (must not be after semicolon)
    (let ((ib-pos (search "(include-book" line-lower)))
      (when (and ib-pos (not (line-has-comment-before line ib-pos)))
        (let ((ev (parse-include-book line (+ ib-pos 13))))
          (when ev (push ev events)))))
    
    ;; Check for acl2::include-book
    (let ((ib-pos (search "(acl2::include-book" line-lower)))
      (when (and ib-pos (not (line-has-comment-before line ib-pos)))
        (let ((ev (parse-include-book line (+ ib-pos 19))))
          (when ev (push ev events)))))
    
    ;; Check for add-include-book-dir! (exported)
    (let ((aid-pos (search "(add-include-book-dir!" line-lower)))
      (when (and aid-pos (not (line-has-comment-before line aid-pos)))
        (let ((ev (parse-add-include-book-dir line (+ aid-pos 22) t)))
          (when ev (push ev events)))))
    
    ;; Check for add-include-book-dir (not exported)
    (let ((aid-pos (search "(add-include-book-dir " line-lower)))
      (when (and aid-pos (not (line-has-comment-before line aid-pos)))
        (let ((ev (parse-add-include-book-dir line (+ aid-pos 21) nil)))
          (when ev (push ev events)))))
    
    ;; Check for depends-on (CAN be in comment)
    (let ((do-pos (search "(depends-on" line-lower)))
      (when do-pos
        (let ((ev (parse-depends-on line (+ do-pos 11))))
          (when ev (push ev events)))))
    
    ;; Check for loads (CAN be in comment)
    (let ((ld-pos (search "(loads " line-lower)))
      (when ld-pos
        (let ((ev (parse-loads-form line (+ ld-pos 7) :loads)))
          (when ev (push ev events)))))
    
    ;; Check for include-events
    (let ((ie-pos (search "(include-events" line-lower)))
      (when (and ie-pos (not (line-has-comment-before line ie-pos)))
        (let ((ev (parse-loads-form line (+ ie-pos 15) :include-events)))
          (when ev (push ev events)))))
    
    ;; Check for include-src-events
    (let ((ise-pos (search "(include-src-events" line-lower)))
      (when (and ise-pos (not (line-has-comment-before line ise-pos)))
        (let ((ev (parse-loads-form line (+ ise-pos 19) :include-src-events)))
          (when ev (push ev events)))))
    
    ;; Check for ld
    (let ((ld-pos (search "(ld " line-lower)))
      (when (and ld-pos (not (line-has-comment-before line ld-pos)))
        (let ((ev (parse-loads-form line (+ ld-pos 4) :ld)))
          (when ev (push ev events)))))
    
    ;; Check for ifdef
    (let ((if-pos (search "(ifdef " line-lower)))
      (when (and if-pos (not (line-has-comment-before line if-pos)))
        (let ((ev (parse-ifdef line (+ if-pos 7) t)))
          (when ev (push ev events)))))
    
    ;; Check for ifndef  
    (let ((ifn-pos (search "(ifndef " line-lower)))
      (when (and ifn-pos (not (line-has-comment-before line ifn-pos)))
        (let ((ev (parse-ifdef line (+ ifn-pos 8) nil)))
          (when ev (push ev events)))))
    
    ;; Check for :endif
    (let ((endif-pos (search ":endif" line-lower)))
      (when endif-pos
        (push (list :endif) events)))
    
    ;; Check for ifdef-define
    (let ((ifd-pos (search "(ifdef-define" line-lower)))
      (when ifd-pos
        (let* ((pos (skip-whitespace line (+ ifd-pos 13)))
               (var-result (or (extract-string-literal line pos)
                              (extract-symbol line pos))))
          (when var-result
            (push (list :ifdef-define (car var-result)) events)))))
    
    ;; Check for ifdef-undefine
    (let ((ifu-pos (search "(ifdef-undefine" line-lower)))
      (when ifu-pos
        (let* ((pos (skip-whitespace line (+ ifu-pos 15)))
               (var-result (or (extract-string-literal line pos)
                              (extract-symbol line pos))))
          (when var-result
            (push (list :ifdef-undefine (car var-result)) events)))))
    
    ;; Return events in order
    (nreverse events)))

(defun scan-file-lines (lines)
  "Scan a list of lines, returning all events found."
  (let ((events nil))
    (dolist (line lines)
      (setf events (nconc events (scan-line line))))
    events))

;; ============================================================================
;; Main scanning entry point
;; ============================================================================

(defun scan-file-raw (filename)
  "Scan a file for dependency events. Uses cache if available.
   Returns list of events."
  (or (get-cached-events filename)
      (let ((lines (read-file-lines-raw filename)))
        (if lines
            (cache-events filename (scan-file-lines lines))
          nil))))

;; ============================================================================
;; Path utilities
;; ============================================================================

(defun canonical-path (path)
  "Convert a path to canonical form (absolute, resolved symlinks)."
  (handler-case
      (namestring (truename (pathname path)))
    (error ()
      ;; If file doesn't exist yet, just make it absolute
      (namestring (merge-pathnames path)))))

(defun path-dirname (path)
  "Get the directory portion of a path."
  (let ((pn (pathname path)))
    (namestring (make-pathname :directory (pathname-directory pn)
                               :device (pathname-device pn)))))

(defun path-basename (path)
  "Get the filename portion of a path."
  (let ((pn (pathname path)))
    (if (pathname-type pn)
        (format nil "~A.~A" (pathname-name pn) (pathname-type pn))
      (pathname-name pn))))

(defun path-join (dir file)
  "Join a directory and filename."
  (namestring (merge-pathnames file dir)))

(defun lisp-to-cert2 (lisp-path)
  "Convert a .lisp path to .cert2 path."
  (let ((base (subseq lisp-path 0 (- (length lisp-path) 5))))
    (concatenate 'string base ".cert2")))

(defun cert2-to-lisp (cert-path)
  "Convert a .cert2 path to .lisp path."
  (let ((base (subseq cert-path 0 (- (length cert-path) 6))))
    (concatenate 'string base ".lisp")))

(defun has-extension (path ext)
  "Check if path has the given extension (including the dot)."
  (and (> (length path) (length ext))
       (string-equal (subseq path (- (length path) (length ext))) ext)))

;; ============================================================================
;; Include-book directory resolution
;; ============================================================================

(defvar *include-book-dirs* (make-hash-table :test 'eq)
  "Global include-book directory mappings (keyword -> path)")

(defun register-include-book-dir (keyword path)
  "Register an include-book directory mapping."
  (setf (gethash keyword *include-book-dirs*) path))

(defun lookup-include-book-dir (keyword local-dirs)
  "Look up an include-book directory, checking local dirs first."
  (or (cdr (assoc keyword local-dirs))
      (gethash keyword *include-book-dirs*)))

(defun resolve-book-path (name dir-keyword local-dirs base-dir)
  "Resolve a book name to a full path.
   NAME is the string from include-book
   DIR-KEYWORD is the :dir argument (string like \":system\") or nil
   LOCAL-DIRS is an alist of local directory mappings
   BASE-DIR is the directory of the file containing the include-book"
  (let* ((kwd (when dir-keyword
                (intern (string-upcase 
                         (if (char= (char dir-keyword 0) #\:)
                             (subseq dir-keyword 1)
                           dir-keyword))
                        :keyword)))
         (dir (if kwd
                  (lookup-include-book-dir kwd local-dirs)
                base-dir)))
    (if dir
        (canonical-path (path-join dir (concatenate 'string name ".lisp")))
      (progn
        (format *error-output* "Warning: Unknown include-book dir ~A~%" dir-keyword)
        nil))))

;; ============================================================================
;; Cert-param parsing from events
;; ============================================================================

(defun parse-cert-param-event (key value params)
  "Update a cert-params structure based on a cert_param key=value.
   Returns the updated params."
  (let ((key-lower (string-downcase key))
        (val-true (or (string-equal value "t")
                      (string-equal value "1")
                      (string-equal value ""))))
    (cond
      ((string-equal key-lower "acl2x")
       (change-cert-params params :acl2x val-true))
      ((string-equal key-lower "acl2xskip")
       (change-cert-params params :acl2xskip val-true))
      ((string-equal key-lower "pcert")
       (change-cert-params params :pcert val-true))
      ((or (string-equal key-lower "reloc-stub")
           (string-equal key-lower "reloc_stub"))
       (change-cert-params params :reloc-stub val-true))
      ((string-equal key-lower "ansi-only")
       (change-cert-params params :ansi-only val-true))
      ((string-equal key-lower "ccl-only")
       (change-cert-params params :ccl-only val-true))
      ((string-equal key-lower "non-allegro")
       (change-cert-params params :non-allegro val-true))
      ((string-equal key-lower "non-cmucl")
       (change-cert-params params :non-cmucl val-true))
      ((string-equal key-lower "non-gcl")
       (change-cert-params params :non-gcl val-true))
      ((string-equal key-lower "non-lispworks")
       (change-cert-params params :non-lispworks val-true))
      ((string-equal key-lower "non-sbcl")
       (change-cert-params params :non-sbcl val-true))
      ((string-equal key-lower "non-acl2r")
       (change-cert-params params :non-acl2r val-true))
      ((string-equal key-lower "non-acl2p")
       (change-cert-params params :non-acl2p val-true))
      ((string-equal key-lower "uses-acl2r")
       (change-cert-params params :uses-acl2r val-true))
      ((string-equal key-lower "uses-abc")
       (change-cert-params params :uses-abc val-true))
      ((string-equal key-lower "uses-glucose")
       (change-cert-params params :uses-glucose val-true))
      ((string-equal key-lower "uses-ipasir")
       (change-cert-params params :uses-ipasir val-true))
      ((string-equal key-lower "uses-smtlink")
       (change-cert-params params :uses-smtlink val-true))
      ((string-equal key-lower "uses-stp")
       (change-cert-params params :uses-stp val-true))
      ((string-equal key-lower "uses-quicklisp")
       (change-cert-params params :uses-quicklisp val-true))
      ((string-equal key-lower "uses-cpp")
       (change-cert-params params :uses-cpp val-true))
      ((string-equal key-lower "acl2-image")
       (change-cert-params params :acl2-image value))
      (t
       ;; Unknown param - could warn here
       params))))

;; ============================================================================
;; Save/restore cache to disk
;; ============================================================================

(defun save-event-cache (filename)
  "Save the event cache to a file."
  (handler-case
      (with-open-file (stream filename :direction :output
                                       :if-exists :supersede)
        (let ((entries nil))
          (maphash (lambda (k v) (push (cons k v) entries)) *event-cache*)
          (print `(:event-cache :version 1 :entries ,entries) stream)))
    (error (c)
      (format *error-output* "Error saving cache to ~A: ~A~%" filename c))))

(defun load-event-cache (filename)
  "Load the event cache from a file."
  (handler-case
      (with-open-file (stream filename :direction :input
                                       :if-does-not-exist nil)
        (when stream
          (let ((data (read stream nil nil)))
            (when (and (consp data)
                       (eq (car data) :event-cache)
                       (eql (getf (cdr data) :version) 1))
              (clrhash *event-cache*)
              (dolist (entry (getf (cdr data) :entries))
                (setf (gethash (car entry) *event-cache*) (cdr entry)))
              t))))
    (error (c)
      (format *error-output* "Error loading cache from ~A: ~A~%" filename c)
      nil)))
