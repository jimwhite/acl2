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
                   (incf n))
          (error () nil))))
    n))


; Constants have to be bound before the world is installed: add-trip consults
; them while extending, and *SYSTEM-VERIFY-GUARDS-ALIST-1* (a WHEN-PASS-2
; MAKE-EVENT output in apply-prim.lisp) is one the boot strap would have bound
; by evaluating that event.  The world records every constant as
; (NAME CONST . VALUE), which is where the value came from anyway.
(let ((t0 (get-internal-real-time)))
  (format t "~&;; replay: rebound ~s constants from the image~%"
          (rebind-constants cl-user::*saved-world*))
  (cl-user::replay-step "rebound the constants" t0))



(format t "~&;; replay: entering boot-strap mode ...~%") (force-output)
(handler-bind
    ((error (lambda (c)
              (format t "~&LISP-ERROR ~a~%" c) (force-output)
              (ignore-errors (si::tpl-backtrace))
              (ext:exit 1))))
  (enter-boot-strap-mode nil (get-os)))
(push nil *acl2-unwind-protect-stack*)

; The *1* counterparts that the ahead-of-time file does not cover, oldest event
; first and evaluated as generated, because ONEIFY-CLTL-CODE itself needs some
; of them (LET-MBE-GUARD-FORM, DEFUN-FN, ...).  Same order the boot strap uses.
;
; This runs BEFORE the world is installed, and scans the image's world rather
; than the live one: add-trip consults these as it extends, and the first one it
; wants is ACL2_*1*_ACL2::BADGE-USERFN -- a counterpart of one of the 248
; definitions the boot strap creates by evaluating WHEN-PASS-2 events.  The
; module built with ACL2_AOT_WHEN_PASS_2=1 supplies the functions themselves.
(defun gen-missing-*1* (wrld)
  (let ((n 0))
    (dolist (trip (reverse wrld))
      (when (and (eq (car trip) 'cltl-command)
                 (eq (cadr trip) 'global-value)
                 (consp (cddr trip))
                 (eq (caddr trip) 'defuns))
        (let ((cmd (cddr trip)))
          (dolist (x (cdddr cmd))
            (unless (member-eq (car x)
                               `(mv-list return-last wormhole-eval
                                         ,@*df-primitives* ,@*defun-overrides*))
              (let ((s (*1*-symbol (car x))))
                (unless (fboundp s)
                  (eval (cons 'defun
                              (oneify-cltl-code
                               (cadr cmd) x
                               (getpropc (car x) 'stobj-function nil wrld)
                               wrld)))
                  (incf n))))))))
    n))

(let ((t0 (get-internal-real-time)))
  (format t "~&;; replay: generated ~s missing *1* counterparts~%"
          (gen-missing-*1* cl-user::*saved-world*))
  (cl-user::replay-step "generated the missing *1* counterparts" t0))

; ACL2's own reader is needed here: add-trip reads forms (the cltl-command
; blocks and the oneified code), and under the standard readtable a dispatch
; character like #' is read differently, which shows up far away as
; "In function CHAR-CODE, the value of the only argument is QUOTE".
(format t "~&;; replay: installing the world ...~%") (force-output)
(let ((t0 (get-internal-real-time))
      (*world-image-replay* t)
      (*readtable* *acl2-readtable*))
  (set-w 'extension cl-user::*saved-world* *the-live-state*)
  (setq cl-user::*saved-world* nil)
  (cl-user::replay-step "installed the world's properties" t0))


; Normally done when the boot strap processes its memoize events.
(memoize-init)



(exit-boot-strap-mode)
(set-initial-cbd)
(initialize-pc-acl2 *the-live-state*)
(f-put-ld-specials *initial-ld-special-bindings* nil *the-live-state*)
(setq *saved-build-date-lst* (list (eval '(saved-build-date-string))))

; ACL2's own post-initialization checks: the soundness gate.
(let ((t0 (get-internal-real-time)))
  (format t "~&;; replay: CHECK-ACL2-INITIALIZATION ~s~%"
          (check-acl2-initialization))
  (cl-user::replay-step "ran ACL2's initialization checks" t0))

(format t "~&;; replay: at the loop in ~,2f s~%" (cl-user::replay-elapsed))

(ext:chdir (or (ext:getenv "ACL2_WASM_INVOCATION_DIR") cl-user::*acl2-dir*))
(acl2-default-restart)
