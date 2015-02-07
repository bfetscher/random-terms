#lang racket

(require redex/pict)

(provide with-font-params
         text-scale)

(define (text-scale p)
  (with-font-params p))

(define-syntax-rule
  (with-font-params e1 e2 ...)
  (parameterize ([default-font-size 12]
                 [metafunction-font-size 12]
                 [default-font-size 12]
                 [label-font-size 12]
                 [metafunction-up/down-indent 10])
    e1 e2 ...))
