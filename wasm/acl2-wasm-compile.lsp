; Compile the ACL2 sources with the WebAssembly build of ECL.
;
; The wasm build has no C compiler, so COMPILE-ACL2 produces portable .fasc
; files in the ACL2 source directory.  Run from anywhere:
;
;   ./wasm/acl2-wasm-compile
;
; which sets up the module's stack the same way as wasm/acl2-wasm.

(in-package "CL-USER")

(setq *load-verbose* nil)

(ext:chdir (or (ext:getenv "ACL2_WASM_DIR")
               (error "ACL2_WASM_DIR is not set")))

(ext:set-limit 'ext:frame-stack 262144)

(load "init.lisp")
(in-package "ACL2")

(acl2::compile-acl2)

(ext:quit 0)
