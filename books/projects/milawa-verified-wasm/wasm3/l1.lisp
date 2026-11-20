; L1, first steps: the certified semantics executes the artifact.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; L1 proper -- "one dispatch iteration of the module equals MVM-STEP" -- is a
; symbolic proof over the module's twelve function bodies and is a project of its
; own.  This book establishes the part that has to come first and that we can
; have now: the certified WASM 3.0 semantics ACCEPTS our artifact's store and
; takes steps of it.  Every theorem here is a ground fact about the pinned
; constants, so each is proved by evaluation; what makes them worth having is that
; they are about the real semantics on the real artifact, not about our model of
; either.
;
; The API, which took some finding and is worth writing down:
;
;   $INSTANTIATE returns a CONFIGURATION, not a store.  Our module has no imports,
;   no data and no start function, so there is nothing to run and that
;   configuration is already final; (CADR (CADR C)) is the store and
;   (CADDR (CADR C)) the frame, which is how the driver's FINAL-CONFIG
;   destructures a stopped configuration.  Both are pinned in state.lisp.
;
;   $INVOKE is LOGIC mode and builds the entry configuration for a call: a frame
;   with no locals, then the argument values, then REF.FUNC_ADDR and CALL_REF.
;   Its third argument is the argument list, here empty.
;
;   STEP is LOGIC mode and returns the LIST of successor configurations, so a step
;   exists exactly when that list is non-empty.

(in-package "MILAWA-WASM")

(include-book "/workspaces/acl2/.wasm-acl2/translate/gen/wasm-3.0/wasm3")
(include-book "state")

;; ---------------------------------------------------------------------------
;; The entry configuration
;; ---------------------------------------------------------------------------

; Function 6 is the exported STEP, which MILAWA-VERIFIED-STEP-IS-FUNCTION-6
; records.  No arguments: the module's step takes none.

(defun milawa-entry-config ()
  (w3t::$invoke *milawa-verified-store* 6 nil))

; The store satisfies what $INVOKE requires of it: a well-typed, callable
; function 6.  If the pinned store were malformed or the pin had drifted, this
; would fail, so it is the check that the two generated constants belong together.
(defthm milawa-entry-config-exists
  (consp (milawa-entry-config)))

;; ---------------------------------------------------------------------------
;; The semantics takes steps
;; ---------------------------------------------------------------------------

; One step of the certified semantics on our module.  The step exists -- STEP
; found a rule that applies -- which means the module is structurally well enough
; formed for the spec's own small-step relation to make progress on it.
(defthm milawa-step-applies
  (consp (w3t::step (milawa-entry-config))))

; The spec's step is a function returning the list of successors; ours is
; deterministic, so exactly one.
(defthm milawa-step-is-single-valued
  (equal (len (w3t::step (milawa-entry-config))) 1))

; Three steps in, still going.  Written as three nested steps rather than through
; STEPS/%FUEL so that the statement does not depend on a fuel budget at all.
(defun milawa-step3 (c) (w3t::step (car (w3t::step (car (w3t::step c))))))

(defthm milawa-three-steps-apply
  (consp (milawa-step3 (milawa-entry-config))))

;; ---------------------------------------------------------------------------
;; What it is executing
;;
;; A configuration in this semantics is (INSTRUCTION-STATE INSTRUCTIONS): the
;; instructions are the third component.  The first two theorems below say what
;; the entry configuration is -- a call to function 6 -- and the third says the
;; call is entered after one step, which is the frame being pushed for our
;; function's locals.  These are the first facts in this project stated ABOUT THE
;; CERTIFIED SEMANTICS RUNNING OUR ARTIFACT, rather than about our model of it.
;; ---------------------------------------------------------------------------

(defun milawa-instrs (c) (caddr c))

(defthm milawa-entry-calls-function-6
  (equal (car (milawa-instrs (milawa-entry-config)))
         '(:ref.func_addr 6)))

(defthm milawa-entry-passes-no-arguments
  (equal (len (milawa-instrs (milawa-entry-config))) 2))

; After one step the machine is inside a frame: the call was taken, and what
; remains to execute is the function's body in a fresh frame whose locals are the
; zero-initialised parameters.
(defthm milawa-first-step-enters-the-frame
  (equal (car (car (milawa-instrs (car (w3t::step (milawa-entry-config))))))
         :frame_%{%}%))
