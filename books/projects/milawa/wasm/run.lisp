;;;; The Lisp entry point of the WebAssembly checker.
;;;;
;;;; This file is compiled into the checker program along with milawa.lsp (see
;;;; wasm/build-kernel.lisp) and called from wasm/milawa-wasm.c.
;;;;
;;;; It runs the command loop and handles FINISH itself, rather than calling
;;;; milawa.lsp's MAIN: MAIN calls (QUIT) at end of input, and ECL's QUIT
;;;; unwinds to the bottom of its toplevel, which does not exist in this
;;;; embedding -- the unwind crashes under emscripten.  FINISH only has to
;;;; write the image, which DUMP-ECL-IMAGE does, and then stop reading.

(in-package "CL-USER")

(defun milawa-wasm-run (image extension events)
  (set 'cl-user::image-extension extension)
  (format t "Milawa Proof Checker.~%")
  (with-open-file (stream events)
    (loop for cmd = (let ((*package* (find-package "MILAWA")))
                      (read stream nil cl-user::unique-cons-for-eof))
          until (eq cmd cl-user::unique-cons-for-eof)
          do (if (and (consp cmd)
                      (eq (car cmd) 'MILAWA::FINISH)
                      (stringp (second cmd)))
                 (progn
                   (format t "~A > FINISH ~A~%"
                           cl-user::*event-number* (second cmd))
                   (cl-user::dump-ecl-image
                    (concatenate 'string (second cmd) "." extension))
                   (return))
                 (cl-user::try-to-accept-command cmd))
             (incf cl-user::*event-number*)))
  t)
