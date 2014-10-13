#lang racket

(require scribble/core
         scribble/latex-properties
         scribble/latex-prefix
         (except-in slideshow/pict table)
         redex/pict
         (only-in racket/draw get-face-list))

(provide (all-defined-out))

(define (doc-style)
  (style #f (list (latex-defaults 
                        (string->bytes/utf-8 
                         (string-append "\\documentclass[onecolumn, 9pt]{sigplanconf}\n"
                                        unicode-encoding-packages
                                        ;"\\usepackage{fullpage}\n"
                                        "\\usepackage{times}\n"
                                        "\\usepackage{qcourier}\n"
                                        "\\usepackage{multicol}\n"))
                        "style-old.tex"
                        (list "sigplanconf.cls")))))

(define two-cols (element (style "begin" '(exact-chars))
                           '("multicols}{2")))

(define one-col (element (style "end" '(exact-chars))
                          '("multicols")))

(define (text-scale p)
  (with-font-params p))

(define-syntax-rule
  (with-font-params e1 e2 ...)
  (parameterize ([default-font-size 12]
                 [metafunction-font-size 12]
                 [default-font-size 12]
                 [label-font-size 12])
    e1 e2 ...))

(define (extend-style style-p [rule "Triplicate T4p"])
   (define v (style-p)) 
   (style-p
    (let loop ([v v])
      (if (pair? v)
          (cons (car v) (loop (cdr v)))
          #;(cons v rule)
          rule))))

(define (extend-style-c style-p)
  (extend-style style-p "Triplicate C4p"))



(define (lower-font-by font [n 2])
  (font (- (font) 2)))

(when #;(member "Triplicate T4p" (get-face-list)) #f
  
  (for-each extend-style (list grammar-style #;literal-style
                               non-terminal-style non-terminal-subscript-style
                               non-terminal-superscript-style))
  
  (for-each extend-style-c (list metafunction-style label-style))
  
  (for-each lower-font-by (list label-font-size metafunction-font-size)))

