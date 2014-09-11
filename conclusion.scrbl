#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          "citations.rkt")

@title{Conclusion}

We extended the random testing capabilities of PLT Redex
to support the generation of terms satisfying judgment
forms and metafunctions. The previous method was an 
approach based on recursively unfolding the non-terminals
of a grammar. The new method outperformed the old on a
benchmark of bugs we developed, but a hand-written generator
based on the old method outperformed the new at finding
bugs in a model of the Racket virtual machine.

Random generation based on recursively expanding productions
in a grammar with no additional processing or heuristics is
really the simplest possible ``pushbutton'' strategy, so performing
better than this approach should be considered only an
initial hurdle for any alternative strategy. As such, it
is encouraging that our derivation-based generation strategy
performed much better than the grammar generator 
on the benchmark, but that doesn't mean we should
necessarily embrace this as a better strategy. 
Indeed, our experience with the virtual machine model
shows that post-processing terms generated from a grammar
can perform much better than derivation based generation for
at least one system. (Although, as we point out in Chapter 4,
there are some specific characteristics of this system that
are difficulties for the derivation generator.) The approach
of using the grammar generator with a fixing function is
more fully developed, and we expect to be able to improve the
derivation generator as we gain more experience with it.

The benchmark we developed for comparing the grammar-based
generation strategy to the derivation-based strategy 
is a valuable foundation for the evaluation of future
work on random testing. There are a variety of possible
strategies that, if implemented successfully, could be
evaluated immediately with this benchmark. For example,
it may be possible to generate well-typed terms from
judgment form definitions using approaches similar to
those of @citet[feat] or @citet[every-bit-counts]. If
we are able to implement such an idea, the benchmark
we already have could be used to compare it to both
of Redex's existing generation methods.

The benchmark itself should still be considered a work
in progress. Extending it with a further variety of
systems could prove illuminating. Possibilities include
adding type systems for imperative programming languages,
or systems based on pre-existing models with realistic
bugs. We plan to make the benchmark more modular and
work to extend it with new bugs and systems when appropriate.
As we continue to develop the benchmark we hope that
it will prove more and more useful in improving Redex's
random testing capabilities.

In terms of generating well-typed terms, there are many
alternative strategies and variations and improvements on
the strategy that we have used that remain to be explored.
We believe that the results obtained with our method make
a good argument for continuing with those investigations.

This work is certainly not the final word in random generation
based on rich properties such as type judgments. However, it
does demonstrate the potential of such an approach, both in
terms of its utility and feasibility. We hope that 
it can serve as a basis for more valuable work to be done 
in this area.

@(require scribble/core)
@(element (style "noindent" '()) '())
@bold{Acknowledgments.} Thanks to Casey Klein for help getting this
project started and work on an initial prototype implementation.
