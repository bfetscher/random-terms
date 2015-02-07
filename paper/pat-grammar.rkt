#lang racket

(require redex/reduction-semantics
         redex/pict
         slideshow/pict
         "common.rkt")

(provide (all-defined-out))

(define-language pats-supported
  (p ::= (nt s)
         (:name s p)
         (mismatch-name s p)
         (:list p ...)
         b
         v
         c)
  (b ::= :any
         :number
         :string
         :natural
         :integer
         :real
         :boolean)
  (v ::= :variable
         (variable-except s ...)
         (variable-prefix s)
         :variable-not-otherwise-mentioned)
  (s ::= symbol)
  (c ::= constant)
  (symbol ::= any)
  (constant ::= any))

(define-extended-language pats-full pats-supported
  (p ::= ....
         :hole
         (:in-hole p p)
         (:hide-hole p)
         (:side-condition p e e)
         (:cross s)))

(define-syntax with-atomic-rewriters
  (syntax-rules ()
    [(with-atomic-rewriters ([sym symrw] rest ...) e)
     (with-atomic-rewriter sym symrw
                           (with-atomic-rewriters (rest ...) e))]
    [(with-atomic-rewriters () e)
     e]))

(define-syntax-rule (with-slp-rws body)
  (with-font-params
   (with-atomic-rewriters
    ([':name "name"]
     [':any "any"]
     [':number "number"]
     [':string "string"]
     [':natural "natural"]
     [':integer "integer"]
     [':real "real"]
     [':list "list"]
     [':boolean "boolean"]
     [':variable "variable"]
     [':variable-not-otherwise-mentioned
      "variable-not-otherwise-mentioned"])
    body)))
  

(define (pats-supp-lang-pict)
  (with-slp-rws
   (ht-append 20
    (render-language pats-supported #:nts '(p v))
    (render-language pats-supported #:nts '(b s c)))))

(define-syntax-rule (slpt t)
  (with-slp-rws
   (render-term pats-supported t)))

