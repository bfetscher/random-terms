#lang racket

(require slideshow/pict
         redex
         redex/pict
         "pats.rkt"
         "program.rkt"
         "disunify-a.rkt"
         "../common.rkt")

(provide (all-defined-out))

(define-extended-language CLP pats)

(define R
  (reduction-relation 
   CLP
   (--> (P ⊢ (π_g a ...) ∥ ((e ...) : (δ ...)))
        (P ⊢ (a ...) ∥ C)
        (where C (solve-cstr π_g (e ...) (δ ...)))
        "new constraint")
   (--> (P ⊢ ((d p_g) a ...) ∥ C)
        (P ⊢ ((p_f = p_g) a_f ... a ...) ∥ C)
        (where (D_0 ... (r_0 ... ((d p_r) ← a_r ...) r_1 ...) D_1 ...) P)
        (where ((d p_f) ← a_f ...) (freshen ((d p_r) ← a_r ...)))
        "reduce")))

(define-metafunction CLP
  solve-cstr : π Σ Ω -> C
  [(solve-cstr π (e ...) (δ ...))
   (solve ((do-subst π ((x = p) ...))) (e ...) (δ ...))
   (where ((x = p) ...) (e ...))])

(define-metafunction CLP
  [(do-subst π ((x = p) ...))
   ,(apply-subst (term ((x = p) ...)) (term π))])

(define-metafunction CLP
  [(freshen ((d p_c) ← a ...))
   ((freshen-l (d p_c)) ← (freshen-l a) ...)
   (side-condition (inc-fresh-index))])

(define-metafunction CLP
  [(freshen-l (d p))
   (d (freshen-p () p))]
  [(freshen-l (∀ (x ...) (p_1 ≠ p_2)))
   (∀ (x ...) ((freshen-p (x ...) p_1) ≠ (freshen-p (x ...) p_2)))])

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

(define-syntax-rule (clpt exp) 
  (with-font-params (render-term CLP exp)))