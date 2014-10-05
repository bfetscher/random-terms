#lang racket

(require redex
         "pats.rkt")

(provide (all-defined-out))

(define-extended-language program pats/mf)

(define-metafunction program
  compile : P -> (D ...)
  [(compile ((r ...) ...))
   ((extract-apps-D (r ...)) ...)]
  [(compile (D_0 ... M D_1 ...))
   (compile (D_0 ... (compile-M M) D_1 ...))])

(define-metafunction program
  compile-M : M -> D
  [(compile-M M)
   ,(parameterize ([fresh-index 0])
      (term (compile-M-help (freshen-cases M))))])

(define-metafunction program
  compile-M-help : M -> D
  [(compile-M-help (((f p_in) = p_out)))
   (((f (lst p_in p_out)) ←))]
  [(compile-M-help (((f_0 p_1) = p_2) ... ((f p_in) = p_out)))
   (r ... ((f (lst p_in p_out)) ← (∀ (vars p_1) (∨ (p_1 ≠ p_in))) ...))
   (where (r ...) (compile-M-help (((f_0 p_1) = p_2) ...)))])

(define-metafunction program
  freshen-cases : M -> M
  [(freshen-cases ()) 
   ()]
  [(freshen-cases (((f p_1) = p_2) c ...))
   (((f (freshen-p () p_1)) = (freshen-p () p_2)) c_f ...)
   (where (c_f ...) (freshen-cases (c ...)))
   (side-condition (inc-fresh-index))])

(define-metafunction program
  [(freshen-p (x ...) (lst p ...))
   (lst (freshen-p (x ...) p) ...)]
  [(freshen-p (x ...) (f p))
   (f (freshen-p (x ...) p))]
  [(freshen-p (x ...) m)
   m]
  [(freshen-p (x_0 ... x x_1 ...) x)
   x]
  [(freshen-p (x_0 ...) x)
   ,(fresh-v (term x))])

(define fresh-index (make-parameter 0))

(define (inc-fresh-index)
  (fresh-index (add1 (fresh-index)))
  ;(printf "~s\n" (fresh-index))
  #t)

(define (fresh-v x)
  (string->symbol
   (string-append
    (symbol->string x)
    "_"
    (number->string (fresh-index)))))

(module+ test
  (require rackunit)
  (check-equal?
   (term
    (compile-M
     (((f (lst x_1 x_2)) = 2)
      ((f x) = 1))))
   (term
    (((f (lst (lst x_1_2 x_2_2) 2)) ←)
     ((f (lst x_1 1)) ← (∀ (x_1_2 x_2_2) (∨ ((lst x_1_2 x_2_2) ≠ x_1))))))))

(define-metafunction program
  extract-apps-D : (r ...) -> (r ...)
  [(extract-apps-D (r ...))
   ((extract-apps-r r) ...)])

(define-metafunction program
  extract-apps-r : r -> r
  [(extract-apps-r ((d p) ← a ...))
   ((d p_0) ← a_0 ... (f_1 p_1) ... (f_2 p_2) ... ...)
   (where (p_0 ((f_1 p_1) ...)) (extract-apps-p p))
   (where ((a_0 ((f_2 p_2) ...)) ...) ((extract-apps-a a) ...))])

(define-metafunction program
  extract-apps-a : a -> (a (a ...))
  [(extract-apps-a (d p))
   ((d p_0) ((f_1 p_1) ...))
   (where (p_0 ((f_1 p_1) ...)) (extract-apps-p p))]
  ;; we know these don't have any apps because
  ;; p_1 and p_2 come from the lhs of a metafunction and
  ;; thus must be actual pats, not term-pats...
  ;; need a nice way to work this in
  [(extract-apps-a (∀ (x ...) (∨ (p_1 ≠ p_2))))
   ((∀ (x ...) (∨ (p_1 ≠ p_2))) ())])

(define-metafunction program
  extract-apps-p : p -> (p (a ...))
  [(extract-apps-p (f p_0))
   (x ((f (lst p x)) (f_1 p_1) ...))
   (where x (fresh-var x))
   (where (p ((f_1 p_1) ...)) (extract-apps-p p_0))]
  [(extract-apps-p (lst p ...))
   ((lst p_1 ...) ((f_2 p_2) ... ...))
   (where ((p_1 ((f_2 p_2) ...)) ...) ((extract-apps-p p) ...))]
  [(extract-apps-p x)
   (x ())]
  [(extract-apps-p m)
   (m ())])


(define fresh-inc (make-parameter 0))

(define-metafunction program
  [(fresh-var x)
   ,(begin0
      (string->symbol
       (string-append
        (symbol->string (term x)) "_"
        (number->string (fresh-inc))))
      (fresh-inc (add1 (fresh-inc))))])

(module+ test
  (parameterize ([fresh-inc 100])
    (check-equal?
     (term
      (compile
       ((((f (lst x_1 x_2)) = 2)
         ((f x) = 1))
        (((J (lst 1 1)) ←)
         ((J (lst x_1 (f x_1))) ← (J (lst 1 1)))))))
     (term
      ((((f (lst (lst x_1_2 x_2_2) 2)) ←)
        ((f (lst x_1 1)) ← (∀ (x_1_2 x_2_2) (∨ ((lst x_1_2 x_2_2) ≠ x_1)))))
       (((J (lst 1 1)) ←)
        ((J (lst x_1 x_100)) ← (J (lst 1 1)) (f (lst x_1 x_100))))))))
  (parameterize ([fresh-inc 100])
    (check-equal?
     (term
      (compile
       ((((g (lst x_1 x_2)) = 2)
         ((g x) = 1))
        (((q (lst 1 1)) ←)
         ((q (lst x_1 (g x_1))) ← (q (lst 1 1)))))))
     (term
      ((((g (lst (lst x_1_2 x_2_2) 2)) ←)
        ((g (lst x_1 1)) ← (∀ (x_1_2 x_2_2) (∨ ((lst x_1_2 x_2_2) ≠ x_1)))))
       (((q (lst 1 1)) ←)
        ((q (lst x_1 x_100)) ← (q (lst 1 1)) (g (lst x_1 x_100)))))))))
  
  