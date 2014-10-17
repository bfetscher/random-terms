#lang racket
(require redex 
         "clp.rkt"
         "pats.rkt"
         "program.rkt")

;; This is the Redex code for the example below:
(let ()
  (define-language L
    (n ::= z (s n)))
  
  (define-metafunction L
    [(evenp (s (s n))) (evenp n)]
    [(evenp z) true]
    [(evenp n) false])
  
  (test-equal (term (evenp z)) (term true))
  (test-equal (term (evenp (s z))) (term false))
  (test-equal (term (evenp (s (s z)))) (term true))
  (test-equal (term (evenp (s (s (s z))))) (term false))
  
  (define-judgment-form L
    #:mode (odd I)
    [(where false (evenp n))
     --------
     (odd n)])
  
  (test-equal (judgment-holds (odd z)) #f)
  (test-equal (judgment-holds (odd (s z))) #t)
  (test-equal (judgment-holds (odd (s (s z)))) #f)
  (test-equal (judgment-holds (odd (s (s (s z))))) #t)
  
  (define (to-nat n)
    (match n
      [`z 0]
      [`(s ,n) (+ 1 (to-nat n))]))
  
  (define ht (make-hash))
  (for ([x (in-range 100)])
    (define candidate (generate-term L #:satisfying (odd n) 5))
    (define n (and candidate (to-nat (cadr candidate))))
    (hash-set! ht n (+ 1 (hash-ref ht n 0))))
  
  #;
  (printf "found: ~s\n" ht))
;; where we use this to translate into the model:
;;   0 = z
;;   1 = s
;;   2 = true
;;   3 = false
;;   (even (lst <bool> <nat>)) is the shape of 'even'

(define ep
  (term ((((ep (lst 1 (lst 1 n))) = (ep n))
          ((ep 0) = 2)
          ((ep n) = 3)))))

(define epc (parameterize ([fresh-inc 10000]
                           [caching-enabled? #f])
              (term (compile ,ep))))

#|
epc =
'((((ep (lst (lst 1 (lst 1 n_3)) x_10000)) ← 
                                             (ep (lst n_3 x_10000)))
     ((ep (lst 0 2)) ← 
                     (∀ (n_3) (∨ ((lst 1 (lst 1 n_3)) ≠ 0))))
     ((ep (lst n_1 3)) ← 
                       (∀ (n_3) (∨ ((lst 1 (lst 1 n_3)) ≠ n_1))) 
                       (∀ () (∨ (0 ≠ n_1))))))

(∧
  (∧ (n_1_3 = n))
  (∧
   (∀ () (∨ (n ≠ 0)))
   (∀
    (n_3)
    (∨
     (n
      ≠
      (lst
       1
       (lst 1 n_3)))))))

|#

(define awkward-even-P
  (term ((((evenp (lst x (lst 1 (lst 1 n)))) ← (evenp (lst x n)))
          ((evenp (lst 2 0)) ← (∀ (x_2) (∨ (x ≠ 2))))
          ((evenp (lst 3 n_1)) 
           ← 
           (∀ (x_3 n_2) (∨ ((lst 3 n_1)
                            ≠ 
                            (lst x_3 (lst 1 (lst 1 n_2))))))
           (∀ () (∨ (n_1 ≠ 0))))))))

(parameterize ([caching-enabled? #f])
  (traces R
          (term 
           (,awkward-even-P
            ⊢
            ((evenp (lst 3 n))) ∥
            (∧ (∧) (∧))))))
