; ACL2 Build2 System - Package Definition
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "ACL2")

; Define the BUILD2 package for our certification system
; We import from:
;   - ACL2 exports for standard functionality
;   - STR for string manipulation
;   - DEPGRAPH for dependency graph algorithms
;   - OSLIB for OS utilities

(defpkg "BUILD2"
  (union-eq
   '(; ACL2 state and IO
     state
     open-input-channel
     close-input-channel
     read-char$
     peek-char$
     read-byte$
     read-object
     princ$
     cw
     fmt-to-string
     canonical-pathname
     cbd
     system-books-dir
     ;; Error handling
     er
     msg
     value
     er-let*
     ;; Global state
     f-get-global
     f-put-global
     state-global-let*
     ;; Book operations
     include-book
     certify-book
     ld
     ;; String utilities (from STR)
     str::strpos
     str::strtok
     str::strprefixp
     str::strsuffixp
     str::strsubst
     str::cat
     str::natstr
     str::downcase-string
     str::upcase-string
     str::trim
     ;; Dependency graph (from DEPGRAPH)
     depgraph::toposort
     depgraph::topologically-ordered-p
     depgraph::invert-graph
     ;; OSLIB utilities
     oslib::catpath
     oslib::dirname
     oslib::basename
     oslib::ls
     oslib::file-kind
     oslib::regular-file-p
     oslib::directory-p
     )
   (union-eq *acl2-exports*
             *common-lisp-symbols-from-main-lisp-package*)))
