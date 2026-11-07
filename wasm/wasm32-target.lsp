;;;; wasm32-target.lsp -- the wasm32 cross-compilation target, shared by the two
;;;; drivers that need it.
;;;;
;;;;   wasm/mk-wasm32-target.lsp   runs in the host ECL (build-ecl-wasm.sh's
;;;;                               $WORK/ecl-host) and writes a target-info
;;;;                               *file* for `compile-file :target'.
;;;;   wasm/aot-acl2.lsp           runs inside a native ACL2 (whose ECL also has
;;;;                               the C compiler) and builds the same
;;;;                               target-info *in memory', because that ECL
;;;;                               cannot read a target-info file written by a
;;;;                               different ECL build (the printer qualifies
;;;;                               symbols like SI:RADIX that the other build
;;;;                               does not export).
;;;;   wasm/aot-host.lsp           the same job as aot-acl2.lsp, but in the
;;;;                               *host* ECL from the same source tree as the
;;;;                               wasm one.  Rebuilds the target-info in memory
;;;;                               from the delta for the same reason, and is
;;;;                               preferred: same ABI, and no entry-point
;;;;                               renaming.  See wasm/aot-book.sh.
;;;;
;;;; ECL's `compile-file' takes `:target <target-info>', an alist mapping
;;;; compiler configuration symbols to values; `compile-with-target-info' in
;;;; src/cmp/cmpmain.lsp progv-binds every pair around the compilation and sets
;;;; `*cross-compiling*'.  `c::get-target-info' produces the running ECL's own
;;;; alist, which is what these functions start from.

(defpackage #:wasm-target
  (:use #:cl)
  (:export #:main #:*wasm-c-types* #:*drop-features* #:*side-module-flags*
           #:*side-module-cc-flags* #:set-target #:apply-overrides
           #:wasm-machine #:machine-form #:delta #:read-delta #:write-delta))

(in-package #:wasm-target)

;;; From $WORK/wasm32.cross_config (the Emscripten wasm32 ABI):
;;;   CL_FIXNUM_TYPE=int, 32 bits, max 536870911 = 2^29-1
;;; so the fixnum has 30 bits, logcount(most-positive-fixnum) = 29, and the
;;; "bits" entry for :fixnum is -(1+29).  `long' is 32 bits (ILP32).
;;; csfloat/cdfloat/clfloat exist (:complex-float is in the wasm features) but
;;; carry no bit count, exactly as in the host's table.
(defparameter *wasm-c-types*
  '((:byte               .  -8)
    (:unsigned-byte      .   8)
    (:unsigned-short     . -16)
    (:short              . -16)
    (:unsigned-int       .  32)
    (:int                . -32)
    (:unsigned-long      .  32)         ; ILP32
    (:long               . -32)
    (:unsigned-long-long .  64)
    (:long-long          . -64)
    (:cl-index           .  29)         ; logcount most-positive-fixnum
    (:fixnum             . -30)
    (:uint8-t            .   8)
    (:int8-t             .  -8)
    (:uint16-t           .  16)
    (:int16-t            . -16)
    (:uint32-t           .  32)
    (:int32-t            . -32)
    (:uint64-t           .  64)
    (:int64-t            . -64)
    (:csfloat)
    (:cdfloat)
    (:clfloat)))

;;; Features to drop from the wasm build's list.  :cross is an artifact of the
;;; build (compile.lsp ran with it set); :ecl-bytecmp means "no C compiler at
;;; run time", which the thing we generate code for does have.
(defparameter *drop-features* '(:cross :ecl-bytecmp))

;;; Flags for `emcc' when the output is a module to be dlopen'ed into the
;;; running ECL rather than a program of its own:
;;;   -sSIDE_MODULE=2   produce a side module, importing from the main one and
;;;                     exporting only what is asked for
;;;   -Wl,--export=__ecl_init_fas_CODE
;;;                     the one symbol that has to be visible: `si_load_binary'
;;;                     dlsym's `_ecl_library_default_entry()', which for a
;;;                     :fasl module is INIT_PREFIX "CODE" with INIT_PREFIX
;;;                     "__ecl_init_fas_" (c/ffi/libraries.d, and
;;;                     compute-init-name in cmp/cmpbackend-cxx/cmpc-init-name.lsp
;;;                     for kind :fasl).  The name is fixed, since
;;;                     init-function-name is only randomised for :object.
;;;                     (`-sEXPORTED_FUNCTIONS=___ecl_init_fas_CODE' works too,
;;;                     but needs one extra leading underscore: those names are
;;;                     the JS ones.)
;;;   -fwasm-exceptions ... -sSUPPORT_LONGJMP=wasm
;;;                     must match the main module (ECL's condition system is
;;;                     setjmp/longjmp; mismatched EH aborts at load time).
;;;   -sERROR_ON_UNDEFINED_SYMBOLS=0
;;;                     everything (cl_env_p, ecl_aref_unsafe, ...) is an
;;;                     import from the main module, by design
(defparameter *side-module-flags*
  (concatenate 'string
               "-shared -sSIDE_MODULE=2 -Wl,--export=__ecl_init_fas_CODE"
               " -fwasm-exceptions -mllvm -wasm-use-legacy-eh=false"
               " -sSUPPORT_LONGJMP=wasm -sALLOW_MEMORY_GROWTH=1"
               " -sERROR_ON_UNDEFINED_SYMBOLS=0"
               ;; bdwgc is conservative: a Lisp object that lives only in a
               ;; register (a wasm local) is invisible to it, and gets
               ;; collected under the program's feet.  ECL's wasm build has to
               ;; use the same binaryen pass as the main module
               ;; (src/configure: "-sBINARYEN_EXTRA_PASSES=--spill-pointers
               ;; --strip-debug"), which spills pointers to the shadow stack.
               ;; Without it a compiled module silently loses live data: a
               ;; one-line (length (loop repeat 100000 collect 1)) in a module
               ;; returns 65 instead of 100000, and with GC_DONT_GC it is
               ;; right.  See WASM-PORT-NOTES.md, "Native wasm code for ACL2's
               ;; own sources".
               " -sBINARYEN_EXTRA_PASSES=--spill-pointers"
               ;; ACL2_AOT_WFLAGS appends extra *link* flags.  The one that
               ;; matters for diagnosis is --profiling-funcs: without it a side
               ;; module carries no name section, so V8 prints
               ;; "wasm-function[303]" instead of the Lisp function's name in a
               ;; stack trace.  (-g3 in ACL2_AOT_CC_FLAGS is not enough: that
               ;; is DWARF, which the trace does not use.)
               (let ((extra (ext:getenv "ACL2_AOT_WFLAGS")))
                 (if (and extra (plusp (length extra)))
                     (concatenate 'string " " extra)
                     ""))))

;;; A side module's object code has to be position independent: without -fPIC
;;; wasm-ld rejects the module with
;;;   relocation R_WASM_MEMORY_ADDR_LEB cannot be used against symbol `VV';
;;;   recompile with -fPIC
;;; (`VV' is the vector of constants every compiled Lisp file has.)
(defparameter *side-module-cc-flags* " -fPIC")

(defun set-target (alist symbol value)
  (let ((pair (assoc symbol alist)))
    (unless pair
      (error "Target info has no entry for ~s" symbol))
    (setf (cdr pair) value)))

;;; Like SET-TARGET but tolerates a host whose `c::*config-options*' does not
;;; mention the option at all (different ECL builds record different sets), and
;;; returns the alist, which may have grown at the front.
(defun force-target (alist symbol value)
  (let ((pair (assoc symbol alist)))
    (if pair
        (progn (setf (cdr pair) value) alist)
        (acons symbol value alist))))

;;; A `c::machine' describing wasm32, built exactly as `c::default-machine'
;;; does for the running ECL but from WASM-C-TYPES.  The host's own machine
;;; describes the host: 62-bit fixnums and 64-bit longs, which would generate
;;; the wrong code.  Types the target does not have (sse packs) drop out by
;;; themselves, because `c::make-host-type' ignores unknown names.
;;;
;;; The slots are filled in at construction (%MAKE-HOST-TYPE) rather than with
;;; (setf host-type-index), because a compiled file cannot see ECL's setf
;;; expander for these accesses: `(setf (c::host-type-index x) i)' works when
;;; evaluated, but compiling it yields a call to the nonexistent function
;;; (SETF C::HOST-TYPE-INDEX).
(defun %host-type-copy (ht index from-lisp-unsafe)
  (c::%make-host-type
   :index index
   :name (c::host-type-name ht)
   :lisp-type (c::host-type-lisp-type ht)
   :bits (c::host-type-bits ht)
   :numberp (c::host-type-numberp ht)
   :integerp (c::host-type-integerp ht)
   :c-name (c::host-type-c-name ht)
   :to-lisp (c::host-type-to-lisp ht)
   :from-lisp (c::host-type-from-lisp ht)
   :from-lisp-unsafe from-lisp-unsafe))

(defun wasm-machine ()
  (let* ((all-c-types (append *wasm-c-types* c::+all-machines-c-types+))
         ;; (name index prototype) in precedence order, which is the order of
         ;; c::+host-types+ restricted to the types wasm32 has.
         (defs (loop for i from 0
                     for record in c::+host-types+
                     for ht = (apply #'c::make-host-type all-c-types record)
                     when ht
                       collect (list (c::host-type-name ht)
                                     (if (eq (c::host-type-name ht) :int-sse-pack)
                                         'ext:int-sse-pack
                                         i)
                                     ht)))
         (fixnum-lisp-type
          (c::host-type-lisp-type
           (apply #'c::make-host-type all-c-types
                  (assoc :fixnum c::+host-types+))))
         (table (make-hash-table :size 128 :test 'eq)))
    (dolist (def defs)
      (destructuring-bind (name index ht) def
        (setf (gethash name table)
              (%host-type-copy
               ht index
               (if (subtypep (c::host-type-lisp-type ht) fixnum-lisp-type)
                   "ecl_fixnum"           ; same second pass as c::default-machine
                   (c::host-type-from-lisp-unsafe ht))))))
    (c::make-machine :c-types all-c-types
                     :host-type-hash table
                     :sorted-types (mapcar (lambda (def) (gethash (car def) table))
                                           defs))))

;;; Text of the `#.' form that reconstructs `c::*machine*' when a target-info
;;; *file* is read.  Written out as text rather than printed from a live
;;; object: the machine holds a hash table keyed by (and sharing structure
;;; with) the sorted type vector, which does not survive `#S' printing with
;;; *print-circle* in slot order (the hash table would be a forward reference).
(defun machine-form ()
  (with-output-to-string (s)
    (format s "#.(let* ((types '~s)~%" *wasm-c-types*)
    (format s "         (all (append types c::+all-machines-c-types+))~%")
    (format s "         (table (make-hash-table :size 128 :test 'eq))~%")
    (format s "         (sorted~%")
    (format s "          (loop for i from 0~%")
    (format s "                for record in c::+host-types+~%")
    (format s "                for ht = (apply #'c::make-host-type all record)~%")
    (format s "                when ht~%")
    (format s "                  do (setf (c::host-type-index ht) i)~%")
    (format s "                  and collect (setf (gethash (c::host-type-name ht)~%")
    (format s "                                     table)~%")
    (format s "                              ht))))~%")
    (format s "    (let ((r (gethash :int-sse-pack table)))~%")
    (format s "      (when r (setf (c::host-type-index r) 'ext:int-sse-pack)))~%")
    (format s "    (loop with fh = (gethash :fixnum table)~%")
    (format s "          with fl = (c::host-type-lisp-type fh)~%")
    (format s "          for rec in c::+host-types+~%")
    (format s "          for r = (gethash (car rec) table)~%")
    (format s "          when (and r (subtypep (c::host-type-lisp-type r) fl))~%")
    (format s "            do (setf (c::host-type-from-lisp-unsafe r) \"ecl_fixnum\"))~%")
    (format s "    (c::make-machine :c-types all~%")
    (format s "                     :host-type-hash table~%")
    (format s "                     :sorted-types sorted))")))

;;; The wasm-specific values, as a plist of strings and keywords so that any
;;; ECL can read it (see the header for why a whole target-info file cannot be
;;; shared between differently-configured ECL builds).
(defun dir-name (path)
  "PATH as a directory namestring, with a trailing separator whether or not the
caller supplied one (DIRECTORY-NAMESTRING alone turns \"/opt/emsdk\" into
\"/opt/\", treating the last component as a file name)."
  (let ((s (namestring path)))
    (if (and (> (length s) 0) (char= (char s (1- (length s))) #\/))
        s
        (concatenate 'string s "/"))))

(defun delta (features include-dir emsdk &key (side-module t))
  (let* ((prefix (dir-name include-dir))
         (emsdk (dir-name emsdk)))
    (list :cc (concatenate 'string emsdk "upstream/emscripten/emcc")
          :ld (concatenate 'string emsdk "upstream/emscripten/emcc")
          :ar (concatenate 'string emsdk "upstream/emscripten/emar")
          :ranlib (concatenate 'string emsdk "upstream/emscripten/emranlib")
          :nm (concatenate 'string emsdk "upstream/bin/llvm-nm")
          ;; The flags the wasm ECL itself was compiled with: a side module
          ;; has to agree with the main module on exception handling.
          ;;
          ;; ACL2_AOT_CC_FLAGS appends to these, which is how a diagnostic build
          ;; gets names into a module: V8 prints "wasm-function[477]" for a
          ;; module compiled without a name section and the Lisp function name
          ;; for one compiled with -g3, which is the difference between
          ;; guessing and knowing when a module blows the stack.
          :cc-flags (concatenate
                     'string
                     "-fwasm-exceptions -mllvm -wasm-use-legacy-eh=false"
                     " -DECL_C_COMPATIBLE_VARIADIC_DISPATCH -Demscripten"
                     (if side-module *side-module-cc-flags* "")
                     (let ((extra (ext:getenv "ACL2_AOT_CC_FLAGS")))
                       (if (and extra (plusp (length extra)))
                           (concatenate 'string " " extra)
                           "")))
          :cc-optimize (let ((opt (ext:getenv "ACL2_AOT_OPT")))
                         (if (and opt (plusp (length opt))) opt "-O2"))
          :cmpinclude "<ecl/ecl-cmp.h>"
          ;; `ecl-include-directory' wants a directory that contains
          ;; ecl/config.h, and the wasm build installs its headers flat, i.e.
          ;; $PREFIX/ecl/config.h -- not $PREFIX/include/ecl/config.h.  Using
          ;; the *host's* headers here would silently give the target the
          ;; host's typedefs for cl_fixnum and friends.
          :include prefix
          :library prefix
          :data prefix
          :ld-shared-flags (if side-module *side-module-flags* "")
          :ld-libs (if side-module "" "-lecl -leclgc -leclgmp -lm")
          :ld-flags ""
          :ld-program-flags ""
          :shared-extension (if side-module "wasm" "so")
          :shared-format (if side-module "lib~a.wasm" "lib~a.so")
          :architecture "WASM32"
          :software-type "emscripten"
          :features (set-difference features *drop-features*))))

(defun apply-overrides (alist delta &optional (emsdk nil))
  "Apply DELTA to ALIST (a target-info) in place.  EMSDK is only used for the
older callers that passed it separately."
  (declare (ignore emsdk))
  (flet ((d (key) (getf delta key))
         (put (symbol value) (setf alist (force-target alist symbol value))))
    (put 'c::*cc* (d :cc))
    (put 'c::*ld* (d :ld))
    (put 'c::*ar* (d :ar))
    (put 'c::*ranlib* (d :ranlib))
    (put 'c::*nm* (d :nm))
    (put 'c::*cc-flags* (d :cc-flags))
    (put 'c::*cc-optimize* (d :cc-optimize))
    (put 'c::*cmpinclude* (d :cmpinclude))
    (put 'c::*ecl-include-directory* (d :include))
    (put 'c::*ecl-library-directory* (d :library))
    (put 'c::*ecl-data-directory* (d :data))
    (put 'c::*ld-rpath* "")
    (put 'c::*ld-shared-flags* (d :ld-shared-flags))
    (put 'c::*ld-bundle-flags* (d :ld-shared-flags))
    (put 'c::*ld-libs* (d :ld-libs))
    (put 'c::*ld-flags* (d :ld-flags))
    (put 'c::*ld-program-flags* (d :ld-program-flags))
    (put 'c::+shared-library-prefix+ "lib")
    (put 'c::+shared-library-extension+ (d :shared-extension))
    (put 'c::+shared-library-format+ (d :shared-format))
    (put 'c::+static-library-prefix+ "lib")
    (put 'c::+static-library-extension+ "a")
    (put 'c::+static-library-format+ "lib~a.a")
    (put 'c::+object-file-extension+ "o")
    (put 'c::+executable-file-format+ "~a.html")
    (put 'c::*target-architecture* (d :architecture))
    (put 'c::*target-software-type* (d :software-type))
    (put 'c::*target-identifier* "wasm32-unknown-emscripten")
    (put 'c::*target-lisp-implementation-version*
         (lisp-implementation-version))
    (put 'c::*machine* (wasm-machine))
    (put 'cl:*features* (d :features))
    alist))

(defun write-delta (delta file)
  (with-open-file (s file :direction :output :if-exists :supersede)
    (with-standard-io-syntax
      (format s "~S~%" delta))))

(defun read-delta (file)
  (with-open-file (s file)
    (with-standard-io-syntax
      (read s))))
