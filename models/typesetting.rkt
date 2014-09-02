#lang racket

(require redex/pict
         slideshow/pict
         "pats.rkt"
         "program.rkt"
         "clp.rkt"
         "disunify-a.rkt"
         "du-typesetting.rkt"
         "../common.rkt")

(provide (all-defined-out))

;; TODO: fix layout

(define (init-lang)
  (ht-append 
   40
   (render-language pats #:nts '(P D J π))
   (render-language pats #:nts '(a s C e))
   (render-language pats #:nts '(p))))

(define (lang-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Variable"
   (with-atomic-rewriter
    'number "Literal"
    (with-atomic-rewriter 
     'id "Identifier"
     (htl-append 
      40
      (render-language pats #:nts '(P D J M r c a))
      (render-language pats #:nts '(S C s e d))
      (render-language pats #:nts '(Γ Π Σ Ω π))
      (render-language pats #:nts '(p m x f j)))))))

(define (compile-pict)
  (render-metafunction compile #:contract? #t))

(define (compile-M-pict)
  (render-metafunction compile-M #:contract? #t))

(define (extract-apps-J-pict)
  (render-metafunction extract-apps-J #:contract? #t))

(define (extract-apps-r-pict)
  (render-metafunction extract-apps-r #:contract? #t))

(define (extract-apps-a-pict)
  (render-metafunction extract-apps-a #:contract? #t))

(define (extract-apps-p-pict)
  (render-metafunction extract-apps-p #:contract? #t))

(define (clp-red-pict)
  (render-reduction-relation R #:style 'vertical))

(define (solve-pict)
  (with-all-rewriters
   (render-metafunction solve #:contract? #t)))

(define (param-elim-pict)
  (with-all-rewriters
   (render-metafunction param-elim #:contract? #t)))


(define (big-pict)
  (with-font-params
   (vc-append 
    40
    (lang-pict)
   (vl-append 40
              (vl-append 10
                         (compile-pict)
                         (compile-M-pict))
              (vl-append 10
                         (extract-apps-J-pict)
                         (extract-apps-r-pict)
                         (extract-apps-a-pict)
                         (extract-apps-p-pict))
              (clp-red-pict)
              (solve-pict)
              (param-elim-pict)))))