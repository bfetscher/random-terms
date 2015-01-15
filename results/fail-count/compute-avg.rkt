#lang racket

(require math/statistics
         math/distributions)

(define (read-file f)
  (call-with-input-file f
    (λ (in)
      (let loop ()
        (define next (read-line in))
        (cond 
          [(eof-object? next) '()]
          [(regexp-match? #rx"^[0-9]+$" next)
           (cons (string->number next) (loop))]
          [else (loop)])))))

(define (read-dir d)
  (append-map
   read-file
   (directory-list d)))

(define (error95 nums)
  (define sdev (stddev nums #:bias #t))
  (define this-z (if (> (length nums) 30)
                     z
                     (hash-ref t-inv-cdf-97.5 (sub1 (length nums)))))
  (/ (* this-z sdev) (sqrt (length nums))))

(define z (inv-cdf (normal-dist) 0.975))

(define t-inv-cdf-97.5
  (hash 1 12.706
        2 4.303
        3 3.182
        4 2.776
        5 2.571
        6 2.447
        7 2.365
        8 2.306
        9 2.262
        10 2.228
        11 2.201
        12 2.129
        13 2.160
        14 2.145
        15 2.131
        16 2.120
        17 2.110
        18 2.101
        19 2.093
        20 2.086
        21 2.080
        22 2.074
        23 2.069
        24 2.064
        25 2.060
        26 2.056
        27 2.052
        28 2.048
        29 2.045
        30 2.042))

(define (stats)
  (for/list ([d (in-list '("decont" "poly" "rvm6"))])
    (define counts (read-dir d))
    (define avg (mean counts))
    (define rate (/ 1 avg))
    (define raterr (* rate (/ (error95 counts) avg)))
    (list d rate raterr)))
          