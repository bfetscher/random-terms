#lang racket

(require slideshow/pict
         redex
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
        (where C (solve e_g s))
        "new constraint")
   (--> (P ⊢ ((j p_g) g ...) ∥ s)
        (P ⊢ ((p_f = p_g) L_f ... g ...) ∥ s)
        (where (J_0 ... (r_0 ... ((j p_r) ← L_r ...) r_1 ...) J_1 ...) P)
        (where (((j p_f) ← L_f ...)) (freshen ((j p_r) ← L_r ...)))
        "reduce")))

(define-metafunction CLP
  [(D (P ⊢ (e_g g ...) ∥ C_0))
   (D (P ⊢ (g ...) ∥ C))
   (where C (add-constraint C_0 e_g))]
  [(D (P ⊢ ((J p_g ...) g ...) ∥ C))
   (D (P ⊢ ((p_f = p_g) ... L_f ... g ...) ∥ C))
   (where ((J p_r ...) ← L_r ...) (select J P))
   (where ((J p_f ...) ← L_f ...) (freshen ((J p_r ...) ← L_r ...)))]
  [(D (P ⊢ (c_g g ...) ∥ C_0))
   (P ⊢ () ∥ ⊥)
   (where ⊥ (add-constraint C_0 c_g))])

;; TODO : implement the following....
(define-metafunction CLP
  [(freshen any ...)
   (any ...)])

(define-metafunction CLP
  [(add-constraint (c ...) c_1)
   (c_1 c ...)])

(define-metafunction CLP
  [(select any ...)
   (any ...)])

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