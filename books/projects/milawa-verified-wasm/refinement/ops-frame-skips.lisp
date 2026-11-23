; The dispatcher's false-comparison skips at the frame level: five steps
; from the comparison of op with j to the next comparison, opening the next
; (dispatch-cmp, dispatch-tail) pair so the skips chain syntactically.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-trace-1")

(defmacro def-frame-skip (op j)
  (let ((name (acl2::packn-pos (list "FRAME-SKIP" op j)
                               (quote milawa-wasm))))
    `(defthm ,name
       (equal
        (step-prefix
         5
         (frame-cfg ,op a b
                    (append (dispatch-cmp ,j) (dispatch-tail ,j))))
        (frame-cfg ,op a b
                   (append (dispatch-cmp ,(1+ j))
                           (dispatch-tail ,(1+ j)))))
       :hints (("Goal"
                :in-theory (e/d (d-local-get-rest
                                 d-relop-false-rest
                                 d-ifelse-false-rest
                                 d-block-rest
                                 d-label-nil-rest
                                 frame-label-step-of-body-x
                                 dispatch-cmp
                                 dispatch-branch
                                 dispatch-tail
                                 true-listp-dispatch-tail
                                 true-listp-dispatch-branch
                                 frame-cfg
                                 we::exit-body-p
                                 we::exit-block-p
                                 we::exn-throw-p
                                 we::exit-head-p
                                 we::first-nonval
                                 we::vals-p)
                                (w3t::step dframe ir-frame-with-locals
                                 (:e cons)))
                :do-not-induct t)))))

(def-frame-skip 1 0)
(def-frame-skip 2 0)
(def-frame-skip 2 1)
(def-frame-skip 3 0)
(def-frame-skip 3 1)
(def-frame-skip 3 2)
(def-frame-skip 4 0)
(def-frame-skip 4 1)
(def-frame-skip 4 2)
(def-frame-skip 4 3)
(def-frame-skip 5 0)
(def-frame-skip 5 1)
(def-frame-skip 5 2)
(def-frame-skip 5 3)
(def-frame-skip 5 4)
(def-frame-skip 6 0)
(def-frame-skip 6 1)
(def-frame-skip 6 2)
(def-frame-skip 6 3)
(def-frame-skip 6 4)
(def-frame-skip 6 5)
(def-frame-skip 7 0)
(def-frame-skip 7 1)
(def-frame-skip 7 2)
(def-frame-skip 7 3)
(def-frame-skip 7 4)
(def-frame-skip 7 5)
(def-frame-skip 7 6)
