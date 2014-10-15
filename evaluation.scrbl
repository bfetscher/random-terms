#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          slideshow/pict
          "citations.rkt"
          "results/plot-points.rkt"
          "results/plot-lines.rkt")

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
For each version of each model, we define two generators 
and one soundness property, one using the  method explained 
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
95% confidence intervals in the average. The two
blank columns on the right are bugs that neither
generator was able to find. 
Note that the scale on the y-axis is logarithmic,
and the average time ranges from a tenth of a second
to several hours, an extremely wide range in the
rarity of counterexamples.

@figure["fig:lines"
        @list{Random testing performance of the derivation
              generator vs. ad-hoc random generation on
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
time scale separates the two generators for almost all
of the plot.

@; TODO did I go too far here?
As a counterpoint, is it true that
in a practical sense, the derivation generator does suffer
from some significant limitations when compared with 
the ad-hoc generator. The parts of the pattern langauge that
it can't handle are significant and commonly used by
Redex engineers@note{This
    paper and its model being one such use case.}, 
particularly ellipses.
It cannot handle judgments that use Redex's
capability to escape to Racket, and some
judgments may have structure that causes our
search heuristics to fail.
The model from the Redex Benchmark that we
did not include in this study is an example
of the latter; it is a type judgment that
for practical reasons was ``cps-transformed'', so
that all recursive judgments have only a single premise,
which causes most generation attempts to be non-terminating.
Finally, it requires that the model in question have
a type system or something like it to be applicable, 
which is not always the case.        

@section[#:tag "sec:ghc"]{}

@bold{@italic{Awaiting results from our comparison with Michal
              to complete this section.}}




















@; Old stuff, from previous draft:

@;{

This chapter describes the evaluation of the new random
generator. The generator was evaluated by comparing it to 
other methods of random generation that can be applied to
similar specifications. Generators were compared in
terms of their testing effectiveness, measured by
how long they took to find known counterexamples.

The first section discusses the comparison of
the derivation-based generator with a straightforward approach
based on grammars, as originally provided by Redex and explained in Chapter 1.
For this comparison, we developed a benchmark of several Redex models,
introducing a number of bugs into each, and evaluated the performance
of the two generators on each model/bug pair.

We then compared the performance of the derivation-based generator
with pre-existing Redex model and test framework for the Racket
Virtual Machine, as explained in Section 4.2. 
This effort had a more refined approach to random
generation that post-processed terms generated from the grammar to
make them more likely to be valid test cases. In this case we
reintroduced several bugs found during the original effort and
compared the ability of the two generation approaches to 
produce counterexamples.

@section{A Bugfinding Benchmark}

To compare the performance of the derivation-based generator to the
original grammar-based approach used in Redex, we developed a 
bugfinding benchmark. The benchmark is not necessarily limited
in application to the two approaches we have used it with;
it could in principle be used with any generation method that
that takes some part of a semantic model (i.e. a type system,
reduction relation, or type system) as its input and generates
terms automatically. It couldn't be applied as easily, however,
with approaches that are not ``push-button'' and require some
human ingenuity@note{On the other hand, such approaches have the
                     advantage of being limited only by the 
                     ingenuity of the implementor.}
to implement the generator.

The benchmark consists of six different Redex models, each
of which consists of a grammar, a dynamic semantics in the 
form of a reduction relation or metafunction, and some
static well-formedness property formulated with judgement
forms and metafunctions. (The last is usually a type system.)
Finally, each has some predicate that relates the dynamic
properties of the system to the static properties. 
Type soundness, for example, states
that reducing a well-typed term that is not a value is 
always possible and always preserves the type of the term. 

For each model, several ``mutations'' provide the tests for the benchmark.
The mutations are made by manually introducing bugs into a new version 
of the model, such that each mutation is identical to the correct@note{So far as we know. The ``correct'' versions 
                                                                       satisfy our unit tests and
                                                                       had no bugs we were able 
                                                                       to uncover with random testing.}
version aside from a single bug. The models used are:
@itemlist[#:style 'never-indents
 @item{@bold{stlc} A simply-typed lambda calculus with base
        types of numbers and lists of numbers, including the constants
        @code{cons}, @code{head}, @code{tail}, and @code{nil} (the empty list), all
        of which operate only on lists of numbers. The property checked
        is type soundness: the combination of subject reduction (that
        types are preserved by the reductions) and progress (that well-typed
        non-values always take a reduction step). 9 different mutations
        (bugs) of this system are included.}
 @item{@bold{poly-stlc} This is a polymorphic version of @bold{stlc}, with
        a single numeric base type, polymorphic lists, and polymorphic 
        versions of the same constants. Again, the property checked is
        type soundness. 9 mutations are included.}
 @item{@bold{stlc-sub} The same language and type system as @bold{stlc},
        except that in this case all of the errors are in the substitution
        function. Type soundness is checked. 9 mutations are included.}
 @item{@bold{list-machine} An implementation of the 
        @italic{list-machine benchmark} described in @citet[list-machine],
        this is a reduction semantics (as a pointer machine operating over
        an instruction pointer and a store) and a type system for a
        seven-instruction first-order assembly language that manipulates
        @code{cons} and @code{nil} values. The property checked is type soundness
        as specified in @citet[list-machine], namely that well-typed programs
        always step or halt (``do not get stuck''). 3 mutations are included.
        This was a pre-existing implementation of this system in Redex
        that we adapted for the benchmark.}
 @item{@bold{rbtrees} A model implementing red-black trees via a judgment
        that a tree has the red-black property and a metafunction defining
        the insert operation. The property checked is that insert preserves
        the red-black tree property. 3 mutations of this model are included.}
 @item{@bold{delim-cont} A model of the contract and type system for
        delimited control described in @citet[delim-cont-cont]. The language
        is essentially PCF extended with operators for delimited continuations
        and continuation marks, and contracts for those operations. 
        The property checked is type soundness. 2
        mutations of this model are included, one of which was found and fixed
        during the original development of the model.
        This was a pre-existing model developed by @citet[delim-cont-cont] which
        was adapted for the benchmark.}]

For each mutation and each generation method, the benchmark repeatedly generates
random terms and tests the correctness property, tracking how long the model runs
for before the property is falsified and a counterexample is found. For each
mutation/method instance, we ran the tests for increasing intervals of time from
5 minutes up to 24 hours, stopping if the average interval stabilized. The tests
were run for a maximum of 48 hours total for each instance. Thus if a generation method
failed to find a counterexample for some mutation, it ran for 2 days without finding
a single counterexample.

The results of the benchmark for the grammar-based generator
and the derivation based generator are shown in @figure-ref["fig:bench-plot"].
In each of these tests, the grammar-based generator is used to generate terms
from the grammar which are then discarded if they fail to be well-typed. If they
are well-typed, then the correctness property is checked. The derivation-based
generator, on the other hand, generates terms that are already well-typed so
the correctness property can be checked for every term that it generates.

@(define pw
   (pict-width (text (list->string (build-list 80 (λ (_) #\X))))))

@figure*["fig:bench-plot"
        @string-append{Comparison of the derivation-based generator (``search,'' the red
                       triangles) and the grammar-based generator (``grammar,'' the green
                       circles) on the bug-finding benchmark tests. The y-axis is
                       the average time to find the bug in seconds, in a log scale. The error
                       bars are 95% confidence intervals in the average.}
        @centered[(scale-to-fit
                   (plot-gram-search #:directory "results/benchmark")
                   pw +inf.0)]]

The relative performance of the two generators is related to two metrics
which are not visible in @figure-ref["fig:bench-plot"]: the rate at which terms
are produced, and the ratio of counterexamples to terms produced. In fact, the
grammar-based generator produces terms at rates up to greater than one hundred times
as fast as the derivation generator. On the other hand, the ratio of counterexamples 
to terms produced is @italic{much} better for the derivation generator --- if we had
used this for our metric, in fact, the the difference between the two would appear
to be even greater. The metric used here was chosen to reflect as closely as possible
the effective difference between the two approaches in actual application during 
the development process. However, we note in passing that there could be significant
payoff to increasing the speed of the derivation generator, and it seems likely there
is much more room for optimization here than in the grammar-based approach.


The averages in @figure-ref["fig:bench-plot"] span nearly 6 orders of magnitude from less than
a tenth of a second to almost two hours, and are shown on a logarithmic scale. The error
bars shown reflect 95% confidence intervals in the average, meaning there is a 95% chance that the
actual average falls within the delineated interval. The derivation-based generator (``search'') succeeded
on each of the 34 tests, and the grammar-based generator (``grammar'') succeeded on only 26.
As noted before, for each failure this generator ran for 48 hours without finding a counterexample.
The derivation-based generator is consistently faster (with three exceptions), by a factor of up
to over 1000 in some cases. The ratio of the two averages varies dramatically, however.
In the few cases where the grammar-based generator is faster, both averages are near a second, indicating
that these aren't particularly difficult bugs to find, and the ratio between the two is not large.

@section{Comparison with an Established Redex Testing Effort}

To further evaluate the performance of the derivation-based generator, we compared
it with a pre-existing test framework for the Racket virtual machine and
bytecode verifier.@~cite[racket-virtual-machine] This testing approach was based on
a Redex model of the virtual machine and verifier, and used the approach of
generating random bytecode terms and processing them with a ``fixing'' function
that modifies the terms to make them more likely to pass the verifier. This 
testing approach proved effective, successfully finding more than two dozen
bugs in the machine model and a few in the actual Racket implementation.

@Figure-ref["fig:rvm-plot"] compares the performance of the derivation generator
and the grammar-based generator with a ``fixing'' function. The derivation generator
is used to directly produce bytecode that will pass the verifier. The other generation
method is that used by @citet[racket-virtual-machine] and uses Redex to automatically
produce terms satisfying the byte-code grammar, which are then passed to the fixing
function.
The main changes performed by the fixing function are to 
adjust stack offsets to agree with the current context and replace
some references with values, greatly increasing the chance that the randomly
generated bytecode will be verifiable.

@figure*["fig:rvm-plot"
        @string-append{Comparison of bug-finding effectivenesss of the
                       typed term generator vs. the grammar generator and
                       a ``fixing'' function. The generators were compared
                       on 6 bugs, one of which both failed to uncover. 
                       Again, the y-axis is the average time to find
                       a bug in seconds on a log scale, and error bars are 95%
                       confidence intervals in the average.}
        @centered[(scale-to-fit
                   (plot-gram-search #:directory "results/racket-vm" #:order-by 'grammar
                                     #:min 10 #:max 3000)
                   pw +inf.0)]]

The two generation methods were compared on 6 bugs discovered during the development
of the virtual machine model by @citet[racket-virtual-machine] and found to be 
difficult to uncover with their random-testing efforts.
(The labels in @figure-ref["fig:rvm-plot"] correspond to those from figure 28
in that paper.)
Interestingly, using the
same generation methods as they did, we were able to find one bug they failed to
find in over 25 million attempts, and failed to find one bug they uncovered with random
testing. This is yet more evidence of the sensitivity of random testing to seemingly
unrelated changes in the model, and the difficulty of repeating specific random
results.

The results of the comparison are shown in @figure-ref["fig:rvm-plot"].
These were indeed all difficult bugs to find, with the lowest average
time to find a bug being several minutes and the largest close to a full
day. (We ran these tests for up to a total of nearly four days for
each instance.)
The derivation generator is about a factor of ten slower in the four
cases where it succeeded. Thus in this case the grammar/fix method
is significantly more effective. (There is some reason to believe this
specific case may be especially difficult for the derivation generator and
perhaps easier for a fixing function, as discussed below.)

The fixing function used in this case was developed simultaneously
with the model and doesn't provide the same ``push-button'' feedback
we hope for from the derivation generator. 
Writing such functions requires some amount of cleverness on the
part of the user and imposes some cognitive overhead on the
development process. On the other hand,
there are significant constraints (also addressed below) placed
on the form of the model to make
it compatible with derivation generation.

Finally, we note that the ability of the derivation generator to find
these bugs is encouraging in the sense that they indicate it is
at least minimally effective when applied to models of production systems,
and could be used for testing efforts extending beyond ``toy'' semantic
models.

@subsection{Translating the model and effects on term generation}

Since this effort dealt with a pre-existing Redex model of non-trivial complexity, 
it provides an opportunity to consider the limitations of the derivation
generator from the perspective of the effort needed to translate the 
model into a form the new generator could handle.

As already noted, the derivation generator isn't able to handle ellipses
(``repeat'' patterns) or uses of @code{unquote}. Ellipses provide rich ways of
destructuring and constructing lists and @code{unquote} allows escaping to arbitrary Racket 
code from inside of Redex. Removing ellipses and @code{unquote}s from the judgment forms
and metafunctions of the verifier followed a process simliar to other efforts
to translate pre-existing Redex code into a form the new generator can process.
Lists had to be replaced with an explicit representation using pairs, and 
uses of ellipses to process lists had to be replaced with metafunctions
dispatching on cons and nil. In the verifier, uses of @code{unquote} 
almost exclusively escaped to Racket to do arithmetic on natural numbers
for indexing into the stack and verifying offsets. This was replaced with
an explicit unary representation of arithmetic, and related list operations 
such as length and indexing.

Besides the pain of forcing users to avoid ellipses and roll their own
unary arithmetic operations, these changes can have a significant effect 
on the performance of the generator. Clearly list operations and unary
arithmetic defined using Redex are much slower than Redex's internal
list processing or Racket's number operations. Also, the recursive nature
of the definitions skews the generator towards producing shorter lists and
smaller numbers. In fact, since the generator chooses equally between 
alternatives, simply using it to produce unary numbers will result in a 
distribution where the probability of generating a number falls off exponentially
with its size.

The specification of the bytecode and verifier prove to be especially
difficult for the derivation generator to handle in this case.
Interestingly, they make a ``fixing'' function whose main transformation
is to fix stack offsets somewhat easier to write, since that functions main
task is to track and adjust a few natural numbers. Fixing functions
for properties with richer recursive structure may present more
difficulty. In those cases where a good fixing function becomes
more like a reimplementation of the type system, using the derivation
generator may be a better option.

This comparison also exposes some opportunities to improve the derivation generator.
Adding natural number arithmetic and finite domain constraints might make
it much more effective for cases like this by avoiding the inefficient
and poorly distributed unary representation. Similarly, adding support
for repeat patterns would provide gains in both expressiveness and
testing effectiveness. (Pattern and sequence unification
@~cite[pattern-unification] might be
a productive area to investigate in this direction.)

@;{
@section{Discussion}

How good is a random term generator? How effective is a random
testing framework? These are both difficult questions for which
there is no obvious objective metric. However it is necessary
to come up with some way to evaluate the utility of the generator
and testing approach.

Instead of attempting to come up with a metric for how
good a random generator is, we have chosen to evaluate the
random generator based on its effectiveness as a test generator.
This still leaves us with the problem of evaluating testing
effectiveness. Again, there is no obvious way to quantify this
easily.

To address the issue of testing effectiveness, we use comparative
evaluation of different testing methods, measuring the average
interval to find a counterexample for a known bug. This approach
provides some insight into the relative effectiveness of
some specific different methods, by judging which is better at finding
some specific set of bugs.

One can think of random test generators along a spectrum.
At one extreme are low-effort generators that are likely to be
less effective, such as the grammar-based generator that Redex users
get for free. At the other extreme are very effective generators that
require substantial effort to implement. Csmith@~cite[csmith] is an example of
a test generator that is both very effective and represents a directed
and substantial (and thus less general) development effort. It generates
random C programs for compiler testing, consists of over 40,000 lines
of C++ code, and is exceptionally effective, even finding bugs in
CompCert@~cite[compcert], a formally verified C compiler. Ideally, we would compare
our generator to many others along this spectrum to evaluate
its relative utility. This chapter gives the results for two 
such comparisons.

The first section discusses the development
of a benchmark of bugs in Redex models and its use to compare
the bug-finding performance of the new derivation-based generator
presented in Chapter 2 with the grammar-based approach.

The second section examines bug-finding performance on a model
of the Racket Virtual Machine that has been used for random testing
of the Racket runtime system. In this case, the new generation approach
is compared with a specialized approach that processes terms generated
from the grammar to make them more likely to be well-formed.}

  }