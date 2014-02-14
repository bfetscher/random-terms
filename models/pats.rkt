#lang racket

(require redex/reduction-semantics)

(provide (all-defined-out))

(define-language pats
  (P (D ...))
  (D J M)
  (J (r ...))
  (M (c ...))
  (r ((j p) ← a ...))
  (c ((f p) = p))
  (a (j p) d)
  (S (P ⊢ (l ...) ∥ C))
  (C s ⊥)
  (s ((e ...) : (d ...)))
  (Γ (Π : Σ : Ω) 
     ⊥)
  (Π (π ...))
  (Σ (e ...))
  (Ω (d ...))
  (π e d)
  (e (p = p))
  (d (∀ (x ...) (p ≠ p)))
  (p (lst p ...)
     (f p)
     m
     x)
  (m number)
  (x variable-not-otherwise-mentioned)
  ((f j) id)
  (id variable-not-otherwise-mentioned))

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


