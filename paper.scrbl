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

@include-section{intro.scrbl}

@include-section{deriv.scrbl}

@include-section{semantics.scrbl}

@include-section{evaluation.scrbl}

@include-section{related-work.scrbl}

@include-section{conclusion.scrbl}

@(generate-bibliography)

@include-section{appendix.scrbl}
