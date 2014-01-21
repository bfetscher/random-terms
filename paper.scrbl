#lang scribble/sigplan

@(require "citations.rkt")

@section{Introduction}
@include-section{intro.scrbl}

@section{Example Term Generation}
@(larger @emph{Drop in "deriv.pdf" here, the new plan is for that to be the bulk of section 2.
               (Once we figure out how to get it in here in the right format.)})

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
