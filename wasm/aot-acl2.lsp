;;;; aot-acl2.lsp -- cross-compile ACL2 book expansion files into loadable
;;;; WebAssembly modules, from inside a native ACL2.
;;;;
;;;; Why inside ACL2: certify-book's expansion file (<book>@expansion.lsp) is
;;;; not plain text.  It begins with ACL2 `serialize' data (#Z/#Y read macros,
;;;; for the hcomp alists) and continues with the book's events.  Only ACL2's
;;;; own readtable can read that -- `*acl2-readtable*`, installed by
;;;; ACL2_SAVE_EXPANSION-certified books -- so the compile has to happen in a
;;;; process with the ACL2 sources loaded.  A native saved ACL2 is such a
;;;; process, and its ECL also has the Lisp->C compiler.
;;;;
;;;; Why not `compile-file :target' here: the ECL inside a native ACL2 build is
;;;; a *different* ECL from the one build-ecl-wasm.sh builds, and the two
;;;; disagree about the entry-point name of a compiled file -- this one emits
;;;; `init_fas_CODE', the wasm one looks for `__ecl_init_fas_CODE' (see
;;;; cmp/cmpbackend-cxx/cmpc-init-name.lsp and c/ffi/libraries.d in each).  So
;;;; the compile is split in two here: ECL generates the C, this file renames
;;;; the entry point if needed, and emcc compiles and links the module.
;;;;
;;;; Usage, from a shell:
;;;;
;;;;   ACL2_AOT_FILES="books/x/foo@expansion.lsp ..." \
;;;;   ACL2_AOT_DELTA=/tmp/wasm32.delta \
;;;;   ./saved_acl2 < wasm/aot-acl2.lsp
;;;;
;;;; Each <book>@expansion.lsp becomes <book>.fasc -- the name include-book
;;;; later loads -- as a wasm side module for a wasm ECL built with DYLINK=1.
;;;;
;;;; The target's flags come from the delta file written by
;;;; wasm/mk-wasm32-target.lsp; see wasm/wasm32-target.lsp for why a delta of
;;;; plain strings and keywords is used instead of the target-info file itself
;;;; (this ECL cannot read a target-info written by the other one).

(in-package "ACL2")

(value :q)

(in-package "ACL2")

(load (or (ext:getenv "ACL2_AOT_TARGET")
          "/workspaces/acl2-ecl/wasm/wasm32-target.lsp"))

(defparameter *aot-delta*
  (wasm-target:read-delta (or (ext:getenv "ACL2_AOT_DELTA") "/tmp/wasm32.delta")))

(defparameter *aot-target-info* nil)

(defun aot-target-info ()
  (or *aot-target-info*
      (setf *aot-target-info*
            (wasm-target:apply-overrides (c::get-target-info) *aot-delta*))))

(defun aot-module-name (expansion-file)
  "…/<book>@expansion.lsp -> …/<book>.fasc"
  (let* ((p (pathname expansion-file))
         (name (pathname-name p))
         (suffix "@expansion")
         (n (length suffix)))
    (unless (and (> (length name) n)
                 (string= suffix name :start2 (- (length name) n)))
      (error "~a is not a book expansion file" expansion-file))
    (make-pathname :name (subseq name 0 (- (length name) n))
                   :type "fasc"
                   :defaults p)))

(defun aot-run (command)
  (let ((status (si::system command)))
    (unless (eql status 0)
      (error "command failed (~d): ~a" status command))))

;;; ECL's short entry-point name -> the long one the wasm ECL dlsym's.  The
;;; generated C mentions it twice: in the definition and in the @EcLtAg: tag
;;; (which is how find-init-name locates it when `nm' is unavailable).
;;; The short name only ever appears unprefixed here (the long one contains it
;;; as a suffix), so a plain search-and-replace is safe once we know which
;;; convention this ECL uses.
(defun aot-fix-entry-name (c-file)
  (let* ((text (with-open-file (s c-file :direction :input)
                 (let* ((len (file-length s))
                        (buf (make-string len))
                        (n (read-sequence buf s)))
                   (subseq buf 0 n))))
         (long "__ecl_init_fas_CODE")
         (short "init_fas_CODE"))
    (if (search long text)
        nil
        (progn
          (unless (search short text)
            (error "no init entry point found in ~a" c-file))
          (with-open-file (s c-file :direction :output :if-exists :supersede)
            (loop with n = (length short)
                  with start = 0
                  for pos = (search short text :start2 start)
                  while pos
                    do (write-string text s :start start :end pos)
                       (write-string long s)
                       (setf start (+ pos n))
                  finally (write-string text s :start start)))
          (format t "~&;; renamed ~a: ~a -> ~a~%"
                  (file-namestring c-file) short long)
          t))))

(defun aot-file (expansion-file)
  (let* ((delta *aot-delta*)
         (out (aot-module-name expansion-file))
         (tmp (make-pathname :name (concatenate 'string
                                                (pathname-name out) "-aot")
                             :type "fasc" :defaults out))
         (c (make-pathname :name (pathname-name tmp) :type "c" :defaults tmp))
         (h (make-pathname :name (pathname-name tmp) :type "eclh" :defaults tmp))
         (d (make-pathname :name (pathname-name tmp) :type "data" :defaults tmp))
         (o (make-pathname :name (pathname-name tmp) :type "o" :defaults tmp))
         (start (get-internal-real-time)))
    (format t "~&;; AOT ~a -> ~a~%" expansion-file out)
    (force-output)
    ;; 1. ECL generates the C.  The .fasc it also writes is thrown away.
    (let ((*readtable* *acl2-readtable*))
      (proclaim '(ext:use-direct-c-call nil))
      (unwind-protect
           (c::compile-with-target-info
            (lambda ()
              (compile-file expansion-file :output-file tmp
                            :c-file c :h-file h :data-file d))
            (aot-target-info))
        (proclaim '(ext:use-direct-c-call t))))
    (aot-fix-entry-name c)
    ;; 2. emcc compiles and links the side module.
    (aot-run (format nil "~a -I. -I~a ~a -c ~a -o ~a"
                     (getf delta :cc)
                     (getf delta :include)
                     (getf delta :cc-flags)
                     (namestring c) (namestring o)))
    (aot-run (format nil "~a -o ~a -L~a ~a ~a"
                     (getf delta :ld)
                     (namestring out)
                     (getf delta :library)
                     (getf delta :ld-shared-flags)
                     (namestring o)))
    (format t ";;   ~a (~d bytes, ~,2f s)~%"
            out
            (with-open-file (s out :element-type '(unsigned-byte 8))
              (file-length s))
            (/ (- (get-internal-real-time) start)
               internal-time-units-per-second))
    (dolist (f (list tmp c h d o))
      (when (probe-file f) (delete-file f)))
    out))

(defun aot-files (files)
  (let ((ok 0) (bad '()))
    (dolist (f files)
      (handler-case (progn (aot-file f) (incf ok))
        (error (e)
          (format t "~&;; AOT FAILED ~a: ~a~%" f e)
          (push f bad))))
    (format t "~&;; AOT: ~d module~:p written, ~d failed~%" ok (length bad))
    (values ok bad)))

(defun aot-main ()
  (let ((files (let ((s (ext:getenv "ACL2_AOT_FILES")))
                 (when (and s (not (equal s "")))
                   (loop with start = 0
                         for pos = (position #\Space s :start start)
                         collect (subseq s start pos)
                         while pos
                         do (setf start (1+ pos)))))))
    (format t "~&;; AOT: ~d file~:p to compile~%" (length files))
    (aot-files files)))

;; Run as a script (the last form of the file, since `(value :q)' above put us
;; back in raw Lisp): nothing to do if no files were named.
(when (ext:getenv "ACL2_AOT_FILES")
  (aot-main)
  (si:quit))
