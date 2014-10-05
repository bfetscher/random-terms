#lang racket

(require redex/reduction-semantics
         (except-in rackunit check)
         "program.rkt"
         "disunify-a.rkt"
         "clp.rkt")

(caching-enabled? #f) ;; variable freshness

(define (reduce/depth t depth)
  (set->list 
   (parameterize ([caching-enabled? #f])
     (let recur ([terms (list t)]
                 [count 0])
       (if (count . > . depth)
           (list->set terms)
           (apply set-union 
                  (map (λ (t)
                         (define reds (apply-reduction-relation R t))
                         (if (empty? reds)
                             (set t)
                             (recur reds (add1 count))))
                       terms)))))))
  
(define (answers ps)
  (map (λ (p) (redex-let program ([(P ⊢ () ∥ (∧ (∧ e ...) (∧ δ ...))) p]) (term (e ...))))
       (filter (λ (p) (redex-match program (P ⊢ () ∥ (∧ (∧ e ...) (∧ δ ...))) p))
               ps)))
                          

;; ========================================
;; program 1
;; natural numbers
;; ========================================
(define P1
  (term ((((sum (lst x 0 x)) ←)
          ((sum (lst x (lst 1 x_2) (lst 1 x_3))) ← (sum (lst x x_2 x_3))))
         (((dummy 1) ←)))))

(check-not-false (redex-match program P P1))

(define P1C (term (compile ,P1)))

(check-equal? P1 P1C)

(define (make-goal g)
  `(,P1C ⊢ (,g) ∥ (∧ (∧) (∧))))

#;(check-equal? (answers (reduce/depth (make-goal '(sum (lst (lst 1 0) 0 x))) 3))
              '((((x = (lst 1 0))) : ())))

(define (answer-contains? ps binds)
  (define answs (answers ps))
  (for/or ([a (in-list answs)])
    (for/and ([b (in-list binds)])
      (member b a))))

(check-not-false (answer-contains? 
                  (reduce/depth (make-goal '(sum (lst (lst 1 0) (lst 1 0) x))) 8)
                  '((x = (lst 1 (lst 1 0))))))

(check-not-false (answer-contains? 
                  (reduce/depth (make-goal '(sum (lst (lst 1 (lst 1 0)) (lst 1 0) x))) 10)
                  '((x = (lst 1 (lst 1 (lst 1 0)))))))

(check-not-false (answer-contains? 
                  (reduce/depth (make-goal '(sum (lst (lst 1 0) (lst 1 (lst 1 0)) x))) 10)
                  '((x = (lst 1 (lst 1 (lst 1 0)))))))

(check-not-false (answer-contains? 
                  (reduce/depth (make-goal '(sum (lst (lst 1 (lst 1 0)) (lst 1 (lst 1 0)) x))) 10)
                  '((x = (lst 1 (lst 1 (lst 1 (lst 1 0))))))))

;; ========================================
;; program 2
;; simply-typed lambda calculus
;; base type of numbers
;; ========================================

;; ``0'' is the only number
(define lam 1)
(define num 2)
(define arr 3)
(define var 4)
(define app 5)
(define fls 6)
;; vars indexed from 10 and up

(define P2
  (term ((((typeof (lst G 0 ,num)) ←)
          ((typeof (lst G (lst ,var x) (lookup (lst x G)))) ←)
          ((typeof (lst G (lst ,lam x x_t e) (lst ,arr x_t t))) ← 
           (typeof (lst (lst x x_t G) e t)))
          ((typeof (lst G (lst ,app e_1 e_2) t)) ←
           (typeof (lst G e_1 (lst ,arr t_1 t)))
           (typeof (lst G e_2 t_1))))
         (((lookup (lst x (lst x x_t G))) = x_t)
          ((lookup (lst x (lst x_2 x_t G))) = (lookup (lst x G)))))))

(check-not-false (redex-match program P P2))

;; just make this big enogh that the two 
;; "types" of fresh vars don't collide
;; the horror...
;; (not an issue in program 1 because it has no metafunctions)
;; TODO fix variable freshness
(define P2C (parameterize ([fresh-inc 10000])
              (term (compile ,P2))))

(check-not-false (redex-match program P P2C))

(define (e-goal e)
  `(,P2C ⊢ ((typeof (lst (lst) ,e t))) ∥ (∧ (∧) (∧))))

(check-not-false (answer-contains?
                  (reduce/depth (e-goal 0) 10)
                  `((t = ,num))))

(check-not-false (empty? (answers (reduce/depth (e-goal `(lst ,var 10)) 
                                                100))))

(check-not-false (answer-contains?
                  (reduce/depth (e-goal `(lst ,lam 10 ,num (lst ,var 10))) 100)
                  `((t = (lst ,arr ,num ,num)))))

(check-not-false (answer-contains?
                  (reduce/depth 
                   (e-goal `(lst ,lam 10 (lst ,arr ,num ,num)
                                 (lst ,lam 11 ,num (lst ,var 10))))
                   100)
                  `((t = (lst ,arr (lst ,arr ,num ,num)
                              (lst ,arr ,num
                                   (lst ,arr ,num ,num)))))))

(check-not-false (answer-contains?
                  (reduce/depth 
                   (e-goal `(lst ,lam 10 (lst ,arr ,num ,num)
                                 (lst ,lam 11 ,num (lst ,var 11))))
                   100)
                  `((t = (lst ,arr (lst ,arr ,num ,num)
                              (lst ,arr ,num ,num))))))

;; use with traces and stepper
(define (pp t a b c)
  (redex-let program ([(P ⊢ any_1 ∥ any_2) t])
             ((dynamic-require 'redex 'default-pretty-printer)
              (term (any_1 ∥ any_2)) a b c)))


