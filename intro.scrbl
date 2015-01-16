#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          "citations.rkt"
          "common.rkt")

@title{Introduction}

Redex@~cite[redex] employs property-based testing to help semantics engineers
uncover bugs in their models. Semantics engineers write down
properties that should hold of their models (e.g., type soundness)
and Redex can randomly generate example expressions in an attempt
to falsify those properties. Until recently, Redex used a naive
generation strategy: it simply randomly picks productions from
the grammar of the language to build a term and then checks to
see if that falsifies the property of interest. For untyped models,
or when the model author writes a ``fixing'' function
that makes expressions more likely to type-check (e.g., by writing
a post-processing function that binds free variables),
this naive technique is 
effective@~cite[run-your-research klein-masters racket-virtual-machine].
With typed models, however, such randomly generated terms rarely
type check and so the testing process spends most of its
time rejecting ill-typed terms instead of actually testing the model.

To make testing more effective, we built a solver that randomly
generates solutions to problems involving a subset of first-order logic
with equality and inequality constraints, and we use that to
transform a Redex specification of a type-system into a random
generator of well-typed terms.

@;{TODO: what we say about fixing here seems to contradict what we
   say above. Fix this and discuss more in Sec. 4} 
We evaluate our generator on a benchmark suite of buggy Redex
models and show that it is far more effective than the 
naive approach and less effective than the fixing function approach,
but still competitive. We also evaluate our generator against
the best known, hand-tuned generator for random well-typed 
terms@~cite[palka-workshop]. This generator handles only a language
closely matched to the GHC Haskell compiler intermediate language, but is better
than our generic generator, overall.
We compared the two generators by searching
for counterexamples to two properties using a buggy version of
GHC.
A straightforward translation into Redex using our generator
is able to find one bug infrequently, and to investigate
the difficulties we refined that translation into a non-polymorphic
model that was much more effective, demonstrating how
polymorphism can be a difficult issue to tackle with 
random testing.@;{TODO - update this more}
We carefully explore why and
discuss the issues in @secref["sec:evaluation"].

@Secref["sec:deriv"] works through the generation process for a
specific model in order to explain our method. 
@Secref["sec:semantics"] gives a small, formal model of our generator. 
@Secref["sec:evaluation"] explains the evaluation of our generator.
@Secref["sec:related"] discusses related work and @secref["sec:conclusion"]
concludes.
