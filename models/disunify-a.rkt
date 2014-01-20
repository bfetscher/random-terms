#lang racket

(require redex
         slideshow/pict
         #;(only-in "unify.rkt"
                  unify))

(provide trees
         U
         DU
         param-elim
         U-red
         DU-red
         subst
         vars
         unify)

(define-language trees
  (s t ::= (f t ...) x)
  (x   ::= variable-not-otherwise-mentioned))

(define-extended-language U trees
  (Γ    ::= (P : S : D) 
            ⊥)
  (P    ::= (c ...))
  (S    ::= ((x = t) ...))
  (D    ::= ((∀ (x ...) (s ≠ t)) ...))
  (c    ::= eq dq)
  (eq   ::= (s = t))
  (dq    ::= (∀ (x ...) (s ≠ t))))

#;(define-metafunction U
  [(disunify P)
   (S : D)
   (where (() : S : D) ,(car (apply-reduction-relation* DU-red (term (P : () : ())))))]
  [(disunify P)
   ⊥
   (where ⊥ ,(car (apply-reduction-relation* DU-red (term (P : () : ())))))])

(define-metafunction U
  occurs? : x t -> boolean
  [(occurs? x t)
   #t
   (side-condition (member (term x) (term (vars t))))]
  [(occurs? x t)
   #f])

(define U-red
  (reduction-relation 
   U #:domain Γ
   (--> (((t = t) c ...) : S : D)
        ((c ...) : S : D)
        "identity")
   (--> ((((f t ..._1) = (f s ..._1)) c ...) : S : D)
        (((t = s) ... c ...) : S : D)
        (side-condition (term (different (f t ...) (f s ...))))
        "decompose")
   (--> ((((f t ..._!_1) = (f s ..._!_1)) c ...) : S : D)
        ⊥
        "clash")
   (--> (((t = x) c ...) : S : D)
        (((x = t) c ...) : S : D)
        (side-condition (term (not-variable t)))
        (side-condition (term (different x t)))
        "orient")
   (--> (((x = t) c ...) : S : D)
        ⊥
        (side-condition (term (occurs? x t)))
        (side-condition (term (different x t)))
        "occurs")
   (--> (((x = t) c ...) : (c_s ...) : (dq ...))
        (((subst-c/dq c x t) ...) : ((subst-c/dq c_s x t) ... (x = t)) : ((subst-c/dq dq x t) ...))
        (side-condition (term (¬ (occurs? x t))))
        "variable elim")))

(define-metafunction U
  unify : P S D -> (S : D) or ⊥
  [(unify ((t = t) c ...) S D)
   (unify (c ...) S  D)
   (clause-name "identity")]
  [(unify (((f s ..._1) = (f t ..._1)) c ...) S D)
   (unify ((s = t) ... c ...) S D)
   (side-condition (term (length-eq (s ...) (t ...))))
   (clause-name "decompose")]
  [(unify (((f s ..._!_1) = (f t ..._!_1)) c ...) S D)
   ⊥
   (clause-name "clash")]
  [(unify ((x = t) c ...) S D)
   ⊥
   (side-condition (term (occurs? x t)))
   (side-condition (term (different x t)))
   (clause-name "occurs")]
  [(unify ((x = t) c ...) (c_s ...) (dq ...))
   (unify ((subst-c/dq c x t) ...) ((x = t) (subst-c/dq c_s x t) ...) ((subst-c/dq dq x t) ...))
   (clause-name "variable elim")]
  [(unify ((t = x) c ...) S D)
   (unify ((x = t) c ...) S D)
   (clause-name "orient")]
  [(unify () S D)
   (S : D)
   (clause-name "success")])

(define-metafunction U
  [(length-eq any_1 any_2) #t
   (side-condition (equal? (length (term any_1)) (length (term any_2))))]
  [(length-eq any_1 any_2) #f])

(define DU-red
  (extend-reduction-relation
   U-red U
   (--> (((∀ (x ...) (s ≠ t)) c ...) : S : D)
        ((unify_d (((s = t)) : ()) (x ...)) (x ...) ≫ ((c ...) : S : D))
        "simplify")
   (--> ((() : ()) (x ...) ≫ Γ)
        ⊥
        "failed constraint")
   (--> ((() : S_0) (x ...) ≫ (P : S : (dq ...)))
        (P : S : ((∀ (x ...) (env->dq S_0)) dq ...))
        (side-condition (term (different S_0 ())))
        (where ((x_s = t_s) ...) S_0)
        (side-condition (term (disjoint (x ...) (x_s ...))))
        "add constraint")
   (--> (⊥ (x ...) ≫ Γ)
        Γ
        "empty constraint")
   (--> (P : S : (c_1 ... (∀ (x_a ...) (∨ ((f s ...) ≠ t) ...)) c_2 ...))
        ((unify_d ((((f s ...) = t) ...) : ()) (x_a ...)) (x_a ...) ≫ (P : S : (c_1 ... c_2 ...)))
        "resimplify")
   (--> ((() : ((x_0 = t_0) ... (x = t) (x_1 = t_1) ...)) (x_2 ... x x_3 ...) ≫ Γ)
        ((() : ((x_0 = t_0) ... (x_1 = t_1) ...)) (x_2 ... x x_3 ...) ≫ Γ)
        (side-condition (term (not-in x (x_0 ... x_1 ...))))
        "param-elim-1")
   (--> ((() : (c_0 ... (x = s) c_1 ... (x = t) c_3 ...)) (x_2 ... x x_3 ...) ≫ Γ)
        ((unify_d (((x = s) (x = t) c_0 ... c_1 ... c_3 ...) : ()) (x_2 ... x x_3 ...)) (x_2 ... x x_3 ...) ≫ Γ)
        "param-elim-2")))

(define-metafunction U
  [(disunify P)
   (DUa P () ())])

(define-metafunction/extension unify U
  [(DU ((∀ (x ...) (s ≠ t)) c ...) S (dq ...)) 
   ⊥
   (where (() : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(DU ((∀ (x ...) (s ≠ t)) c ...) S (dq ...)) 
   (DU (c ...) S (dq ...))
   (where ⊥ (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(DU ((∀ (x ...) (s ≠ t)) c ...) S (dq ...))
   (DU (c ...) S ((∀ (x ...) ((f x_s ...) ≠ (f t_s ...))) dq ...))
   (where (((x_s = t_s) ...) : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(DU (c ...) S (c_1 ... (∀ (x_a ...) ((f (f s ...) ... ) ≠ (f t ...))) c_2 ...))
   (DU ((∀ (x_a ...) ((f (f s ...) ...) ≠ (f t ...))) c ...) S (c_1 ... c_2 ...))
   (clause-name "resimplify")])

(define-metafunction U
  [(DUa ((∀ (x ...) (s ≠ t)) c ...) S (dq ...)) 
   ⊥
   (where (() : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "failed constraint")]
  [(DUa ((∀ (x ...) (s ≠ t)) c ...) S (dq ...)) 
   (DUa (c ...) S (dq ...))
   (where ⊥ (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "empty constraint")]
  [(DUa ((∀ (x ...) (s ≠ t)) c ...) S (dq ...))
   (DUa (c ...) S ((∀ (x ...) ((f x_s ...) ≠ (f t_s ...))) dq ...))
   (where (((x_s = t_s) ...) : ()) (param-elim (unify ((s = t)) () ()) (x ...)))
   (clause-name "simplify constraint")]
  [(DUa (c ...) S (c_1 ... (∀ (x_a ...) ((f (f s ...) ... ) ≠ (f t ...))) c_2 ...))
   (DUa ((∀ (x_a ...) ((f (f s ...) ...) ≠ (f t ...))) c ...) S (c_1 ... c_2 ...))
   (clause-name "resimplify")]
  [(DUa ((t = t) c ...) S D)
   (DUa (c ...) S  D)
   (clause-name "identity")]
  [(DUa (((f t ..._1) = (f s ..._1)) c ...) S D)
   (DUa ((t = s) ... c ...) S D)
   (clause-name "decompose")]
  [(DUa (((f t ..._!_1) = (f s ..._!_1)) c ...) S D)
   ⊥
   (clause-name "clash")]
  [(DUa ((x = t) c ...) S D)
   ⊥
   (side-condition (term (occurs? x t)))
   (side-condition (term (different x t)))
   (clause-name "occurs")]
  [(DUa ((x = t) c ...) (c_s ...) (dq ...))
   (DUa ((subst-c/dq c x t) ...) ((x = t) (subst-c/dq c_s x t) ...) ((subst-c/dq dq x t) ...))
   (clause-name "variable elim")]
  [(DUa ((t = x) c ...) S D)
   (DUa ((x = t) c ...) S D)
   (clause-name "orient")]
  [(DUa () S D)
   (S : D)
   (clause-name "success")])

(define-metafunction U
  [(param-elim (((x_0 = t_0) ... (x = t) (x_1 = t_1) ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = t_0) ... (x_1 = t_1) ...) : ()) (x_2 ... x x_3 ...))
   (clause-name "param-elim-1")]
  [(param-elim (((x_0 = t_0) ... (x_l = x) c_2 ...) : ()) (x_2 ... x x_3 ...))
   (param-elim (((x_0 = t_0) ... (x_1 = x_2) ... c_3 ...) : ()) (x_2 ... x x_3 ...))
   (side-condition (term (not-in x (t_0 ...))))
   (where ((x_1 = x_2) ... c_3 ...) (elim-x x (x_l = x) c_2 ...))
   (clause-name "param-elim-2")]
  [(param-elim ⊥ (x ...))
   ⊥
   (clause-name "param-elim-failed")]
  [(param-elim (S : ()) (x ...))
   (S : ())
   (clause-name "param-elim-finish")])

(define-metafunction U
  [(elim-x x c ...)
   ,(elim-x-func (term x) (term (c ...)))])

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
   ((f t_l ...) ≠ (f t_r ...))])

(define-metafunction U
  [(unify_d (P : S_0) (x ...))
   (orient-params (() : S_1) (x ...))
   (where (S_1 : D) (unify P S_0 ()))]
  [(unify_d (P : S) (x ...))
   (orient-params ⊥ (x ...))
   (where ⊥ (unify P S ()))])

(define-metafunction U
  [(orient-params ⊥ (x ...))
   ⊥]
  [(orient-params (() : (c_1 ... (t = x) c_2 ...)) (x x_1 ...))
   (orient-params (() : (c_1 ... (x = t) c_2 ...)) (x x_1 ...))
   (side-condition (not (equal? (term t) (term x))))]
  [(orient-params (() : (c ...)) (x x_1 ...))
   (orient-params (() : (c ...)) (x_1 ...))]
  [(orient-params (() : (c ...)) ())
   (() : (c ...))])
   

(define-metafunction trees
  vars : t -> (x ...)
  [(vars x)
   (x)]
  [(vars (f t ...))
   (x ... ...)
   (where ((x ...) ...) ((vars t) ...))])

(define-metafunction U
  subst-cs : x t (c ...) -> (c ...)
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

(define-metafunction trees
  subst : x t t -> t
  [(subst x t x)
   t]
  [(subst x_1 t x_2)
   x_2]
  [(subst x t (f s ...))
   (f (subst x t s) ...)])

(define-metafunction U
  env->dq : S -> (∨ (x ≠ t) ...)
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

(define-syntax-rule (utest in out)
  (test-->> U-red in out))

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
    [`(f ,es ...)
     (define-values (new-es new-vs)
       (for/fold ([new-es '()]
                  [new-vs vars])
         ([e es])
         (define-values (new-e new-v) (narrow-e-vars e vars))
         (values (cons new-e new-es) new-v)))
     (values `(f ,@(reverse new-es)) new-vs)]
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
  
(module+ 
 test
 ;(current-traced-metafunctions 'all)
 (utest (term ((((f) = (f))) : () : ()))
        (term (() : () : ())))
 (utest (term ((((f) = (f))) : ((y = (f))) : ()))
        (term (() : ((y = (f))) : ())))
 (utest (term ((((f y) = (f (f))) (y = z)) : () : ()))
        (term (() : ((y = (f)) (z = (f))) : ())))
 (utest (term ((((f y (f)) = (f z (f))) (y = z)) : () : ()))
        (term (() : ((y = z)) : ())))
 (utest (term ((((f y (f)) = (f z)) (y = z)) : () : ()))
        '⊥)
 (utest (term ((((f) = y) ((f) = (f x))) : () : ()))
        '⊥)
 (utest (term (((y = (f y)) ((f) = (f))) : () : ()))
        (term ⊥))
 (utest (term (((y = y) ((f) = (f))) : () : ()))
        (term (() : () : ())))
 (utest (term (((y = (f)) (y = z)) : ((w = (f y))) : ()))
        (term (() : ((w = (f (f))) (y = (f)) (z = (f))) : ())))
 )

(module+
 test
 (test-equal (term (disunify (((f x x) = (f (f) (f))))))
             (term (((x = (f))) : ())))
 (test-equal (term (disunify (((f x x) = (f (f) (f))) (∀ () (x ≠ (f))))))
             (term ⊥))
 (test-equal (term (disunify (((f y x) = (f (f) (f))))))
             (term (((x = (f)) (y = (f))) : ())))
 (test-equal (term (disunify (((f y x) = (f (f) (f))) (∀ () (x ≠ y)))))
             (term ⊥))
 (test-equal (term (disunify (((f y x) = (f (f) (f))) (∀ () ((f x) ≠ (f y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (f (f) (f))) (∀ () (x ≠ (f y y))))))
             (term (((x = (f (f) (f)))) : ((∀ () (∨ (y ≠ (f))))))))
 (test-equal (term (disunify ((x = (f (f) (f))) (y = (f)) (∀ () (x ≠ (f y y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (f (f) (f))) (y = (f (f))) (∀ () (x ≠ (f y y))))))
             (term (((y = (f (f))) (x = (f (f) (f)))) : ())))
 )

(module+
 test
 (test-equal (term (disunify ((x = (f (f) (f))) (∀ (y) (x ≠ (f y y))))))
             (term ⊥))
 (test-equal (term (disunify ((x = (f (f))) (∀ (y) (x ≠ (f y y))))))
             (term (((x = (f (f)))) : ())))
 (test-equal (term (disunify ((x = (f a b)) (∀ (y) (x ≠ (f y y))))))
             (term (((x = (f a b))) : ((∀ (y) (∨ (b ≠ a)))))))
 (test-equal (term (disunify ((x = (f a b)) (a = (f)) (∀ (y) (x ≠ (f y y))))))
             (term (((a = (f)) (x = (f (f) b))) : ((∀ (y) (∨ (b ≠ (f))))))))
  (test-equal (term 
               (disunify 
                ((x = (f a b))
                 (a = b)
                 (∀ (y) (x ≠ (f y y))))))
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
     ((∀ (a b) ((f a b) ≠ x))
      (x = (f (f) (f(f)))))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify
     ((x = (f (f) (f(f))))
      (∀ (a b) ((f a b) ≠ x)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify
     ((∀ (a b) ((f a a) ≠ x))
      (x = (f (f) (f(f))))))))
  
  (not-failed
   (term
    (disunify
     ((x = (f (f) (f(f))))
      (∀ (a b) ((f a a) ≠ x))))))
  
  (test-equal
   (term
    (disunify
     ((x = (f (f) (f(f))))
      (∀ (c d) (x ≠ (f c d)))
      (x = (f a b)))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify
     ((∀ (c d) (x ≠ (f c d)))
      (x = (f (f) (f(f))))
      (x = (f a b)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify
     ((x = (f (f) (f(f))))
      (∀ (c d) (x ≠ (f c c)))
      (x = (f a b))))))
  
  (not-failed
   (term
    (disunify
     ((∀ (c d) (x ≠ (f c c)))
      (x = (f (f) (f(f))))
      (x = (f a b))))))
  
  (test-equal
   (term
    (disunify
     ((∀ (c d) (x ≠ (f c c)))
      (x = (f (f) (f)))
      (x = (f a b)))))
   (term ⊥))
  
  )