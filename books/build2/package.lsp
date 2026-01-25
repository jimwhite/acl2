; ACL2 Build2 System - Package Definition
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

(in-package "ACL2")

; Define the BUILD2 package for our certification system
(defpkg "BUILD2"
  (union-eq
   '(; Additional symbols we want to import
     value
     er
     msg
     state
     state-global-let*
     f-get-global
     f-put-global
     observation
     cw
     fmt-to-string
     include-book
     certify-book
     ld
     set-ld-error-action
     canonical-pathname
     cbd
     )
   (union-eq *acl2-exports*
             *common-lisp-symbols-from-main-lisp-package*)))
