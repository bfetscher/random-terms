#lang racket

(require "stlc.rkt")

(define n-trials
  (command-line #:args (number-trials)
                (string->number number-trials)))

(call-with-output-file "stlc-stats.rktd"
  (λ (out)
    (write n-trials out)
    (write (gather-stats n-trials) out))
  #:exists 'replace)
