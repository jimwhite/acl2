; ACL2 Build2 System - Top-level book for ACL2 verification
; Copyright (C) 2026
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.

; This book includes the certifiable portions of the build2 system.
; The raw Lisp files (.lsp) are loaded separately at runtime.

(in-package "ACL2")

; Load the package definition
(include-book "tools/include-raw" :dir :system)

; Include the data structures
; Note: certinfo.lisp includes std/util/defaggregate and std/alists
; which provide the infrastructure for our data structures.

; For bootstrapping, we need a simpler approach that doesn't require
; those books to already be certified. This file serves as documentation
; of the intended structure.

; The actual build2 system runs entirely in raw Lisp mode and doesn't
; require these books to be certified - it only needs ACL2 (or the
; underlying Lisp) to be available.

(defun build2-version ()
  (declare (xargs :guard t))
  "0.1.0")

; Placeholder - the real implementation is in the raw Lisp files
(defstub certify-book2-stub (path state) => (mv result state))
