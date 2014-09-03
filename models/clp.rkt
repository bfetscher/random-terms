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
   (--> (P ⊢ (π_g a ...) ∥ s)
        (P ⊢ (a ...) ∥ C)
        (where ((e ...) : (d ...)) s)
        (where C (solve (,(apply-subst (term (e ...)) (term π_g))) (e ...) (d ...)))
        ;; TODO : this substitution should be happening inside the call to solve!
        "new constraint")
   (--> (P ⊢ ((j p_g) a ...) ∥ s)
        (P ⊢ ((p_f = p_g) a_f ... a ...) ∥ s)
        (where (J_0 ... (r_0 ... ((j p_r) ← a_r ...) r_1 ...) J_1 ...) P)
        (where ((j p_f) ← a_f ...) (freshen ((j p_r) ← a_r ...)))
        "reduce")))


(define-metafunction CLP
  [(freshen ((j p_c) ← a ...))
   ((freshen-l (j p_c)) ← (freshen-l a) ...)
   (side-condition (inc-fresh-index))])

(define-metafunction CLP
  [(freshen-l (j p))
   (j (freshen-p () p))]
  [(freshen-l (∀ (x ...) (p_1 ≠ p_2)))
   (∀ (x ...) ((freshen-p (x ...) p_1) ≠ (freshen-p (x ...) p_2)))])

(define clp-pict
  (render-reduction-relation R
                             #:style 'horizontal))

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
  (text-scale (render-term CLP exp)))