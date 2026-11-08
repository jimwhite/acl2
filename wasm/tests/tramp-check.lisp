(in-package "ACL2")

(defun tramp-check-fn (n)
  (if (zp n) 0 (+ 1 (tramp-check-fn (- n 1)))))

(defthm tramp-check-fn-bound
  (implies (natp n) (equal (tramp-check-fn n) n)))
