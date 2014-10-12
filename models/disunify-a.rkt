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
  solve : e C -> C or ⊥
  [(solve e_new (∧ (∧ (x = p) ...) (∧ δ ...)))
   (∧ (∧ (x_2 = p_2) ...)
      (∧ δ_2 ...))
   (where (∧ (x_2 = p_2) ...) (unify ((apply-subst e_new (x p) ...)) (∧ (x = p) ...)))
   (where (∧ δ_2 ...) (check (∧ (apply-subst δ (x_2 p_2) ...) ...)))
   or 
   ⊥])

(define-metafunction U
  dissolve : δ C -> C or ⊥
  [(dissolve δ_new (∧ (∧ (x = p) ...) (∧ δ ...)))
   (∧ (∧ (x = p) ...) (∧ δ ...))
   (where ⊤ (disunify (apply-subst δ_new (x p) ...)))

   or ⊥
   (where ⊥ (disunify (apply-subst δ_new (x p) ...)))

   or
   (∧ (∧ (x = p) ...) (∧ δ_0 δ ...))
   (where δ_0 (disunify (apply-subst δ_new (x p) ...)))])
   

(define-metafunction U
  unify : (e ...) (∧ (x = p) ...) -> (∧ (x = p) ...) or ⊥
  [(unify ((p = p) e ...) (∧ e_s ...))
   (unify (e ...) (∧ e_s ...))
   (clause-name "identity")]
  [(unify (((lst p_1 ..._1) = (lst p_2  ..._1)) e ...) (∧ e_s ...))
   (unify ((p_1 = p_2) ... e ...) (∧ e_s ...))
   (side-condition (term (length-eq (p_1...) (p_2  ...))))
   (clause-name "decompose")]
  [(unify ((x = p) e ...) (∧ e_s ...))
   ⊥
   (side-condition (term (occurs? x p)))
   (side-condition (term (different x p)))
   (clause-name "occurs")]
  [(unify ((x = p) e ...) (∧ e_s ...))
   (unify ((subst-c/dq e x p) ...) 
          (∧ (x = p) (subst-c/dq e_s x p) ...))
   (clause-name "variable elim")]
  [(unify ((p = x) e ...) (∧ e_s ...))
   (unify ((x = p) e ...) (∧ e_s ...))
   (clause-name "orient")]
  [(unify () (∧ e ...))
   (∧ e ...)
   (clause-name "success")]
  [(unify (e ...) (∧ e_s ...))
   ⊥
   (clause-name "clash")])

(define-metafunction U
  disunify : δ -> δ or ⊤ or ⊥
  [(disunify (∀ (x ...) (∨ (p_1 ≠ p_2) ...)))
   
   ⊤ (where ⊥ (unify ((p_1 = p_2) ...) (∧)))
  
   or
   ⊥ (where (∧) (param-elim (unify ((p_1 = p_2) ...) (∧))
                            (x ...)))
   
   or
   (∀ (x ...) 
      (∨ (x_p ≠ p) ...))
   (where (∧ (x_p = p) ...)
          (param-elim (unify ((p_1 = p_2) ...) (∧))
                      (x ...)))])

(define-metafunction U
  check : (∧ δ ...) -> (∧ δ ...) or ⊥
  [(check (∧ δ_1 ... (∀ (x_a ...) (∨ ((lst p_l ...) ≠ p_r) ...)) δ_2 ...))
   (check (∧ δ_1 ... δ_s δ_2 ...))
   (where δ_s (disunify (∀ (x_a ...) (∨ ((lst p_l ...) ≠ p_r) ...))))
  
   or
   (check (∧ δ_1 ... δ_2 ...))
   (where ⊤ (disunify (∀ (x_a ...) (∨ ((lst p_l ...) ≠ p_r) ...))))
   
   or
   ⊥
   (where ⊥ (disunify (∀ (x_a ...) (∨ ((lst p_l ...) ≠ p_r) ...))))]
  
  [(check (∧ δ ...))
   (∧ δ ...)])


(define-metafunction U
  param-elim : (∧ e ...) (x ...) -> (∧ e ...) or ⊥
  [(param-elim (∧ (x_0 = p_0) ... (x = p) (x_1 = p_1) ...) (x_2 ... x x_3 ...))
   (param-elim (∧ (x_0 = p_0) ... (x_1 = p_1) ...) (x_2 ... x x_3 ...))
   (clause-name "param-elim-1")]
  [(param-elim (∧ (x_0 = p_0) ... (x_1 = x) (x_2 = p_2) ...) (x_4 ... x x_5 ...))
   (param-elim (∧ (x_0 = p_0) ... (x_3 = p_3)  ...) (x_4 ... x x_5 ...))
   (side-condition (term (not-in x (p_0 ...))))
   (where ((x_3 = p_3) ...) (elim-x x ((x_1 = x) (x_2 = p_2) ...)))
   (clause-name "param-elim-2")]
  [(param-elim (∧ e ...) (x ...))
   (∧ e ...)
   (clause-name "param-elim-finish")])

(define-metafunction U
  [(elim-x x (e ...))
   ,(elim-x-func (term x) (term (e ...)))])

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
  solve/test : (any ...) (∧ e ...) (∧ δ ...) -> any
  [(solve/test (e_0 any ...) (∧ (x = p) ...) (∧ δ ...))
   (solve/test (any ...) (∧ (x_2 = p_2) ...) (∧ δ_2 ...))
   (where (∧ (∧ (x_2 = p_2) ...) (∧ δ_2 ...)) (solve e_0 (∧ (∧ (x = p) ...) (∧ δ ...))))]
  [(solve/test (δ_0 any ...) (∧ (x = p) ...) (∧ δ ...))
   (solve/test (any ...) (∧ (x = p) ...) (∧ δ_2 ...))
   (where (∧ (∧ (x = p) ...) (∧ δ_2 ...)) (dissolve δ_0 (∧ (∧ (x = p) ...) (∧ δ ...))))]
  [(solve/test () (∧ e ...) (∧ δ ...))
   ((e ...) : (δ ...))]
  [(solve/test _ _ _)
   ⊥])

(define-metafunction U
  [(disunify/test (any ...))
   (solve/test ((orify any) ...) (∧) (∧))])

(define-metafunction U
  [(orify (∀ (x ...) (p_1 ≠ p_2)))
   (∀ (x ...) (∨ (p_1 ≠ p_2)))]
  [(orify any)
   any])

#;
  (define-metafunction U
  [(∨ (p_l ≠ p_r) ...)
   ((lst p_l ...) ≠ (lst p_r ...))])

(define-metafunction U
  [(orient-params ⊥ (x ...))
   ⊥]
  [(orient-params (() : (any_1 ... (p = x) any_2 ...)) (x x_1 ...))
   (orient-params (() : (any_1 ... (x = p) any_2 ...)) (x x_1 ...))
   (side-condition (not (equal? (term p) (term x))))]
  [(orient-params (() : (any ...)) (x x_1 ...))
   (orient-params (() : (any ...)) (x_1 ...))]
  [(orient-params (() : (any ...)) ())
   (() : (any ...))])

(define-metafunction U
  subst-cs : x p (any ...) -> (any ...)
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
  ;; this is not capture avoiding, but because of the way
  ;; constraints are created (metafunction compilation), the
  ;; substitution never contains quantified variables in this model
  [(subst-c/dq (∀ (x_a ...) (∨ (p_1 ≠ p_2) ...)) x p)
   (∀ (x_a ...) (∨ ((subst x p p_1) ≠ (subst x p p_2)) ...))])

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

(define-metafunction U
  [(apply-subst any (x p) ...)
   ,(apply-subst-help (term ((x = p) ...)) (term any))])

(define (apply-subst-help subst init-c)
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
                                  (apply-subst-help subst (term (p_1 = p))))))
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
  (redex-let U ([((any_1 (... ...)) : (e_1 (... ...)) : (δ_1 (... ...))) a])
             (test-equal
              (term (solve/test (any_1 (... ...)) (∧ e_1 (... ...)) (∧ δ_1 (... ...))))
              (if (equal? b '⊥) 
                  '⊥
                  (redex-let U ([((any_2 (... ...)) : (e_2 (... ...)) : (δ_2 (... ...))) b])
                             (term ((e_2 (... ...)) : (δ_2 (... ...)))))))))


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
        (term (() : ((z = (lst)) (y = (lst)) (w = (lst (lst)))) : ()))))

(module+
 test
 (test-equal (term (disunify/test (((lst x x) = (lst (lst)  (lst) )))))
             (term (((x = (lst) )) : ())))
 (test-equal (term (disunify/test (((lst x x) = (lst (lst)  (lst) )) (∀ () (x ≠ (lst) )))))
             (term ⊥))
 (test-equal (term (disunify/test (((lst y x) = (lst (lst)  (lst) )))))
             (term (((x = (lst) ) (y = (lst) )) : ())))
 (test-equal (term (disunify/test (((lst y x) = (lst (lst)  (lst) )) (∀ () (x ≠ y)))))
             (term ⊥))
 (test-equal (term (disunify/test (((lst y x) = (lst (lst)  (lst) )) (∀ () ((lst x) ≠ (lst y))))))
             (term ⊥))
 (test-equal (term (disunify/test ((x = (lst (lst)  (lst) )) (∀ () (x ≠ (lst y y))))))
             (term (((x = (lst (lst)  (lst) ))) : ((∀ () (∨ (y ≠ (lst) )))))))
 (test-equal (term (disunify/test ((x = (lst (lst)  (lst) )) (y = (lst) ) (∀ () (x ≠ (lst y y))))))
             (term ⊥))
 (test-equal (term (disunify/test ((x = (lst (lst)  (lst) ))
                                   (y = (lst (lst) )) (∀ () (x ≠ (lst y y))))))
             (term (((y = (lst (lst) )) (x = (lst (lst)  (lst) ))) : ()))))

(module+
 test
 (test-equal (term (disunify/test ((x = (lst (lst)  (lst) )) (∀ (y) (x ≠ (lst y y))))))
             (term ⊥))
 (test-equal (term (disunify/test ((x = (lst (lst) )) (∀ (y) (x ≠ (lst y y))))))
             (term (((x = (lst (lst) ))) : ())))
 (test-equal (term (disunify/test ((x = (lst a b)) (∀ (y) (x ≠ (lst y y))))))
             (term (((x = (lst a b))) : ((∀ (y) (∨ (b ≠ a)))))))
 (test-equal (term (disunify/test ((x = (lst a b)) (a = (lst) ) (∀ (y) (x ≠ (lst y y))))))
             (term (((a = (lst) ) (x = (lst (lst)  b))) : ((∀ (y) (∨ (b ≠ (lst) )))))))
  (test-equal (term 
               (disunify/test 
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
    (disunify/test
     ((∀ (a b) ((lst a b) ≠ x))
      (x = (lst (lst) (lst (lst)))))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify/test
     ((x = (lst (lst) (lst (lst))))
      (∀ (a b) ((lst a b) ≠ x)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify/test
     ((∀ (a b) ((lst a a) ≠ x))
      (x = (lst (lst) (lst (lst))))))))
  
  (not-failed
   (term
    (disunify/test
     ((x = (lst (lst)  (lst (lst))))
      (∀ (a b) ((lst a a) ≠ x))))))
  
  (test-equal
   (term
    (disunify/test
     ((x = (lst (lst)  (lst (lst))))
      (∀ (c e) (x ≠ (lst c e)))
      (x = (lst a b)))))
   (term ⊥))
  
  (test-equal
   (term
    (disunify/test
     ((∀ (c e) (x ≠ (lst c e)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b)))))
   (term ⊥))
  
  (not-failed
   (term
    (disunify/test
     ((x = (lst (lst) (lst (lst))))
      (∀ (c e) (x ≠ (lst c c)))
      (x = (lst a b))))))
  
  (not-failed
   (term
    (disunify/test
     ((∀ (c e) (x ≠ (lst c c)))
      (x = (lst (lst) (lst (lst) )))
      (x = (lst a b))))))
  
  (test-equal
   (term
    (disunify/test
     ((∀ (c e) (x ≠ (lst c c)))
      (x = (lst (lst) (lst) ))
      (x = (lst a b)))))
   (term ⊥)))
