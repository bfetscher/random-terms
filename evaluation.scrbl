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

@section[#:tag "sec:ghc"]{Comparison With a Specialized Generator}

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
Such an automatically derived generator must make some 
performance tradeoffs, and this comparison gave us an excellent 
opportunity to investigate those.

We compared the generators on a version of GHC with known
bugs and two soundness properties known to expose those
bugs. @;{TODO: what are the properties?????}

@(define table-head
   (list @bold{Generator}
                    @bold{Terms/Ctrex.}
                    @bold{Gen. Time (s)}
                    @bold{Check Time (s)}
                    @bold{Time/Ctrex. (s)}))

@figure["fig:prop2-table" @list{Testing GHC: comparison of the derivation
                                generator and a hand-written typed term
                                generator.}
                                ]{
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
]

@;{
@figure["fig:prop1-table" "Property 2"]{
  @centered{
    @tabular[#:sep @hspace[1]
             (cons
              table-head
              (make-table table-prop2-data))]
     }}
]}

















