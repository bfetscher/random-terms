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
  (with-font-params
   (with-atomic-rewriter 
    'number "Literal"
    (with-atomic-rewriter 
     'variable-not-otherwise-mentioned "Variable"
     (with-atomic-rewriter
      'id "Identifier"
      (hc-append 
       40
       (render-language pats #:nts '(P D r a d))
       (render-language pats #:nts '(π s C e δ))
       (render-language base-pats)))))))

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
  (render-metafunction compile #:contract? #t))

(define (compile-M-pict)
  (render-metafunction compile-M #:contract? #t))

(define (compile-M-help-pict)
  (render-metafunction compile-M-help #:contract? #t))

(define (extract-apps-J-pict)
  (render-metafunction extract-apps-D #:contract? #t))

(define (extract-apps-r-pict)
  (render-metafunction extract-apps-r #:contract? #t))

(define (extract-apps-a-pict)
  (render-metafunction extract-apps-a #:contract? #t))

(define (extract-apps-p-pict)
  (render-metafunction extract-apps-p #:contract? #t))

(define (clp-red-pict)
  (with-font-params
   (render-reduction-relation R #:style 'compact-vertical)))

(define (solve-pict)
  (parameterize ([metafunction-pict-style 'up-down])
    (with-all-rewriters
     (render-metafunction solve #:contract? #t))))

(define (solve-cstr-pict)
  (with-compound-rewriter
   'do-subst
   (λ (lws)
     (match lws
       [(list _ _ pi inner-lw _)
        (match inner-lw
          [(lw (list _ inner2-lw ellips _) _ _ _ _ _ _)
           (match inner2-lw
             [(lw (list _ x _ p _) _ _ _ _ _ _)
              (list "" pi "({" x " → " p "} ...)")])])]))
   (render-metafunction solve-cstr #:contract? #t)))

(define (param-elim-pict)
  (parameterize ([metafunction-pict-style 'up-down])
    (with-all-rewriters
     (render-metafunction param-elim #:contract? #t))))


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
              (solve-cstr-pict)
              (solve-pict)
               (param-elim-pict))))