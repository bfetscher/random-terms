#lang racket

(require redex/reduction-semantics
         redex/pict
         slideshow/pict
         "pats.rkt")

(provide (all-defined-out))

(define-extended-language U pats
  ((s t) p)
  (Γ    (Π : Σ : Ω) 
         ⊥)
  (Π    (π ...))
  (Σ    ((x = t) ...))
  (Ω    ((∀ (x ...) (s ≠ t)) ...))
  (π    e d)
  (e   (s = t))
  (d   (∀ (x ...) (s ≠ t))))

(define-metafunction U
  occurs? : x t -> boolean
  [(occurs? x t)
   #t
   (side-condition (member (term x) (term (vars t))))]
  [(occurs? x t)
   #f])

(define-metafunction U
  unify : Π Σ Ω -> (Σ : Ω) or ⊥
  [(unify ((t = t) π ...) Σ Ω)
   (unify (π ...) Σ  Ω)
   (clause-name "identity")]
  [(unify (((lst s ..._1) = (lst t ..._1)) π ...) Σ Ω)
   (unify ((s = t) ... π ...) Σ Ω)
   (side-condition (term (length-eq (s ...) (t ...))))
   (clause-name "decompose")]
  [(unify (((lst s ..._!_1) = (lst t ..._!_1)) π ...) Σ Ω)
   ⊥
   (clause-name "clash")]
  [(unify ((x = t) π ...) Σ Ω)
   ⊥
   (side-condition (term (occurs? x t)))
   (side-condition (term (different x t)))
   (clause-name "occurs")]
  [(unify ((x = t) π ...) (π_s ...) (d ...))
   (unify ((subst-c/dq π x t) ...) ((x = t) (subst-c/dq π_s x t) ...) ((subst-c/dq d x t) ...))
   (clause-name "variable elim")]
  [(unify ((t = x) π ...) Σ Ω)
   (unify ((x = t) π ...) Σ Ω)
   (clause-name "orient")]
  [(unify () Σ Ω)
   (Σ : Ω)
   (clause-name "success")])

(define-metafunction/extension unify U
  [(DU ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...)) 
   ⊥
   (where (() : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(DU ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...)) 
   (DU (π ...) Σ (d ...))
   (where ⊥ (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(DU ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...))
   (DU (π ...) Σ ((∀ (x ...) ((lst x_s ...) ≠ (lst t_s ...))) d ...))
   (where (((x_s = t_s) ...) : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(DU (π ...) Σ (π_1 ... (∀ (x_a ...) ((lst (lst s ...) ... ) ≠ (lst t ...))) π_2 ...))
   (DU ((∀ (x_a ...) ((lst (lst s ...) ...) ≠ (lst t ...))) π ...) Σ (π_1 ... π_2 ...))
   (clause-name "resimplify")])

(define-metafunction U
  [(solve ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...)) 
   (solve (π ...) Σ (d ...))
   (where ⊥ (param-elim (solve ((s = t)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(solve ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...)) 
   ⊥
   (where (() : ()) (param-elim (solve ((s = t)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(solve ((∀ (x ...) (s ≠ t)) π ...) Σ (d ...))
   (solve (π ...) Σ ((∀ (x ...) ((lst x_s ...) ≠ (lst t_s ...))) d ...))
   (where (((x_s = t_s) ...) : ()) (param-elim (solve ((s = t)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(solve (π ...) Σ (π_1 ... (∀ (x_a ...) ((lst (lst s ...) ... ) ≠ (lst t ...))) π_2 ...))
   (solve ((∀ (x_a ...) ((lst (lst s ...) ...) ≠ (lst t ...))) π ...) Σ (π_1 ... π_2 ...))
   (clause-name "resimplify")]
  [(solve ((t = t) π ...) Σ Ω)
   (solve (π ...) Σ  Ω)
   (clause-name "identity")]
  [(solve (((lst t ..._1) = (lst s ..._1)) π ...) Σ Ω)
   (solve ((t = s) ... π ...) Σ Ω)
   (clause-name "decompose")]
  [(solve ((x = t) π ...) Σ Ω)
   ⊥
   (side-condition (term (occurs? x t)))
   (side-condition (term (different x t)))
   (clause-name "occurs")]
  [(solve ((x = t) π ...) (π_s ...) (d ...))
   (solve ((subst-c/dq π x t) ...) ((x = t) (subst-c/dq π_s x t) ...) ((subst-c/dq d x t) ...))
   (clause-name "variable elim")]
  [(solve ((t = x) π ...) Σ Ω)
   (solve ((x = t) π ...) Σ Ω)
   (clause-name "orient")]
  [(solve (((lst t ..._!_1) = (lst s ..._!_1)) π ...) Σ Ω)
   ⊥
   (clause-name "clash")]
  [(solve () Σ Ω)
   (Σ : Ω)
   (clause-name "success")])

(define-metafunction U
  [(disunify Π)
   (solve Π () ())])

(define-metafunction U
  [(param-elim (((x_0 = t_0) ... (x = t) (x_1 = t_1) ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = t_0) ... (x_1 = t_1) ...) : ()) (x_2 ... x x_3 ...))
   (clause-name "param-elim-1")]
  [(param-elim (((x_0 = t_0) ... (x_l = x) π_2 ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = t_0) ... (x_1 = x_2) ... π_3 ...) : ()) (x_2 ... x x_3 ...))
   (side-condition (term (not-in x (t_0 ...))))
   (where ((x_1 = x_2) ... π_3 ...) (elim-x x (x_l = x) π_2 ...))
   (clause-name "param-elim-2")]
  [(param-elim ⊥ (x ...))
   ⊥
   (clause-name "param-elim-failed")]
  [(param-elim (Σ : ()) (x ...))
   (Σ : ())
   (clause-name "param-elim-finish")])

(define-metafunction U
  [(elim-x x π ...)
   ,(elim-x-func (term x) (term (π ...)))])

(define (elim-x-func x eqs)
  (define-values (to-elim to-keep)
    (partition (match-lambda [`(,lhs = ,rhs) (eq? rhs x)]) eqs))
  (define lhss
    (map car to-elim))
  (remove-duplicates
   (append
    (for*/list ([r (in-list lhss)] 
                [l (in-list lhss)]
                #:when (not (eq? r l)))
      `(,r = ,l))
    
    to-keep)
   #:key
   (match-lambda [`(,r = ,l) (set r l)])))

(define-metafunction U
  [(∨ (t_l ≠ t_r) ...)
   ((lst t_l ...) ≠ (lst t_r ...))])

(define-metafunction U
  [(unify_d (Π : Σ_0) (x ...))
   (orient-params (() : Σ_1) (x ...))
   (where (Σ_1 : Ω) (unify Π Σ_0 ()))]
  [(unify_d (Π : Σ) (x ...))
   (orient-params ⊥ (x ...))
   (where ⊥ (unify Π Σ ()))])

(define-metafunction U
  [(orient-params ⊥ (x ...))
   ⊥]
  [(orient-params (() : (π_1 ... (t = x) π_2 ...)) (x x_1 ...))
   (orient-params (() : (π_1 ... (x = t) π_2 ...)) (x x_1 ...))
   (side-condition (not (equal? (term t) (term x))))]
  [(orient-params (() : (π ...)) (x x_1 ...))
   (orient-params (() : (π ...)) (x_1 ...))]
  [(orient-params (() : (π ...)) ())
   (() : (π ...))])

(define-metafunction U
  subst-cs : x t (π ...) -> (π ...)
  [(subst-cs x t_x ((s = t) ...))
   (((subst x t_x s) = (subst x t_x t)) ...)])

(define-metafunction U
  [(subst-dq (∀ (x_a ...) (∨ (x_1 ≠ t_1) ...)) x t)
   (∀ (x_a ...) (∨ (subst-c/dq (x_1 ≠ t_1) x t) ...))])

(define-metafunction U
  [(subst-c/dq (s_1 = s_2) x t)
   ((subst x t s_1) = (subst x t s_2))]
  [(subst-c/dq (s_1 ≠ s_2) x t)
   ((subst x t s_1) ≠ (subst x t s_2))]
  [(subst-c/dq (∀ (x_a ...) (s_1 ≠ s_2)) x t)
   (∀ (x_a ...) ((subst x t s_1) ≠ (subst x t s_2)))])

(define-metafunction U
  env->dq : Σ -> (∨ (x ≠ t) ...)
  [(env->dq ((x = t) ...))
   (∨ (x ≠ t) ...)])

(define-metafunction U
  [(different any_1 any_1) #f]
  [(different any_1 any_2) #t])

(define-metafunction U
  [(not-variable x) #f]
  [(not-variable any) #t])

(define-metafunction U
  [(disjoint (any_1 ...) (any_2 ...))
   #t
   (side-condition (andmap (λ (a) (not (member a (term (any_2 ...)))))
                            (term (any_1 ...))))]
  [(disjoint (any_1 ...) (any_2 ...))
   #f])

(define-metafunction U
  [(not-in any_1 (any_2 ...))
   #t
   (side-condition (not (member (term any_1) (term (any_2 ...)))))]
  [(not-in any_1 (any_2 ...))
   #f])

(define-metafunction U
  [(¬ #t) #f]
  [(¬ #f) #t])

(define (wrap-P P)
  `(,P : () : ()))

(define (apply-subst subst init-c)
  (match (for/fold ([e `(,init-c)])
           ([s (in-list subst)])
           (match s
             [`(,x = ,t)
              (term (subst-cs ,x ,t ,e))]))
    [`(,c)
     c]))

(define print-terms (make-parameter #f))

(define (check-u n proc)
  (define num-successes 0)
  (redex-check U (s = t)
               (let ([subst (proc (term (s = t)))])
                 (when (print-terms)
                   (printf "~s -> ~s\n" (term (s = t)) subst))
                 (when (not (equal? subst '⊥))
                   ;(printf "\n~s\n" subst)
                   (set! num-successes (add1 num-successes)))
                 (or (equal? subst '⊥)
                     (redex-match U (t = t)
                                  (apply-subst subst (term (s = t))))))
               #:attempts n)
  (printf "successful unifications: ~s\n" num-successes))

(define (narrow-P-vars P [vars (hash)])
  (match P
    [`(,eq ,eqs ...)
     (define-values (new-eq new-vrs) (narrow-eq-vars eq vars))
     `(,new-eq ,@(narrow-P-vars eqs vars))]
    ['() '()]))

(define (narrow-eq-vars eq vars)
  (match eq
    [`(∀ (,ps ...) (,l ≠ ,r))
     (define-values (new-ps ps-vars) (narrow-vars ps vars))
     (define-values (new-l l-vars) (narrow-e-vars l ps-vars))
     (define-values (new-r r-vars) (narrow-e-vars r l-vars))
     (values `(∀ ,new-ps (,new-l ≠ ,new-r)) r-vars)]
    [`(,l = ,r)
     (define-values (new-l l-vars) (narrow-e-vars l vars))
     (define-values (new-r r-vars) (narrow-e-vars r l-vars))
     (values `(,new-l = ,new-r) r-vars)]))

(define (narrow-e-vars e vars)
  (match e
    [`(lst ,es ...)
     (define-values (new-es new-vs)
       (for/fold ([new-es '()]
                  [new-vs vars])
         ([e es])
         (define-values (new-e new-v) (narrow-e-vars e vars))
         (values (cons new-e new-es) new-v)))
     (values `(lst ,@(reverse new-es)) new-vs)]
    [(? symbol? var)
     (narrow-var var vars)]))

(define (narrow-vars varlist vars)
  (define-values (new-vls new-vs)
    (for/fold ([new-vls '()]
               [new-vs vars])
         ([v varlist])
         (define-values (new-v new-vrs) (narrow-var v new-vs))
      (values (cons new-v new-vls) new-vrs)))
  (values (reverse new-vls) new-vs))

(define narrowed-vars '(l m n o))

(define (narrow-var var vars)
  (define new-v
    (hash-ref vars var
            (λ ()
              (define v (list-ref narrowed-vars 
                                  (random (length narrowed-vars))))
              (set! vars (hash-set vars var v))
              v)))
  (values new-v vars))
   
(define-syntax-rule (utest a b)
  (redex-let U ([(Π_1 : Σ_1 : Ω_1) a])
             (test-equal
              (term (solve Π_1 Σ_1 Ω_1))
              (if (equal? b '⊥) 
                  '⊥
                  (redex-let U ([(Π_2 : Σ_2 : Ω_2) b])
                             (term (Σ_2 : Ω_2)))))))


(module+ 
 test
  
 ;(current-traced-metafunctions 'all)
 
  (utest (term ((((lst)  = (lst))) : () : ()))
        (term (() : () : ())))
 (utest (term ((((lst)  = (lst) )) : ((y = (lst) )) : ()))
        (term (() : ((y = (lst) )) : ())))
 (utest (term ((((lst y) = (lst (lst) )) (y = z)) : () : ()))
        (term (() : ((z = (lst) ) (y = (lst) )) : ())))
 (utest (term ((((lst y (lst) ) = (lst z (lst) )) (y = z)) : () : ()))
        (term (() : ((y = z)) : ())))
 (utest (term ((((lst y (lst) ) = (lst z)) (y = z)) : () : ()))
        '⊥)
 (utest (term ((((lst)  = y) ((lst)  = (lst x))) : () : ()))
        '⊥)
 (utest (term (((y = (lst y)) ((lst)  = (lst) )) : () : ()))
        (term ⊥))
 (utest (term (((y = y) ((lst)  = (lst) )) : () : ()))
        (term (() : () : ())))
 (utest (term (((y = (lst) ) (y = z)) : ((w = (lst y))) : ()))
        (term (() : ((z = (lst)) (y = (lst)) (w = (lst (lst)))) : ())))
 )

(module+
 test
 (test-equal (term (disunify (((lst x x) = (lst (lst)  (lst) )))))
             (term (((x = (lst) )) : ())))
 (test-equal (term (disunify (((lst x x) = (lst (lst)  (lst) )) (∀ () (x ≠ (lst) )))))
             (term ⊥))
 (test-equal (term (disunify (((lst y x) = (lst (lst)  (lst) )))))
             (term (((x = (lst) ) (y = (lst) )) : ())))
 (test-equal (term (disunify (((lst y x) = (lst (lst)  (lst) )) (∀ () (x ≠ y)))))
             (term ⊥))
 (test-equal (term (disunify (((lst y x) = (lst (lst)  (lst) )) (∀ () ((lst x) ≠ (lst y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (lst (lst)  (lst) )) (∀ () (x ≠ (lst y y))))))
             (term (((x = (lst (lst)  (lst) ))) : ((∀ () (∨ (y ≠ (lst) )))))))
 (test-equal (term (disunify ((x = (lst (lst)  (lst) )) (y = (lst) ) (∀ () (x ≠ (lst y y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (lst (lst)  (lst) )) (y = (lst (lst) )) (∀ () (x ≠ (lst y y))))))
             (term (((y = (lst (lst) )) (x = (lst (lst)  (lst) ))) : ())))
 )

(module+
 test
 (test-equal (term (disunify ((x = (lst (lst)  (lst) )) (∀ (y) (x ≠ (lst y y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (lst (lst) )) (∀ (y) (x ≠ (lst y y))))))
             (term (((x = (lst (lst) ))) : ())))
 (test-equal (term (disunify ((x = (lst a b)) (∀ (y) (x ≠ (lst y y))))))
             (term (((x = (lst a b))) : ((∀ (y) (∨ (b ≠ a)))))))
 (test-equal (term (disunify ((x = (lst a b)) (a = (lst) ) (∀ (y) (x ≠ (lst y y))))))
             (term (((a = (lst) ) (x = (lst (lst)  b))) : ((∀ (y) (∨ (b ≠ (lst) )))))))
  (test-equal (term 
               (disunify 
                ((x = (lst a b))
                 (a = b)
                 (∀ (y) (x ≠ (lst y y))))))
              (term ⊥)))
             
             
(module+
    test
  
  (define-syntax-rule (not-failed e)
    (test-predicate
     (λ (t) (not (equal? t '⊥)))
     e))
  
  (test-equal
   (term
    (disunify
     ((∀ (a b) ((lst a b) ≠ x))
      (x = (lst (lst) (lst (lst)))))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify
     ((x = (lst (lst) (lst (lst))))
      (∀ (a b) ((lst a b) ≠ x)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify
     ((∀ (a b) ((lst a a) ≠ x))
      (x = (lst (lst) (lst (lst))))))))
  
  (not-failed
   (term
    (disunify
     ((x = (lst (lst)  (lst (lst))))
      (∀ (a b) ((lst a a) ≠ x))))))
  
  (test-equal
   (term
    (disunify
     ((x = (lst (lst)  (lst (lst))))
      (∀ (c d) (x ≠ (lst c d)))
      (x = (lst a b)))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify
     ((∀ (c d) (x ≠ (lst c d)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify
     ((x = (lst (lst) (lst (lst))))
      (∀ (c d) (x ≠ (lst c c)))
      (x = (lst a b))))))
  
  (not-failed
   (term
    (disunify
     ((∀ (c d) (x ≠ (lst c c)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b))))))
  
  (test-equal
   (term
    (disunify
     ((∀ (c d) (x ≠ (lst c c)))
      (x = (lst (lst) (lst) ))
      (x = (lst a b)))))
   (term ⊥))
  
  )