#lang racket

(require math
         plot
         pict
         
         (only-in redex/private/search get-dist))

(provide d-plots
         max-depth
         number-of-choices
         nperms)

(define number-of-choices 4)
(define nperms (factorial number-of-choices))
(define max-depth 4)

(define (d-plots full-width)
  (define pw (round (/ full-width (+ max-depth 1))))
  (apply hc-append
         (for/list ([depth (in-range (+ max-depth 1))])
           (parameterize ([plot-font-size 12]
                          [plot-y-ticks no-ticks]
                          [rectangle-line-width 1]
                          [plot-line-width 1])
             (plot-pict
              (discrete-histogram 
               (map vector 
                    (build-list nperms values)
                    (build-list nperms (distribution-pdf
                                        (get-dist number-of-choices depth max-depth))))
               #:add-ticks? #f
               #:y-max .6)
              #:x-label (format "depth = ~a" depth)
              #:y-label #f
              #:width pw
              #:height (* 2 pw))))))
