#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          slideshow/pict
          "citations.rkt"
          "results/plot-points.rkt"
          "results/plot-lines.rkt"
          "results/ghc-data.rkt")

@title[#:tag "sec:evaluation"]{Evaluating the Generator}

@section[#:tag "sec:benchmark"]{Redex Benchmark}

Our first effort at evaluating the effectiveness of the derivation
generator compares it to the existing random expression generator
included with Redex@~cite[sfp2009-kf], which we term the ``ad hoc'' 
generation strategy in what follows. 
This generator is based on the method of recursively unfolding
non-terminals in a grammar.

To compare the two generators, we used the Redex 
Benchmark@~cite[redex-benchmark], a suite of buggy models
developed specifically to evaluate methods of automated testing
for Redex. Models included in the benchmark define
a soundness property and come in a number of different
versions, each of which introduces a single bug that can violate
the soundness property into the model.
Most models are of programming languages and most soundness
properties are type-soundness.
For each version of each model, we define one soundness property
and two generators, one using the  method explained 
in this paper and one using Redex's ad hoc generation strategy. 
For a single test run, we pair a generator with its soundness 
property and repeatedly generate test cases using the
generator, testing them with the soundness property, 
and tracking the intervals between instances where the
test case causes the soundness property to fail, exposing
the bug. For this study, each run continued for either
24 hours or until the uncertainty in the average interval
between such counterexamples became acceptably small.

This study used 6 different models@note{The benchmark
      actually includes one more model, however the
      details of that model currently preclude using
      the derivation generator with it.}, each of which
has between 3 and 9 different bugs introduced into it,
for a total of 40 unique bugs.
The models in the benchmark come from a number of different 
sources, some synthesized based on our experience for the 
benchmark, and some drawn from outside sources or pre-existing
efforts in Redex. The latter are based on
@citet[list-machine]'s list machine benchmark,
the model of contracts for delimited continuation developed
by @citet[delim-cont-cont], and the model of the Racket
virtual machine from @citet[racket-virtual-machine].
Detailed descriptions of all the models and bugs in the
benchmark can be found in @citet[redex-benchmark].

@figure["fig:points"
        @list{Performance results by individual bug on the Redex 
              Benchmark, following the naming scheme
              @italic{model name}-@italic{bug number}.}
        @(centered (plot-points 24hr))]

@Figure-ref["fig:points"] summarizes the results of the
comparison on a per-bug basis. The y-axis is time
in seconds, and for each bug we plot the average
time it took each generator to find a counterexample.
The bugs are arranged
along the x-axis, sorted by the average time for both
generators to find the bug. The error bars represent
95% confidence intervals in the average, and in all
cases except one, the errors are small enough
to clearly differentiate the averages.
The two blank columns on the right are bugs that neither
generator was able to find. 
Note that the scale on the y-axis is logarithmic,
and the average time ranges from a tenth of a second
to several hours, an extremely wide range in the
rarity of counterexamples.

@figure["fig:lines"
        @list{Random testing performance of the derivation
              generator vs. ad hoc random generation on
              the Redex Benchmark.}
        @(line-plot/directory 24hr)]

To depict more clearly the relative testing effectiveness
of the two generation methods, we plot our data slightly
differently in @figure-ref["fig:lines"]. Here we show
time in seconds on the x-axis (the y-axis from 
@figure-ref["fig:points"], again on a log scale), 
and total number of bugs found
for each point in time on the y-axis. 
This plot makes it clear that the derivation generator
is much more effective, finding more bugs more 
quickly at almost every time scale.
In fact, an order of magnitude or more on the
time scale separates the two generators for almost
the entire plot.

While the derivation generator is more effective when it is
used, it cannot be used with every Redex model, unlike the
ad hoc generator. There are three broad categories why it
may not apply to a given model. First, the language may not
have a type system, or the type system's implementation
might use constructs that the generator fundamentally cannot
handle (like escaping to Racket code to run arbitrary
computation). Second, the generator currently cannot handle
ellipses (aka repetition or Kleene star); we hope to someday
figure out how to generalize our solver to support those
patterns, however. And finally, some judgment forms thwart
our termination heuristics. Indeed, there is one model in
the Redex benchmark that we excluded for the third reason
(let-poly).

@section[#:tag "sec:ghc"]{Testing GHC: A Comparison With a Specialized Generator}

We also compared the derivation generator we developed for
Redex to a more specialized generator of typed terms.
This generator was designed to be used for differential
testing of GHC, and generates terms for a 
lambda calculus with polymorphic constants, chosen to be
close to the compiler's intermediate language.
The generator is implemented using Quickcheck@~cite[QuickCheck],
a widely-used library for random testing in Haskell,
and is able to leverage its extensive support for
writing random test case generators.
Writing a generator for well-typed terms in this
context required significant effort, essentially
implementing a function from types to terms in Quickcheck.
On the other hand, implementing the entire generator from
the ground up provided many opportunities for specialized
optimizations, such as variations of type rules that
are more likely to succeed, or varying the frequency with
which different constants are chosen. The details
are dicusssed in @citet[palka-diss].

Implementing this language in Redex was easy: we were
able to port the formal description in @citet[palka-diss]
directly into Redex with little difficulty.
Once a type system is defined in Redex we can use the
derivation generator immediately to generate well-typed terms.
Such an automatically derived generator is likely to make some 
performance tradeoffs versus a specialized one, and this comparison 
gave us an excellent opportunity to investigate those.

We compared the generators on a version of GHC with known
bugs and two soundness properties known to expose those
bugs. @bold{@italic{TODO:property details}} @;{TODO: what are the properties?????}

@(define table-head
   (list @bold{Generator}
                    @bold{Terms/Ctrex.}
                    @bold{Gen. Time (s)}
                    @bold{Check Time (s)}
                    @bold{Time/Ctrex. (s)}))

@figure["fig:table" 
        @list{Comparison of the derivation
              generator and a hand-written typed term
              generator.}]{
  @centered{
    @tabular[#:sep @hspace[1]
             (cons
              table-head
              (append
               (cons (cons @bold{Property 1} (build-list 4 (λ (_) "")))
                     (make-table table-prop1-data))
               (cons (cons @bold{Property 2} (build-list 4 (λ (_) "")))
                     (make-table table-prop2-data))))]
     }}

@Figure-ref["fig:table"] summarizes the results of our comparison 
of the two generators. Each row represents a run of one of the 
generators, with a few varying parameters. We refer
to @citet[palka-diss]'s generator as ``hand-written.'' It takes
a size parameter, which we varied over 50, 70, and 90 for each property.
The initial implementation of this system in the Redex is
called ``Redex poly.'' The Redex generator takes a depth
parameter, which we vary over 6,7,8, and, in one case, 10.
``Redex non-poly'' is a modified version of our initial implementation,
the details of which we discuss below. The columns show
approximately how many tries it took to find a counterexample,
the average time to generate a term, the average time to check
a term, and finally the average time per counterexample over the
entire run.

A generator based on our initial Redex implementation was
able to find counterexamples for only one of the properties,
and did so and at significantly slower rate than the hand-written
generator. The hand-written generator performed best when
targeting a size of 90, the largest, on both properties.
Likewise, Redex was only able to find counterexamples when targeting
the largest depth on property one. There, the hand-written
generator was able to find a counterexample every 12K terms,
and about once every 260 seconds. The Redex generator
both found terms much more rarely, at one in 4000K, and
generated terms several orders of magnitude more slowly.
Property two was more difficult for the hand-written 
generator, and our first try in Redex was unable to 
find any counterexamples there.

Comparing the test cases from both generators,
we found that Redex was producing
significantly smaller terms than the hand-written generator.
The left two histrograms in @figure-ref["fig:size-hists"]
compare the size distributions, which show that
most of the terms made by the hand-written generator
are larger than almost all of the terms that Redex produced
(most of which are clumped below a size of 25).
The majority of counterexamples we were able to produce
with the hand-written generator fell in this larger range.
@;{TODO: should we plot counterexamples on the histogram,
   or perhap indicate the range in which they fall?}


@figure["fig:size-hists"
        @list{Histograms of the sizes (number of internal nodes)
              of terms produced by the different runs.
              The vertical scale of each plot is one twentieth
              of the total number of terms in that run.}]{
         @centered[(hists-pict 200 430)]}
                 
Digging deeper, we found that Redex's generator was backtracking
an excessive amount.
This directly affects the speed at which terms are generated, 
and it also causes the generator to fail more often because 
the search limits discussed in @secref["sec:search"] are
exceeded. Finally, it skews the distribution toward smaller
terms because these failures become more likely as the
size of the search space expands.
We hypothesized that the backtracking was caused by
making doomed choices when instantiating polymorphic types
and only discovering that much later in the search,
causing it have get stuck in expensive backtracking cycles.
The hand-written generator avoids such problems by
encoding model-specific knowledge in heuristics.

To test this hypothesis, we built a new Redex model
identical to the first except with a pre-instantiated
set of constants, removing polymorphism.
We picked the 40 most common instantiations from a set
of counterexamples to both models generated by
the hand-written generator.
Runs based on this model are referred to as ``Redex non-poly'' 
in both @figure-ref["fig:table"] and @figure-ref["fig:size-hists"].

As @figure-ref["fig:size-hists"] shows, we get a much
better size distribution with the non-polymorphic model, 
comparable to the hand-written generator's distribution.
A look at the second column of @figure-ref["fig:table"]
shows that this model produces terms much faster than
the first try in Redex, though still slower than the hand-written
generator. 
This model's counterexample rate is especially interesting.
For property one, it ranges from one in 500K terms at depth
6 to, astonishingly, one in 320 at depth 8, a dramatic
example of the widely-held belief that larger terms
make better test cases.
This success rate is also much better than that of the hand-written
generator, and in fact, it was this model that was most
effective on property 1, finding a counterexample
approximately every 30 seconds,
significantly faster than the hand-written generator.
Thus, it is interesting that it did much worse on
property 2, only finding a counterexample once
every 4000K terms, and at very large time intervals.
We don't presently know how to explain this discrepancy.

@;TODO conclude -- what things were learned about random testing













