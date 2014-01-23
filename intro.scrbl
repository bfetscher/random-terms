#lang scribble/base

@(require scriblib/figure
          scribble/manual
          scriblib/footnote
          "citations.rkt"
          "common.rkt")

Testing is universally considered an integral part of the
software development process. It is less widely accepted
as a useful tool for semantics engineering, where
formal proofs are the tool of choice. Since its
inception, PLT Redex@~cite[redex] has challenged that assumption
as a lightweight workbench for semantics modeling
that utilizes testing, and specifically random
testing, as an integral part of its toolbox. 
Redex has used a straightforward approach to random 
generation which has been effective as a basis for random testing.
In this work, we enrich Redex's random testing capabilities
by providing automatic support for generating terms
that satisfy relations and functions defined in Redex. We then 
evaluate the potential of this approach to random
testing by comparing it to several others.

Redex already provides significant support for random testing,
inspired by the well-known Haskell testing library
QuickCheck@~cite[QuickCheck]. After writing a model of a
semantics in Redex, users can define a property they wish
to test and Redex is then able to randomly generate terms
satisfying a grammar which are used as test cases to try
to falsify the property. This approach, and variations thereof,
has been used to successfully find counterexamples in many 
real-world semantics models.@~cite[run-your-research klein-masters racket-virtual-machine]
However, it suffers from the deficiency that useful
testable properties usually have a precondition that is
stricter than the language grammar, so that
the vast majority of randomly generated terms are not
valid test cases.

To attempt to remedy this situation, we have extended
Redex's ``push-button'' approach beyond language grammars 
with the capability to generate random terms from richer
relations on terms that are frequently defined as
part of a semantic model. Type systems are a primary
example. With the old method of random testing, Redex
users would frequently define a property of @italic{well-typed}
terms, and then generate terms from a grammar, using 
the type system as a filter before testing the property.
The new approach allows test cases to be automatically
generated from the type system as the user has
already written it down.

This approach to generating random terms is more complex
and necessarily slower than using a grammar, so it
is not immediately clear that it is more effective
as a testing method. To evaluate its effectiveness,
we first compared it to the old method on a
benchmark of Redex models to which we have added
bugs by hand. We find that
the new generator does much better than this naive
grammar-based method, finding bugs the old method does
not and in much shorter times.

Because of the relative scarcity
of test cases generated from a grammar, most
Redex testing efforts incldue hand-written extensions
to the automatic random generation capabilities.
We have also compared the new random generator against
a handcrafted test generator of this type, a pre-existing
model of the Racket Virtual Machine@~cite[racket-virtual-machine] 
that already had many hours of development effort 
behind it. The handcrafted generator
performs better than the new method, finding bugs
faster and exposing one bug the new generator wasn't
able to find.

This dissertation continues by giving a more
in-depth tour of Redex and its test and random
generation capabilities in Chapter 2. 
Chapter 3 then explains how the new method of
random term generation works, and Chapter 4
details work to evaluate its effectiveness.
Chapter 5 discusses related work and
Chapter 6 concludes.


@one-col
