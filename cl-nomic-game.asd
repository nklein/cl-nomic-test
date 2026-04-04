;;;; nomic-game.asd

#-asdf
(require "asdf")
(cl:load "./quicklisp/bundle.lisp")

(asdf:defsystem #:cl-nomic-game
  :description "CL-NOMIC-GAME"
  :author "Patrick Stein <pat@nklein.com>"
  :license "UNLICENSE"
  :version "0.1.20260328"
  :depends-on (:alexandria :local-time :yason :named-readtables)
  :components
  ((:static-file "README.md")
   (:static-file "UNLICENSE.txt")
   (:module "src"
    :components ((:file "package")
                 (:file "players" :depends-on ("package"))
                 (:file "json-utils" :depends-on ("package"))
                 (:file "reader-macro" :depends-on ("package"
                                                  "json-utils"))
                 (:file "decision" :depends-on ("package"
                                                "json-utils"))
                 (:file "vote-count" :depends-on ("package"
                                                  "players"
                                                  "reader-macro"))
                 (:file "decide" :depends-on ("package"
                                              "players"
                                              "reader-macro"
                                              "vote-count"
                                              "decision"))
                 (:file "start" :depends-on ("package"
                                             "json-utils"
                                             "decide"))))))
