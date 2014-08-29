#lang racket

(require scribble/core
         scribble/latex-properties
         scribble/latex-prefix
         (except-in slideshow/pict table)
         redex/pict)

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
  (scale p 0.85))

(define-syntax-rule
  (with-font-params e)
  #;(parameterize ([default-style "Menlo"]
                 [grammar-style "CMU Serif"]
                 [literal-style "CMU Serif"]
                 [metafunction-style '(bold . "Menlo")]
                 [non-terminal-style '(italic . "CMU Serif")])
    e)
  e)

