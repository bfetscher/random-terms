#lang scribble/sigplan

@(require scribble/core
          scribble/latex-prefix
          scribble/latex-properties
          "citations.rkt"
          "common.rkt")

@title[#:style (doc-style)]{Making Random Judgments@subtitle{Automatically Generating Well-typed Terms from the Definition of a Type-system}}

@(authorinfo "Burke Fetscher" "Northwestern University" "burke.fetscher@eecs.northwestern.edu")
@(authorinfo "Robert Bruce Findler" "Northwestern University" "robby@eecs.northwestern.edu")
@(authorinfo "Koen Claessen" "Chalmers University of Technology" "koen@chalmers.se")
@(authorinfo "Micha\u0142 Pa\u0142ka" "Chalmers University of Technology" "michal.palka@chalmers.se")
@(authorinfo "John Hughes" "Chalmers University of Technology" "rjmh@chalmers.se")

@(conferenceinfo "ICFP" "Gothenburg, Sweden")

@abstract{The abstract.}

@two-cols

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

@section[#:style (style #f '(hidden unnumbered))]{}
@one-col
