;;; Exercises the parts of the interpreter a trampoline could break: normal
;;; return, non-local exit from arbitrarily deep activations, unwinding,
;;; multiple values, closures, special bindings and argument decoding.
;;; Run with:  ecl --load /tmp/tramp-test.lsp --eval '(si::quit)'

(defun check (name got want)
  (if (equal got want)
      (format t "ok   ~a~%" name)
      (format t "FAIL ~a: got ~s want ~s~%" name got want)))

;;; --- plain recursion -------------------------------------------------------
(defun fact (n) (if (zerop n) 1 (* n (fact (1- n)))))
(check "fact" (fact 20) 2432902008176640000)

(defun deep (n) (if (zerop n) 0 (1+ (deep (1- n)))))
(check "deep 2000" (deep 2000) 2000)

(defun tree-sum (x)
  (cond ((null x) 0)
        ((atom x) x)
        (t (+ (tree-sum (car x)) (tree-sum (cdr x))))))
(check "tree-sum" (tree-sum '(1 (2 (3 4)) (((5))))) 15)

;;; --- tail recursion through labels ----------------------------------------
(defun loop-sum (n)
  (labels ((iter (i acc) (if (zerop i) acc (iter (1- i) (+ acc i)))))
    (iter n 0)))
(check "loop-sum" (loop-sum 5000) 12502500)

;;; --- block and return-from, from deep inside -------------------------------
(defun find-it (x tree)
  (block found
    (labels ((walk (t2)
               (cond ((atom t2) nil)
                     ((equal (car t2) x) (return-from found :yes))
                     (t (walk (car t2)) (walk (cdr t2))))))
      (walk tree))
    :no))
(check "return-from deep" (find-it 7 '(1 (2 (3 (4 (5 (6 (7)))))))) :yes)
(check "return-from absent" (find-it 9 '(1 (2 (3)))) :no)

;;; --- catch and throw ------------------------------------------------------
(defun catch-deep (n)
  (catch 'out
    (labels ((iter (i) (if (zerop i) (throw 'out (list :thrown i)) (iter (1- i)))))
      (iter n))
    :not-thrown))
(check "throw from depth" (catch-deep 1000) '(:thrown 0))

;;; --- unwind-protect, normal and non-local ---------------------------------
(defvar *log* nil)
(defun prot (n)
  (unwind-protect
      (labels ((iter (i) (if (zerop i) :done (iter (1- i)))))
        (iter n))
    (push :cleanup *log*)))
(check "unwind-protect normal" (prot 300) :done)
(check "unwind-protect ran once" (length *log*) 1)

(setf *log* nil)
(defun prot-throw (n)
  (catch 'x
    (unwind-protect
        (labels ((iter (i) (if (zerop i) (throw 'x :thrown) (iter (1- i)))))
          (iter n))
      (push :cleanup *log*))))
(check "unwind-protect throw" (prot-throw 300) :thrown)
(check "unwind-protect throw cleanup" *log* '(:cleanup))

;; error unwinds through many interpreted frames
(setf *log* nil)
(defun prot-error (n)
  (handler-case
      (unwind-protect
          (labels ((iter (i) (if (zerop i) (error "boom") (iter (1- i)))))
            (iter n))
        (push :cleanup *log*))
    (error (e) (declare (ignore e)) :caught)))
(check "unwind-protect error" (prot-error 200) :caught)
(check "unwind-protect error cleanup" *log* '(:cleanup))

;;; --- tagbody and go -------------------------------------------------------
(defun tags (n)
  (let ((i 0) (acc 0))
    (tagbody
     top
       (when (< i n) (incf acc i) (incf i) (go top)))
    acc))
(check "tagbody/go" (tags 1000) 499500)

;;; --- multiple values ------------------------------------------------------
(defun mv (x) (values x (1+ x) (1+ (1+ x))))
(check "multiple-value-list" (multiple-value-list (mv 1)) '(1 2 3))
(check "multiple-value-bind" (multiple-value-bind (a b c) (mv 1) (list c b a)) '(3 2 1))
(check "nth-value" (nth-value 2 (mv 5)) 7)

;;; --- closures, flet, labels, nested lambda --------------------------------
(defun adder (n) (lambda (x) (+ x n)))
(check "closure" (funcall (adder 10) 5) 15)

(defun counter ()
  (let ((n 0)) (lambda () (incf n))))
(let ((c (counter))) (funcall c) (funcall c) (check "closure state" (funcall c) 3))

(check "flet" (flet ((sq (x) (* x x))) (+ (sq 3) (sq 4))) 25)

;;; --- argument lists -------------------------------------------------------
(defun args (a &optional (b 2 bp) &rest r &key (k 5 kp) &aux (z 9))
  (list a b bp r k kp z))
(check "arglist 1" (args 1) '(1 2 nil nil 5 nil 9))
(check "arglist 2" (args 1 3 :k 7) '(1 3 t (:k 7) 7 t 9))

;;; --- special bindings -----------------------------------------------------
(defvar *sp* 1)
(defun read-sp () *sp*)
(check "special binding" (let ((*sp* 42)) (read-sp)) 42)
(check "special restored" (read-sp) 1)

;;; --- higher order through apply/mapcar/reduce -----------------------------
(check "apply" (apply #'+ 1 2 '(3 4)) 10)
(check "reduce" (reduce #'+ '(1 2 3 4 5)) 15)
(check "mapcar" (mapcar #'1+ '(1 2 3)) '(2 3 4))
(check "sort" (sort (list 3 1 2) #'<) '(1 2 3))

;;; --- mutual recursion -----------------------------------------------------
(defun evp (n) (if (zerop n) t (odp (1- n))))
(defun odp (n) (if (zerop n) nil (evp (1- n))))
(check "mutual recursion" (evp 1001) nil)

;;; --- progv / dynamic rebinding --------------------------------------------
(defun progv-test ()
  (progv '(*sp*) '(77) (read-sp)))
(check "progv" (progv-test) 77)

;;; --- interpreted call of a compiled function and back --------------------
(check "compiled callee" (string-upcase "abc") "ABC")
(check "format" (format nil "~a-~a" 1 2) "1-2")

;;; --- errors inside deeply nested interpreted calls -----------------------
(defun deep-error (n) (if (zerop n) (car 1) (deep-error (1- n))))
(check "ignore-errors" (ignore-errors (deep-error 100)) nil)

;;; --- keyword args passed by keyword in a deep chain ----------------------
(defun kw (n &key (v 0)) (if (zerop n) v (kw (1- n) :v (1+ v))))
(check "keywords deep" (kw 500) 500)

(format t "~&DONE~%")
