; Install an ACL2 world image instead of running the boot strap.
;
;   ACL2_WASM_DIR=/path/to/acl2 ACL2_WORLD_IMAGE=/tmp/world-wasm.ser \
;     node .../ecl.js --load wasm/world-replay.lsp -- < commands
;
; The image is what ACL2_WRITE_WORLD_IMAGE on wasm/acl2-wasm.lsp writes: the
; post-boot-strap world, serialized.  Installing it is the two-pass
; `initialize-acl2` skipped, and it is what makes ACL2 reachable at all in a
; browser, where the boot strap's transation of a large constant needs more
; native stack than a page has (WASM-PORT-NOTES.md, "The last wall, named").
;
; Two things the boot strap does that a replay must still do itself:
;
;  * The definitions that exist only because the boot strap *evaluated*
;    WHEN-PASS-2 events (248 of them: APPLY$, the badge functions, ...).  Those
;    blocks expand to NIL in raw Lisp, so they are in no compiled file -- unless
;    the modules were built with ACL2_AOT_WHEN_PASS_2=1, which is what a replay
;    needs and what a live start would simply overwrite.  wasm/aot-books.sh
;    builds them that way for the eight affected files.
;  * MEMOIZE-INIT and the *1* counterparts that the ahead-of-time file does not
;    cover; see the prototype notes in wasm/acl2-wasm.lsp's history.

(in-package "CL-USER")

(setq *load-verbose* nil)

(defparameter cl-user::*acl2-dir*
  (or (ext:getenv "ACL2_WASM_DIR")
      (error "ACL2_WASM_DIR is not set; it should name the ACL2 source directory.")))

(defparameter cl-user::*image-path*
  (or (ext:getenv "ACL2_WORLD_IMAGE")
      (error "ACL2_WORLD_IMAGE is not set; it should name a world image.")))

(defparameter cl-user::*start* (get-internal-real-time))

(defun cl-user::replay-elapsed ()
  (/ (- (get-internal-real-time) cl-user::*start*)
     internal-time-units-per-second))

(defun cl-user::replay-step (what &optional (t0 nil))
  (format t "~&;; replay: ~a~@[ (~,2f s)~]~%" what
          (if t0 (/ (- (get-internal-real-time) t0) internal-time-units-per-second)
              nil))
  (force-output))

(ext:chdir cl-user::*acl2-dir*)

; As in wasm/acl2-wasm.lsp: the compiler is the bytecodes one and it must stay
; installed, and the frame-stack limit has to be raised before DEFCONST of a
; large quoted constant.
(ext:set-limit 'ext:frame-stack 262144)

(dolist (name '("LOCK-PACKAGE" "UNLOCK-PACKAGE"))
  (let ((sym (find-symbol name "EXT")))
    (when (and sym (not (fboundp sym)))
      (setf (symbol-function sym)
            (lambda (&rest args) (declare (ignore args)) nil)))))

; A module keeps the ".fasc" name (ACL2 asks for "<file>.fasc") but is a wasm
; side module, so sniff the magic and send it to the dlopen path.
(defun cl-user::module-p (file)
  (handler-case
      (with-open-file (s file :element-type '(unsigned-byte 8))
        (and (= (or (read-byte s nil -1) -1) 0)
             (= (or (read-byte s nil -1) -1) 97)
             (= (or (read-byte s nil -1) -1) 115)
             (= (or (read-byte s nil -1) -1) 109)))
    (error () nil)))

(defun cl-user::load-fasc (file verbose print external-format)
  (if (cl-user::module-p file)
      (si::load-binary file verbose print external-format)
      (si::load-bytecodes file verbose print external-format)))

(when (fboundp 'si::load-binary)
  (let ((hook (assoc "fasc" ext::*load-hooks* :test #'equal)))
    (if hook
        (setf (cdr hook) #'cl-user::load-fasc)
        (push (cons "fasc" #'cl-user::load-fasc) ext::*load-hooks*))))

(load "init.lisp")
(in-package "ACL2")

(let ((t0 (get-internal-real-time)))
  (load-acl2)
  (cl-user::replay-step "loaded ACL2's compiled sources" t0))

(let ((t0 (get-internal-real-time)))
  (load "acl2-exec-aot.fasc")
  (cl-user::replay-step "loaded the ahead-of-time *1* file" t0))

(ext:install-bytecodes-compiler)

; The image itself.
(let ((t0 (get-internal-real-time)))
  (defparameter cl-user::*saved-world*
    (with-open-file (s cl-user::*image-path* :direction :input)
      (ser-decode-from-stream nil :never s)))
  (cl-user::replay-step (format nil "deserialized ~a (~:d triples)"
                         cl-user::*image-path*
                         (length cl-user::*saved-world*))
                 t0))

; Diagnostic: what does the image say about a constant the raw side needs?
(when (let ((s (ext:getenv "ACL2_REPLAY_DEBUG"))) (and s (plusp (length s))))
  (dolist (name '(*system-verify-guards-alist-1* *system-verify-guards-alist-2*))
    (let ((trips (remove-if-not (lambda (x)
                                  (and (consp x) (eq (car x) name)))
                                cl-user::*saved-world*)))
      (format t "~&;; debug: ~a has ~s triples: ~s~%"
              name (length trips)
              (mapcar (lambda (x) (list (car x) (cadr x)
                                        (if (consp (cddr x))
                                            (length (cddr x))
                                            (type-of (cddr x)))))
                      (subseq trips 0 (min 3 (length trips)))))))
  (force-output))

(defun unquote-value (x)
  (if (and (consp x) (eq (car x) 'quote) (consp (cdr x)) (null (cddr x)))
      (cadr x)
    x))

(defun rebind-constants (wrld)
  (let ((n 0)
        (names nil)
        (cl (find-package "COMMON-LISP")))
    (dolist (trip wrld)
      (when (and (consp trip)
                 (eq (cadr trip) 'const)
                 (symbolp (car trip))
                 (not (keywordp (car trip)))
                 (not (eq (car trip) t))
                 (not (eq (car trip) nil))
                 (not (and cl (eq (symbol-package (car trip)) cl)))
                 ;; Only the ones the loaded sources did *not* bind: those are
                 ;; the boot-strap-created constants (WHEN-PASS-2 MAKE-EVENT
                 ;; output such as *SYSTEM-VERIFY-GUARDS-ALIST-1*).  Leaving
                 ;; the rest alone also avoids importing the image's
                 ;; representation of constants that the build already has.
                 (not (boundp (car trip))))
        (handler-case
            (progn (setf (symbol-value (car trip))
                         (unquote-value (cddr trip)))
                   (incf n)
                   (push (car trip) names))
          (error () nil))))
    (values n (nreverse names))))


; Some of those constants are fast alists in a live ACL2 -- *BADGE-PRIM-FALIST*
; maps each primitive to its badge -- and the image holds them as ordinary
; lists, because a hash table is not part of the serialized value.  HONS-GET on
; such an alist falls back to a linear scan and complains "Fast alist
; discipline violated" at every badge lookup, hundreds of times during a single
; INCLUDE-BOOK.  FAST-ALIST-FORK copies an alist into a fresh fast alist.
(defun refasten-constants (names)
  (let ((n 0))
    (dolist (name names)
      (let ((v (and (boundp name) (symbol-value name))))
        (when (and (consp v)
                   (consp (car v))
                   (> (length v) 100))
          (handler-case
              (progn (setf (symbol-value name)
                           (fast-alist-fork v nil))
                     (incf n))
            (error () nil)))))
    n))

; Constants have to be bound before the world is installed: add-trip consults
; them while extending, and *SYSTEM-VERIFY-GUARDS-ALIST-1* (a WHEN-PASS-2
; MAKE-EVENT output in apply-prim.lisp) is one the boot strap would have bound
; by evaluating that event.  The world records every constant as
; (NAME CONST . VALUE), which is where the value came from anyway.
(let ((t0 (get-internal-real-time)))
  (multiple-value-bind (n names) (rebind-constants cl-user::*saved-world*)
    (format t "~&;; replay: rebound ~s constants from the image~@[: ~s~]~%"
            n names)
    (format t "~&;; replay: re-fastened ~s of them as fast alists~%"
            (refasten-constants names)))
  (cl-user::replay-step "rebound and re-fastened the constants" t0))



(format t "~&;; replay: entering boot-strap mode ...~%") (force-output)
(handler-bind
    ((error (lambda (c)
              (format t "~&LISP-ERROR ~a~%" c) (force-output)
              (ignore-errors (si::tpl-backtrace))
              (ext:exit 1))))
  (enter-boot-strap-mode nil (get-os)))
(push nil *acl2-unwind-protect-stack*)

; The attachment side of the *1* symbols.
;
; This is what the previous attempt got wrong.  It is not the *functions* that
; are missing -- ACL2-EXEC-AOT supplies the *1* definitions, including the ones
; for the 248 boot-strap-created functions -- but the *variables*.
;
; A function defined with a THROW-OR-ATTACH body (every non-executable function:
; APPLY$-USERFN, BADGE-USERFN, ...) compiles to code that reads its *1* symbol
; as a variable, because ATTACHMENT-SYMBOL *is* *1*-SYMBOL (axioms.lisp:10614)
; and THROW-OR-ATTACH opens with (let ((g ,at-fn)) ...) where at-fn is the
; attachment symbol (axioms.lisp:5334).  The boot strap makes those cells exist
; by evaluating THROW-OR-ATTACH-CALL, whose (eval `(defvar ,at-fn nil)) runs at
; *compile* time when a file is compiled -- and therefore not at all when a
; compiled file is merely loaded.  Its own comment says as much ("When loading a
; compiled file on behalf of including a book, this eval call would no longer be
; around; it would instead have been executed during compilation").  A replay
; loads compiled files and installs a world, so nothing ever ran that eval, and
; the first non-executable function installed reports its attachment symbol as
; unbound: "The variable ACL2_*1*_ACL2::BADGE-USERFN is unbound."
;
; NIL is the correct value.  A fresh session has no attachments: the long
; comment in THROW-OR-ATTACH-CALL records that (boundp (attachment-symbol 'foo))
; is NIL after (load "foo") and only becomes true after (include-book "foo"),
; and the boot strap's own eval defines the cell to NIL.
(defun bind-attachment-symbols (wrld)
  (let ((n 0))
    (dolist (trip wrld)
      (when (and (consp trip)
                 (eq (car trip) 'cltl-command)
                 (eq (cadr trip) 'global-value)
                 (consp (cddr trip))
                 (eq (caddr trip) 'defuns))
        (dolist (x (cdddr (cddr trip)))
          (let ((s (*1*-symbol (car x))))
            (when (and (symbolp s)
                       (not (keywordp s))
                       (not (boundp s)))
              (handler-case
                  (progn (setf (symbol-value s) nil)
                         (proclaim (list 'special s))
                         (incf n))
                (error () nil)))))))
    n))

(let ((t0 (get-internal-real-time)))
  (format t "~&;; replay: bound ~s *1* attachment variables~%"
          (bind-attachment-symbols cl-user::*saved-world*))
  (cl-user::replay-step "bound the *1* attachment variables" t0))
; MEMOIZE-INIT has to run before the install, not after it: adding a trip for a
; memoized function calls MEMOIZE-FN, which refuses to work until this has run
; ("Memoize-fn:  *MEMOIZE-INIT-DONE* is still nil").  The boot strap runs it
; when it processes its memorum events.
(memoize-init)

; ACL2's own reader is needed here: add-trip reads forms (the cltl-command
; blocks and the oneified code), and under the standard readtable a dispatch
; character like #' is read differently, which shows up far away as
; "In function CHAR-CODE, the value of the only argument is QUOTE".
(format t "~&;; replay: installing the world ...") (force-output)
(let ((t0 (get-internal-real-time))
      (*world-image-replay* t)
      (*readtable* *acl2-readtable*))
  (set-w 'extension cl-user::*saved-world* *the-live-state*)
  (setq cl-user::*saved-world* nil)
  (cl-user::replay-step "installed the world's properties" t0))

; EXTEND-WORLD1 calls UPDATE-WRLD-STRUCTURES only when the world being
; installed is named 'CURRENT-ACL2-WORLD (interface-raw.lisp:7881); SET-W with
; any other name skips it.  It is not housekeeping: it installs the
; GLOBAL-ENABLED-STRUCTURE, which is a fast alist, and the state in the image
; was serialized with that alist's hash table in a particular state, so
; without this the very first DEFUN reports
;
;   Fast alist discipline violated in HONS-GET
;
; and the termination proof then runs with no rules at all ("Rules: NIL").
; It also updates the memoized entries for attachments.
(dolist (s '(*defattach-fns* *user-stobj-alist* *saved-user-stobj-alist*
             *non-executable-user-stobj-lst*
             *saved-non-executable-user-stobj-lst*))
  (unless (boundp s) (set s nil)))

(let ((t0 (get-internal-real-time))
      (*readtable* *acl2-readtable*))
  (update-wrld-structures (w *the-live-state*) *the-live-state*)
  (cl-user::replay-step "updated the world's derived structures" t0))

; APPLY$-PRIM's dispatch table.
;
; (apply$-prim fn args) looks its work up in a hash table,
;
;   (let ((trip (gethash fn *apply$-prim-ht*))) ...)
;
; and that table is filled by
;
;   (make-apply$-prim-body-fn-raw *badge-prim-falist* *apply$-prim-ht*)
;
; which sits inside (when-pass-2 ...) in apply-prim.lisp:1207-1211.  WHEN-PASS-2
; expands to NIL in raw Lisp, so a compiled module never runs it and a replay
; never sees it run: the table stays empty, APPLY$-PRIM returns NIL for every
; primitive, and (apply$ 'car '((1 2))) is NIL instead of 1 -- while (badge
; 'car) is right, which is what makes this hard to see.  This is the only
; (set-raw-mode t) side effect in the whole source tree, so it is the only one
; a replay has to perform by hand.
(let ((t0 (get-internal-real-time)))
  (make-apply$-prim-body-fn-raw *badge-prim-falist* *apply$-prim-ht*)
  (cl-user::replay-step "rebuilt the apply$-prim dispatch table" t0))


(exit-boot-strap-mode)
(set-initial-cbd)
(initialize-pc-acl2 *the-live-state*)
(f-put-ld-specials *initial-ld-special-bindings* nil *the-live-state*)
(setq *saved-build-date-lst* (list (eval '(saved-build-date-string))))

; ACL2's own post-initialization checks: the soundness gate.  They report a
; problem by erroring out (EXIT-WITH-BUILD-ERROR, or a hard error from one of
; the checks), so returning normally -- with the NIL that is the body's last
; form -- means every check passed.
(let ((t0 (get-internal-real-time)))
  (check-acl2-initialization)
  (cl-user::replay-step "passed ACL2's initialization checks" t0))

(format t "~&;; replay: at the loop in ~,2f s~%" (cl-user::replay-elapsed))

(ext:chdir (or (ext:getenv "ACL2_WASM_INVOCATION_DIR") cl-user::*acl2-dir*))
(acl2-default-restart)
