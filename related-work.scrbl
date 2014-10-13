#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          slideshow/pict
          "citations.rkt")

@title[#:tag "sec:related"]{Related Work}

Quickcheck@~cite[QuickCheck] is a widely-used library
for random testing in Haskell. It provides combinators supporting the
definition of testable properties, random generators, and analysis
of results. Although Quickcheck's approach is much more general than
the one taken here, it has been used to implement a random generator
for well-typed terms robust enough to find bugs in GHC.@~cite[palka-diss]
This generator provides a good contrast to the approach of this work,
as it was implemented by hand, albeit with the assistance of a powerful
test framework. Significant effort was spent on adjusting the distribution
of terms and optimization, even adjusting the type system in clever
ways. Our approach, on the other hand, is to provide a straightforward
way to implement a test generator, ideally by simply writing down the
type system, the inherent tradeoff being that an automatically derived
generator is almost certain to be much slower and likely to have a
less effective distribution of terms.

Random program generation for testing purposes is not a new idea
and goes back at least to @citet[Hanford], who details the
development and application of the ``syntax machine'', essentially
a tool for producing random expressions from a grammar similar to
Redex original term generation method. The tool was intended for 
testing compilers, a common target for this type of random generation. 
Other uses of random testing for
compiler testing throughout the years are discussed in the 1997
survey of @citet[compiler-testing].

In the area of random testing for compilers,
of special note is Csmith@~cite[csmith], a highly effective tool for generating
C programs for compiler testing. Csmith generates C programs that avoid
undefined or unspecified behavior. These programs are then used for differential
testing, where the output of a given program is compared across several compilers
and levels of optimization, so that if the results differ, at least one of test
targets must contain a bug. Csmith represents a significant development effort
at 40,000+ lines of C++ and the programs it generates are finely tuned to be
effective at finding bugs based on several years of experience. This approach
has been effective, finding over 300 bugs in mainstream compilers as of 2011.

Efficient random generation of program terms has seen some interesting
advances in previous years, much of which focuses on enumerations.
Feat@~cite[feat], or ``Functional Enumeration of Algebraic Types,'' is a 
Haskell library that exhaustively enumerates a datatype's possible values.
The enumeration is made very efficient by memoising cardinality metadata,
which makes it practical to access values that have very large indexes.
The enumeration also weights all terms equally, so a random sample of values
can in some sense be said to have a more uniform distribution. Feat was used 
to test Template Haskell by generating AST values, and compared favorably with
Smallcheck in terms of its ability to generate terms above a certain size.
(QuickCheck was excluded from this particular case study because it was
``very difficult'' to write a QuickCheck generator for ``mutual recursive
datatypes of this size'', the size being around 80 constructors. This provides 
some insight into the effort involved in writing the generator described
in @citet[palka-diss].)

Another, more specialized, approach to enumerations was taken by 
@citet[counting-lambdas]. Their work addresses specifically the problem
of enumerating well-formed lambda terms. (Terms where all variables
are bound.) They present a variety of combinatorial results on
lambda terms, notably some about the extreme scarcity of simply-typable
terms among closed terms. As a by-product they get an efficient generator
for closed lambda terms. To generate typed terms their approach
is simply to filter the closed terms with a typechecker. This approach
is somewhat inefficient (as one would expect due to the rarity of typed
terms) but it does provide a uniform distribution.

Instead of enumerating terms, @citet[every-bit-counts] develop a
bit-coding scheme where every string of bits either corresponds
to a term or is the prefix of some term that does. Their approach
is quite general and can be used to encode many different types.
They are able to encode a lambda calculi with polymorphically-typed
constants and discuss its possible extension to even more challenging
languages such as System-F. This method cannot be used for random generation
because only bit-strings that have a prefix-closure property correspond
to well-formed terms.

@citet[equational-problems]
@citet[colmerauer-inequations]
@citet[pattern-unification]
