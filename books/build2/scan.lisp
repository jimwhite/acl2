; ACL2 Build2 System - Dependency Scanner Interface
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; This file documents the interface for the dependency scanner.
; The actual implementation is in scan-raw.lsp (raw Common Lisp).

(in-package "ACL2")

;; ============================================================================
;; Event types recognized during scanning
;; ============================================================================

;; These correspond to the dependency-affecting forms we recognize in source files.
;;
;; :include-book          - (include-book "name" [:dir :kwd])
;; :add-include-book-dir  - (add-include-book-dir :kwd "path")
;; :add-include-book-dir! - (add-include-book-dir! :kwd "path") - exported
;; :depends-on            - (depends-on "file" [:dir :kwd])
;; :depends-rec           - (depends-rec "book" [:dir :kwd])
;; :loads                 - (loads "file" [:dir :kwd])
;; :include-events        - (include-events "book" [:dir :kwd])
;; :include-src-events    - (include-src-events "file" [:dir :kwd])
;; :ld                    - (ld "file" [:dir :kwd])
;; :cert-param            - ; cert_param: (name=value, ...)
;; :cert-env              - ; cert_env: (name=value)
;; :ifdef                 - (ifdef "VAR" ...) or (ifndef "VAR" ...)
;; :endif                 - :endif marker
;; :ifdef-define          - (ifdef-define "VAR")
;; :ifdef-undefine        - (ifdef-undefine "VAR")
;; :pbs                   - ;PBS directive
;; :set-max-mem           - (set-max-mem n)
;; :set-max-time          - (set-max-time n)

;; ============================================================================
;; Parsed event structure
;; ============================================================================

;; A scanned event is a list: (type arg1 arg2 ...)
;; For example:
;;   (:include-book "foo" ":system" nil nil) 
;;       - include-book of foo from :system, not local, no no_port
;;   (:include-book "bar" nil t nil)        
;;       - include-book of bar, no :dir, local
;;   (:cert-param "pcert" "t")          
;;       - cert_param pcert=t
;;   (:ifdef "SOME_VAR" t)              
;;       - ifdef (t=ifdef, nil=ifndef)

;; ============================================================================
;; Interface documentation
;; ============================================================================

;; The following functions are implemented in scan-raw.lsp:
;;
;; (scan-file-raw filename)
;;   Scan a file for dependency events. Uses cache if available.
;;   Returns list of events.
;;
;; (scan-line line)
;;   Scan a single line for dependency-affecting events.
;;   Returns list of events found on that line.
;;
;; (scan-file-lines lines)
;;   Scan a list of lines, returning all events found.
;;
;; (get-cached-events filename)
;;   Get cached events for a file if still valid.
;;   Returns events or NIL.
;;
;; (cache-events filename events)
;;   Cache events for a file with its current timestamp.
;;
;; (save-event-cache filename)
;;   Save the event cache to a file.
;;
;; (load-event-cache filename)
;;   Load the event cache from a file.

;; ============================================================================
;; Comment recognition rules
;; ============================================================================

;; Most forms must NOT appear after a semicolon (comment) on the same line.
;; Exceptions (CAN appear in comments):
;;   - depends-on
;;   - loads
;;   - cert_param / cert_env (these are comment directives by design)
;;   - ifdef-define / ifdef-undefine
;;
;; The scanner checks for these patterns and ignores forms that appear
;; after a semicolon unless they are in the exception list.

;; ============================================================================
;; Local include-book detection
;; ============================================================================

;; An include-book is considered "local" if the line contains "(local"
;; appearing before "(include-book". This is a heuristic that catches
;; the common pattern:
;;   (local (include-book "foo"))
;;
;; Local include-books don't propagate their cert_param requirements
;; to including books.

;; ============================================================================
;; no_port directive
;; ============================================================================

;; Adding "; no_port" or ";; no_port" after an include-book on the same
;; line suppresses loading of that book's .port file during certification.
;; This is useful when the included book defines packages that conflict
;; with the current book's setup.
