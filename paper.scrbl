#lang scribble/lncs

@(require scribble/core
          scribble/latex-prefix
          scribble/latex-properties
          "citations.rkt"
          "common.rkt")


@authors[@(author #:inst "1" "Burke Fetscher")
         @(author #:inst "2" "Koen Claessen")
         @(author #:inst "2" "Micha\u0142 Pa\u0142ka")
         @(author #:inst "2" "John Hughes")
         @(author #:inst "1" "Robert Bruce Findler")]

@institutes[@institute{Northwestern University}
             @institute{Chalmers University of Technology}]

@title{Making Random Judgments:
       Automatically Generating Well-Typed Terms from the Definition of a Type-System}

@abstract{
 This paper presents a generic method for randomly
 generating well-typed expressions. It starts from a
 specification of a typing judgment in PLT Redex
 and uses a specialized solver that employs
 randomness to find many different valid derivations of the
 judgment form.
 
 Our motivation for building these random terms is to more
 effectively falsify conjectures as part of the tool-support
 for semantics models specified in Redex. Accordingly, we evaluate 
 the generator
 against the other available methods for Redex, as well as
 the best available custom well-typed term generator. Our
 results show that our new generator is much more effective
 than generation techniques that do not explicitly take
 types into account and is competitive with generation
 techniques that do, even though they are specialized to
 particular type-systems and ours is not.
}

@include-section["intro.scrbl"]

@include-section["deriv.scrbl"]

@include-section["semantics.scrbl"]

@include-section["evaluation.scrbl"]

@include-section["related-work.scrbl"]

@include-section["conclusion.scrbl"]

@(generate-bibliography)
