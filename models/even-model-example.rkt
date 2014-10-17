#lang racket
(require redex 
         "clp.rkt"
         "pats.rkt")

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

(define awkward-even-P
  (term ((((even (lst 2 0)) ←)
          ((even (lst 2 (lst 1 (lst 1 n)))) ← (evenp (lst 2 n)))
          ((even (lst 3 n_1)) 
           ← 
           (∀ (n_2) (∨ ((lst 3 n_1)
                        ≠ 
                        (lst (evenp (lst 2 n_2))
                             (lst 1 (lst 1 n_2))))))
           (∀ () (∨ (n_1 ≠ 0))))))))

(parameterize ([caching-enabled? #f])
  (traces R
          (term 
           (,awkward-even-P
            ⊢
            ((even (lst 3 n))) ∥
            (∧ (∧) (∧))))))
