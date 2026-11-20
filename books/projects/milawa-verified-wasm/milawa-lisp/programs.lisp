; Milawa-Lisp, part 3: kernel programs as data.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; A Milawa-Lisp program is a list of (name formals body) triples, exactly the
; shape that milawa2.lsp's milawa-init uses.  The bodies here are in CORE
; syntax: no LET, LET*, COND, AND, or OR.  Turning the surface forms into core
; forms is the job of the (untrusted) front end, so that the verified evaluator
; only ever sees the twelve primitives, IF, QUOTE, variables, and calls.
;
; The functions below are transcribed verbatim from milawa-init in
; books/projects/milawa/milawa2.lsp.

(in-package "MILAWA-WASM")

(defconst *milawa-demo-program*
  '(;; (not (x) (if x nil t))
    (not (x) (if x nil t))

    ;; (rank (x) (if (consp x) (+ 1 (+ (rank (car x)) (rank (cdr x)))) 0))
    ;; Constants are written (QUOTE n), as in ACL2's internal terms.
    (rank (x) (if (consp x)
                  (+ (quote 1) (+ (rank (car x)) (rank (cdr x))))
                (quote 0)))

    ;; (ordp (x) (if (not (consp x)) (natp x) (and (consp (car x))
    ;;                                            (ordp (car (car x)))
    ;;                                            (not (equal (car (car x)) 0)))))
    (ordp (x) (if (if (consp x) nil t)
                  (natp x)
                (if (consp (car x))
                    (if (ordp (car (car x)))
                        (if (equal (car (car x)) (quote 0)) nil t)
                      nil)
                  nil)))

    ;; (ord< (x y) (cond ((not (consp x)) (if (consp y) t (< x y)))
    ;;                   ((not (consp y)) nil)
    ;;                   ((not (equal (car (car x)) (car (car y))))
    ;;                    (ord< (car (car x)) (car (car y))))
    ;;                   ((not (equal (cdr (car x)) (cdr (car y))))
    ;;                    (< (cdr (car x)) (cdr (car y))))
    ;;                   (t (ord< (cdr x) (cdr y)))))
    (ord< (x y) (if (if (consp x) nil t)
                    (if (consp y) t (< x y))
                  (if (if (consp y) nil t)
                      nil
                    (if (if (equal (car (car x)) (car (car y))) nil t)
                        (ord< (car (car x)) (car (car y)))
                      (if (if (equal (cdr (car x)) (cdr (car y))) nil t)
                          (< (cdr (car x)) (cdr (car y)))
                        (ord< (cdr x) (cdr y)))))))

    ;; (lookup (a x) (if (consp x)
    ;;                   (if (equal a (car (car x)))
    ;;                       (if (consp (car x))
    ;;                           (car x)
    ;;                         (cons (car (car x)) (cdr (car x))))
    ;;                     (lookup a (cdr x)))
    ;;                 nil))
    (lookup (a x) (if (consp x)
                      (if (equal a (car (car x)))
                          (if (consp (car x))
                              (car x)
                            (cons (car (car x)) (cdr (car x))))
                        (lookup a (cdr x)))
                    nil))))
