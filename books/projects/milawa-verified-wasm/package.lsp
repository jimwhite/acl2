; The project's package.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; Every book in milawa-lisp/, machine/ and wasm3/ is in MILAWA-WASM, so the
; functions and theorems this project defines cannot collide with another
; book's.  The name is project-specific rather than MILAWA because the sibling
; Milawa ACL2 tree (../milawa/ACL2/package.lsp) already defines a package called
; MILAWA with a different, curated import list; two definitions of one package
; name would be a worse conflict than the one this package exists to avoid.
;
; This file is loaded by each directory's cert.acl2 before any book is
; certified (the powerlists/ convention), because a defpkg is not an embedded
; event form and so cannot live in a book.  A session that includes these books
; by hand must (ld "package.lsp") first.
;
; The comment line below tells the build system to recertify if ACL2's export
; list changes:
; (depends-on "build/acl2-exports.certdep" :dir :system)

(in-package "ACL2")

(defpkg "MILAWA-WASM"
  (union-eq *acl2-exports*
            (union-eq *common-lisp-symbols-from-main-lisp-package*
                      ; From ihs/basic-definitions, which is not part of
                      ; *acl2-exports*: the byte functions our memory proofs use.
                      '(expt2 logapp loghead logtail))))
