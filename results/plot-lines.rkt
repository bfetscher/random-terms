#lang racket

(require plot/pict 
         pict
         redex/benchmark/private/graph-data
         "plot-points.rkt")

(provide (all-defined-out))

(define (line-plot/directory dir-path)
  (define-values (d-stats _)
    (process-data
     (extract-data/log-directory dir-path)
     (extract-names/log-directory dir-path)))
  (parameterize ([plot-x-transform log-transform]
                 [plot-x-label "Time in Seconds"]
                 [plot-y-label "Number of Bugs Found"]
                 [plot-width 435] 
                 [plot-height 200]
                 [plot-x-ticks (log-ticks #:number 20 #:base 10)]
                 [type-symbols type->sym]
                 [type-names type->name]
                 [type-colors type->color])
    (plot-pict (make-renderers d-stats)
               #:x-min 0.05)))

(define line-styles
  (list 'solid 'dot 'long-dash
        'short-dash 'dot-dash))

(define (make-renderers stats)
  (define max-t (apply max (map third stats)))
  
  ;; (listof (list/c type data))
  (define types+datas
    (for/list ([(type avgs) (in-hash (sort-stats stats))]
               [n (in-naturals)])
      (define pts 
        (for/fold ([l '()]) 
          ([a (sort avgs <)]
           [c (in-naturals)])
          (cons (list a (add1 c))
                (cons 
                 (list a c) 
                 l))))
      (list type (reverse (cons (list max-t (/ (length pts) 2)) pts)))))
  
  (unless (= 2 (length types+datas)) 
    (error 'plot-lines.rkt "ack: assuming that there are only two competitors"))
  (define-values (_ crossover-points)
    (for/fold ([last-winner #f]
               [crossover-points '()])
      ([grammar-pr (in-list (list-ref (assoc 'grammar types+datas) 1))]
       [seach-pr (in-list (list-ref (assoc 'search types+datas) 1))])
      (unless (and (= (list-ref grammar-pr 1)
                      (list-ref seach-pr 1)))
        (error 'plot-lines.rkt "ack: expected points to match up ~s ~s"
               grammar-pr
               seach-pr))
      (define y-position (list-ref grammar-pr 1))
      (define grammar-time (list-ref grammar-pr 0))
      (define search-time (list-ref seach-pr 0))
      (define best (min grammar-time search-time))
      (define current-winner
        (cond
          [(= grammar-time best) 'grammar]
          [(= search-time best) 'search]))
      (values current-winner
              (cond
                [(and last-winner (not (equal? last-winner current-winner)))
                 (cons (point-label (vector best y-position)
                                    (format "~a, ~a"
                                            (number+unit/s y-position "bug")
                                            (format-time best))
                                    #:anchor 'bottom-right)
                       crossover-points)]
                [else
                 crossover-points]))))
  (for/list ([type+pts (in-list types+datas)]
             [n (in-naturals)])
    (define type (list-ref type+pts 0))
    (define pts (list-ref type+pts 1))
    (lines
     (reverse pts)
     ;#:width 2
     #:color ((type-colors) type)
     #:style (list-ref line-styles n)
     #:label ((type-names) type))))

(define (format-time number)
  (cond
    [(<= number 60) (number+unit/s number "second")]
    [(<= number (* 60 60)) (number+unit/s (/ number 60) "minute")]
    [(<= number (* 60 60 24)) (number+unit/s (/ number 60 60) "hour")]
    [else (number+unit/s (/ number 60 60 24) "day")]))

(define (number+unit/s raw-n unit) 
  (define n (round raw-n))
  (format "~a ~a~a" n unit (if (= n 1) "" "s")))

(module+ test
  (require rackunit)
  (check-equal? (format-time 0) "0 seconds")
  (check-equal? (format-time 1) "1 second")
  (check-equal? (format-time 59) "59 seconds")
  (check-equal? (format-time 70) "1 minute")
  (check-equal? (format-time 110) "2 minutes")
  (check-equal? (format-time (* 60 60 2)) "2 hours")
  (check-equal? (format-time (* 60 60 #e2.2)) "2 hours")
  (check-equal? (format-time (* 60 60 #e8.2)) "8 hours")
  (check-equal? (format-time (* 60 60 24 3)) "3 days"))

(define (sort-stats stats)
  (for/fold ([h (hash)])
    ([s (in-list stats)])
    (hash-set h (second s)
              (cons (third s)
                    (hash-ref h (second s) '())))))

(define/contract (type+num+method->average d-stats base num method)
  (-> any/c
      (or/c 'stlc 'poly-stlc 'stlc-sub 'let-poly 'list-machine 'rbtrees 'delim-cont 'verification) 
      any/c
      (or/c 'grammar 'ordered 'enum)
      (or/c #f (and/c real? positive?)))
  (define fn (format "~a-~a.rkt" base num))
  (for/or ([ele (in-list d-stats)])
    (define filename (list-ref ele 0))
    (define-values (base name dir) (split-path filename))
    (and (equal? (path->string name) fn)
         (equal? method (list-ref ele 1))
         (list-ref ele 2))))


