#lang racket

(require slideshow/pict
         redex/reduction-semantics
         redex/pict
         "pats.rkt"
         "program.rkt"
         "disunify-a.rkt")

(provide (all-defined-out))

(define-extended-language CLP program
  (S ::= (P ⊢ G ∥ C))
  (P ::= (J ...))
  (G ::= (l ...))
  (C ::= s ⊥)
  (s ::= ((e ...) : (e ...)))
  (g ::= L e)
  (e ::= ....
         (p = p)))

(define R
  (reduction-relation 
   CLP
   (--> (P ⊢ (e_g g ...) ∥ s)
        (P ⊢ (g ...) ∥ C)
        (where ((e_1 ...) : (e_2 ...)) s)
        (where C (solve (e_g) (e_1 ...) (e_2 ...)))
        "new constraint")
   (--> (P ⊢ ((j p_g) g ...) ∥ s)
        (P ⊢ ((p_f = p_g) l_f ... g ...) ∥ s)
        (where (J_0 ... (r_0 ... ((j p_r) ← l_r ...) r_1 ...) J_1 ...) P)
        (where ((j p_f) ← l_f ...) (freshen ((j p_r) ← l_r ...)))
        "reduce")))


(define-metafunction CLP
  [(freshen ((j p_r) ← L_r ...))
   ((freshen-l (j p_r)) ← (freshen-l L_r) ...)
   (side-condition (inc-fresh-index))])

(define-metafunction CLP
  [(freshen-l (j p))
   (j (freshen-p () p))]
  [(freshen-l (∀ (x ...) p_1 ≠ p_2))
   (∀ (x ...) (freshen-p (x ...) p_1) ≠ (freshen-p (x ...) p_2))])

(define-metafunction CLP
  [(freshen-p (x ...) (lst p ...))
   (lst (freshen-p (x ...) p) ...)]
  [(freshen-p (x ...) a)
   a]
  [(freshen-p (x_0 ... x x_1 ...) x)
   x]
  [(freshen-p (x_0 ...) x)
   ,(fresh-v (term x))])

(define fresh-index (make-parameter 0))

(define (inc-fresh-index)
  (fresh-index (add1 (fresh-index)))
  (void))

(define (fresh-v x)
  (string->symbol
   (string-append
    (symbol->string x)
    "_"
    (number->string (fresh-index)))))

(define clp-pict
  (let*
      ([indent 0]
       [gp (vc-append 5
            (render-language CLP #:nts '(S))
            (htl-append 40
                       ;(ghost (rectangle indent 40))
                       (render-language CLP)))])
    (vc-append 15
               gp
               (hc-append
                (ghost (hline indent 5))
                (hline (+ (pict-width gp) 80) 3))
               (render-reduction-relation R
                                          #:style 'horizontal))))

(define test-P
  (term
   ((((j1 x_1) ←)
     ((j1 (lst x_1 x_2)) ← (j1 x_1) (j1 x_2))))))
#;
(traces R
          (term 
           (,test-P ⊢
                    ((j1 (lst 1 (lst 2 3)))) ∥
                    (():()))))