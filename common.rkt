#lang racket

(require scribble/core)

(provide (all-defined-out))


(define two-cols (element (style "begin" '(exact-chars))
                           '("multicols}{2")))

(define one-col (element (style "end" '(exact-chars))
                          '("multicols")))

