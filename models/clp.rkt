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
   (--> (P ⊢ ((d p_g) a ...) ∥ (∧ (∧ e ...) (∧ δ ...)))
        (P ⊢ (a_f ... a ...) ∥ C)
        (where (D_0 ... (r_0 ... ((d p_r) ← a_r ...) r_1 ...) D_1 ...) P)
        (where ((d p_f) ← a_f ...) (freshen ((d p_r) ← a_r ...)))
        (where C (solve (p_f = p_g) (∧ e ...) (∧ δ ...)))
        "reduce")
   (--> (P ⊢ (δ_g a ...) ∥ (∧ (∧ e ...) (∧ δ ...)))
        (P ⊢ (a ...) ∥ C)
        (where C (dis-solve δ_g (∧ e ...) (∧ δ ...)))
        "new constraint")))

(define-metafunction CLP
  [(freshen ((d p_c) ← a ...))
   ((freshen-l (d p_c)) ← (freshen-l a) ...)
   (side-condition (inc-fresh-index))])

(define-metafunction CLP
  [(freshen-l (d p))
   (d (freshen-p () p))]
  [(freshen-l (∀ (x ...) (∨ (p_1 ≠ p_2) ...)))
   (∀ (x ...) (∨ ((freshen-p (x ...) p_1) ≠ (freshen-p (x ...) p_2)) ...))])

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

(define-syntax-rule (rule-name exp)
  (with-font-params (text exp (label-style) (label-font-size))))
