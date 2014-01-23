#lang racket

(require redex/pict slideshow/pict)
(provide (all-defined-out))

(define word-gap (pict-width (text " ")))

(define (non-bnf-def var dom #:wide-nt [wide-nt "e"])
  (hbl-append
   word-gap
   (rbl-superimpose (non-terminal-text var) (ghost (text wide-nt)))
   (cbl-superimpose (text "∈") (ghost (text "::=")))
   (pict/nt dom)))


(define (non-terminal-text t)
  (text t (non-terminal-style) (default-font-size)))

(define (pict/nt t)
  (cond [(string? t)
         (non-terminal-text t)]
        [(pict? t) t]
        [(list? t) 
         (hbl-append 
          (text left-tuple (default-style) (default-font-size))
          (apply hbl-append (add-between (map pict/nt t)
                                         (text ", " (default-style) (default-font-size))))
          (text right-tuple (default-style) (default-font-size)))]
        [else (error 'pict/nt "expected pict or string but got ~s" t)]))

(define left-tuple "〈")
(define right-tuple "〉")


(define (metafunction-signature name . contract)
  (define domain (drop-right contract 1))
  (define codomain (last contract))
  (apply
   hbl-append word-gap 
   (text name (metafunction-style) (metafunction-font-size))
   (text ":")
   (append (add-between (map pict/nt domain)
                        (text ","))
           (list (text "→") (pict/nt codomain)))))

(define (or-alts . alts)
  (define (or-t) (text "or"))
  (apply 
   hbl-append word-gap
   (add-between
    (map pict/nt alts)
    (or-t))))
