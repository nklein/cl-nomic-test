;;; vote-count.lisp

(in-package :cl-nomic-game)

(named-readtables:in-readtable :json-reader-macro)

(alexandria:define-constant +ACCEPT+ "ACCEPT"
  :test 'string=
  :documentation "Review BODY for an ACCEPT vote")

(alexandria:define-constant +REJECT+ "REJECT"
  :test 'string=
  :documentation "Review BODY for an REJECT vote")

(defun sort-reviews-by-submitted-at (list-of-reviews)
  "Return the LIST-OF-REVIEWS sorted by increasing SUBMITTED_AT property."
  (flet ((review-submitted-at (review)
           (local-time:parse-rfc3339-timestring {review submitted_at})))
    (stable-sort list-of-reviews
                 #'local-time:timestamp<
                 :key #'review-submitted-at)))

(defun collect-votes-on-pr-head (augmented)
  "Collect the most recent vote from each user on the pull-request"
  (let ((head-sha {augmented pull_request head sha})
        (most-recent-vote-by-user (json-object nil)))
    (dolist (review (sort-reviews-by-submitted-at (safe-copy-seq {augmented reviews}))
                    most-recent-vote-by-user)
      (when (string= {review commit_id} head-sha)
        (let ((body {review body}))
          (when (member body `(,+ACCEPT+ ,+REJECT+) :test #'string=)
            (setf (gethash {review user login} most-recent-vote-by-user) body)))))))

(defun tally-votes-on-pr-head-for-relevant-users (augmented)
  "Count the number of +ACCEPT+ and +REJECT+ votes on the PR-HEAD"
  (let ((accepts 0)
        (rejects 0))
    (flet ((count-if-relevant-user (user vote)
             (when (relevant-player-login-p user)
               (cond
                 ((string= vote +ACCEPT+)
                  (incf accepts))
                 ((string= vote +REJECT+)
                  (incf rejects))))))
      (maphash #'count-if-relevant-user (collect-votes-on-pr-head augmented)))
    `((:accepts . ,accepts)
      (:rejects . ,rejects)
      (:voters . ,(length *players*)))))

(defun tally-accepts (tally)
  (cdr (assoc :accepts tally)))

(defun tally-rejects (tally)
  (cdr (assoc :rejects tally)))

(defun tally-voters (tally)
  (cdr (assoc :voters tally)))

(defun tally-accepts-proportion-of-voters (tally)
  (/ (tally-accepts tally)
     (tally-voters tally)))

(defun tally-rejects-proportion-of-voters (tally)
  (/ (tally-rejects tally)
     (tally-voters tally)))

(defun tally-votes-proportion-of-voters (tally)
  (/ (+ (tally-accepts tally)
        (tally-rejects tally))
     (tally-voters tally)))

#+(or)
(with-open-file (stream #P"/tmp/test.json" :direction :input)
  (mapcar #'tally-votes-on-pr-head-for-relevant-users
          (json-parse stream)))
