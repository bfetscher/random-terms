#lang racket

(require redex/pict
         slideshow/pict
         "pats.rkt"
         "program.rkt"
         "clp.rkt")

;; TODO: fix layout

(define (pats-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Variables"
   (with-atomic-rewriter
    'number "Literal"
    (render-language pats))))

(define (pterms-lang-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Metafunction id"
   (render-language pterms)))

(define (program-lang-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Judgment id"
   (render-language program)))

(define (compile-pict)
  (render-metafunction compile))

(define (compile-M-pict)
  (render-metafunction compile-M))

(define (extract-apps-J-pict)
  (render-metafunction extract-apps-J))

(define (extract-apps-r-pict)
  (render-metafunction extract-apps-r))

(define (extract-apps-l-pict)
  (render-metafunction extract-apps-l))

(define (extract-apps-p-pict)
  (render-metafunction extract-apps-p))

(define (clp-lang-pict)
  (render-language CLP))

(define (clp-red-pict)
  (render-reduction-relation R
                             #:style 'compact-vertical))

(define (big-pict)
  (hc-append 40
             (vl-append
              (pats-pict)
              (pterms-lang-pict)
              (program-lang-pict)
              (clp-lang-pict))
             (vl-append 40
                        (clp-red-pict)
                        (vl-append 10
                                   (compile-pict)
                                   (compile-M-pict))
                        (vl-append 10
                                   (extract-apps-J-pict)
                                   (extract-apps-r-pict)
                                   (extract-apps-l-pict)
                                   (extract-apps-p-pict)))))