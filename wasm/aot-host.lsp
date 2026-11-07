;;;; aot-host.lsp -- cross-compile ACL2 book expansion files into loadable
;;;; WebAssembly modules, using the host ECL that build-ecl-wasm.sh builds.
;;;;
;;;; This is the successor to wasm/aot-acl2.lsp.  That one had to run inside a
;;;; native `saved_acl2' and do the compile in two steps -- ECL writes C, the
;;;; script renames the entry point to __ecl_init_fas_CODE, then emcc links --
;;;; because a native saved ACL2 is built with whatever ECL the user has, and
;;;; the ECL builds disagree about the name of a compiled file's entry point
;;;; (see cmp/cmpbackend-cxx/cmpc-init-name.lsp).  They also disagree about
;;;; internal calling conventions, which is what made the resulting module die
;;;; in SI:WAITPID when the wasm ECL tried to initialise it.
;;;;
;;;; The host ECL from the same source tree as the wasm ECL has neither
;;;; problem: `(compile-file f :target <wasm target>)' emits
;;;; __ecl_init_fas_CODE itself and links the module with emcc, and the ABI
;;;; matches by construction.  So here the compile is one `compile-file'.
;;;;
;;;; What it still needs from ACL2 is only the reader.  A book's expansion file
;;;; (<book>@expansion.lsp) starts with ACL2 `serialize' data as #Z/#Y read
;;;; macros, which live in *acl2-readtable*, so the compile has to happen in a
;;;; process that has loaded the ACL2 sources -- but NOT initialized ACL2:
;;;; load-acl2 is enough, and it is a few seconds instead of the full boot
;;;; strap.
;;;;
;;;; Usage, from a shell (see wasm/aot-book.sh):
;;;;
;;;;   ACL2_AOT_FILES="books/x/foo@expansion.lsp ..." \
;;;;   /opt/eclwasm/ecl-host/bin/ecl -norc -load wasm/aot-host.lsp
;;;;
;;;; Each <book>@expansion.lsp becomes <book>.fasc -- the name include-book
;;;; later loads -- as a wasm side module for a wasm ECL built with DYLINK=1.
;;;;
;;;; Prerequisites:
;;;;   * /tmp/wasm32.delta, from wasm/mk-wasm32-target.lsp (override with
;;;;     ACL2_AOT_DELTA);
;;;;   * the ACL2 sources compiled by the *wasm* ECL (*.fasc), because that is
;;;;     what gets loaded here; the stale *.fas from other ECL builds are not
;;;;     loadable at all, hence the load hook below.

;;;; ------------------------------------------------------------------
;;;; 1. Bootstrap: make this ECL load the wasm ECL's bytecode
;;;; ------------------------------------------------------------------

;; ACL2's C stack needs are not the default 8 MB.  Both limits matter: the
;; Lisp frame stack for the interpreter, the C stack because the bytecodes
;; dispatch through C.
(ext:set-limit 'ext:frame-stack 262144)
(ignore-errors (ext:set-limit 'ext:c-stack (* 1000 1024 1024)))

(setq *load-verbose* nil)

;; ACL2's sources here were compiled by the wasm ECL, which writes bytecode
;; with the "fasc" type; this ECL asks for its own *compiled-file-extension*,
;; "fas", and the *.fas files in the tree came from a different ECL build
;; (their entry point is init_fas_CODE, which this ECL does not find).  Map
;; such loads onto the portable bytecode instead.  ECL dispatches on the file
;; type through EXT::*LOAD-HOOKS*; see c/main.d.
;;
;; The bytecode is taken from ACL2_AOT_BYTECODE_DIR when that is set, because
;; the .fasc files in the ACL2 directory may since have been replaced by wasm
;; modules (wasm/aot-book.sh), and this is a *native* ECL: it cannot load a
;; module.  wasm/acl2-wasm-compile copies them there.
(defparameter *aot-bytecode-dir*
  (let ((s (ext:getenv "ACL2_AOT_BYTECODE_DIR")))
    (and s (not (equal s "")) s)))

(defun aot-bytecode-copy (file)
  (and *aot-bytecode-dir*
       (merge-pathnames (make-pathname :name (pathname-name file) :type "fasc")
                        (concatenate 'string *aot-bytecode-dir* "/"))))

;; A counter, kept on a keyword's property list rather than in a special
;; variable: this file's forms are read in CL-USER but the report below is
;; printed from the ACL2 package, and a global variable is easy to lose track
;; of across that boundary.
(defun aot-fasc-count (&optional (new nil new-p))
  (if new-p
      (setf (get :acl2-aot-host :fasc-count) new)
      (or (get :acl2-aot-host :fasc-count) 0)))

(defun aot-host-load-fas (file verbose print external-format)
  (let* ((fasc (make-pathname :type "fasc" :defaults file))
         (copy (aot-bytecode-copy fasc)))
    (cond ((and copy (probe-file copy))
           (si::load-bytecodes copy verbose print external-format))
          ((and (fboundp 'si::load-bytecodes) (probe-file fasc))
           (si::load-bytecodes fasc verbose print external-format))
          (t (si::load-binary file verbose print external-format)))))

(defun aot-host-counting-fas (file verbose print external-format)
  (aot-fasc-count (1+ (aot-fasc-count)))
  (aot-host-load-fas file verbose print external-format))

(let ((hook (assoc "fas" ext::*load-hooks* :test #'equal)))
  (if hook
      (setf (cdr hook) 'aot-host-counting-fas)
      (push (cons "fas" 'aot-host-counting-fas) ext::*load-hooks*)))

;; Into the ACL2 build directory, so that the relative pathnames ACL2 uses
;; ("init.lisp", "acl2-fns", ...) resolve.
(ext:chdir (or (ext:getenv "ACL2_AOT_HOME") (ext:getcwd)))
(load "init.lisp")
(in-package "ACL2")
(load-acl2)

(format t "~&;; loaded ACL2 sources (~d compiled file~:p); readtable ~s~%"
        (cl-user::aot-fasc-count) (type-of *acl2-readtable*))

;; The compiled-file extension is a property of the *target*, but ACL2 computes
;; it at load time from this ECL's own *COMPILED-FILE-EXTENSION* -- "fas" here,
;; because the host has a C compiler -- and INITIALIZE-STATE-GLOBALS splices it
;; into the boot strap with `,*compiled-file-extension*', i.e. at
;; macroexpansion time.  A module compiled here would therefore tell the wasm
;; ACL2 to look for ".fas" files (it asked for fact.fas instead of the
;; fact.fasc module it had).  Pin the target's value, which is what the wasm
;; ECL uses.  Any other host-dependent compile-time constant would need the same
;; treatment; see WASM-PORT-NOTES.md.
(setq *compiled-file-extension* "fasc")

(format t ";; compiling for extension ~s (the target's, not this ECL's ~s)~%"
        *compiled-file-extension*
        (pathname-type (compile-file-pathname "foo.lisp")))

;; WHEN-PASS-2 expands to NIL in raw Lisp (axioms.lisp:30527), because those
; events are meant to be evaluated by the boot strap rather than compiled into
; the file -- which is why a census after a completed start finds 248 ACL2
; functions (#<bytecompiled-function>: the APPLY$ family and friends) that no
; AOT of the sources can cover.  With ACL2_AOT_WHEN_PASS_2=1 the raw Lisp
; expansion splices the body instead, so those definitions do land in the
; module; the run-time boot strap still evaluates its own event, and the point
; of the experiment is whether ACL2's redundancy check then leaves the native
; definition alone, the way it already does for the other 7316.
(when (let ((s (ext:getenv "ACL2_AOT_WHEN_PASS_2")))
        (and s (plusp (length s)) (not (equal (string-upcase s) "NIL"))))
  (format t ";; ACL2_AOT_WHEN_PASS_2: compiling WHEN-PASS-2 bodies~%")
  (setf (macro-function 'when-pass-2)
        (lambda (form env)
          (declare (ignore env))
          ;; Only the definitions.  The blocks also contain events that must be
          ;; evaluated by ACL2 rather than compiled: splicing a (MAKE-EVENT ...)
          ;; into raw Lisp makes the module fail at load time with "An error
          ;; occurred during initialization ... offending form (MAKE-EVENT
          ;; `(DEFCONST *FIRST-ORDER-LIKE-TERMS-AND-OUT-ARITIES* ...))".
          (cons 'progn
                (remove-if-not (lambda (x)
                                 (and (consp x)
                                      (member (car x)
                                              '(defun defmacro defconst
                                                defparameter))))
                               (cddr form))))))

;;;; ------------------------------------------------------------------
;;;; 2. The wasm32 target
;;;; ------------------------------------------------------------------

(require :cmp)

;; The target-info *file* (/tmp/wasm32.target) is data for compile-file :target
;; and cannot be LOADed; what is needed here is the Lisp library that rebuilds
;; the same target-info in memory from the delta (this ECL cannot read a
;; target-info written by another one -- see wasm32-target.lsp).
(load (merge-pathnames "wasm32-target.lsp"
                       (or *load-pathname*
                           #p"/workspaces/acl2-ecl/wasm/aot-host.lsp")))

(defparameter *aot-delta*
  (wasm-target:read-delta (or (ext:getenv "ACL2_AOT_DELTA") "/tmp/wasm32.delta")))

(defparameter *aot-target-info* nil)

(defun aot-target-info ()
  (or *aot-target-info*
      (setf *aot-target-info*
            (wasm-target:apply-overrides (c::get-target-info) *aot-delta*))))

;;;; ------------------------------------------------------------------
;;;; 3. Expansion file -> wasm side module
;;;; ------------------------------------------------------------------

(defun aot-expansion-name-p (name)
  (let* ((suffix "@expansion")
         (n (length suffix)))
    (and (> (length name) n)
         (string= suffix name :start2 (- (length name) n)))))

(defun aot-module-name (file)
  "…/<book>@expansion.lsp -> …/<book>.fasc;  …/foo.lisp -> …/foo.fasc
;; Both are needed: a book's expansion file is the thing ACL2 compiles, and a
;; plain file such as ACL2-EXEC-AOT.LISP (the *1* counterparts) is compiled the
;; same way.  Either way the result keeps the name LOAD-COMPILED will ask for."
  (let* ((p (pathname file))
         (name (pathname-name p)))
    (if (aot-expansion-name-p name)
        (make-pathname :name (subseq name 0 (- (length name)
                                               (length "@expansion")))
                       :type "fasc"
                       :defaults p)
        (make-pathname :type "fasc" :defaults p))))

(defun aot-file (expansion-file)
  (let* ((out (aot-module-name expansion-file))
         (tmp (make-pathname :name (concatenate 'string
                                                (pathname-name out) "-aot")
                             :type "fasc" :defaults out))
         (c (make-pathname :name (pathname-name tmp) :type "c" :defaults tmp))
         (h (make-pathname :name (pathname-name tmp) :type "eclh" :defaults tmp))
         (d (make-pathname :name (pathname-name tmp) :type "data" :defaults tmp))
         (start (get-internal-real-time)))
    (format t "~&;; AOT ~a -> ~a~%" expansion-file out)
    (force-output)
    (unwind-protect
         (progn
           ;; Direct C calls are not portable across targets; ACL2's own
           ;; build makes the same proclamation.  One release of ECL does
           ;; not know the declaration, so do not let that be fatal.
           (ignore-errors (proclaim '(ext:use-direct-c-call nil)))
           ;; ACL2_AOT_PROCLAIM: an extra proclaim before the compile, e.g.
           ;; "(optimize (safety 3))" to turn silent type violations (which the
           ;; C compiler can produce where the bytecodes compiler cannot) into
           ;; precise runtime errors.  Used while diagnosing the boot-strap
           ;; failure described in WASM-PORT-NOTES.md.
           (let ((extra (ext:getenv "ACL2_AOT_PROCLAIM")))
             (when (and extra (not (equal extra "")))
               (proclaim (read-from-string extra))))
           (let ((*readtable* (if (aot-expansion-name-p
                                  (pathname-name (pathname expansion-file)))
                                 *acl2-readtable*
                                 *readtable*)))
             (c::compile-with-target-info
              (lambda ()
                ;; The output file *is* the module: with a :target in force,
                ;; compile-file runs the target's linker (emcc) on the C it
                ;; just wrote and puts the result here.  Nothing else to do.
                (compile-file expansion-file
                              :output-file out
                              :c-file c :h-file h :data-file d
                              :load nil))
              (aot-target-info))))
      (ignore-errors (proclaim '(ext:use-direct-c-call t))))
    (format t ";;   ~a (~d bytes, ~,2f s)~%"
            out
            (with-open-file (s out :element-type '(unsigned-byte 8))
              (file-length s))
            (/ (- (get-internal-real-time) start)
               internal-time-units-per-second))
    (dolist (f (list c h d (make-pathname :name (pathname-name tmp)
                                         :type "o" :defaults tmp)))
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
                         for piece = (subseq s start pos)
                         unless (equal piece "") collect piece
                         while pos
                         do (setf start (1+ pos)))))))
    (format t "~&;; AOT: ~d file~:p to compile~%" (length files))
    (aot-files files)))

;; Run as a script: nothing to do if no files were named.
(when (ext:getenv "ACL2_AOT_FILES")
  (aot-main)
  (si:quit))
