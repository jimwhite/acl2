; Decode ../wasm/milawa-verified.wasm with the pinned wasm-acl2 binary decoder.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; This runs in PROGRAM mode, which is the whole point: W3T::GRAM/BMODULE is not a
; logic function, so decoding cannot happen inside a theorem.  This script is the
; bridge instead, and ../harness/gen_module.py turns its output into
; wasm3/module.lisp.
;
; It prints two marker lines and nothing else matters:
;
;   PARSE-REST=n            leftover bytes; 0 means a complete parse
;   MODULE-BEGIN=<term>=MODULE-END
;
; Run it from the repo root:
;
;   ./saved_acl2 < books/projects/milawa-verified-wasm/harness/decode.lsp

(include-book "/workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0/wasm3")
(program)
(set-state-ok t)

(defun read-bytes-loop (channel acc state)
  (mv-let (b state) (read-byte$ channel state)
    (if (null b)
        (mv (reverse acc) state)
      (read-bytes-loop channel (cons b acc) state))))

(defun read-bytes (file state)
  (mv-let (channel state) (open-input-channel file :byte state)
    (if (null channel)
        (mv nil state)
      (mv-let (bs state) (read-bytes-loop channel nil state)
        (let ((state (close-input-channel channel state)))
          (mv bs state))))))

(defconst *wasm*
  "/workspaces/acl2/books/projects/milawa-verified-wasm/wasm/milawa-verified.wasm")

(mv-let (bs state) (read-bytes *wasm* state)
  (let ((p (and bs (w3t::gram/bmodule bs))))
    (pprogn
     (fms "PARSE-REST=~x0~%" (list (cons #\0 (if p (len (cadr p)) -1)))
          (standard-co state) state nil)
     (if (null p)
         (pprogn (fms "PARSE-FAILED~%" nil (standard-co state) state nil)
                 (value :q))
       (pprogn
        (fms "MODULE-BEGIN=~x0=MODULE-END~%" (list (cons #\0 (car p)))
             (standard-co state) state nil)
        ;; Instantiating needs no externs: the module imports nothing, which is
        ;; proved in wasm3/decode.lisp.  This is a check, not a theorem -- like the
        ;; decode itself, because W3T::$INSTANTIATE is in :program mode.
        ;;
        ;; The result of $INSTANTIATE is a CONFIGURATION to run, not a store.  Our
        ;; module has no imports, no data and no start function, so there is
        ;; nothing to execute and that configuration is already final: the store
        ;; is (CADR (CADR C)) and the frame (CADDR (CADR C)), which is exactly how
        ;; the driver's FINAL-CONFIG destructures a stopped configuration.  Both
        ;; are pinned below, because W3T::$INVOKE -- which IS logic mode -- needs
        ;; them to build the entry configuration L1 is about.
        (let* ((c (w3t::$instantiate nil (car p) nil))
               (z (and c (cadr c)))
               (store (and z (cadr z)))
               (frame (and z (caddr z))))
          (pprogn
           (fms "INSTANTIATE=~x0~%" (list (cons #\0 (if c 'OK 'FAILED)))
                (standard-co state) state nil)
           (if (null c)
               (value :q)
             (pprogn
              (fms "STORE-BEGIN=~x0=STORE-END~%" (list (cons #\0 store))
                   (standard-co state) state nil)
              (pprogn
               (fms "FRAME-BEGIN=~x0=FRAME-END~%" (list (cons #\0 frame))
                    (standard-co state) state nil)
               (value :q)))))))))))
