#lang racket

(require redex/pict
         slideshow/pict
         "pats.rkt"
         "program.rkt"
         "clp.rkt"
         "disunify-a.rkt"
         "du-typesetting.rkt")

(provide (all-defined-out))

;; TODO: fix layout

(define (pats-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Variable"
   (with-atomic-rewriter
    'number "Literal"
    (with-atomic-rewriter 
     'id "Identifier"
     (render-language pats #:nts '(p x a f j))))))

(define (program-lang-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Judgment id"
   (render-language program #:nts '(P D J M r c a))))

(define (compile-pict)
  (render-metafunction compile))

(define (compile-M-pict)
  (render-metafunction compile-M))

(define (extract-apps-J-pict)
  (render-metafunction extract-apps-J))

(define (extract-apps-r-pict)
  (render-metafunction extract-apps-r))

(define (extract-apps-a-pict)
  (render-metafunction extract-apps-a))

(define (extract-apps-p-pict)
  (render-metafunction extract-apps-p))

(define (clp-lang-pict)
  (render-language CLP))

(define (clp-red-pict)
  (render-reduction-relation R
                             #:style 'horizontal))

(define (solve-pict)
  (with-all-rewriters
   (render-metafunction solve)))

(define (param-elim-pict)
  (with-all-rewriters
   (render-metafunction param-elim)))

(define (all-lang-pict)
  (htl-append 40
   (program-lang-pict)
   (clp-lang-pict)
   (pats-pict)))

(define (big-pict)
  (vc-append 
   40
   (all-lang-pict)
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
  (param-elim-pict)))