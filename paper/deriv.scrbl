#lang scribble/base

@(require scriblib/figure
          scribble/core
          scribble/manual
          scriblib/footnote
          scribble/latex-prefix
          scribble/latex-properties
          (only-in slideshow/pict scale-to-fit scale)
          (only-in "../models/stlc.rkt" stlc-min-lang-types)
          "deriv-layout.rkt"
          "common.rkt")


@(define (center-rule rule-pict [w-f 1] [h-f 1])
   (centered (scale rule-pict w-f h-f)))

@figure["fig:types"
        @list{Grammar and type system for the simply-typed lambda calculus
	      used in the example derivation.}
        @(center-rule (stlc-min-lang-types))]

@title[#:tag "sec:deriv"]{Example: Generating a Well-Typed Term}

This section gives an overview of our method for generating well-typed
terms by working through the generation of an example term.
We will build a derivation satisfying the judgment form definition
in @figure-ref["fig:types"], a typing judgment for simply-typed
lambda calculus with a single base type of natural numbers.
We begin with a goal pattern, which we will want the conclusion
of the generated derivation to match.

Our goal pattern will be the following: 
@(center-rule
  (typ • e_^0 τ_^0))
stating that we would like to generate an expression with 
arbitrary type in the empty type environment.
We then randomly select one of the type rules. This time, the
generator selects the abstraction rule, which requires us to
specialize the values of @et[e_^0] and
@et[τ_^0] in order to agree with the form of the
rule's conclusion.
To do that, we first generate a new set of
variables to replace the ones in the abstraction rule, and then
unify our conclusion with the specialized rule. We put a super-script 
@et[1] on these variables to indicate that they were introduced in the
first step of the derivation building process, giving us this partial derivation.
@(center-rule
  (infer (typ • (λ (x_^1 τ_x^1) e_^1) (τ_x^1 → τ_^1))
         (typ (x_^1 τ_x^1 •) e_^1 τ_^1)))
The abstraction rule has added a new premise we must now satisfy, so
we follow the same process with the premise. If the generator selects
the abstraction rule again and then the application rule, 
we arrive at the following partial derivation, where the superscripts
on the variables indicate the step where they were generated:
@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (e_1^3 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer  #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (e_1^3 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (e_1^3 e_2^3) τ_^2)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_1^3 (τ_2^3 → τ_^2))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))
Application has two premises, so there are now two unfinished
branches of the derivation. Working on the left side first, 
suppose the generator chooses the variable rule:
@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2)))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))
To continue, we need to use the @et[lookup]
metafunction, whose definition is shown on the left-hand side of
@figure-ref["fig:lookups"]. Unlike judgment forms, however, Redex
metafunction clauses are ordered, meaning that as soon as one of the
left-hand sides matches an input, the corresponding right-hand side is
used for the result. Accordingly, we cannot freely choose a clause of
a metafunction without considering the previous clauses. Internally,
our method treats a metafunction as a judgment form, however, adding
premises to reflect the ordering. 

@figure["fig:lookups"
        "Lookup as a metafunction (left), and the corresponding judgment form (right)."
        @(center-rule (lookup-both-pict))]

For the lookup function, we can use the judgment form shown on the
right of @figure-ref["fig:lookups"].  The only additional premise
appears in the bottom rule and ensures that we only recur with the
tail of the environment when the head does not contain the variable
we're looking for. The general process is more complex than
@et[lookup] suggests and we return to this issue
in @secref["sec:mf-semantics"].

If we now choose that last rule, we have this partial derivation:

@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^4)
                                     (eqt (lookup (x_^1 τ_x^1 •) x_^4) (τ_2^3 → τ_^2))))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))


The generator now chooses @et[lookup]'s first clause,
which has no premises, thus completing the left branch.

@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 (τ_2^3 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 e_2^3))) ((τ_2^3 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_2^3 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) (x_^1 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^1)
                                     (infer (eqt (lookup (x_^1 (τ_2^3 → τ_^2) •) x_^1) (τ_2^3 → τ_^2)))))
                       (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) e_2^3 τ_2^3))))
  1
  1)



Because pattern variables can appear in two different premises (for
example the application rule's @et[τ_2] appears in both premises),
choices in one part of the tree affect the valid choices in other
parts of the tree.  In our example, we cannot satisfy the right
branch of the derivation with the same choices we made on the left,
since that would require @(eqt τ_2^3 (τ_2^3 → τ_^2)).

This time, however, the generator picks the variable rule and then
picks the first clause of the @et[lookup], resulting in the complete
derivation:
@;{
Too wide to scrunch
@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 (τ_x^2 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 x_^2))) ((τ_x^2 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_x^2 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 x_^2)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) (x_^1 x_^2) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^1 (τ_x^2 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^1) (τ_x^2 → τ_^2))
                                     (neqt x_^2 x_^1)
                                     (infer (eqt (lookup (x_^1 (τ_x^2 → τ_^2) •) x_^1) (τ_x^2 → τ_^2)))))
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2 τ_x^2)
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2) τ_x^2))))))
  0.86
  1)}
@(center-rule
  (infer #:h-dec min (typ • (λ (x_^1 (τ_x^2 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 x_^2))) ((τ_x^2 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_x^2 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 x_^2)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) (x_^1 x_^2) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^1 (τ_x^2 → τ_^2))
                              (et ⋮))
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2 τ_x^2)
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2) τ_x^2)))))))

To finish the construction of a random well-typed term, we choose
random values for the remaining, unconstrained variables, e.g.:

@(center-rule
  (text-scale
   (typ • (λ (f (num → num)) (λ (a num) (f a))) ((num → num) → (num → num)))))

We must be careful to obey the constraint that @et[x_^1] and @et[x_^2]
are different, which was introduced earlier during the derivation, as otherwise
we might not get a well-typed term. For example, @et[(λ (f (num → num)) (λ (f num) (f f)))] is not
well-typed but is an otherwise valid instantiation of the non-terminals.
