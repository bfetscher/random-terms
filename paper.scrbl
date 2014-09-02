#lang scribble/lncs

@(require scribble/core
          scribble/latex-prefix
          scribble/latex-properties
          "citations.rkt"
          "common.rkt")


@authors[@(author #:inst "1" "Burke Fetscher")
          @(author #:inst "1" "Robert Bruce Findler")
          @(author #:inst "2" "Koen Claessen")
          @(author #:inst "2" "Micha\u0142 Pa\u0142ka")
          @(author #:inst "2" "John Hughes")]

@institutes[@institute{Northwestern University}
             @institute{Chalmers University of Technology}]

@title{Making Random Judgments:
       Automatically Generating Well-typed Terms from the Definition of a Type-system}

@abstract{The abstract.}

@section{Introduction}
@include-section{intro.scrbl}

@include-section{deriv.scrbl}

@;@section{Random Testing in PLT Redex}
@;@include-section{redex.scrbl}

@section{Random Term Generation}
@;@(larger @emph{The gory details section.})
@include-section{semantics.scrbl}

@section{Evaluating the Generator}
@include-section{evaluation.scrbl}

@section{Related Work}
@include-section{related-work.scrbl}

@section{Conclusion}
@include-section{conclusion.scrbl}


@(generate-bibliography)

@section{Appendix}
@include-section{appendix.scrbl}
