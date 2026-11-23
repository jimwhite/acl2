; L0 inverse, inductive printed-context relation.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse-list")
(include-book "std/testing/must-succeed-star" :dir :system)

(make-event
 '
 (acl2::definductive l0-vl-printed
  :verify-guards nil
  :preds ((l0-vl-printed flag x chars rest))
  :irules
  ((v-atom ((l0-printable-atom-p x))
           (l0-vl-printed :value x
                          (append (l0-print-atom-chars x) rest)
                          rest))
   (v-cons ((l0-vl-printed :value a ac
                           (append (l0-print-tail d)
                                   (cons *l0-rparen* rest)))
            (l0-vl-printed :list d
                           (append (l0-print-tail d)
                                   (cons *l0-rparen* rest))
                           rest))
           (l0-vl-printed :value (cons a d)
                          (cons *l0-lparen* ac)
                          rest))
   (l-nil ()
          (l0-vl-printed :list nil
                         (cons *l0-rparen* rest)
                         rest))
   (l-cons ((l0-vl-printed :value a ac
                           (append (l0-print-tail d)
                                   (cons *l0-rparen* rest)))
            (l0-vl-printed :list d
                           (append (l0-print-tail d)
                                   (cons *l0-rparen* rest))
                           rest))
           (l0-vl-printed :list (cons a d)
                          (cons *l0-space* ac)
                          rest))))
)
