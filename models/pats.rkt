#lang racket

(require redex)

(provide (all-defined-out))

(define-language pats
  (p ::= (cons p p)
         nil
         x
         a)
  (x ::= variable-not-otherwise-mentioned)
  (a ::= number))

(define-extended-language pterms pats
  (p ::= ....
         (f p))
  (f ::= variable-not-otherwise-mentioned))

(define (pats-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Variables"
   (with-atomic-rewriter
    'number "Literal"
    (render-language pats))))

(define (pterms-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Metafuction id"
   (render-language pterms)))


