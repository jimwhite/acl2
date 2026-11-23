; The full dispatcher frame trace for each op with a closed true-branch tail:
; the false-comparison skips, the true comparison and branch, and the two
; return steps.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-tails")
(include-book "ops-frame-skips")
(include-book "ops-unp")
(include-book "ops-tail-5")

(defmacro def-frame-trace (name op tail-lemma tail-steps v hyps)
  `(defthm ,name
     (implies (and ,@hyps)
              (equal
               (step-prefix
                ,(+ (* 5 op) tail-steps 2)
                (frame-cfg ,op (sel a) (sel b)
                           (append (dispatch-cmp 0)
                                   (dispatch-tail 0))))
               (list :|%;%|
                     (list :|%;%| *ir-store* *ir-call-frame*)
                     (list (list :const (list :i32) ,v)))))
     :hints (("Goal"
              :in-theory (e/d (,tail-lemma
                               frame-step-body-append-gen
                               step-frame-ret-cfg-gen
                               sel-un-p
                               true-listp-dispatch-tail
                               no-br-p-dispatch-tail
                               un-p-loghead-32
                               un-p-if-01
                               un-p-if-equal-zero-sel
                               un-p-zero-32
                               un-p-one-32)
                              (w3t::step dframe ir-frame-with-locals
                               frame-cfg sel tail-sel
                               dispatch-tail dispatch-cmp dispatch-branch
                               (:e dispatch-tail) (:e dispatch-cmp)
                               (:e dispatch-branch)
                               append binary-append
                               we::append-of-cons
                               acl2::loghead acl2::loghead$inline
                               acl2::ifix acl2::mod acl2::floor
                               acl2::imod$inline acl2::expt2$inline
                               step-const-return-cons-rest-un-p
                               (:e cons)))
              :do-not-induct t))))

(def-frame-trace frame-trace-2 2 frame-tail-2-sel 8
  (loghead 32 (+ (sel a) (sel b))) nil)

(def-frame-trace frame-trace-3 3 frame-tail-3-raw 8
  (loghead 32 (- (sel a) (sel b))) nil)

(def-frame-trace frame-trace-4 4 frame-tail-4-raw 8
  (if (< (sel a) (sel b)) 1 0)
  ((unsigned-byte-p 31 (sel a))
   (unsigned-byte-p 31 (sel b))))

(def-frame-trace frame-trace-5 5 frame-tail-5-sel 9
  (if (equal (sel a) 0) (sel b) 0) nil)

(def-frame-trace frame-trace-6-op 6 frame-tail-6-raw 6 (sel b) nil)

(def-frame-trace frame-trace-7 7 frame-tail-7-raw 6 (sel a) nil)
