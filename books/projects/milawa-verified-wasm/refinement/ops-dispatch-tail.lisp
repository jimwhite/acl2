; The dispatcher's comparison/if-chain generators, without the engine.
;
; Copyright (C) 2026 Kookamara LLC
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")

(defun dispatch-branch (j)
  (case j
    (0 '((:local.get 1) (:return)))
    (1 '((:local.get 1) (:return)))
    (2 '((:local.get 1) (:local.get 2) (:binop (:i32) (:add)) (:return)))
    (3 '((:local.get 1) (:local.get 2) (:binop (:i32) (:sub)) (:return)))
    (4 '((:local.get 1) (:local.get 2) (:relop (:i32) (:lt (:s))) (:return)))
    (5 '((:local.get 2) (:local.get 1) (:testop (:i32) (:eqz))
          (:binop (:i32) (:mul)) (:return)))
    (6 '((:local.get 2) (:return)))
    (7 '((:local.get 1) (:return)))
    (otherwise nil)))

(defun dispatch-cmp (j)
  (list (list :local.get 0)
        (list :const (list :i32) j)
        (list :relop (list :i32) (list :eq))
        (list :ifelse (quote (:_result nil)) (dispatch-branch j) nil)))

(defun dispatch-body-from (j)
  (declare (xargs :measure (nfix (- 8 j))))
  (if (and (natp j) (< j 8))
      (append (dispatch-cmp j) (dispatch-body-from (1+ j)))
    (list (list :const (list :i32) 0))))

(defun dispatch-tail (j) (dispatch-body-from (1+ j)))

(defthm true-listp-dispatch-branch
  (true-listp (dispatch-branch j))
  :hints (("Goal" :in-theory (enable dispatch-branch))))

(defthm true-listp-dispatch-cmp
  (true-listp (dispatch-cmp j))
  :hints (("Goal" :in-theory (enable dispatch-cmp))))

(defthm true-listp-dispatch-body-from
  (true-listp (dispatch-body-from j))
  :hints (("Goal" :induct (dispatch-body-from j)
                  :in-theory (enable dispatch-body-from))))

(defthm true-listp-dispatch-tail
  (true-listp (dispatch-tail j))
  :hints (("Goal" :in-theory (enable dispatch-tail))))
