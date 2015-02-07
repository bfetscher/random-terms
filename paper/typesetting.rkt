#lang racket

(require slideshow/pict
         redex/reduction-semantics
         redex/pict
         "../models/pats.rkt"
         "../models/disunify-a.rkt"
         "../models/du-typesetting.rkt"
         "common.rkt"
         "deriv-layout.rkt"
         (rename-in "../models/typesetting.rkt" 
                    [lang-pict lp]))

(provide lang-pict
         judgment-pict
         f-pict
         J-L
         j-pict/p
         g-p
         g-jdg-pict
         g-of-12
         f-ex-pict
         f-comp-pict
         c-ext-pict
         r-lang-pict
         unify-func-pict
         unify-init-pict
         eqt
         feqt
         fneqt
         incorrect-g-jdg-pict)


(define lang-pict 
  (lp))


(module f1 racket
  
  (require redex
           slideshow/pict)
  
  (define-language L
    (id variable)
    (pattern variable)
    (term variable))
  
  (define-extended-language F-L L
    (p ::= pattern)
    (t ::= term))
  
  (define-metafunction F-L
    [(f p_1) t_1])
  
  (define f1-pict
    (render-metafunction f))
  
  (provide L F-L f1-pict))

(module fn racket
  
  (require redex
           slideshow/pict)
  
  (define-language L
    (id variable)
    (pattern variable)
    (term variable))
  
  (define-extended-language F-L L
    (p ::= pattern)
    (t ::= term))
  
  (define-metafunction F-L
    [(f p_n) t_n])
  
  (define fn-pict
    (render-metafunction f))
  
  (provide fn-pict))

(require 'f1)
(require 'fn)

(define-for-syntax vellipsis (string->symbol " \u22ee "))
(define-syntax (vlterm stx)
  #`(render-term L #,vellipsis))

(define f-pict
  (ht-append 20
             (scale
              (vc-append f1-pict
                         (vlterm)
                         fn-pict)
              1.0)
             (scale
              (render-language F-L)
              1.0)))



(define-extended-language J-L L
  (J ::= id)
  (s ::= p t)
  (p ::= any)
  (t ::= any))

(define-syntax (j-pict stx)
  (syntax-case stx ()
    [(_ n)
     (or (number? (syntax->datum #'n))
         (symbol? (syntax->datum #'n)))
     (let ([^n (λ (sym)
                 (string->symbol
                  (string-append
                   (symbol->string sym)
                   (format "^~s" (syntax->datum #'n)))))])
       #`(let
             ([ps (hbl-append 2
                              (render-term J-L (#,(^n 'J_1) #,'| | #,(^n 's_1) #,'| ...|))
                              (render-term J-L #,'| ... |)
                              (render-term J-L (#,(^n 'J_m) #,'| | #,(^n 's_m) #,'| ...|)))]
              [c (render-term J-L (#,'J_c #,'| | #,'s_c^1 #,'| ... | #,'s_c^k))])
           (vc-append 2
                      ps
                      (hline (max (pict-width ps) (pict-width ps)) 2)
                      c)))]))

(define-language FexL
  (p any)
  (t any)
  (x any))

(define-metafunction FexL
  [(g (lst p_1 p_2)) 2]
  [(g p) 1])

(define f-comp-pict
  (let ()
    (define-metafunction FexL
      [(f p_l) t_r])
    (let* ([f-pic (render-metafunction f)]
           [f 'shadow-f]
           [f-app (render-term J-L (f t_input))]
           [f-a-res (hbl-append
                     f-app
                     (render-term J-L | → |)
                     (render-term J-L t_output))]
           [c (render-term J-L (f p_l p_r))]
           [g (render-term J-L (f p_input p_output))])
      (vc-append
       (ghost (rectangle 15 15))
       (hc-append 20
                  (vc-append 24
                             (text "Definition:")
                             (text "Application:"))
                  (vc-append 20
                             f-pic
                             f-a-res)
                  (arrow 20 0)
                  (vc-append 20
                             (vc-append 2
                                        (hline (pict-width c) 2)
                                        c)
                             g))))))

(define-extended-language c-ext FexL
  (c ::= (p = p)
     (∀ (x ...) p ≠ p)))

(define c-ext-pict
  (vc-append (ghost (rectangle 15 15))
             (render-language c-ext)))


(define (g-p)
  (with-font-params (render-term FexL g)))

(define-syntax-rule (feqt t1 t2)
  (eqt/lang FexL t1 t2))

(define-syntax-rule (fneqt t1 t2)
  (neqt/lang FexL t1 t2))

(define-syntax-rule (∀neqt vars t1 t2)
  (with-font-params
   (hbl-append
    (render-term FexL |(|)
    (render-term FexL ∀)
    (render-term FexL vars)
    space
    (neqt/lang FexL t1 t2)
    (render-term FexL |)|))))

(define (g-jdg-pict)
  (with-font-params
   (hbl-append 
    40
    (infer (eqt (g (lst p_1 p_2)) 2)
           (ghost (∀neqt (p_1 p_2) (lst p_1 p_2) p)))
    (infer (cbl-superimpose (feqt (g p) 1)
                            (ghost (feqt (g (p_1 p_2)) 2)))
           (∀neqt (p_1 p_2) (lst p_1 p_2) p)))))

(define (incorrect-g-jdg-pict)
  (with-font-params
   (hbl-append 
    40
    (infer (eqt (g (lst p_1 p_2)) 2)
           (ghost (∀neqt (p_1 p_2) (lst p_1 p_2) p)))
    (infer (cbl-superimpose (feqt (g p) 1)
                            (ghost (feqt (g (p_1 p_2)) 2)))
           (neqt/lang FexL (lst p_1 p_2) p)))))


(define (f-ex-pict)
  (with-font-params
   (define (align p) 
     (lbl-superimpose p (ghost (render-term FexL | (a b c))|))))
   (hc-append 
    40
    (render-metafunction g)
    (vl-append
     (hbl-append (render-term FexL (g (lst 1 2)))
                 (render-term FexL | = 2|))
     (hbl-append (render-term FexL (g (lst 1 2 3)))
                 (render-term FexL | = 1|))))))

(define g-of-12
  (with-font-params
   (render-term FexL (g (list 1 2)))))

(define j-pict/p
  (let
      ([ps (hbl-append 5
                       (render-term J-L (J_1 p_1 ...))
                       (render-term J-L ... )
                       (render-term J-L (J_m p_m  ...)))]
       [c (render-term J-L (J p_c ...))])
    (vc-append 2
               ps
               (hline (max (pict-width ps) (pict-width ps)) 2)
               c)))

(define judgment-pict
  (vc-append
   (ghost (rectangle 15 15))
   (vc-append 20
              (scale
               (render-language J-L #:nts '(J s))
               1.0)
              (scale
               (hc-append 10
                          (j-pict 1)
                          (render-term L ...)
                          (j-pict n))
               1.0))))

(define-language redex-lang
  (p ::= (list p ...)
     x
     a
     b)
  (t ::= (t ...)
     (f t ...)
     x
     a)
  (a ::= Literal)
  (x ::= Variable)
  (f ::= Metafunction)
  (b ::= built-in)
  (Literal ::= any)
  (Variable ::= any)
  (Non-terminal ::= any)
  (Metafunction ::= any)
  (built-in ::= any))

(define r-lang-pict
  (with-atomic-rewriter 
   ':name "name"
   (with-atomic-rewriter
    'built-in "Built-in Pattern"
    (with-atomic-rewriter
     'Literal "Racket Constant"
     (ht-append 20
                (render-language redex-lang #:nts '(p))
                (render-language redex-lang #:nts '(t))
                (render-language redex-lang #:nts '(a x f b)))))))
  #|
(define (unify-func-pict/contract)
  (vl-append
   (metafunction-signature
   "U" "P" "S" "D" 
   (or-alts "(S : D)" (text "⊥")))))
   
(define (param-elim-func-pict/contract)
  (vl-append
   (metafunction-signature
   "param-elim" (or-alts "(S : ())" (text "⊥")) "(x ...)" 
   (or-alts "(S : ())" (text "⊥")))
   (param-elim-pict)))


(define (du-pict)
  (vl-append 20
             (param-elim-func-pict/contract)))
|#