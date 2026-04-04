;;; decide.lisp

(in-package :cl-nomic-game)

(named-readtables:in-readtable :json-reader-macro)

(defun sort-list-of-augmented-by-pull-request-updated-at (list-of-augmented)
  "Sort the list of augmented pull requests by ascending date the PULL-REQUEST was last updated"
  (flet ((augmented-pull-request-updated-at (augmented)
           (local-time:parse-rfc3339-timestring {augmented pull_request updated_at})))
    (stable-sort list-of-augmented
                 #'local-time:timestamp<
                 :key #'augmented-pull-request-updated-at)))

(defun find-reject (found augmented)
  "Return FOUND if non-NULL, otherwise determine if the AUGMENTED pull-request should be rejected"
  (or found

      ;; Reject if the pull request is submitted by someone who is not
      ;; on the list of *PLAYERS*.
      (let ((user {augmented pull_request user login}))
        (unless (relevant-player-login-p user)
          (make-reject-decision {augmented id}
                                (format nil "Will not accept pull-request from user <~A>" user))))

      ;; Reject if a majority of *PLAYERS* rejected the proposal.
      (let ((proportion (tally-rejects-proportion-of-voters
                         (tally-votes-on-pr-head-for-relevant-users augmented))))
        (when (<= 1/2 proportion)
          (make-reject-decision {augmented id}
                                (format nil "More than half (~A) of the eligible voters rejected" proportion))))))

(defun find-accept (found augmented)
  "Return FOUND if non-NULL, otherwise determine if the AUGMENTED pull-request should be rejected"
  (or found

      ;; Accept if the pull request is submitted by someone who is on
      ;; the *PLAYERS* list and they have received +ACCEPT+ votes from
      ;; at least half of the *PLAYERS*.
      (when (relevant-player-login-p {augmented pull_request user login})
        (let ((proportion (tally-accepts-proportion-of-voters
                           (tally-votes-on-pr-head-for-relevant-users augmented))))
          (when (< 1/2 proportion)
            (make-accept-decision {augmented id}
                                  (format nil "More than half (~A) of the eligible voters accepted" proportion)))))))

(defun decide (list-of-augmented)
  "Sort the incoming list of AUGMENTED-PULL-REQUEST instances by increasing UPDATED-AT.
Then, look through the list for the first one that is either ACCEPT-PULL-REQUEST-P or
REJECT-PULL-REQUEST-P. If one is found, return the appropriate ALIST to create a
decision."
  (let ((sorted-list (sort-list-of-augmented-by-pull-request-updated-at (safe-copy-seq list-of-augmented))))
    (or (reduce #'find-reject sorted-list :initial-value nil)
        (reduce #'find-accept sorted-list :initial-value nil)
        (make-defer-decision))))
