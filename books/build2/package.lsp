; ACL2 Build2 System - Package Definition
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "ACL2")

; Load std's package definitions first (provides STD::*, STR::*, etc.)
(ld "std/package.lsp" :dir :system)

; Load centaur/fty package (provides FTY::*)
(ld "centaur/fty/package.lsp" :dir :system)

; Load centaur/bridge package (provides BRIDGE::json-encode)
(ld "centaur/bridge/package.lsp" :dir :system)

; Define the BUILD2 package for our certification system.
; We import std's exports which include define, defaggregate, etc.

(defpkg "BUILD2"
  (union-eq
   std::*std-exports*
   (union-eq
    '(;; ACL2 state and IO
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
      ;; b* is in std but make sure it's available
      b*
      )
    (union-eq *acl2-exports*
              *common-lisp-symbols-from-main-lisp-package*))))
