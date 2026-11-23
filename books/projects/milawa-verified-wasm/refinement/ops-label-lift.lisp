; Lifting a step of a label-0 body through label 1 and the frame.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-trace-1")

(defthm label-step-of-body
  (implies (and (true-listp body)
                (true-listp rest)
                (not (we::exit-body-p body))
                (equal inner
                       (w3t::step
                        (list :|%;%| (list :|%;%| s f) body)))
                inner
                (equal (cadr (car inner)) (list :|%;%| s f))
                (we::state-shape-p (cadr (car inner))))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| s f)
                   (cons (list :label_%{%}% 0 nil body) rest)))
            (list
             (list :|%;%| (cadr (car inner))
                   (cons (list :label_%{%}% 0 nil (caddr (car inner)))
                         rest)))))
  :hints (("Goal"
           :in-theory (enable we::admin-term)
           :use ((:instance engine-admin-term-in-block
                            (k :l) (n 0) (x nil) (b body) (r rest)
                            (s s) (f f) (inner inner)))
           :do-not-induct t)))

(defthm not-exit-body-p-cons-label
  (not (we::exit-body-p
        (cons (list :label_%{%}% 0 nil body) rest)))
  :hints (("Goal"
           :in-theory (enable we::exit-body-p we::exit-block-p
                              we::exn-throw-p we::exit-head-p
                              we::first-nonval))))

(defthm frame-label-label-step-of-body-x
  (implies (and (true-listp body)
                (true-listp rest)
                (not (we::exit-body-p body))
                (equal inner0
                       (w3t::step
                        (list :|%;%| (list :|%;%| s x) body)))
                inner0
                (equal (cadr (car inner0)) (list :|%;%| s x))
                (we::state-shape-p (cadr (car inner0)))
                (equal inner1
                       (list
                        (list :|%;%| (cadr (car inner0))
                              (cons (list :label_%{%}% 0 nil
                                          (caddr (car inner0)))
                                    rest)))))
           (equal
            (w3t::step
             (list :|%;%| (list :|%;%| s f)
                   (list (list :frame_%{%}% 1 x
                               (list (list :label_%{%}% 1 nil
                                           (cons (list :label_%{%}% 0 nil body)
                                                 rest)))))))
            (list
             (list :|%;%| (list :|%;%| s f)
                   (list (list :frame_%{%}% 1 x
                               (list (list :label_%{%}% 1 nil
                                           (cons (list :label_%{%}% 0 nil
                                                       (caddr (car inner0)))
                                                 rest)))))))))
  :hints (("Goal"
           :in-theory (disable w3t::step
                               label-step-of-body
                               frame-label-step-of-body-x
                               we::step-of-admin-term-is-context-rule
                               we::exit-body-p we::exit-block-p
                               we::exn-throw-p we::exit-head-p
                               we::first-nonval)
           :use ((:instance label-step-of-body (f x) (inner inner0))
                 (:instance frame-label-step-of-body-x
                            (body (cons (list :label_%{%}% 0 nil body) rest))
                            (inner inner1))
                 (:instance not-exit-body-p-cons-label))
           :do-not-induct t)))

