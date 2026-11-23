; J3b: a verified lowering and the general bytecode-run theorem.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

; The J2a machine runs flat bytecode (machine.lisp).  This book is the
; verified-lowering groundwork for the general run theorem (J1b/J3b): an
; untrusted lowering whose labels are the absolute pcs of their label
; instructions, its instruction count, the position invariant
; (POSITIONAL-FROM: a label instruction's value is its pc), and the
; corresponding LABEL-PC resolution theorem.
;
; These are the facts the run-level induction needs: each IF branch lands on
; the computed pc, and LABEL-PC of the branch labels returns those pcs.
; The run theorem itself (MACHINE-RUN of the lowered code equals BC-EVAL for
; all well-formed IR code, and hence R-EV for terms via COMPILE-CORRECT) is
; the next book; J3's host-loop and front-door acceptance is in top-host and
; poc.

(in-package "MILAWA-WASM")

(include-book "machine")

(defthm len-of-append-j3
  (equal (len (append a b)) (+ (len a) (len b)))
  :hints (("Goal" :induct (len a))))

;; ---------------------------------------------------------------------------
;; Instruction counts and the positional lowering
;; ---------------------------------------------------------------------------

(defun pc-len (code)
  (declare (xargs :guard t :verify-guards nil))
  (case (car code)
    (:const 1)
    (:load 1)
    (:prim (let ((ar (milawa-primitive-arity (cadr code))))
             (cond ((equal ar 1) (+ 1 (pc-len (caddr code))))
                   ((equal ar 2) (+ 1 (pc-len (caddr code))
                                    (pc-len (cadddr code))))
                   (t 1))))
    (:if (+ (pc-len (cadr code)) 1
            (pc-len (caddr code)) 1 1
            (pc-len (cadddr code)) 1))
    (otherwise 1)))

(defun pc-lower-flat (code pc)
  (declare (xargs :guard t :verify-guards nil))
  (case (car code)
    (:const (list (list :const (cadr code))))
    (:load (list (list :load (cadr code))))
    (:prim
     (let ((fn (cadr code))
           (ar (milawa-primitive-arity (cadr code))))
       (cond ((equal ar 1)
              (append (pc-lower-flat (caddr code) pc)
                      (list (list :prim fn))))
             ((equal ar 2)
              (append (pc-lower-flat (caddr code) pc)
                      (append (pc-lower-flat (cadddr code)
                                             (+ pc (pc-len (caddr code))))
                              (list (list :prim fn)))))
             (t (list (list :abort))))))
    (:if
     (let* ((test (cadr code))
            (then (caddr code))
            (else (cadddr code))
            (tlen (pc-len test))
            (ifz-pc (+ pc tlen))
            (then-pc (+ ifz-pc 1))
            (then-len (pc-len then))
            (jmp-pc (+ then-pc then-len))
            (else-label (+ jmp-pc 1))
            (else-pc (+ else-label 1))
            (else-len (pc-len else))
            (end-label (+ else-pc else-len)))
       (append (pc-lower-flat test pc)
               (append (list (list :ifz else-label))
                       (append (pc-lower-flat then then-pc)
                               (append (list (list :jmp end-label))
                                       (append (list (list :label else-label))
                                               (append (pc-lower-flat else else-pc)
                                                       (list (list :label end-label))))))))))
    (otherwise (list (list :abort)))))

(defun pc-lower-program (code)
  (declare (xargs :guard t :verify-guards nil))
  (append (pc-lower-flat code 0) (list (list :halt))))

(defthm len-pc-lower-flat
  (equal (len (pc-lower-flat code pc)) (pc-len code))
  :hints (("Goal" :induct (pc-lower-flat code pc)
                  :in-theory (e/d (pc-lower-flat pc-len len-of-append-j3)
                                  ()))))

;; ---------------------------------------------------------------------------
;; Positional invariant: a label instruction's value is its pc
;; ---------------------------------------------------------------------------

(defun positional-from (pc code)
  (declare (xargs :guard t :verify-guards nil :measure (acl2-count code)))
  (if (endp code)
      t
    (and (or (not (and (consp (car code))
                       (equal (car (car code)) :label)))
             (equal (cadr (car code)) pc))
         (positional-from (1+ pc) (cdr code)))))

(defthm positional-from-append
  (implies (natp pc)
           (equal (positional-from pc (append a b))
                  (and (positional-from pc a)
                       (positional-from (+ pc (len a)) b))))
  :hints (("Goal" :induct (positional-from pc a)
                  :in-theory (enable positional-from))))

(defthm positional-from-pc-lower-flat
  (implies (natp pc)
           (positional-from pc (pc-lower-flat code pc)))
  :hints (("Goal" :induct (pc-lower-flat code pc)
                  :in-theory (e/d (pc-lower-flat pc-len positional-from
                                                 positional-from-append
                                                 len-pc-lower-flat)
                                  ()))))

;; ---------------------------------------------------------------------------
;; LABEL-PC on positional code
;; ---------------------------------------------------------------------------

(defthm label-pc-when-positional
  (implies (and (positional-from pc code)
                (natp pc)
                (natp l)
                (<= pc l)
                (< l (+ pc (len code)))
                (equal (nth (- l pc) code) (list :label l)))
           (equal (label-pc l code pc) l))
  :hints (("Goal" :induct (positional-from pc code)
                  :in-theory (enable label-pc positional-from))))

