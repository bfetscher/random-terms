#lang racket

(require math
         plot
         pict)

(provide d-plots)

(define (get-bd nperms depth max-depth)
         (binomial-dist (sub1 nperms) 
                        (+ (/ depth max-depth) 
                           (* 0.05 (- 0.5 (/ depth max-depth))))))

(define nperms (factorial 4))

(define (d-plots full-width)
  (define md 5)
  (define pw (round (/ full-width 5)))
  (apply hc-append
         (for/list ([d (in-range 5)])
           (parameterize ([plot-height pw]
                          [plot-width pw]
                          [plot-font-size 12]
                          [plot-y-ticks no-ticks]
                          [rectangle-line-width 1]
                          [plot-line-width 1])
             (plot-pict
              (discrete-histogram 
               (map vector (build-list nperms values)
                    (build-list nperms (distribution-pdf (get-bd nperms d 5))))
               #:add-ticks? #f
               #:y-max (if (= d 0) 0.6 0.25))
              #:x-label (format "depth = ~a" d) 
              #:y-label #f
              #:y-max (if (= d 0) 0.6 0.25)
              #:width pw
              #:height pw)))))