;;; start.lisp

(in-package :cl-nomic-game)

(defun start ()
  (let ((list-of-augmented (json-parse *standard-input*)))
    (prog1
        (json-encode (json-object (decide list-of-augmented))
                     *standard-output*)
      (terpri *standard-output*))))

#+(or)
(with-open-file (*standard-input* #P"/tmp/test.json" :direction :input)
  (start))
