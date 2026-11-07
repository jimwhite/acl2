;;;; dylink-test.lisp -- payload for the browser dynamic-linking smoke test.
;;;;
;;;; wasm/web/dylink.html loads this as a wasm side module into the browser
;;;; build of ECL and calls the functions below.  It is the same mechanism a
;;;; certified book uses: compile a .lisp file for the wasm target with
;;;; wasm/aot-book.sh, and LOAD the result in a running ECL -- except that here
;;;; the ECL is the one in the page, so it proves the browser module can dlopen
;;;; modules at all (which needs a DYLINK=1 build; see wasm/build-ecl-wasm.sh).

(in-package "CL-USER")

(defun dylink-double (x)
  (* 2 x))

(defun dylink-fib (n)
  (if (< n 2) n (+ (dylink-fib (- n 1)) (dylink-fib (- n 2)))))

(defun dylink-vec-sum (v)
  (loop for x across v sum x))

;; A load-time side effect, so the log shows the module's init function ran.
(format t "~&; dylink-test module initialised~%")
