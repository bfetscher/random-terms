#lang racket

(require "models/stlc.rkt"
         redex
         slideshow/pict)

(provide STLC
         lookup
         (all-defined-out)
         lookup-both-pict
         stlc-term)

(define space
  (ghost (render-term STLC X)))

(define l (string->symbol "\u27E6"))
(define r (string->symbol "\u27E7"))

(define-syntax-rule (typ env e t)
  (hbl-append
   (render-term STLC env)
   space
   (render-term STLC ⊢)
   space
   (render-term STLC e)
   space
   (render-term STLC :)
   space
   (render-term STLC t)))

(define-syntax-rule (lkf x t)
  (hbl-append
   (render-term STLC lookup)
   (render-term STLC ⟦)
   (render-term STLC x)
   (render-term STLC ⟧)
   space
   (render-term STLC =)
   space
   (render-term STLC t)))

(define-syntax-rule (eqt t1 t2)
  (hbl-append
   (render-term STLC t1)
   space
   (render-term STLC =)
   space
   (render-term STLC t2)))

(define-syntax-rule (neqt t1 t2)
  (hbl-append
   (render-term STLC t1)
   space
   (render-term STLC ≠)
   space
   (render-term STLC t2)))

(define (infer #:h-dec [max/min max] r . l)
  (define top
    (apply hb-append
          (* 2 (pict-width space))
          l))
  (vc-append 2
             top
   (linewidth 1
              (hline 
               (max/min (pict-width r)
                        (pict-width top))
               1))
   r))

(define (lookup-infer-pict)
  (hc-append 20
   (vc-append 10
    (infer (eqt (lookup (x τ Γ) x) τ))
    (infer (eqt (lookup • x) #f)))
   (infer (eqt (lookup (x_1 τ_x Γ) x_2) τ)
          (neqt x_1 x_2)
         (eqt (lookup Γ x_2) τ))))

(define (lookup-both-pict)
  (hc-append 35
             lookup-pict
             (lookup-infer-pict)))


(define-syntax-rule (stlc-term e)
  (render-term STLC e))