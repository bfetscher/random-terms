#lang racket

(require redex)

(provide (all-defined-out))

(define-language pats
  (p ::= (lst p ...)
         x
         a)
  (x ::= variable-not-otherwise-mentioned)
  (a ::= number))

(define-extended-language pterms pats
  (p ::= ....
         (f p))
  (f ::= variable-not-otherwise-mentioned))

(define-metafunction pats
  vars : p -> (x ...)
  [(vars (lst p ...))
   (x_1 ... ...)
   (where ((x_1 ...) ...) ((vars p) ...))]
  [(vars x_new)
   (x_new)]
  [(vars a)
   ()])

(define-metafunction pats
  subst : x p p -> p
  [(subst x p x)
   p]
  [(subst x_1 p x_2)
   x_2]
  [(subst x p (lst p_1 ...))
   (lst (subst x p p_1) ...)]
  [(subst x p a)
   a])


