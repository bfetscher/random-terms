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

(define-syntax-rule (with-rewriters/params body)
  (with-font-params
   (with-all-rewriters
    body)))

(define (init-lang)
  (with-font-params
   (with-atomic-rewriter 
    'number "Literal"
    (with-atomic-rewriter 
     'variable-not-otherwise-mentioned "Variable"
     (with-atomic-rewriter
      'id "Identifier"
      (let ()
        (define programs 
          (render-language pats #:nts '(P D r a d)))
        (define formulas
          (render-language pats #:nts '(C e δ)))
        (define patterns
          (render-language base-pats))
        
        (define bkg 
          (blank 0 (max (pict-height programs)
                        (pict-height formulas)
                        (pict-height patterns))))
        (define (add-label p label)
          (vc-append 
           10
           (lb-superimpose bkg p)
           ;; wrong font!
           (text label)))
        (hc-append 40 
                   (add-label programs "Programs")
                   (add-label formulas "Formulas")
                   (add-label patterns "Patterns"))))))))
                   

(define (lang-pict)
  (with-atomic-rewriter
   'variable-not-otherwise-mentioned "Variable"
   (with-atomic-rewriter
    'number "Literal"
    (with-atomic-rewriter 
     'id "Identifier"
     (htl-append 
      40
      (render-language base-pats)
      (render-language pats)
      (render-language base-pats/mf)
      (render-language pats/mf))))))

(define (compile-pict)
  (with-rewriters/params
   (render-metafunction compile #:contract? #t)))

(define (compile-M-pict)
  (with-rewriters/params
   (render-metafunction compile-M #:contract? #t)))

(define (compile-M-help-pict)
  (with-rewriters/params
   (render-metafunction compile-M-help #:contract? #t)))

(define (extract-apps-J-pict)
  (with-rewriters/params
   (render-metafunction extract-apps-D #:contract? #t)))

(define (extract-apps-r-pict)
  (with-rewriters/params
   (render-metafunction extract-apps-r #:contract? #t)))

(define (extract-apps-a-pict)
  (with-rewriters/params
   (render-metafunction extract-apps-a #:contract? #t)))

(define (extract-apps-p-pict)
  (with-rewriters/params
   (render-metafunction extract-apps-p #:contract? #t)))

(define (clp-red-pict)
  (with-rewriters/params
   (render-reduction-relation R #:style 'compact-vertical)))

(define (solve-pict [contract? #t])
  (parameterize ([metafunction-pict-style 'left-right/vertical-side-conditions])
    (with-rewriters/params
     (render-metafunction solve #:contract? contract?))))

(define (dis-solve-pict [contract? #t])
  (parameterize ([metafunction-pict-style 'left-right/vertical-side-conditions])
    (with-rewriters/params
     (render-metafunction dis-solve #:contract? contract?))))

(define (unify-pict [contract? #t])
  (parameterize ([metafunction-pict-style 'left-right])
    (with-rewriters/params
     (render-metafunction unify #:contract? contract?))))

(define (disunify-pict [contract? #t])
  (parameterize ([metafunction-pict-style 'left-right])
    (with-rewriters/params
     (render-metafunction disunify #:contract? contract?))))

(define (check-pict [contract? #t])
  (parameterize ([metafunction-pict-style 'left-right])
    (with-rewriters/params
     (render-metafunction check #:contract? contract?))))


(define (param-elim-pict)
  (with-rewriters/params
   (vl-append
    (parameterize ([metafunction-pict-style 'up-down]
                   [metafunction-cases '(0 1)])
      (with-all-rewriters
       (render-metafunction param-elim)))
    (parameterize ([metafunction-pict-style 'left-right]
                   [metafunction-cases '(2 3)])
      (with-all-rewriters
       (render-metafunction param-elim))))))


(define (big-pict)
  (with-font-params
   (vc-append 
    40
    (lang-pict)
    (vl-append 40
               (vl-append 10
                          (compile-pict)
                          (compile-M-pict)
                          (compile-M-help-pict))
               (vl-append 10
                          (extract-apps-J-pict)
                          (extract-apps-r-pict)
                          (extract-apps-a-pict)
                          (extract-apps-p-pict))
               (clp-red-pict)))))

(define (big-pict-2)
  (with-font-params
   (vl-append 40
              (solve-pict)
              (dis-solve-pict)
              (unify-pict)
              (disunify-pict)
              (check-pict)
              (param-elim-pict))))