#lang racket

(require redex
         "pats.rkt")

(provide (all-defined-out))

(define-extended-language program pterms
  (P ::= (D ...))
  (D ::= J M)
  (J ::= (r ...))
  (M ::= (c ...))
  (r ::= ((j p) ← (j p) ...))
  (c ::= ((f p) = p))
  (j ::= variable-not-otherwise-mentioned))

(define-extended-language gen-prog program
  (r ::= ((j p) ← l ...))
  (l ::= L c)
  (L ::= (j p))
  (c ::= (∀ (x ...) p ≠ p)))

(define-metafunction gen-prog
  [(compile (J ...))
   ((extract-apps-J J) ...)]
  [(compile (D_0 ... M D_1 ...))
   (compile (D_0 ... (compile-M M) D_1 ...))])

(define-metafunction gen-prog
  compile-M : M -> J
  [(compile-M (((f p_in) = p_out)))
   (((f (cons p_in p_out)) ←))]
  [(compile-M (((f_0 p_1) = p_2) ... ((f p_in) = p_out)))
   (((f (cons p_in p_out)) ← (∀ (vars p_1) p_1 ≠ p_in) ...) r ...)
   (where (r ...) (compile-M (((f_0 p_1) = p_2) ...)))])

(define-metafunction gen-prog
  vars : p -> (x ...)
  [(vars (cons p_1 p_2))
   (x_1 ... x_2 ...)
   (where (x_1 ...) (vars p_1))
   (where (x_2 ...) (vars p_2))]
  [(vars nil)
   ()]
  [(vars x_new)
   (x_new)]
  [(vars a)
   ()])

(module+ test
  (require rackunit)
  (check-equal?
   (term
    (compile-M
     (((f (cons x_1 x_2)) = 2)
      ((f x) = 1))))
   (term
    (((f (cons x 1)) ← (∀ (x_1 x_2) (cons x_1 x_2) ≠ x))
     ((f (cons (cons x_1 x_2) 2)) ←)))))

(define-metafunction gen-prog
  [(extract-apps-J (r ...))
   ((extract-apps-r r) ...)])

(define-metafunction gen-prog
  [(extract-apps-r ((j p) ← l ...))
   ((j p_0) ← l_0 ... (f_1 p_1) ... (f_2 p_2) ... ...)
   (where (p_0 ((f_1 p_1) ...)) (extract-apps-p p))
   (where ((l_0 ((f_2 p_2) ...)) ...) ((extract-apps-l l) ...))])

(define-metafunction gen-prog
  [(extract-apps-l (j p))
   ((j p_0) ((f_1 p_1) ...))
   (where (p_0 ((f_1 p_1) ...)) (extract-apps-p p))]
  ;; we know these don't have any apps because
  ;; p_1 and p_2 come from the lhs of a metafunction and
  ;; thus must be actual pats, not term-pats...
  ;; need a nice way to work this in
  [(extract-apps-l (∀ (x ...) p_1 ≠ p_2))
   ((∀ (x ...) p_1 ≠ p_2) ())])

(define-metafunction gen-prog
  [(extract-apps-p (f p_0))
   (x ((f (cons p x)) (f_1 p_1) ...))
   (where x (fresh-var x))
   (where (p ((f_1 p_1) ...)) (extract-apps-p p_0))]
  [(extract-apps-p (cons p_1 p_2))
   ((cons p_3 p_4) ((f_5 p_5) ... (f_6 p_6) ...))
   (where (p_3 ((f_5 p_5) ...)) (extract-apps-p p_1))
   (where (p_4 ((f_6 p_6) ...)) (extract-apps-p p_2))]
  [(extract-apps-p nil)
   (nil ())]
  [(extract-apps-p x)
   (x ())]
  [(extract-apps-p a)
   (a ())])

(define fresh-inc (make-parameter 0))

(define-metafunction gen-prog
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
       ((((f (cons x_1 x_2)) = 2)
         ((f x) = 1))
        (((J (cons 1 1)) ←)
         ((J (cons x_1 (f x_1))) ← (J (cons 1 1)))))))
     (term
      ((((f (cons x 1)) ← (∀ (x_1 x_2) (cons x_1 x_2) ≠ x))
        ((f (cons (cons x_1 x_2) 2)) ←))
       (((J (cons 1 1)) ←)
        ((J (cons x_1 x_100)) ← (J (cons 1 1)) (f (cons x_1 x_100))))))))
  (parameterize ([fresh-inc 100])
    (check-equal?
     (term
      (compile
       ((((g (cons x_1 x_2)) = 2)
         ((g x) = 1))
        (((q (cons 1 1)) ←)
         ((q (cons x_1 (g x_1))) ← (q (cons 1 1)))))))
     (term
      ((((g (cons x 1)) ← (∀ (x_1 x_2) (cons x_1 x_2) ≠ x))
        ((g (cons (cons x_1 x_2) 2)) ←))
       (((q (cons 1 1)) ←)
        ((q (cons x_1 x_100)) ← (q (cons 1 1)) (g (cons x_1 x_100)))))))))
  
  