#lang racket

(require "disunify-a.rkt"
         redex/reduction-semantics
         redex/pict
         slideshow/pict)

(provide with-all-rewriters
         unify-func-pict
         unify-init-pict
         du-init-pict)

(define (different-rewriter lws)
  (match lws
    [`(,_ ,_ ,l1 ,l2 ,_)
     `(,l1 " ≠ " ,l2)]))

(define (not-variable-rewriter lws)
  (match lws
    [(list _ _ x _)
     (list x (text (string-append " " (list->string (list (integer->char #x2209))) " Variables")
                   (non-terminal-style) (default-font-size)))]))

(define (¬-rewriter lws)
  (match lws
    [(list _ _ l _)
     (list "¬" l)]))

(define (disjoint-rewriter lws)
  (match lws
    [(list _ _ l1 l2 _)
     (list l1 " ∩ " l2 " = ∅")]))

(define (not-in-rewriter lws)
  (match lws
    [(list _ _ l1 l2 _)
     (list l1 (string-append " " (list->string (list (integer->char #x2209))) " ") l2)]))

(define (subst-rewriter lws)
  (match lws
    [(list _ _ t x s _)
     (list "" t "{" x " → " s "}" "")]))

(define (length-eq-rewriter lws)
  (match lws
    [(list _ _ l1 l2 _)
     (list "|" l1 "| = |" l2 "|")]))

(define (unify-rewriter lws)
  (match lws
    [(list _ _ p s d _)
     (list (text "U" (metafunction-style) (default-font-size))
           "\u27ec" p ", " s ", " d "\u27ed")]))

(define (DU-rewriter lws)
  (match lws
    [(list _ du p s d _)
     (list #;(text "DU" (metafunction-style) (default-font-size)) du
           "\u27ec" p ", " s ", " d "\u27ed")]))

(define (metafuc-brace-rw lws)
  (match lws
    [(list _ name stuff ... _)
     `(,name "\u27ec" ,@(add-between stuff ", ") "\u27ed")]))

(define (ast-rw lws)
  (match lws
    [(list _ _ e xs ps _)
     (match (lw-e xs)
       [(list _ x y _)
        (list "" e "{" x " → " y  ", ...}")])]))

(define-syntax-rule (with-all-rewriters e)
  (with-compound-rewriters
   (['different different-rewriter]
    ['not-variable not-variable-rewriter]
    ['¬ ¬-rewriter]
    ['disjoint disjoint-rewriter]
    ['not-in not-in-rewriter]
    ['subst-c/dq subst-rewriter]
    ['subst-dq subst-rewriter]
    ['length-eq length-eq-rewriter]
    ['apply-subst ast-rw])
   e))

(define (unify-func-pict)
  (parameterize ([metafunction-pict-style 'left-right/beside-side-conditions])
    (with-all-rewriters
          (render-metafunction unify))))

(define (unify-init-pict)
  (with-all-rewriters
   (render-term U
                (unify P () ()))))

(define (du-init-pict)
  (with-all-rewriters
   (render-term U
                (DU P () ()))))
