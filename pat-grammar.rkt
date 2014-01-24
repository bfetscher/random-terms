#lang racket

(require redex/reduction-semantics
         redex/pict
         slideshow/pict)

(provide (all-defined-out))

#;
(define should-be-pats
        (append '(`any
                  `number
                  `string
                  `natural
                  `integer
                  `real
                  `boolean
                  `variable
                  `(variable-except ,var ...)
                  `(variable-prefix ,var)
                  `variable-not-otherwise-mentioned
                  `hole
                  `(nt ,var)
                  `(name ,var ,pat)
                  `(mismatch-name ,var ,pat)
                  `(in-hole ,pat ,pat) ;; context, then contractum
                  `(hide-hole ,pat)
                  `(side-condition ,pat ,condition ,srcloc-expr)
                  `(cross ,var)
                  `(list ,lpat ...)
                  
                   ;; pattern for literals (numbers, strings, prefabs, etc etc etc)
                  (? (compose not pair?)))
                (if (or allow-else? skip-non-recursive?)
                    (list '_)
                    (list))))

(define-language pats-supported
  (p ::= b
         v
         (nt s)
         (:name s p)
         (mismatch-name s p)
         (list p ...)
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

(define (pats-supp-lang-pict)
  (with-atomic-rewriters
   ([':name "name"]
    [':any "any"]
    [':number "number"]
    [':string "string"]
    [':natural "natural"]
    [':integer "integer"]
    [':real "real"]
    [':boolean "boolean"]
    [':variable "variable"]
    [':variable-not-otherwise-mentioned
     "variable-not-otherwise-mentioned"])
   (ht-append 20
    (render-language pats-supported #:nts '(p v))
    (render-language pats-supported #:nts '(b s c)))))
