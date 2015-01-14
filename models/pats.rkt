#lang racket

(require redex/reduction-semantics)

(provide (all-defined-out))

(define-language base-pats
  (p (lst p ...)
     m
     x)
  (m number)
  (x variable-not-otherwise-mentioned))

(define-extended-language base-pats/mf base-pats
  (p ....
     (f p)))

(define-extended-language pats base-pats
  (P (D ...))
  (D (r ...))
  (r ((d p) ← a ...))
  (a (d p) δ)
  (C (∧ (∧ (x = p) ...) 
        (∧ δ ...)))
  (e (p = p))
  (δ (∀ (x ...) (∨ (p ≠ p) ...)))
  (d id)
  (id variable-not-otherwise-mentioned))

(define-extended-language pats/mf pats
  (p ....
     (f p))
  (D ....
     M)
  (M (c ...))
  (c ((f p) = p))
  (f id))

(define-metafunction pats
  vars : p -> (x ...)
  [(vars (lst p ...))
   (x_1 ... ...)
   (where ((x_1 ...) ...) ((vars p) ...))]
  [(vars x_new)
   (x_new)]
  [(vars m)
   ()])

(define-metafunction pats
  subst : x p p -> p
  [(subst x p x)
   p]
  [(subst x_1 p x_2)
   x_2]
  [(subst x p (lst p_1 ...))
   (lst (subst x p p_1) ...)]
  [(subst x p m)
   m])


