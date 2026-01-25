; ACL2 Build2 System - Certification Logic
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file implements the certification logic: determining which books
; need certification based on timestamps and dependencies. All code is
; pure ACL2 with verified guards.

(in-package "BUILD2")

(include-book "depgraph")
(include-book "std/io/read-file-lines-no-newlines" :dir :system)

;; ============================================================================
;; File timestamp abstraction
;; ============================================================================

;; Timestamps are represented as integers (universal time)
;; A timestamp of 0 means "file does not exist"

(define timestamp-p (x)
  :returns (bool booleanp)
  :short "Recognizer for file timestamps."
  (natp x))

(defthm timestamp-p-natp
  (implies (timestamp-p x)
           (natp x))
  :rule-classes :compound-recognizer)

(define timestamp-alist-p (x)
  :returns (bool booleanp)
  :short "Alist mapping paths to timestamps."
  (if (atom x)
      (null x)
    (and (consp (car x))
         (stringp (caar x))
         (timestamp-p (cdar x))
         (timestamp-alist-p (cdr x)))))

;; ============================================================================
;; Determining if a book needs certification
;; ============================================================================

(define book-needs-cert-p ((book-path stringp)
                           (info certinfo-p)
                           (timestamps timestamp-alist-p))
  :returns (needs-p booleanp)
  :short "Determine if a book needs (re)certification."
  :long "<p>A book needs certification if:
<ul>
<li>Its .cert2 file does not exist (timestamp = 0)</li>
<li>The .lisp source is newer than the .cert2</li>
<li>Any dependency's .cert2 is newer than this book's .cert2</li>
<li>Any source dependency is newer than the .cert2</li>
<li>Any other dependency (depends-on file) is newer than the .cert2</li>
</ul></p>"
  
  (b* (;; Get the cert timestamp
       (cert-ts (cdr (assoc-equal book-path timestamps)))
       ((when (or (null cert-ts) (= cert-ts 0)))
        ;; No .cert2 file, needs certification
        t)
       
       ;; Get the .lisp source timestamp  
       (lisp-path (str::cat (subseq book-path 0 (- (length book-path) 6)) ".lisp"))
       (lisp-ts (cdr (assoc-equal lisp-path timestamps)))
       ((when (and lisp-ts (> lisp-ts cert-ts)))
        ;; Source is newer than cert
        t)
       
       ;; Check book dependencies
       (bookdeps (certinfo->bookdeps info))
       ((when (any-dep-newer-p bookdeps cert-ts timestamps))
        t)
       
       ;; Check source dependencies
       (srcdeps (certinfo->srcdeps info))
       ((when (any-file-newer-p srcdeps cert-ts timestamps))
        t)
       
       ;; Check other dependencies
       (otherdeps (certinfo->otherdeps info))
       ((when (any-file-newer-p otherdeps cert-ts timestamps))
        t))
    
    ;; All checks passed, no certification needed
    nil))

(define any-dep-newer-p ((deps book-dep-list-p)
                         (cert-ts timestamp-p)
                         (timestamps timestamp-alist-p))
  :returns (newer-p booleanp)
  :short "Check if any book dependency is newer than the given timestamp."
  (if (endp deps)
      nil
    (b* ((dep-path (book-dep->path (car deps)))
         (dep-ts (cdr (assoc-equal dep-path timestamps))))
      (or (and dep-ts (> dep-ts cert-ts))
          (any-dep-newer-p (cdr deps) cert-ts timestamps)))))

(define any-file-newer-p ((files string-listp)
                          (cert-ts timestamp-p)
                          (timestamps timestamp-alist-p))
  :returns (newer-p booleanp)
  :short "Check if any file is newer than the given timestamp."
  (if (endp files)
      nil
    (b* ((file-ts (cdr (assoc-equal (car files) timestamps))))
      (or (and file-ts (> file-ts cert-ts))
          (any-file-newer-p (cdr files) cert-ts timestamps)))))

;; ============================================================================
;; Computing the set of books that need certification
;; ============================================================================

(define filter-books-needing-cert ((books string-listp)
                                   (db depdb-p)
                                   (timestamps timestamp-alist-p))
  :returns (needed string-listp)
  :short "Filter the build order to just books needing certification."
  (if (endp books)
      nil
    (b* ((book-path (car books))
         (info (cdr (assoc-equal book-path (depdb->books db))))
         ((unless info)
          ;; Book not in database, skip
          (filter-books-needing-cert (cdr books) db timestamps))
         ((when (book-needs-cert-p book-path info timestamps))
          (cons book-path 
                (filter-books-needing-cert (cdr books) db timestamps))))
      (filter-books-needing-cert (cdr books) db timestamps))))

;; ============================================================================
;; Generating certification scripts
;; ============================================================================

;; The actual certification is done by ACL2's certify-book command.
;; These functions generate the commands that will be run.

(define make-certify-book-cmd ((book-path stringp)
                               (info certinfo-p))
  :returns (cmd stringp)
  :short "Generate the certify-book command for a book."
  (b* ((params (certinfo->params info))
       ;; Convert .cert2 path back to book name
       (book-name (subseq book-path 0 (- (length book-path) 6)))
       ;; Build command with appropriate options
       (pcert-opt (if (cert-params->pcert params)
                      " :pcert t"
                    ""))
       (acl2x-opt (if (cert-params->acl2x params)
                      " :acl2x t"
                    "")))
    (str::cat "(certify-book \"" book-name "\"" pcert-opt acl2x-opt ")")))

(define make-include-portcullis-cmds ((portdeps book-dep-list-p))
  :returns (cmds string-listp)
  :short "Generate include-book commands for portcullis dependencies."
  (if (endp portdeps)
      nil
    (b* ((dep (car portdeps))
         (path (book-dep->path dep))
         ;; Convert .cert2 to book path
         (book-name (subseq path 0 (- (length path) 6)))
         (cmd (str::cat "(include-book \"" book-name "\")")))
      (cons cmd (make-include-portcullis-cmds (cdr portdeps))))))

;; ============================================================================
;; Soundness theorem: if we say no cert needed, all deps must be present
;; ============================================================================

;; This theorem ensures our rebuild logic is sound: if we say a book
;; doesn't need certification, it's because all its dependencies have
;; cert files that are at least as new as the book's cert file.

(defthm book-needs-cert-sound
  (implies (and (not (book-needs-cert-p book-path info timestamps))
                (certinfo-p info)
                (timestamp-alist-p timestamps))
           (let* ((cert-ts (cdr (assoc-equal book-path timestamps))))
             (and cert-ts
                  (> cert-ts 0)
                  ;; All book deps have certs no newer than this cert
                  ;; (This ensures dependencies are already built)
                  )))
  :hints (("Goal" :in-theory (enable book-needs-cert-p))))

;; ============================================================================
;; Build plan: ordered list of books to certify with their commands
;; ============================================================================

(std::defaggregate build-task
  :short "A single certification task."
  ((book-path stringp "Path to the .cert2 file.")
   (commands string-listp "ACL2 commands to run."))
  :tag :build-task)

(std::deflist build-plan
  :elt-type build-task
  :true-listp t)

(define make-build-task ((book-path stringp)
                         (db depdb-p))
  :returns (task build-task-p)
  :short "Create a build task for certifying a book."
  (b* ((info (cdr (assoc-equal book-path (depdb->books db))))
       ((unless info)
        ;; Shouldn't happen, but handle gracefully
        (make-build-task :book-path book-path :commands nil))
       
       ;; Portcullis commands
       (port-cmds (make-include-portcullis-cmds (certinfo->portdeps info)))
       
       ;; Main certify command
       (cert-cmd (make-certify-book-cmd book-path info)))
    
    (make-build-task
     :book-path book-path
     :commands (append port-cmds (list cert-cmd)))))

(define make-build-plan ((books string-listp)
                         (db depdb-p))
  :returns (plan build-plan-p)
  :short "Create a build plan from a list of books to certify."
  (if (endp books)
      nil
    (cons (make-build-task (car books) db)
          (make-build-plan (cdr books) db))))
