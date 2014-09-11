#lang racket

(require redex/reduction-semantics
         redex/pict
         slideshow/pict
         "pats.rkt")

(provide (all-defined-out))

(define-extended-language U pats)

(define-metafunction U
  occurs? : x p -> boolean
  [(occurs? x p)
   #t
   (side-condition (member (term x) (term (vars p))))]
  [(occurs? x p)
   #f])

(define-metafunction U
  unify : Π Σ Ω -> (Σ : Ω) or ⊥
  [(unify ((p = p) π ...) Σ Ω)
   (unify (π ...) Σ  Ω)
   (clause-name "identity")]
  [(unify (((lst p_1 ..._1) = (lst p_2  ..._1)) π ...) Σ Ω)
   (unify ((p_1 = p_2) ... π ...) Σ Ω)
   (side-condition (term (length-eq (p_1...) (p_2  ...))))
   (clause-name "decompose")]
  [(unify (((lst p_1 ..._!_1) = (lst p_2 ..._!_1)) π ...) Σ Ω)
   ⊥
   (clause-name "clash")]
  [(unify ((x = p) π ...) Σ Ω)
   ⊥
   (side-condition (term (occurs? x p)))
   (side-condition (term (different x p)))
   (clause-name "occurs")]
  [(unify ((x = p) π ...) (π_s ...) (δ ...))
   (unify ((subst-c/dq π x p) ...) ((x = p) (subst-c/dq π_s x p) ...) ((subst-c/dq δ x p) ...))
   (clause-name "variable elim")]
  [(unify ((p = x) π ...) Σ Ω)
   (unify ((x = p) π ...) Σ Ω)
   (clause-name "orient")]
  [(unify () Σ Ω)
   (Σ : Ω)
   (clause-name "success")])

(define-metafunction/extension unify U
  [(DU ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...)) 
   ⊥
   (where (() : ()) (param-elim (unify ((p_1 = p_2)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(DU ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...)) 
   (DU (π ...) Σ (δ ...))
   (where ⊥ (param-elim (unify ((p_1= p_2)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(DU ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...))
   (DU (π ...) Σ ((∀ (x ...) ((lst x_s ...) ≠ (lst p_s ...))) δ ...))
   (where (((x_s = p_s) ...) : ()) (param-elim (unify ((p_1 = p_2)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(DU (π ...) Σ (π_1 ... (∀ (x_a ...) ((lst (lst p_1 ...) ... ) ≠ (lst p_2  ...))) π_2 ...))
   (DU ((∀ (x_a ...) ((lst (lst p_1 ...) ...) ≠ (lst p_2  ...))) π ...) Σ (π_1 ... π_2 ...))
   (clause-name "resimplify")])

(define-metafunction U
  [(solve ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...)) 
   (solve (π ...) Σ (δ ...))
   (where ⊥ (param-elim (solve ((p_1 = p_2)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(solve ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...)) 
   ⊥
   (where (() : ()) (param-elim (solve ((p_1 = p_2)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(solve ((∀ (x ...) (p_1 ≠ p_2)) π ...) Σ (δ ...))
   (solve (π ...) Σ ((∀ (x ...) ((lst x_s ...) ≠ (lst p_s ...))) δ ...))
   (where (((x_s = p_s) ...) : ()) (param-elim (solve ((p_1 = p_2)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(solve (π ...) Σ (π_1 ... (∀ (x_a ...) ((lst (lst p_1 ...) ... ) ≠ (lst p_2  ...))) π_2 ...))
   (solve ((∀ (x_a ...) ((lst (lst p_1 ...) ...) ≠ (lst p_2  ...))) π ...) Σ (π_1 ... π_2 ...))
   (clause-name "resimplify")]
  [(solve ((p = p) π ...) Σ Ω)
   (solve (π ...) Σ  Ω)
   (clause-name "identity")]
  [(solve (((lst p_1  ..._1) = (lst p_2 ..._1)) π ...) Σ Ω)
   (solve ((p_1 = p_2) ... π ...) Σ Ω)
   (clause-name "decompose")]
  [(solve ((x = p) π ...) Σ Ω)
   ⊥
   (side-condition (term (occurs? x p)))
   (side-condition (term (different x p)))
   (clause-name "occurs")]
  [(solve ((x = p) π ...) (π_s ...) (δ ...))
   (solve ((subst-c/dq π x p) ...) ((x = p) (subst-c/dq π_s x p) ...) ((subst-c/dq δ x p) ...))
   (clause-name "variable elim")]
  [(solve ((p = x) π ...) Σ Ω)
   (solve ((x = p) π ...) Σ Ω)
   (clause-name "orient")]
  #;[(solve (((lst p_2 ..._!_1) = (lst p_1 ..._!_1)) π ...) Σ Ω)
   ⊥
   (clause-name "clash")]
  [(solve ((p_1 = p_2) π ...) Σ Ω) ;; everything valid is covered?
   ⊥
   (clause-name "clash")]
  [(solve () Σ Ω)
   (Σ : Ω)
   (clause-name "success")])

(define-metafunction U
  [(disunify Π)
   (solve Π () ())])

(define-metafunction U
  [(param-elim (((x_0 = p_0) ... (x = p) (x_1 = p_1) ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = p_0) ... (x_1 = p_1) ...) : ()) (x_2 ... x x_3 ...))
   (clause-name "param-elim-1")]
  [(param-elim (((x_0 = p_0) ... (x_l = x) π_2 ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = p_0) ... (x_1 = x_2) ... π_3 ...) : ()) (x_2 ... x x_3 ...))
   (side-condition (term (not-in x (p_0 ...))))
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
  [(∨ (p_l ≠ p_r) ...)
   ((lst p_l ...) ≠ (lst p_r ...))])

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
  [(orient-params (() : (π_1 ... (p = x) π_2 ...)) (x x_1 ...))
   (orient-params (() : (π_1 ... (x = p) π_2 ...)) (x x_1 ...))
   (side-condition (not (equal? (term p) (term x))))]
  [(orient-params (() : (π ...)) (x x_1 ...))
   (orient-params (() : (π ...)) (x_1 ...))]
  [(orient-params (() : (π ...)) ())
   (() : (π ...))])

(define-metafunction U
  subst-cs : x p (π ...) -> (π ...)
  [(subst-cs x p_x ((p_1 = p_2) ...))
   (((subst x p_x p_1) = (subst x p_x p_2)) ...)])

(define-metafunction U
  [(subst-dq (∀ (x_a ...) (∨ (x_1 ≠ p_1) ...)) x p)
   (∀ (x_a ...) (∨ (subst-c/dq (x_1 ≠ p_1) x p) ...))])

(define-metafunction U
  [(subst-c/dq (p_1 = p_2) x p)
   ((subst x p p_1) = (subst x p p_2))]
  [(subst-c/dq (p_1 ≠ p_2) x p)
   ((subst x p p_1) ≠ (subst x p p_2))]
  [(subst-c/dq (∀ (x_a ...) (p_1 ≠ p_2)) x p)
   (∀ (x_a ...) ((subst x p p_1) ≠ (subst x p p_2)))])

(define-metafunction U
  env->dq : Σ -> (∨ (x ≠ p) ...)
  [(env->dq ((x = p) ...))
   (∨ (x ≠ p) ...)])

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
  (for/fold ([e init-c])
    ([s (in-list subst)])
    (match s
      [`(,x = ,t)
       (term (subst-c/dq ,e ,x ,t))])))

(define print-terms (make-parameter #f))

(define (check-u n proc)
  (define num-successes 0)
  (redex-check U (p_1 = p)
               (let ([subst (proc (term (p_1 = p)))])
                 (when (print-terms)
                   (printf "~s -> ~s\n" (term (p_1 = p)) subst))
                 (when (not (equal? subst '⊥))
                   ;(printf "\n~s\n" subst)
                   (set! num-successes (add1 num-successes)))
                 (or (equal? subst '⊥)
                     (redex-match U (t = t)
                                  (apply-subst subst (term (p_1 = p))))))
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
      (∀ (c e) (x ≠ (lst c e)))
      (x = (lst a b)))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify
     ((∀ (c e) (x ≠ (lst c e)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify
     ((x = (lst (lst) (lst (lst))))
      (∀ (c e) (x ≠ (lst c c)))
      (x = (lst a b))))))
  
  (not-failed
   (term
    (disunify
     ((∀ (c e) (x ≠ (lst c c)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b))))))
  
  (test-equal
   (term
    (disunify
     ((∀ (c e) (x ≠ (lst c c)))
      (x = (lst (lst) (lst) ))
      (x = (lst a b)))))
   (term ⊥))
  
  )