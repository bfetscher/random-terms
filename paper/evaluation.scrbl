#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          slideshow/pict
          "citations.rkt"
          "../results/plot-points.rkt"
          "../results/plot-lines.rkt"
          "../results/ghc-data.rkt")

@title[#:tag "sec:evaluation"]{Evaluating the Generator}

We evaluate the generator in two ways. First, we compare its
effectiveness against the standard Redex generator on Redex's
benchmark suite. Second, we compare it against the best known
hand-tuned typed term generator.

@figure["fig:points"
        @list{Performance results by individual bug on the Redex 
              Benchmark.}
        @(centered (plot-points 24hr))]

@section[#:tag "sec:benchmark"]{The Redex Benchmark}

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
24 hours@note{With one exception: we ran the derivation
              generator on ``rvm-3'' for a total of 32 days
              of processor time to reduce its uncertainty.}
or until the uncertainty in the average interval
between such counterexamples became acceptably small.

@figure["fig:lines"
        @list{Random testing performance of the derivation
              generator vs. ad hoc random generation on
              the Redex Benchmark.}
        @(line-plot/directory 24hr)]

This study used 6 different models, each of which
has between 3 and 9 different bugs introduced into it,
for a total of 40 different bugs.
The models in the benchmark come from a number of different 
sources, some synthesized based on our experience for the 
benchmark, and some drawn from outside sources or pre-existing
efforts in Redex. The latter are based on
@citet[list-machine]'s list machine benchmark,
the model of contracts for delimited continuations developed
by @citet[delim-cont-cont], and the model of the Racket
virtual machine from @citet[racket-virtual-machine].
Detailed descriptions of all the models and bugs in the
benchmark can be found in @citet[redex-benchmark].

@Figure-ref["fig:points"] summarizes the results of the
comparison on a per-bug basis. The y-axis is time
in seconds, and for each bug we plot the average
time it took each generator to find a counterexample.
The bugs are arranged
along the x-axis, sorted by the average time for both
generators to find the bug. The error bars represent
95% confidence intervals in the average, and in all
cases the errors are small enough
to clearly differentiate the averages.
The two blank columns on the right are bugs that neither
generator was able to find. 
The vertical scale is logarithmic,
and the average time ranges from a tenth of a second
to several hours, an extremely wide range in the
rarity of counterexamples.

To depict more clearly the relative testing effectiveness
of the two generation methods, we plot our data slightly
differently in @figure-ref["fig:lines"]. Here we show
time in seconds on the x-axis (the y-axis from 
@figure-ref["fig:points"], again on a log scale), 
and the total number of bugs found
for each point in time on the y-axis. 
This plot makes it clear that the derivation generator
is much more effective, finding more bugs more 
quickly at almost every time scale.
In fact, an order of magnitude or more on the
time scale separates the two generators for almost
the entire plot.

While the derivation generator is more effective when it is
used, it cannot be used with every Redex model, unlike the
ad hoc generator. There are three broad categories of models
to which it may not apply.
First, the language may not
have a type system, or the type system's implementation
might use constructs that the generator fundamentally cannot
handle (like escaping to Racket code to run arbitrary
computation). Second, the generator currently cannot handle
ellipses (aka repetition or Kleene star); we hope to someday
figure out how to generalize our solver to support those
patterns, however. And finally, some judgment forms thwart
our termination heuristics. Specifically, our heuristics
make the assumptions that the cost of completing the
derivation is proportional to the size of the goal stack,
and that terminal nodes in the search space are uniformly
distributed. Typically these are safe assumptions, but not
always; the benchmark's ``let-poly'' model, for example,
is a CPS-transformed type judgment, embedding the search's
continuation in the model, and breaking the first assumption.


@section[#:tag "sec:ghc"]{Testing GHC: A Comparison With a Specialized Generator}

We also compared the derivation generator we developed for
Redex to a specialized generator of typed terms.
This generator was designed to be used for differential
testing of GHC, and generates terms for a specific variant of the 
lambda calculus with polymorphic constants, chosen to be
close to the compiler's intermediate language.
The generator is implemented using Quickcheck@~cite[QuickCheck],
and is able to leverage its extensive support for
writing random test case generators.
Writing a generator for well-typed terms in this
context required significant effort, essentially
implementing a function from types to terms in Quickcheck.
The effort yielded significant benefit, however, as implementing the entire generator from
the ground up provided many opportunities for specialized
optimizations, such as variations of type rules that
are more likely to succeed, or varying the frequency with
which different constants are chosen. @citet[palka-diss] discusses
the details.

@(define table-head
   (list @bold{Generator}
                    @bold{Terms/Ctrex.}
                    @bold{Gen. Time (s)}
                    @bold{Check Time (s)}
                    @bold{Time/Ctrex. (s)}))



@figure["fig:table" 
        @list{Comparison of the derivation
              generator and a hand-written typed term
              generator. ∞ indicates runs where no
              counterexamples were found. Runs marked with *
              found only one counterexample, which gives
              low confidence to their figures. }]{
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



@figure["fig:size-hists"
        @list{Histograms of the sizes (number of internal nodes)
              of terms produced by the different runs.
              The vertical scale of each plot is one twentieth
              of the total number of terms in that run.}]{
         @centered[(hists-pict 200 430)]}

Implementing this language in Redex was easy: we were
able to port the formal description in @citet[palka-diss]
directly into Redex with little difficulty.
Once a type system is defined in Redex we can use the
derivation generator immediately to generate well-typed terms.
Such an automatically derived generator is likely to make some 
performance tradeoffs versus a specialized one, and this comparison 
gave us an excellent opportunity to investigate those.

We compared the generators by testing two of the properties used in @citet[palka-diss],
and using same baseline version of the GHC (7.3.20111013) that was used there.
@bold{Property 1} checks whether turning on optimization influences the strictness of the
compiled Haskell code. The property fails if the compiled 
function is less strict with optimization turned on.
@bold{Property 2} observes the order of evaluation, and fails if optimized code has a
different order of evaluation compared to unoptimized code.

Counterexamples from the first property demonstrate erroneous behavior of the compiler,
as the strictness of Haskell expressions should not be influenced by optimization. In contrast,
changing the order of evaluation is allowed for a Haskell compiler to some extent, so
counterexamples from the second property usually demonstrate interesting cases of
the compiler behavior, rather than bugs.

@Figure-ref["fig:table"] summarizes the results of our comparison 
of the two generators. Each row represents a run of one of the 
generators, with a few varying parameters. We refer
to @citet[palka-diss]'s generator as ``hand-written.'' It takes
a size parameter, which we varied over 50, 70, and 90 for each property.
``Redex poly'' is our initial implementation of this system in the Redex,
the direct translation of the language from @citet[palka-diss].
The Redex generator takes a depth
parameter, which we vary over 6,7,8, and, in one case, 10.
The depths are chosen so that both generators target
terms of similar size.@note{Although we are able to generate terms
                           of larger depth, the runtime increases quickly
                           with the depth. One possible explanation is that
                           well-typed terms become very sparse as term size
                           increases. @citet[counting-lambdas]
                           show how scarce well-typed terms are even for
                           simple types. In our experience polymorphism
                           exacerbates this problem.}
(@Figure-ref["fig:size-hists"] compares generated terms at
targets of size 90 and depth 8).
``Redex non-poly'' is a modified version of our initial implementation,
the details of which we discuss below. The columns show
approximately how many tries it took to find a counterexample,
the average time to generate a term, the average time to check
a term, and finally the average time per counterexample over the
entire run. Note that the goal type of terms used to test
the two properties differs, which may affect generation time
for otherwise identical generators.

A generator based on our initial Redex implementation was
able to find counterexamples for only one of the properties,
and did so and at significantly slower rate than the hand-written
generator. The hand-written generator performed best when
targeting a size of 90, the largest, on both properties.
Likewise, Redex was only able to find counterexamples when targeting
the largest depth on property one. There, the hand-written
generator was able to find a counterexample every 12K terms,
about once every 260 seconds. The Redex generator
both found counterexamples much less frequently, at one in 4000K, and
generated terms several orders of magnitude more slowly.
Property two was more difficult for the hand-written 
generator, and our first try in Redex was unable to 
find any counterexamples there.


Comparing the test cases from both generators,
we found that Redex was producing
significantly smaller terms than the hand-written generator.
The left two histograms in @figure-ref["fig:size-hists"]
compare the size distributions, which show that
most of the terms made by the hand-written generator
are larger than almost all of the terms that Redex produced
(most of which are clumped below a size of 25).
The majority of counterexamples we were able to produce
with the hand-written generator fell in this larger range.
                 
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
causing it to get stuck in expensive backtracking cycles.
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
6 to, astonishingly, one in 320 at depth 8, providing more evidence
that larger terms
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

Overall, our conclusion is that our generator is not
competitive with the hand-tuned generator when it has
to cope with polymorphism. Polymorphism, in turn, is
problematic because it requires the generator to make
parallel choices that must match up, but where the generator
does not discover that those choices must match until 
much later in the derivation. Because the choice point
is far from the place where the constraint is discovered,
the generator spends much of its time backtracking.
The improvement in generation speed for the
Redex generator when removing polymorphism provides 
evidence for our explanation of what makes generating
these terms difficult.
The ease with which we were
able to implement this language in Redex, and
as a result, conduct this experiment,
speaks to the value of a general-purpose generator.

