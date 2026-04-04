(in-package :cl-nomic-game)

(defun json-parse (string-or-stream)
  (let ((yason:*parse-object-as* :hash-table)
        (yason:*parse-json-booleans-as-symbols* t)
        (yason:*parse-json-null-as-keyword* t))
    (yason:parse string-or-stream)))

(defparameter *json-indent* nil)

(defun json-encode (json-object &optional (stream *debug-io*))
  (yason:with-output (stream :indent *json-indent*)
    (yason:encode json-object)))

(defun json-encode* (json-object)
  (yason:with-output-to-string* (:indent *json-indent*)
    (yason:encode json-object)))

(defun json-attr (name json-object &optional default)
  (gethash name json-object default))

(defgeneric json-object (src)
  (:method ((alist list))
    (alexandria:alist-hash-table alist
                                 :test 'equal)))

(defun json-object-to-alist (json-object)
  (alexandria:hash-table-alist json-object))

(defun safe-copy-seq (seq-or-null)
  (unless (eql seq-or-null :null)
    (copy-seq seq-or-null)))
