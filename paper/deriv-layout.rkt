#lang racket

(require "../models/stlc.rkt"
         "common.rkt"
         redex/reduction-semantics
         redex/pict
         slideshow/pict
         racket/stxparam
         (for-syntax racket/list
                     racket/function))

(provide STLC
         lookup
         lookup-both-pict
         stlc-term
         infer
         eqt/lang
         neqt/lang
         space
         typ
         et
         eqt
         neqt)

(define space
  (ghost (render-term STLC x)))

(define l (string->symbol "\u27E6"))
(define r (string->symbol "\u27E7"))

(define-syntax-rule (typ env e t)
  (with-font-params
   (hbl-append
    (render-term STLC env)
    space
    (render-term STLC ⊢)
    space
    (render-term STLC e)
    space
    (render-term STLC :)
    space
    (render-term STLC t))))

(define-syntax-rule (lkf x t)
  (with-font-params
   (hbl-append
    (render-term STLC lookup)
    (render-term STLC ⟦)
    (render-term STLC x)
    (render-term STLC ⟧)
    space
    (render-term STLC =)
    space
    (render-term STLC t))))

(define-syntax-rule (eqt/lang lang t1 t2)
  (with-font-params
   (hbl-append
    (render-term lang t1)
    space
    (render-term lang =)
    space
    (render-term lang t2))))

(define-syntax-rule (eqt t1 t2)
  (eqt/lang STLC t1 t2))

(define-syntax-rule (neqt/lang lang t1 t2)
  (with-font-params
   (hbl-append
    (render-term lang t1)
    space
    (render-term lang ≠)
    space
    (render-term lang t2))))

(define-syntax-rule (neqt t1 t2)
  (neqt/lang STLC t1 t2))

(define-for-syntax infer-ignored '(• et ⋮ eqt neqt λ typ infer 
                                     ≠ lookup ⟦ ⟧ = : ⊢ →))

(define-syntax-parameter infer-ids #f)

(define-syntax (infer stx)
  (syntax-case stx ()
    [(_ #:h-dec m #:add-ids ais r . l)
     (begin
       (define if-ids (syntax-parameter-value #'infer-ids))
       (define a-ids (syntax->datum #'ais))
       (define open-ls (filter
                        (λ (l)
                          (syntax-case l (infer)
                            [(infer . rest) #f]
                            [_ #t]))
                        (syntax->list #'l)))
       (define ids (filter
                    (λ (id)
                      (not (member id infer-ignored)))
                    (remove-duplicates (flatten (map syntax->datum (cons #'r open-ls))))))
       (when if-ids
         (define new-ids (filter (λ (id)
                                   (not (member id (append a-ids if-ids))))
                                 ids))
         (unless (empty? new-ids)
           (raise-syntax-error 'infer (format "new id(s): ~s, introduced" new-ids) #'r)))
       (if if-ids
           #`(syntax-parameterize ([infer-ids '#,(append a-ids if-ids)])
                                  (infer/func #:h-dec m r . l))
           #`(syntax-parameterize ([infer-ids '#,ids])
                                  (infer/func #:h-dec m r . l))))]
    [(infer #:h-dec m r . l)
     #'(infer #:h-dec m #:add-ids () r . l)]
    [(infer #:add-ids ais r . l)
     #'(infer #:h-dec max #:add-ids ais r . l)]
    [(infer r . l)
     #`(infer #:h-dec max #:add-ids () r . l)]))

(define (infer/func #:h-dec [max/min max] r . l)
  (when (empty? l)
    (set! l (list (ghost (text "X")))))
  (define top
    (apply hb-append
           (* 2 (pict-width space))
           l))
  (with-font-params
   (vc-append 2
              top
              (linewidth 1
                         (hline 
                          (max/min (pict-width r)
                                   (pict-width top))
                          1))
              r)))

(define (lookup-infer-pict)
  (with-font-params
   (vc-append 10
              (infer (eqt (lookup (x τ Γ) x) τ))
              (infer (eqt (lookup • x) #f))
              (infer (eqt (lookup (x_1 τ_x Γ) x_2) τ)
                     (neqt x_1 x_2)
                     (eqt (lookup Γ x_2) τ)))))

(define (lookup-both-pict)
  (define loc (blank))
  (define main
    (hc-append 20
               (lookup-pict)
               loc
               (lookup-infer-pict)))
  (pin-over main loc (lambda args (define-values (x y) (apply cc-find args)) (values x 0))
            (frame (blank 0 (pict-height main)))))


(define-syntax-rule (stlc-term e)
  (render-term STLC e))

(define-syntax-rule (et exp) (with-font-params (stlc-term exp)))
