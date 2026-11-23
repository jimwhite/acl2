(include-book "/workspaces/acl2/books/projects/milawa-verified-wasm/wasm-acl2/translate/gen/wasm-3.0/wasm3")
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
  "/workspaces/acl2/books/projects/milawa-verified-wasm/wasm/milawa-ops.wasm")

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
