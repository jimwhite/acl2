; Milawa-Lisp: the verified core of a WASM-targeted Lisp for Milawa.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This book pulls in the language and its metatheory.  The WASM refinement
; books (machine/, wasm/) build on it and are not written yet; see
; ../README.md for what is and is not proved.

(in-package "ACL2")

(include-book "values")
(include-book "eval")
(include-book "programs")
(include-book "metatheory")
(include-book "reachability")
