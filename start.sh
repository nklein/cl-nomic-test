#!/bin/sh

cd `dirname "$0"`

exec /usr/local/bin/sbcl --noinform \
                         --no-userinit \
                         --disable-debugger \
                         --eval '(declaim (sb-ext:muffle-conditions cl:warning))' \
                         --eval '(declaim (sb-ext:muffle-conditions sb-ext:compiler-note))' \
                         --eval '(setf *compile-verbose* nil)' \
                         --eval '(setf *load-verbose* nil)' \
                         --eval '(require "asdf")' \
                         --eval '(load "./cl-nomic-game.asd")' \
                         --eval '(asdf:load-system :cl-nomic-game)' \
                         --eval '(cl-nomic-game:start)' \
                         --quit
