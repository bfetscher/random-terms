#lang racket

(require slideshow/pict
         redex/reduction-semantics
         redex/pict)

(provide clp-pict)

(define-language CLP
  (S ::= (P ⊢ G ∥ C))
  (P ::= (R ...))
  (G ::= (g ...))
  (C ::= (c ...))
  (g ::= c L)
  (c ::= (p = p))
  (R ::= (L ← L ...))
  (L ::= (J p ...))
  (J ::= variable-not-otherwise-mentioned)
  (p ::= variable-not-otherwise-mentioned))



(define R
  (reduction-relation CLP
                      (--> (P ⊢ (c_g g ...) ∥ C_0)
                           (P ⊢ (g ...) ∥ C)
                           (where C (add-constraint C_0 c_g))
                           "new constraint")
                      (--> (P ⊢ ((J p_g ...) g ...) ∥ C)
                           (P ⊢ ((p_f = p_g) ... L_f ... g ...) ∥ C)
                           (where ((J p_r ...) ← L_r ...) (select J P))
                           (where ((J p_f ...) ← L_f ...) (freshen ((J p_r ...) ← L_r ...)))
                           "reduce")
                      (--> (P ⊢ (c_g g ...) ∥ C_0)
                           (P ⊢ () ∥ ⊥)
                           (where ⊥ (add-constraint C_0 c_g))
                           "invalid constraint")
                      (--> (P ⊢ ((J p_g ...) g ...) ∥ C)
                           (P ⊢ () ∥ ⊥)
                           (where ⊥ (select J P))
                           "invalid literal")))

(define-metafunction CLP
  [(D (P ⊢ (c_g g ...) ∥ C_0))
   (D (P ⊢ (g ...) ∥ C))
   (where C (add-constraint C_0 c_g))]
  [(D (P ⊢ ((J p_g ...) g ...) ∥ C))
   (D (P ⊢ ((p_f = p_g) ... L_f ... g ...) ∥ C))
   (where ((J p_r ...) ← L_r ...) (select J P))
   (where ((J p_f ...) ← L_f ...) (freshen ((J p_r ...) ← L_r ...)))]
  [(D (P ⊢ (c_g g ...) ∥ C_0))
   (P ⊢ () ∥ ⊥)
   (where ⊥ (add-constraint C_0 c_g))])

(define-metafunction CLP
  [(freshen any ...)
   (any ...)])

(define-metafunction CLP
  [(add-constraint any ...)
   (any ...)])

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
                       (render-language CLP
                                        #:nts '(P R L))
                       (render-language CLP
                                        #:nts '(G g c))))])
    (vc-append 15
               gp
               (hc-append
                (ghost (hline indent 5))
                (hline (+ (pict-width gp) 80) 3))
               (render-reduction-relation R
                                          #:style 'horizontal))))