#lang scribble/base

@(require scriblib/figure
          scribble/core
          scribble/manual
          scriblib/footnote
          scribble/latex-prefix
          scribble/latex-properties
          (only-in slideshow/pict scale-to-fit scale)
          (only-in "models/stlc.rkt" stlc-type-pict-horiz)
          "deriv-layout.rkt")



@title[#:style 
       (style #f (list (latex-defaults 
                        (string->bytes/utf-8 
                         (string-append "\\documentclass{article}\n"
                                        unicode-encoding-packages
                                        "\\usepackage{fullpage}\n"
                                        "\\usepackage{multicol}\n"))
                        #"" '())))]{An Example Derivation}


@(define two-cols (element (style "begin" '(exact-chars))
                           '("multicols}{2")))

@(define one-col (element (style "end" '(exact-chars))
                          '("multicols")))


@figure["fig:types"
        "Typing judgment for the simply-typed lambda calculus"
        @centered[stlc-type-pict-horiz]]

@two-cols

The judgment-form based random generator uses the strategy of
attempting to generate a random derivation satisfying the
judgment. To motivate how it works, we will work through the
generation of an example derivation for the type system shown
in @figure-ref["fig:types"]. We can begin with a schema for
how we would like the resulting judgment to look. We would like
to find a derivation for some expression @(stlc-term e_^0)
with some type @(stlc-term τ_^0) in the empty environment:

@(centered
  (typ • e_^0 τ_^0))

Where we have added superscripts to distinguish variables introduced 
in this step from those introduced later; since this is the initial
step, we mark them with the index 0.
The rule chosen in the initial generation step will be final
rule of the derivation.
The derivation will have to end with some rule, so 
we randomly choose one, suppose it is the abstraction rule.
Choosing that rule will require us to specialize the values
of @(stlc-term e_^0) and @(stlc-term τ_^0) in order to agree
with the form of the rule's conclusion.
Once we do so, we have a partial derivation that looks like:

@(centered
  (infer (typ • (λ (x_^1 τ_x^1) e_^1) (τ_x^1 → τ_^1))
         (typ (x_^1 τ_x^1 •) e_^1 τ_^1)))

Variables from this step are marked with a 1.
This will work fine, so long as we can recursively generate a derivation
for the premise we have added. We can randomly choose a rule again and try
to do so. 

If we next choose abstraction again, followed by function application, 
we arrive at the following partial derivation:

@one-col

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (e_1^3 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer  #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (e_1^3 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (e_1^3 e_2^3) τ_^2)
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_1^3 (τ_2^3 → τ_^2))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))

@two-cols

Abstraction has two premises, so now there are two branches of the derivation
that need to be filled in. We can work on the left side first.
Suppose we make a random choice to use the variable rule there, and
arrive at the following:

@one-col

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2)))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))

@two-cols

At this point it isn't obvious how to continue, because @tt{lookup} is defined as
a metafunction, and we are generating a derivation using a method based on judgment forms. 
To complete the derivation for @tt{lookup}, we will treat it as a judgment form, except that 
we have to be careful to preserve its meaning, since judgment form cases don't apply in order
and, in fact, the second case of @tt{lookup} overlaps with the first. So that we can never
apply the rule corresponding to the second case when we should be using the first, we
will add a second premise to that rule stating that @italic{x@subscript{1} ≠ x@subscript{2}}.
The new version of @tt{lookup} is shown in @figure-ref["fig:lookups"], alongside the original. If
we now choose the @tt{lookup} rule that recurs on the tail of the environment (corresponding
to the second clause of the metafunction), the partial 
derivation looks like: 

@one-col

@figure["fig:lookups"
        "Lookup as a metafunction (left), and as a judgment form."
        @centered[(lookup-both-pict)]]

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 τ_x^1) (λ (x_^2 τ_x^2) (x_^4 e_2^3))) (τ_x^1 → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 τ_x^1 •) (λ (x_^2 τ_x^2) (x_^4 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) (x_^4 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 τ_x^1 •)) x_^4) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^4)
                                     (eqt (lookup (x_^1 τ_x^1 •) x_^4) (τ_2^3 → τ_^2))))
                       (typ (x_^2 τ_x^2 (x_^1 τ_x^1 •)) e_2^3 τ_2^3)))))

@two-cols

This branch of the derivation can be completed by choosing the rule corresponding to
the first clause of @tt{lookup} to get:

@one-col

@(centered
  (infer #:h-dec min (typ • (λ (x_^1 (τ_2^3 → τ_^2)) (λ (x_^2 τ_x^2) (x_^1 e_2^3))) ((τ_2^3 → τ_^2) → (τ_x^2 → τ_^2)))
         (infer #:h-dec min (typ (x_^1 (τ_2^3 → τ_^2) •) (λ (x_^2 τ_x^2) (x_^1 e_2^3)) (τ_x^2 → τ_^2))
                (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) (x_^1 e_2^3) τ_^2)
                       (infer (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1 (τ_2^3 → τ_^2))
                              (infer (eqt (lookup (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) x_^1) (τ_2^3 → τ_^2))
                                     (neqt x_^2 x_^1)
                                     (infer (eqt (lookup (x_^1 (τ_2^3 → τ_^2) •) x_^1) (τ_2^3 → τ_^2)))))
                       (typ (x_^2 τ_x^2 (x_^1 (τ_2^3 → τ_^2) •)) e_2^3 τ_2^3)))))

@two-cols

It is worth noting at this point that the form of the partial derivation may sometimes exclude
rules from being chosen. For example, we couldn't satisfy the right branch of the derivation in the same way,
since that would eventually mean that @(eqt τ_2^3 (τ_2^3 → τ_^2)), leaving us with no finite value
for @(stlc-term τ_2^3). 
However, we can complete the right branch by again choosing (randomly) the variable rule, followed
by the rule corresponding to @tt{lookup}'s first clause, arriving at:

@one-col

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

@two-cols

At this point we have a complete derivation for a pattern of non-terminals that is valid for
any term that matches that pattern as long as the new premise that 
@(neqt x_^2 x_^1) is also satisfied. Thus we can simply
pick appropriate random values for @(stlc-term x_^1) and all other non-terminals
in the pattern to get
a random term that satisfies the typing judgment. An example would be:

@one-col

@(centered
  (typ • (λ (f (num → num)) (λ (a num) (f a))) ((num → num) → (num → num))))

@two-cols

and the constraint that @tt{f} ≠ @tt{a} is satisfied. We note however, the 
importance of this constraint, since a term that does not satisfy it, such
as @(stlc-term (λ (f (num → num)) (λ (f num) (f f)))), is not well-typed.

In the remainder of this chapter, the approach used in this example
is generalized to all Redex judgment forms and metafunctions.

@one-col
