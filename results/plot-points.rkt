#lang racket/base

(require racket/runtime-path
         (only-in plot
                  plot-width
                  plot-height
                  plot-x-label
                  plot-y-label)
         (only-in pict
                  pict-width
                  pict-height
                  pin-over
                  scale-to-fit
                  cellophane
                  rotate
                  text)
         redex/benchmark/private/graph-data)

(provide (all-defined-out))

(define-runtime-path 1ht "1-hr-trial")
(define-runtime-path 24hr "24-hr")

(define (type->sym t)
  (hash-ref (hash 'search 'diamond
                  'grammar 'circle)
            t))

(define (type->color t)
  (hash-ref (hash 'search 1
                  'grammar 2)
            t))

(define (type->name t)
  (hash-ref (hash 'search "Derivation Generation"
                  'grammar "Ad Hoc Generation")
            t))

(define (plot-points data-directory)
  (parameterize ([plot-width 435]
                 [plot-height 275]
                 [type-symbols type->sym]
                 [type-names type->name]
                 [type-colors type->color]
                 [plot-x-label #f]
                 [plot-y-label "Average Seconds to Find Each Bug"])
    (plot/log-directory data-directory)))

(define (add-trial-warning pict)
  (define pw (pict-width pict))
  (define ph (pict-height pict))
  (pin-over pict 0 0
            (scale-to-fit (cellophane (rotate (text "Trial Data")
                                              (atan ph pw))
                                      0.35)
                          pict)))
