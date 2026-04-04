;;; decision.lisp

(in-package :cl-nomic-game)

;; ================================================
(defstruct decision
  "Base STRUCT common ancestor of all DECISION types")

;; ================================================
(defstruct (messageable-decision (:include decision))
  "Base STRUCT for all DECISION types with an optional message."
  (message nil :type (or string null) :read-only t))

(defmethod json-object ((src messageable-decision))
  (let ((message (messageable-decision-message src)))
    (json-object (when message
                   `(("message" . ,message))))))

;; ================================================
(defstruct (winner-decision (:include messageable-decision)
                            (:constructor make-winner-decision (name &optional message)))
  "Struct for DECISION saying NAME won."
  (name (error "Must supply NAME") :type string :read-only t))

(defmethod json-object ((src winner-decision))
  (json-object (append `(("decision" . "winner")
                         ("name" . ,(winner-decision-name src)))
                       (json-object-to-alist (call-next-method)))))

;; ================================================
(defstruct (pr-decision (:include messageable-decision))
  "Base STRUCT for all DECISION types referencing a particular augmented pull request."
  (id (error "Must supply ID") :type (integer 1 *) :read-only t))

(defmethod json-object ((src pr-decision))
  (json-object (append `(("id" . ,(pr-decision-id src)))
                       (json-object-to-alist (call-next-method)))))

;; ================================================
(defstruct (accept-decision (:include pr-decision)
                            (:constructor make-accept-decision (id &optional message))))

(defmethod json-object ((src accept-decision))
  (json-object (append `(("decision" . "accept"))
                       (json-object-to-alist (call-next-method)))))

;; ================================================
(defstruct (reject-decision (:include pr-decision)
                            (:constructor make-reject-decision (id &optional message))))

(defmethod json-object ((src reject-decision))
  (json-object (append `(("decision" . "reject"))
                       (json-object-to-alist (call-next-method)))))

;; ================================================
(defstruct (defer-decision (:include decision)))

(defmethod json-object ((src defer-decision))
  (json-object `(("decision" . "defer"))))
