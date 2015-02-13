#lang racket
(require redex
         "models/clp.rkt"
         "models/pats.rkt"
         "models/program.rkt")

(provide awkward-even
         awkward-even-rw
         state->C
         state->a)

;; This is the Redex code for the example below:
(define-language L
  (n ::= z (s n)))

(define-metafunction L
  [(even? z) true]
  [(even? (s (s n))) (even? n)]
  [(even? n) false])

(module+ test
  (test-equal (term (even? z)) (term true))
  (test-equal (term (even? (s z))) (term false))
  (test-equal (term (even? (s (s z)))) (term true))
  (test-equal (term (even? (s (s (s z))))) (term false)))

(define-judgment-form L
  #:mode (odd I)
  [(where false (even? n))
   --------
   (odd n)])

(module+ test
  (test-equal (judgment-holds (odd z)) #f)
  (test-equal (judgment-holds (odd (s z))) #t)
  (test-equal (judgment-holds (odd (s (s z)))) #f)
  (test-equal (judgment-holds (odd (s (s (s z))))) #t))

(define (to-nat n)
  (match n
    [`z 0]
    [`(s ,n) (+ 1 (to-nat n))]))

(module+ test
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

; We can translate the above metafunction (even?) into the model as follows:
; (compile-M in models/program.rkt has the formal definiton of the translation)
(define awkward-even
  (term (((even (lst 2 0)) ←)
         ((even (lst b (lst 1 (lst 1 n)))) ← (even (lst b n)))
         ((even (lst 3 n))
          ← 
          (∀ (n_1) (∨ (n ≠ (lst 1 (lst 1 n_1)))))
          (∀ () (∨ (n ≠ 0)))))))


(define awkward-even-P
  (term (,awkward-even)))

; necessary for because some operations in the model, 
; i.e. freshening, are stateful
(caching-enabled? #f)

; initial state, corresponds to the call: (even? (s (s (s z))))
(define state0
  (term 
   (,awkward-even-P
    ⊢
    ((even (lst 3 (lst 1 (lst 1 (lst 1 0))))))
    ∥
    (∧ (∧) (∧)))))

(define-metafunction pats/mf
  rewrite-pattern : p -> any
  [(rewrite-pattern (lst p_1 p_2)) 
   (lst (rewrite-pattern p_1) (rewrite-pattern p_2))]
  [(rewrite-pattern 1) s]
  [(rewrite-pattern 0) z]
  [(rewrite-pattern 2) true]
  [(rewrite-pattern 3) false]
  [(rewrite-pattern x) x])

(define-metafunction pats/mf
  rewrite-eqn : e -> any
  [(rewrite-eqn (p_1 = p_2))
   ((rewrite-pattern p_1) = (rewrite-pattern p_2))])

(define-metafunction pats/mf
  rewrite-diseqn : δ -> any
  [(rewrite-diseqn (∀ () (∨ (p_1 ≠ p_2))))
   ((rewrite-pattern p_1) ≠ (rewrite-pattern p_2))]
  [(rewrite-diseqn (∀ (x ...) (∨ (p_1 ≠ p_2))))
   (∀ (x ...) ((rewrite-pattern p_1) ≠ (rewrite-pattern p_2)))]
  [(rewrite-diseqn (∀ (x ...) (∨ (p_1 ≠ p_2) ...)))
   (∀ (x ...) (∨ ((rewrite-pattern p_1) ≠ (rewrite-pattern p_2)) ...))])

(define-metafunction pats/mf
  rewrite-C : C -> any
  [(rewrite-C (∧ (∧ e) (∧)))
   (rewrite-eqn e)]
  [(rewrite-C (∧ (∧) (∧ δ)))
   (rewrite-diseqn δ)]
  [(rewrite-C (∧ (∧ e ...) (∧ δ ...)))
   (∧ (rewrite-eqn e) ... (rewrite-diseqn δ) ...)])

(define-metafunction pats/mf
  rewrite-as : (a ...) -> any
  [(rewrite-as ()) ()]
  [(rewrite-as ((d p) a ...))
   ((d (rewrite-pattern p)) any_2 ...)
   (where (any_2 ...) (rewrite-as (a ...)))]
  [(rewrite-as (δ a ...))
   ((rewrite-diseqn δ) any_2 ...)
   (where (any_2 ...) (rewrite-as (a ...)))])

(define-metafunction pats/mf
  rewrite-r : r -> any
  [(rewrite-r ((d p) ← a ...))
   ((d (rewrite-pattern p)) ← any_r ...)
   (where (any_r ...) (rewrite-as (a ...)))])

(define (state->C state) (term (rewrite-C ,(list-ref state 4))))
(define (state->a state) (term (rewrite-as ,(list-ref state 2))))

(define awkward-even-rw
  (redex-let pats/mf 
             ([(r ...) awkward-even])
             (term ((rewrite-r r) ...))))

(define (reduction-pretty-printer v port width text)
  (default-pretty-printer
    (match v
      [`(,program ⊢ ,gs ∥ ,cstrs)
       `(P ⊢ ,(term (rewrite-as ,gs)) ∥ ,(term (rewrite-C ,cstrs)))]
      [else (error 'reduction-pretty-printer "bad reductions state: ~s" v)])
    port width text))

(module+ main
  ; build a reduction graph for state0
  (traces R state0
          #:pp reduction-pretty-printer))

