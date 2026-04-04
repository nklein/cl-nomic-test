;;; players.lisp

(in-package :cl-nomic-game)

(defstruct (player (:constructor make-player (login name)))
  "This defines a PLAYER struct with a given LOGIN on github and given NAME."
  (login (error "Must specify LOGIN for player") :type string :read-only t)
  (name (error "Must specify NAME for player") :type string :read-only t))

(defmethod make-load-form ((pp player) &optional environment)
  (declare (ignore environment))
  `(make-player ,(player-login pp) ,(player-name pp)))

;;; To get a game started, Patrick will remove themself
;;; from the following list and add in the real players
;;; for the game.
(defvar *players* (list (make-player "nklein" "Patrick Stein"))
  "This is the list of github logins which will be considered relevant
for the game logic.")

(defun player-login* (player)
  "If PLAYER is non-NIL, then return its PLAYER-LOGIN"
  (check-type player (or player null))
  (when player
    (player-login player)))

(defun player-name* (player)
  "If PLAYER is non-NIL, then return its PLAYER-NAME"
  (check-type player (or player null))
  (when player
    (player-name player)))

(defun relevant-player-login-p (login)
  (find login *players*
        :key #'player-login :test #'string=))
