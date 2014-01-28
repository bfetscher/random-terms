#lang scribble/base

@(require scriblib/figure
          scribble/core
          scribble/manual
          scriblib/footnote
          scribble/latex-prefix
          scribble/latex-properties
          (only-in slideshow/pict scale-to-fit scale)
          (only-in "models/stlc.rkt" stlc-min-lang-types)
          "deriv-layout.rkt"
          "common.rkt")

@title{An Example Derivation}

@figure["fig:types"
        @(list "Grammar and type system for the simply-typed lambda calculus"
               " used in the example derivation. "
              @tt{lookup}
              " is a metafunction that returns the corresponds type " @italic{τ}
              " matching some variable " @italic{x} " (see "
              @figure-ref["fig:lookups"] ").")
        (centered stlc-min-lang-types)]

To introduce the method used to generate well-typed terms,
we begin with an example that works through the generation
of a single term. The term will satisfy
the type system shown in @figure-ref["fig:types"], a simply-typed
lambda calculus with a single base type of natural numbers (@tt{num}).
We use the strategy of attempting to generate a random
derivation satisfying the judgment. 
Once we have such a derivation it is easy to fill in any
remaining holes to create a well-typed term.
We can begin with a schema for
how we would like the resulting judgment to look. We would like
to find a derivation for some expression @(text-scale(stlc-term e_^0))
with some type @(text-scale (stlc-term τ_^0)) in the empty environment:

@(centered
  (typ • e_^0 τ_^0))

Where we have added superscripts to distinguish variables introduced 
in this step from those introduced later; since this is the initial
step, we mark them with the index 0.
The rule chosen in the initial generation step will be final
rule of the derivation.
At this point we can choose from any of the rules, so
suppose that, choosing randomly, we pick the rule for abstraction.
Choosing that rule will require us to specialize the values
of @(text-scale (stlc-term e_^0)) and @(text-scale (stlc-term τ_^0)) in order to agree
with the form of the rule's conclusion.
Once we do so, we have a partial derivation that looks like:

@(centered
  (infer (typ • (λ (x_^1 τ_x^1) e_^1) (τ_x^1 → τ_^1))
         (typ (x_^1 τ_x^1 •) e_^1 τ_^1)))

Variables from this step are marked with a 1.
The abstraction rule has added a new premise we must
now satisfy, so we will
recursively attempt to generate a derivation that will do so.
Again, we randomly chose some rule from the judgment and attempt
to apply it.
If we next choose abstraction again, followed by function application, 
we arrive at the following partial derivation:

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (e_1^3 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer  #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (e_1^3 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (e_1^3 e_2^3) τ_^2)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_1^3 (τ_2^3 → τ_^2))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))


Abstraction has two premises, so now there are two branches of the derivation
that need to be filled in. We can work on the left side first.
Suppose we make a random choice to use the variable rule there, and
arrive at the following:


@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2)))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))


At this point it isn't obvious how to continue, because @tt{lookup} is defined as
a metafunction (see @figure-ref["fig:lookups"]), not a judgment form,
so we can't continue in exactly the same way.
To complete the derivation for @tt{lookup}, we will treat it as a judgment form, with a 
few caveats to. We must be careful to preserve its meaning since judgment form cases don't apply in order
and, in fact, the second case of @tt{lookup} overlaps with the first. So that we can never
apply the rule corresponding to the second case when we should be using the first, we
will add a second premise to that rule stating that @italic{x@subscript{1} ≠ x@subscript{2}}.
The new version of @tt{lookup} is shown in @figure-ref["fig:lookups"], alongside the original. If
we now choose the @tt{lookup} rule that recurs on the tail of the environment (corresponding
to the second clause of the metafunction), the partial 
derivation looks like: 


@figure["fig:lookups"
        "Lookup as a metafunction (left), and as a judgment form."
        @centered[(lookup-both-pict)]]

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer #:add-ids (τ_2^3)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^4)
                                     (eqt (lookup (x_^1 τ_x^1 •) x_^4) (τ_2^3 → τ_^2))))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))


This branch of the derivation can be completed by choosing the rule corresponding to
the first clause of @tt{lookup} to get:


@(centered
  (infer #:h-dec min (typ • (λ (x_^1 (τ_2^3 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 e_2^3))) ((τ_2^3 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_2^3 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) (x_^1 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^1)
                                     (infer (eqt (lookup (x_^1 (τ_2^3 → τ_^2) •) x_^1) (τ_2^3 → τ_^2)))))
                       (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) e_2^3 τ_2^3)))))


It is worth noting at this point that the form of the partial derivation may sometimes exclude
rules from being chosen. For example, we couldn't satisfy the right branch of the derivation in the same way
as the laft, since that would eventually mean that @(text-scale (eqt τ_2^3 (τ_2^3 → τ_^2))), 
leaving us with no finite value for @(text-scale (stlc-term τ_2^3)).
However, we can complete the right branch by again choosing (randomly) the variable rule, followed
by the rule corresponding to @tt{lookup}'s first clause, arriving at:


@(centered
  (infer #:h-dec min (typ • (λ (x_^1 (τ_x^2 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 x_^2))) ((τ_x^2 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_x^2 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 x_^2)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) (x_^1 x_^2) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^1 (τ_x^2 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^1) (τ_x^2 → τ_^2))
                                     (neqt x_^2 x_^1)
                                     (infer (eqt (lookup (x_^1 (τ_x^2 → τ_^2) •) x_^1) (τ_x^2 → τ_^2)))))
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2 τ_x^2)
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_x^2 → τ_^2) •)) x_^2) τ_x^2)))))))


At this point we have a complete derivation for a pattern of non-terminals that is valid for
any term that matches that pattern as long as the new premise that 
@(text-scale (neqt x_^2 x_^1)) is also satisfied. Thus we can simply
pick appropriate random values for @(text-scale (stlc-term x_^1)) and all other non-terminals
in the pattern to get
a random term that satisfies the typing judgment. An example would be:


@(centered
  (text-scale
   (typ • (λ (f (num → num)) (λ (a num) (f a))) ((num → num) → (num → num)))))


The constraint that @tt{f} ≠ @tt{a} is satisfied. We note however, the 
importance of this constraint, since a term that does not satisfy it, such
as @(text-scale (stlc-term (λ (f (num → num)) (λ (f num) (f f))))), is not well-typed.

@two-cols