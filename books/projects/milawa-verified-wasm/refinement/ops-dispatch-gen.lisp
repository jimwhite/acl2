; The dispatcher's concrete comparison/if-chain generators and a concrete skip.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "ops-dispatch-tail")
(include-book "ops-dispatch-rest")

; The five-step false-comparison skip, for op = 0 and comparison 1.
(defthm skip-0-1
  (equal
   (car
    (w3t::step
     (car
      (w3t::step
       (car
        (w3t::step
         (car
          (w3t::step
           (car
            (w3t::step
             (list :|%;%|
                   (list :|%;%| *ir-store* (dframe 0 a b))
                   (append (dispatch-cmp 1)
                           (dispatch-tail 1)))))))))))))
   (list :|%;%| (list :|%;%| *ir-store* (dframe 0 a b))
         (dispatch-tail 1)))
  :hints (("Goal"
           :in-theory (e/d (d-local-get-rest
                              d-relop-false-rest
                              d-ifelse-false-rest
                              d-block-rest
                              d-label-nil-rest
                              dispatch-cmp
                              dispatch-branch
                              dispatch-tail
                              true-listp-dispatch-tail
                              true-listp-dispatch-branch)
                           (w3t::step dframe ir-frame-with-locals))
           :do-not-induct t)))
