; -*- Mode: Lisp -*-

; Timing profile of ACL2 initialization on ECL.
;
; Usage, from the ACL2 source directory (the one holding init.lisp):
;
;   /opt/ecl-26.5.5/bin/ecl -norc -load ecl-tools/init-profile.lsp
;
; The script reproduces what nsaved_acl2.lsp does -- load init.lisp, load
; the compiled sources, install the bytecodes compiler -- and then calls
; initialize-acl2 with the instruments in place.  The result is written to
; ecl-init-profile.txt.
;
; Why instruments on LD-FN and the compile-uncompiled-* functions, rather
; than on COMPILE and COMPILE-FILE: ECL's compiler turns calls to functions
; defined earlier in the same file into direct C calls, so redefining
; COMPILE or COMPILE-FILE at run time intercepts only a small fraction of
; the work (see WASM-PORT-NOTES.md).  LD-FN (ld.lisp), and
; COMPILE-UNCOMPILED-DEFUNS / COMPILE-UNCOMPILED-*1*-DEFUNS
; (interface-raw.lisp) are each called from a different file than the one
; they are defined in, so they go through the symbol's function cell and
; can be wrapped from outside.
;
; Environment:
;   ACL2_INIT_PROFILE_KEEP_TMP=1  -- keep TMP*.lisp and the compiled TMP*
;                                   files for a phase-by-phase measurement.
;   ACL2_INIT_PROFILE_VERBOSE=1   -- do not suppress ACL2's initialization
;                                   output (suppressed by default, as in
;                                   nsaved_acl2.lsp).
;   ACL2_INIT_PROFILE_AOT=<file>  -- load <file> as the ahead-of-time file of
;                                   executable counterparts (see
;                                   *ACL2-*1*-AOT-FILE* in interface-raw.lisp).
;   ACL2_INIT_PROFILE_EXTRA=a,b,c -- also time the named ACL2 functions.  This
;                                   works in the wasm build for functions that
;                                   a native build turns into direct C calls.

(in-package "CL-USER")

(setq *load-verbose* nil)

(defvar *profile-table* (make-hash-table :test #'equal))

(defun prof-record (label seconds)
  (let ((cell (gethash label *profile-table*)))
    (if cell
        (progn (incf (car cell)) (incf (cdr cell) seconds))
        (setf (gethash label *profile-table*) (cons 1 seconds)))))

(defun call-timed (label thunk)
  (let ((t0 (get-internal-real-time)))
    (multiple-value-prog1
        (funcall thunk)
      (prof-record label
                   (/ (float (- (get-internal-real-time) t0))
                      internal-time-units-per-second)))))

(defun profile-total (&optional prefix)
  (let ((total 0.0))
    (maphash (lambda (label cell)
               (when (or (null prefix) (eql 0 (search prefix label)))
                 (incf total (cdr cell))))
             *profile-table*)
    total))

(defun wrap-with-timer (name label-fn &optional before)
  (let ((orig (symbol-function name)))
    (setf (symbol-function name)
          (lambda (&rest args)
            (when before (funcall before args))
            (call-timed (funcall label-fn args)
                        (lambda () (apply orig args)))))))

; Run from the ACL2 source directory: it is the parent of this script's
; directory, which is more reliable than the caller's working directory.
; Under the WebAssembly build (see wasm/acl2-wasm) there is no meaningful
; script directory inside the module, so ACL2_WASM_DIR names it instead.

(ext:chdir (or (ext:getenv "ACL2_WASM_DIR")
               (make-pathname
                :directory (butlast (pathname-directory
                                     (truename *load-pathname*)))
                :name nil :type nil)))
(ext:set-limit 'ext:frame-stack 262144)
(load "init.lisp")
(in-package "ACL2")
(load-acl2)
(ext:install-bytecodes-compiler)

; Everything below may use ACL2 package symbols, which exist only now.

(defun fns-desc (fns)
  (cond ((null fns) "nil")
        ((or (keywordp fns) (symbolp fns)) (symbol-name fns))
        ((consp fns) (format nil "(~d fns)" (length fns)))
        (t "?")))

(defun ld-fn-label (args)
  (let ((oi (cdr (assoc 'standard-oi (car args) :test #'eq))))
    (format nil "ld ~a"
            (cond ((stringp oi) oi)
                  ((streamp oi)
                   (format nil "~a" (or (ignore-errors (pathname oi))
                                        (type-of oi))))
                  ((consp oi)
                   (let ((form (car oi)))
                     (cond ((consp form)
                            (format nil "(~a ...)" (car form)))
                           (t (format nil "~s" (type-of form))))))
                  (t (format nil "~s" (type-of oi)))))))

(defun make-comp-label (kind)
  (lambda (args)
    (format nil "~a ~a" kind (fns-desc (cadr args)))))

(defun eval-label (args)
  (let ((form (car args)))
    (format nil "eval ~a"
            (cond ((consp form)
                   (let ((h (car form)))
                     (cond ((symbolp h) (symbol-name h))
                           ((consp h) "lambda")
                           (t "?"))))
                  ((null form) "nil")
                  (t (type-of form))))))

(defun compile-label (args)
  (format nil "compile ~a"
          (let ((x (car args)))
            (cond ((symbolp x) (symbol-name x))
                  (t (type-of x))))))

(defun compile-file-label (args)
  (format nil "compile-file ~a"
          (let ((x (car args)))
            (cond ((stringp x) x)
                  ((pathnamep x) (format nil "~a" (pathname-name x)))
                  (t (type-of x))))))

(when (equal (getenv$-raw "ACL2_INIT_PROFILE_KEEP_TMP") "1")
  (f-put-global 'keep-tmp-files t *the-live-state*))

; ACL2_INIT_PROFILE_AOT names a compiled file of executable counterparts to
; load instead of regenerating and compiling them (see *ACL2-*1*-AOT-FILE* in
; interface-raw.lisp).

(let ((aot (getenv$-raw "ACL2_INIT_PROFILE_AOT")))
  (when (and aot (not (equal aot "")))
    (setq *acl2-*1*-aot-file* aot)))

; ENTER-BOOT-STRAP-MODE resets every state global through
; INITIALIZE-STATE-GLOBALS, so KEEP-TMP-FILES has to be set again once the
; boot-strap has begun; the wrapper below does that.

(defun keep-tmp-files-before (args)
  (declare (ignore args))
  (when (equal (getenv$-raw "ACL2_INIT_PROFILE_KEEP_TMP") "1")
    (f-put-global 'keep-tmp-files t *the-live-state*)))

(cl-user::wrap-with-timer 'ld-fn #'ld-fn-label)
(cl-user::wrap-with-timer 'compile-uncompiled-defuns
                          (make-comp-label "raw-defuns")
                          #'keep-tmp-files-before)
(cl-user::wrap-with-timer 'compile-uncompiled-*1*-defuns
                          (make-comp-label "*1*-defuns")
                          #'keep-tmp-files-before)

; ACL2_INIT_PROFILE_EXTRA is a comma-separated list of ACL2 function names to
; time as well, e.g. ACL2_INIT_PROFILE_EXTRA=translate,ev-fncall.  Calls made
; from a compiled file to a function defined earlier in that same file are
; direct C calls in a native build and cannot be intercepted; in the
; bytecodes-only wasm build every call goes through the function cell, so this
; is the way to look inside pass 2 there.

(let ((extra (getenv$-raw "ACL2_INIT_PROFILE_EXTRA")))
  (when (and extra (not (equal extra "")))
    (let ((start 0) (len (length extra)))
      (loop
       (let* ((end (or (position #\, extra :start start) len))
              (name (subseq extra start end))
              (sym (and (not (equal name ""))
                        (find-symbol (string-upcase name) "ACL2"))))
         (when (and sym
                    (fboundp sym)
                    (not (macro-function sym))
                    (not (special-operator-p sym)))
           (cl-user::wrap-with-timer
            sym
            (let ((s sym))
              (lambda (args)
                (declare (ignore args))
                (symbol-name s)))))
         (when (>= end len)
           (return))
         (setq start (1+ end)))))))


; The three below are Common Lisp functions; ACL2 code reaches them through
; the function cell, so these wrappers do see the bootstrap's calls.  (The
; direct C calls that defeat wrapping at run time are only for functions
; defined earlier in the same file.)

; The wasm build has no package-locks module, so there is nothing to unlock
; there.

(when (fboundp 'ext:unlock-package)
  (ext:unlock-package "COMMON-LISP"))
(cl-user::wrap-with-timer 'cl:eval #'eval-label)
(cl-user::wrap-with-timer 'cl:compile #'compile-label)
(cl-user::wrap-with-timer 'cl:compile-file #'compile-file-label)

(let* ((verbose (equal (getenv$-raw "ACL2_INIT_PROFILE_VERBOSE") "1"))
       (real-co (get 'acl2-output-channel::standard-character-output-0
                     *open-output-channel-key*))
       (t0 (get-internal-real-time))
       (result
        (if verbose
            (initialize-acl2 'include-book)
          (progn
            (setf (get 'acl2-output-channel::standard-character-output-0
                       *open-output-channel-key*)
                  (make-broadcast-stream))
            (unwind-protect
                (let ((*standard-output* (make-broadcast-stream))
                      (*error-output* (make-broadcast-stream))
                      (*trace-output* (make-broadcast-stream)))
                  (initialize-acl2 'include-book))
              (setf (get 'acl2-output-channel::standard-character-output-0
                         *open-output-channel-key*)
                    real-co)))))
       (total (/ (float (- (get-internal-real-time) t0))
                 internal-time-units-per-second)))

; Write the report outside any output redirection, and to a file so that it
; is visible even when the caller suppresses ACL2's output.

  (with-open-file (s "ecl-init-profile.txt"
                     :direction :output
                     :if-exists :supersede)
    (format s "ACL2 initialization profile (ECL ~a)~%~
               initialize-acl2 returned ~s~%~
               total ~,3f s~%~
               summed ld-fn time ~,3f s~%~
               summed eval time ~,3f s~%~
               summed compile+compile-file time ~,3f s~2%"
            (lisp-implementation-version)
            result
            total
            (cl-user::profile-total "ld ")
            (cl-user::profile-total "eval ")
            (+ (cl-user::profile-total "compile ")
               (cl-user::profile-total "compile-file ")))
    (let ((rows nil))
      (maphash (lambda (label cell) (push (cons label cell) rows))
               cl-user::*profile-table*)
      (dolist (row (sort rows #'> :key (lambda (r) (cdr (cdr r)))))
        (format s "~8,3f s ~7d  ~a~%"
                (cdr (cdr row)) (car (cdr row)) (car row)))))
  (format t "~&Profile written to ecl-init-profile.txt (total ~,3f s).~%"
          total)
  (ext:quit 0))
