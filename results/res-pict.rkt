#lang racket

(require "graph-data.rkt")

(provide plot-gram-search)

(define (plot-gram-search #:directory [directory #f] #:order-by [order 'search]
                          #:min [ymin 0.01] #:max [ymax #f])
  (define files
    (for/list ([l (in-directory directory)]
               #:when (regexp-match #rx"^.*\\.rktd$"
                                    (path->string l)))
      (path->string l)))
  (parameterize
      ([order-by order]
       [types '(search grammar)]
       [confidence-interval #t]
       [min-y ymin]
       [max-t ymax])
    (make-plot files)))