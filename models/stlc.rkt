#lang racket/base

(require racket/match
         racket/list
         slideshow/pict
         redex/reduction-semantics
         redex/pict
         redex/tut-subst
         "../paper/common.rkt")

(provide (all-defined-out))

(define-language STLC-min
  (e ::= (e e) 
         (λ (x τ) e) 
         x n)
  (τ ::= (τ → τ) 
         num)
  (Γ ::= (x τ Γ) •)
  (n ::= number)
  (x ::= variable-not-otherwise-mentioned))

(define-extended-language STLC STLC-min
  (e ::= ....
         (if0 e e e) 
         (+ e e))
  (v ::= (λ (x τ) e) n)
  (E ::= (E e) (v E) (+ E e) (+ v E) 
         (if0 E e e) hole))

(define STLC-red
  (reduction-relation STLC
   (--> (in-hole E ((λ (x τ) e) v))
        (in-hole E (subst e x v))
        β)
   (--> (in-hole E (if0 0 e_1 e_2))
        (in-hole E e_1)
        if-0)
   (--> (in-hole E (if0 n e_1 e_2))
        (in-hole E e_2)
        (side-condition (term (different n 0)))
        if-n)
   (--> (in-hole E (+ n_1 n_2))
        (in-hole E (sum n_1 n_2))
        plus)))

(define-judgment-form STLC
  #:mode (tc I I O)
  [--------------
   (tc Γ n num)]
  [(where τ (lookup Γ x))
   ----------------------
   (tc Γ x τ)]
  [(tc (x τ_x Γ) e τ_e)
   ---------------------------------
   (tc Γ (λ (x τ_x) e) (τ_x → τ_e))]
  [(tc Γ e_1 (τ_2 → τ)) (tc Γ e_2 τ_2)
   -----------------------------------
   (tc Γ (e_1 e_2) τ)]
  [(tc Γ e_0 num) 
   (tc Γ e_1 τ) (tc Γ e_2 τ)
   ---------------------------
   (tc Γ (if0 e_0 e_1 e_2) τ)]
  [(tc Γ e_0 num) (tc Γ e_1 num)
   -----------------------------
   (tc Γ (+ e_0 e_1) num)])

(define-metafunction STLC
  [(lookup (x τ Γ) x)
   τ]
  [(lookup (x_1 τ Γ) x_2)
   (lookup Γ x_2)]
  [(lookup • x)
   #f])

(define-metafunction STLC
  [(sum n_1 n_2)
   ,(+ (term n_1) (term n_2))])

(define-metafunction STLC
  [(different v v) #f]
  [(different v_1 v_2) #t])

(define-metafunction STLC
  [(subst e x v)
   ,(subst/proc x? (term (x)) (term (v)) (term e))])

(define-metafunction STLC
  [(Eval e)
   n
   (judgment-holds (refl-trans e n))]
  [(Eval e)
   function
   (judgment-holds (refl-trans e e_2))
   (where (λ (x τ) e_3) e_2)])

(define-judgment-form STLC
  #:mode (refl-trans I O)
  [(refl-trans e_1 e_2)
   (where e_2 ,(car (apply-reduction-relation* STLC-red (term e_1))))])

(define (x? e)
  (redex-match STLC x e))

(define (tc-rewriter lws)
  (match lws
    [(list _ _ Γ e τ _)
     (list "" Γ " ⊢ " e " : " τ "")]))

(define (lookup-rewriter lws)
  (match lws
    [(list _ _ Γ x _)
     (list "" Γ "(" x ")" "")]))

(define (subst-rewriter lws)
  (match lws
    [(list _ _ e x v _)
     (list "" e "{" x " ← " v "}" "")]))

(define (different-rewriter lws)
  (match lws
    [(list _ _ a b _)
     (list "" a " ≠ " b "")]))

(define (sum-rewriter lws)
  (match lws
    [(list _ _ a b _)
     (list "" "\u2308" a " + " b "\u2309")]))

(define (refl-trans-rewriter lws)
  (match lws
    [(list _ _ e_1 e_2 _)
     (list "" e_1 (arrow->pict '-->) "* " e_2 "")]))


(define-syntax-rule (with-rewriters e)
  (with-compound-rewriters
   (['tc tc-rewriter]
    ;['lookup lookup-rewriter]
    ['subst subst-rewriter]
    ['different different-rewriter]
    ['sum sum-rewriter]
    ['refl-trans refl-trans-rewriter])
   e))

(define old-style (rule-pict-style))

(rule-pict-style 'horizontal)

(define stlc-lang-pict (render-language STLC #:nts '(e v τ E Γ)))
(define stlc-red-pict (with-rewriters
                       (render-reduction-relation STLC-red)))
(define stlc-typing-pict (with-rewriters
                          (render-judgment-form tc)))
(define stlc-type-pict-horiz
  (with-rewriters
   (hb-append 20
    (parameterize ([judgment-form-cases '(0 4)])
     (render-judgment-form tc))
    (parameterize ([judgment-form-cases '(1 2)])
     (render-judgment-form tc))
    (parameterize ([judgment-form-cases '(3 5)])
     (render-judgment-form tc)))))

(define (stlc-type-by-2s)
  (with-font-params
   (with-rewriters
    (hb-append 20
               (parameterize ([judgment-form-cases '(0 2)])
                 (render-judgment-form tc))
               (parameterize ([judgment-form-cases '(1 3)])
                 (render-judgment-form tc))))))

(define (lookup-pict) 
  (with-rewriters
   (with-font-params
    (render-metafunction lookup))))

(define (eval-pict) 
  (parameterize ([metafunction-style 'script]
                 [metafunction-pict-style
                  'left-right/beside-side-conditions])
    (with-rewriters
     (render-metafunction Eval))))

(define (big-stlc-pict)
  (vc-append 10
             (hc-append 25
                        (vl-append 10
                                   (text "Grammar" "Menlo, bold")
                                   stlc-lang-pict
                                   (text "Reduction relation" "Menlo, bold")
                                   stlc-red-pict
                                   (text "Metafunctions" "Menlo, bold")
                                   (lookup-pict))
                        (vl-append 10
                                   (text "Type judgment" "Menlo, bold")
                                   stlc-typing-pict))
             (text "Evaluation" "Menlo, bold")
             eval-pict))

(define (stlc-min-lang-types)
  (with-rewriters
   (hc-append 30
              (with-font-params (render-language STLC-min #:nts '(e τ Γ)))
              (stlc-type-by-2s))))


(define (well-typed? e)
  (judgment-holds (tc • ,e τ)))

(define (number-exp? e)
  (redex-match STLC n e))

(define (constant-func? e)
  (redex-match STLC (λ (x τ) n) e))

(define (typed-and-interesting? e)
  (and (well-typed? e)
       (not (number-exp? e))
       (not (constant-func? e))))

(define (at-least-n-steps? n)
  (λ (exp)
    (let loop ([e exp]
               [i 0])
      (or (>= i n)
          (let ([next (apply-reduction-relation STLC-red e)])
            (and (not (empty? next))
                 (loop (car next) (add1 i))))))))

(define (uses-reduction? name)
  (λ (exp)
    (let loop ([e exp])
      (match (apply-reduction-relation/tag-with-names STLC-red e)
        ['() #f]
        [`((,red-name ,next))
         (or (equal? red-name name)
             (loop next))]))))

(define (gather-stats trials [depth 5])
  (define to-check
    (list (cons 'well-typed? well-typed?)
          (cons 'typed-and-interesting? typed-and-interesting?)
          (cons 'at-least-1-red (at-least-n-steps? 1))
          (cons 'at-least-2-red (at-least-n-steps? 2))
          (cons 'at-least-3-red (at-least-n-steps? 3))
          (cons 'uses-β (uses-reduction? "β"))
          (cons 'uses-plus (uses-reduction? "plus"))
          (cons 'uses-if-0 (uses-reduction? "if-0"))
          (cons 'uses-if-else (uses-reduction? "if-n"))
          (cons 'typed-and-reduces (λ (e)
                                     (and (well-typed? e)
                                          ((at-least-n-steps? 1) e))))))
  (define stats (make-hash))
  (for ([_ trials])
    (define e (generate-term STLC e depth))
    (map (match-lambda
           [(cons stat check)
            (when (check e)
              (hash-set! stats stat
                         (add1 (hash-ref stats stat 0))))])
         to-check))
  (for/list ([(k v) (in-hash stats)])
    (cons k (exact->inexact (/ v trials)))))
