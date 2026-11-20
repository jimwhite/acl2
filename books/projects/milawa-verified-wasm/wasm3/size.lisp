; L1, step 0: the size lemmas the context rules need.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The certified semantics' step relation steps INSIDE an instruction sequence with
; four context rules -- Step/ctxt-instrs, Step/ctxt-label, Step/ctxt-frame,
; Step/ctxt-handler -- and each of them guards its recursive call with a
; termination check of the form
;
;   (OR (< (%SIZE INNER-INSTRUCTIONS) (%SIZE OUTER-INSTRUCTIONS))
;       (AND (EQUAL ...) (< (%SIZE (LIST INNER-CONFIG)) (%SIZE (LIST OUTER-CONFIG)))))
;
; With a concrete configuration these checks evaluate.  With a symbolic
; instruction list they are goals, and nothing in the semantics' books discharges
; them -- which is why this book exists.
;
; BUT: measured after this book was started, and it changes the priority.  The
; module's WASM code is a constant of the artifact (the store's :CODE field, which
; neither $WITH_MEM nor $WITH_GLOBAL touches), so every instruction list that
; appears in a configuration is CONCRETE.  Only the store's memory bytes and its
; five globals are symbolic.  And the split point the context rules search for --
;
;   (step/prefix7 '((:GLOBAL.GET 3) (:CONST (:I32) 1) ...)) = 0
;   (step/prefix7 '((:CONST (:I32) 7) (:RETURN)))            = 1
;   (step/prefix7 '((:CONST (:I32) 7) (:CONST (:I32) 9) ...)) = 2
;
; -- is therefore decidable too, and with it the %SIZE guard, which mentions only
; the instruction list.  So these lemmas are NOT on the critical path for L1 as
; this project states it: they are what an arbitrary-program version would need.
; They stay because they are cheap, they are true, and %SIZE being acl2-count
; hidden behind MBE and disabled is the kind of fact that costs an afternoon to
; rediscover.
;
; WHAT %SIZE IS.  (DEFUN %SIZE (X) (MBE :LOGIC (ACL2-COUNT X) :EXEC (%SIZE-ACC X 0)))
; -- logically acl2-count, executed by a loop so that a machine with a
; hundred-page memory does not exhaust the Lisp stack.  It is DISABLED in the
; prelude's theory, which is why the bridge below is needed at all: with %SIZE
; opaque, no amount of rewriting can compare two of its applications.
;
; A trap worth its own note: ACL2's TAKE pads.  (TAKE 3 '(A B)) is (A B NIL) and
; (TAKE 1 NIL) is (NIL), because TAKE has no ENDP test, so "a prefix is no bigger
; than the list" is FALSE without a length hypothesis.  The same shape of trap as
; TAKE-LEN-OF-APPEND in memory.lisp.

(in-package "MILAWA-WASM")

(include-book "/workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0/wasm3")

;; ---------------------------------------------------------------------------
;; The bridge: %SIZE is acl2-count
;; ---------------------------------------------------------------------------

; The prelude defines %SIZE with MBE and then disables it, so this is the one
; fact that has to be recovered before anything can be compared.
(defthm size-is-acl2-count
  (equal (wrt::%size x) (acl2-count x))
  :hints (("Goal" :in-theory (enable wrt::%size))))

; From here on %SIZE can stay disabled; the rewriter rewrites it away with the
; rule above, which is the point of proving it rather than enabling %SIZE.
(in-theory (disable wrt::%size))

;; ---------------------------------------------------------------------------
;; Monotonicity of acl2-count, in the two shapes the context rules produce
;; ---------------------------------------------------------------------------

; A suffix is no bigger than the list it came from.
(defthm acl2-count-of-nthcdr
  (<= (acl2-count (nthcdr n l)) (acl2-count l))
  :hints (("Goal" :induct (nthcdr n l))))

; So is a prefix -- and TAKE does NOT behave like one, which is worth measuring
; rather than assuming: ACL2's TAKE has no ENDP test, so it pads.
;
;   (take 3 '(a b))  = (A B NIL)      (take 1 nil) = (NIL)
;
; So the bare statement is FALSE, and it is false for a true list too.  The
; hypothesis that makes it true is (<= N (LEN L)): ask for no more than the list
; holds.  Everything downstream asks for a contiguous run of an instruction list,
; which always satisfies it.
(defthm acl2-count-of-take
  (implies (and (true-listp l)
                (<= n (len l)))
           (<= (acl2-count (take n l)) (acl2-count l)))
  :hints (("Goal" :induct (take n l)
                  :in-theory (enable acl2-count true-listp))))
