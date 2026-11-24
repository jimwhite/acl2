; L0 inverse, final value/list theorem with two conclusions.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(include-book "l0-inverse-list")

(defthm l0-printable-value-p-when-list
  (implies (l0-printable-list-p x)
           (l0-printable-value-p x))
  :hints (("Goal" :induct (l0-printable-list-p x)
                  :in-theory (enable l0-printable-list-p
                                     l0-printable-value-p))))

(defthm l0-read-inverse-stack
  (and
   (implies (and (l0-printable-value-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel)
                 (or (endp (l0-context stack suffix))
                     (l0-delimiter-char-p
                      (car (l0-context stack suffix)))))
            (mv-let (y rest labels)
              (l0-read-sexp
               (append (l0-print-chars x)
                       (l0-context stack suffix))
               fuel nil)
              (and (equal y x)
                   (equal rest (l0-context stack suffix))
                   (null labels))))
   (implies (and (l0-printable-list-p x)
                 (l0-stack-p stack)
                 (integerp fuel)
                 (<= (l0-read-fuel x) fuel))
            (mv-let (y rest labels)
              (l0-read-list
               (l0-skip-whitespace
                (append (l0-print-tail x)
                        (append (list *l0-rparen*)
                                (l0-context stack suffix))))
               fuel nil)
              (and (equal y x)
                   (equal rest (l0-context stack suffix))
                   (null labels)))))
  :hints (("Goal" :induct (l0-inv-induct x stack suffix fuel)
                  :do-not (quote (generalize eliminate-destructors))
                  :in-theory (e/d (l0-read-list-after-car-step)
                                  (l0-read-sexp
                                   l0-read-list
                                   l0-print-chars
                                   l0-print-tail
                                   l0-print-atom-chars
                                   l0-symbol-print-chars
                                   l0-read-atom
                                   l0-take-until-pipe
                                   l0-token-chars
                                   l0-token-rest
                                   l0-printable-value-p
                                   l0-printable-list-p
                                   l0-printable-atom-p
                                   l0-printable-symbol-p
                                   l0-raw-symbol-p
                                   l0-pipe-symbol-p
                                   l0-context
                                   l0-stack-p
                                   l0-delimiter-char-p
                                   l0-whitespace-char-p
                                   l0-read-fuel)))))
