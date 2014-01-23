#lang scribble/sigplan @onecolumn

@(require scribble/core
          scribble/latex-prefix
          scribble/latex-properties
          "citations.rkt"
          "common.rkt")

@title[#:style 
       (style #f (list (latex-defaults 
                        (string->bytes/utf-8 
                         (string-append "\\documentclass{article}\n"
                                        unicode-encoding-packages
                                        "\\usepackage{fullpage}\n"
                                        "\\usepackage{multicol}\n"))
                        #"" '())))]{Paper title}
@two-cols

@section{Introduction}
@include-section{intro.scrbl}


@include-section{deriv.scrbl}

@;@section{Random Testing in PLT Redex}
@;@include-section{redex.scrbl}

@section{Random Term Generation}
@(larger @emph{The gory details section.})
@;@include-section{semantics.scrbl}

@section{Evaluating the Generator}
@include-section{evaluation.scrbl}

@section{Related Work}
@include-section{related-work.scrbl}

@section{Conclusion}
@include-section{conclusion.scrbl}


@(generate-bibliography)

@section{Hi}
@one-col
