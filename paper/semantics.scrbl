#lang scribble/base

@(require scriblib/figure
          scribble/core
          scribble/manual
          scriblib/footnote
          racket/pretty
          (only-in pict vc-append ghost)
          (only-in slideshow/pict scale-to-fit scale)
          (only-in "../models/stlc.rkt" stlc-type-pict-horiz)
          (only-in pict vl-append blank)
          "citations.rkt"
          "typesetting.rkt"
          "../models/clp.rkt"
          (except-in "../models/typesetting.rkt" lang-pict)
          "pat-grammar.rkt"
          "common.rkt"
          (only-in pict hbl-append)
          "dist-pict.rkt")


@title[#:tag "sec:semantics"]{Derivation Generation in Detail}

@figure["fig:clp-grammar"
        @list{The syntax of the derivation generator model.}
              @(init-lang)]


This section describes a formal model@note{The corresponding Redex
   model is available from this paper's website (listed after the
   conclusion), including a runnable simple example that may prove
   helpful when reading this section.} of the derivation generator.
The centerpiece of the model is a relation that rewrites programs consisting
of metafunctions and judgment forms into the set of possible derivations 
that they can generate. Our implementation has a structure similar to the
model, except that it uses randomness and heuristics to select just one
of the possible derivations that the rewriting relation can produce.
Our model is based on @citet[clp-semantics]'s constraint logic programming
semantics.

@figure["fig:clp-red"
        @list{Reduction rules describing generation of the complete
              tree of derivations.}
        @(clp-red-pict)]

The grammar in @figure-ref["fig:clp-grammar"] describes the language of the model.
A program @clpt[P] consists of  definitions @clpt[D], which
are sets of inference rules @clpt[((d p) ← a ...)], here written
horizontally with the conclusion on the left and premises on the right. (Note that
ellipses are used in a precise manner to indicate repetition of the immediately
previous expression, in this case @clpt[a], following Scheme tradition. 
They do not indicate elided text.)
Definitions can express both judgment forms and metafunctions. They are a strict
generalization of judgment forms, and metafunctions are compiled
into them via a process we discuss in @secref["sec:mf-semantics"].

The conclusion of each rule has the form @clpt[(d p)], where @clpt[d] is an 
identifier naming the definition and @clpt[p] is a pattern.
The premises @clpt[a] may consist of literal goals @clpt[(d p)] or disequational
constraints @clpt[δ]. We dive into the operational meaning behind
disequational constraints later in this section, but as their form in 
@figure-ref["fig:clp-grammar"] suggests, they are a disjunction of negated equations, 
in which the variables listed following @clpt[∀] are universally quantified.
The remaining variables in a disequation are implicitly existentially
quantified, as are the variables in equations.

The reduction relation shown in @figure-ref["fig:clp-red"] generates
the complete tree of derivations for the program @clpt[P]
with an initial goal of the form @clpt[(d p)], where
@clpt[d] is the identifier of some definition
in @clpt[P] and @clpt[p] is a pattern
that matches the conclusion of all of the generated derivations.
The relation is defined using two rules: @rule-name{reduce} and @rule-name{new constraint}.
The states that the relation acts on are of the form @clpt[(P ⊢ (a ...) ∥ C)],
where @clpt[(a ...)] represents a stack of goals, which can
either be incomplete derivations of the form @clpt[(d p)], indicating a
goal that must be satisfied to complete the derivation, or disequational constraints 
that must be satisfied. A constraint store @clpt[C] is a set of 
simplified equations and disequations that are guaranteed to be satisfiable.
The notion of equality we use here is purely syntactic; two ground terms are equal
to each other only if they are identical.

Each step of the rewriting relation
looks at the first entry in the goal stack and rewrites to another
state based on its contents.
In general, some reduction sequences are ultimately
doomed, but may still reduce for a while before the constraint
store becomes inconsistent. In our implementation,
discovery of such doomed reduction sequences causes backtracking. Reduction
sequences that lead to valid derivations
always end with a state of the form @clpt[(P ⊢ () ∥ C)], and the derivation 
itself can be read off of the reduction sequence that reaches that state.

When a goal of the form @clpt[(d p)] is the first element
of the goal stack (as is the root case, when the initial goal is the
sole element), then the @rule-name{reduce} rule applies. For every
rule of the form @clpt[((d p_r) ← a_r ...)] in the program such
that the definition's id @clpt[d] agrees with the goal's, a reduction
step can occur. The reduction step first freshens the variables in
the rule, asks the solver to combine the equation @clpt[(p_f = p_g)] 
with the current constraint store, and reduces to a new state with
the new constraint store and a new goal state. If the solver fails,
then the reduction rule doesn't apply (because @clpt[solve] returns @clpt[⊥]
instead of a @clpt[C_2]). The new goal stack has
all of the previously pending goals as well as the new ones introduced
by the premises of the rule.

The @rule-name{new constraint} rule covers the case where a disequational constraint @clpt[δ] 
is the first element in the goal
stack. In that case, the disequational solver is called with the
current constraint store and the disequation. If it returns a new constraint
store, then the disequation is consistent and the new constraint store is
used.

The remainder of this section fills in the details in this model and
discusses the correspondence between the model and the implementation
in more detail.
Metafunctions are added via a procedure generalizing the 
process used for @clpt[lookup] in @secref["sec:deriv"], 
which we explain in @secref["sec:mf-semantics"]. 
@Secref["sec:solve"] describes how our solver handles
equations and disequations.
@Secref["sec:search"] discusses the heuristics in our implementation
and @secref["sec:pats"] describes how our implementation
scales up to support features in Redex that are not covered in this model.

@section[#:tag "sec:mf-semantics"]{Compiling Metafunctions}

The primary difference between a metafunction, as written in Redex,
and a set of @clpt[((d p) ← a ...)] clauses from @figure-ref["fig:clp-grammar"]
is sensitivity to the ordering of clauses. 
Specifically, when the second clause in a metafunction fires,
then the pattern in the first clause must not match, in contrast to
the rules in the model, which fire regardless of their relative order. Accordingly,
the compilation process that translates metafunctions into the model must
insert disequational constraints to capture the ordering of the cases.

As an example, consider the
metafunction definition of @clpt[g] on the left and some example applications on the right:
@centered{@(f-ex-pict)}
The first clause matches any two-element list, and the second clause matches
any pattern at all. Since the clauses apply in order, an application where the
argument is a two-element list will reduce to @clpt[2] and an argument of any
other form will reduce to @clpt[1]. To generate conclusions of the judgment
corresponding to the second clause, we have to be careful not to generate
anything that matches the first.

Applying the same idea as @clpt[lookup] in @secref["sec:deriv"], 
we reach this incorrect translation:
@centered{@(incorrect-g-jdg-pict)}
This is wrong because it would let us derive
@(hbl-append 2 @g-of-12 @clpt[=] @clpt[1]), 
using @clpt[3] for @clpt[p_1] and
@clpt[4] for @clpt[p_2] in the premise of the right-hand rule.
The problem is that we need to disallow all possible instantiations
of @clpt[p_1] and @clpt[p_2], but the variables 
can be filled in with just specific values to satisfy the premise.

The correct translation, then, universally quantifies the variables
@clpt[p_1] and @clpt[p_2]:
@centered{@(g-jdg-pict)}
Thus, when we choose the second rule,
we know that the argument will never be able to match the first clause.

In general, when compiling a metafunction clause, we add a disequational
constraint for each previous clause in the metafunction definition.
Each disequality is between the left-hand side patterns of one of the previous
clauses and the left-hand side of the current clause, and it is quantified 
over all variables in the previous clause's left-hand side.


@section[#:tag "sec:solve"]{The Constraint Solver}

The constraint solver maintains a set of equations and
disequations that captures invariants of the current
derivation that it is building. These constraints are called
the constraint store and are kept in the canonical form 
@clpt[C], as shown in @figure-ref["fig:clp-grammar"], with
the additional constraint that the equational portion of the
store can be considered an idempotent substitution. That is, it always
equates variables with with @clpt[p]s and, no variable on 
the left-hand side of an equality also appears in any
right-hand side. Whenever a new
constraint is added, consistency is checked again
and the new set is simplified to maintain the canonical
form.

@;{
To better understand how the solver works, consider the following
definition of evenness for Peano numbers, a series of @clpt[r]
clauses at left compiled via the process of @secref["sec:mf-semantics"] from
the somewhat awkward predicate defined at left:
@table[(style #f (list (table-cells `((,(style #f '(bottom))
                                       ,(style #f '(bottom))
                                       ,(style #f '(bottom)))))))
       (list
        (list
         (paragraph (style #f '())
                    (list (vc-append (even?-pict)
                                     (blank 25))))
         (paragraph (style #f '()) (hspace 3))
         (table (style #f (list (table-cells `((,(style #f '(top)))
                                               (,(style #f '(vcenter)))
                                               (,(style #f '(bottom)))))))
                (parameterize ([pretty-print-columns 60])
                  (list (list 
                         (paragraph (style #f '()) 
                                    (list @clpt/e[(list-ref awkward-even-rw 0)])))
                        (list 
                         (paragraph (style #f '()) 
                                    (list @clpt/e[(list-ref awkward-even-rw 1)])))
                        (list 
                         (paragraph (style #f '()) 
                                    (list (vc-append (blank 2)
                                                     @clpt/e[(list-ref awkward-even-rw 2)])))))))
         ))]
As a running example to illustrate our solver, we'll follow a short reduction
sequence based on a program @clpt[P] containing only the above definition.}


@Figure-ref["fig:solve"] shows @clpt[solve], the entry point to the solver
for new equational constraints. It accepts an equation and a constraint
store and either returns a new constraint store that is equivalent to
the conjunction of the constraint store and the equation or @clpt[⊥], indicating
that adding @clpt[e] is inconsistent with the constraint store. 
In its body, it first applies the equational portion of the constraint
store as a substitution to the equation. Second, it
performs syntactic unification@~cite[baader-snyder] of
the resulting equation with the equations from the original
store to build a new equational portion of the constraint.
Third, it calls @clpt[check], which simplifies the disequational constraints
and checks their consistency. Finally, if all that succeeds, @clpt[check] 
returns a constraint store that combines the results of
@clpt[unify] and @clpt[check]. If either @clpt[unify] or @clpt[check] fails, then
@clpt[solve] returns @clpt[⊥].

@figure["fig:solve"
        @list{The Solver for Equations}
        @(vl-append
          20
          (solve-pict)
          (unify-pict))]

@figure["fig:dissolve"
        "The Solver for Disequations"
        @(vl-append
          20
          (dissolve-pict)
          (disunify-pict))]

@Figure-ref["fig:dissolve"] shows @clpt[dissolve], the disequational
counterpart to @clpt[solve]. It applies the equational part
of the constraint store as a substitution to the new disequation
and then calls @clpt[disunify]. It @clpt[disunify] returns
@clpt[⊤], then the disequation was already guaranteed in the current
constraint store and thus does not need to be recorded. If @clpt[disunify]
returns @clpt[⊥] then the disequation is inconsistent with the current
constraint store and thus @clpt[dissolve] itself returns @clpt[⊥]. 
In the final situation, @clpt[disunify] returns a new disequation, 
in which case @clpt[dissolve] adds that to the resulting constraint store.

@figure["fig:dis-help"
        @list{Metafunctions used to process disequational constaints.}
        @(vl-append
          20
          (param-elim-pict)
          (check-pict))]

The @clpt[disunify] function exploits unification and a few cleanup steps
to determine if the input disequation is satisfiable. In addition, 
@clpt[disunify] is always called with a disequation that has had the 
equational portion of the constraint store applied to it (as a substitution).

The key trick in this function is to observe that since
a disequation is always a disjunction of inequalities, its negation is
a conjuction of equalities and is thus suitable as an input to unification. 
The first case in @clpt[disunify] covers the case where unification fails.
In this situation we know that the disequation must have already been guaranteed
to be false in constraint store (since the equational portion of the constraint
store was applied as a substitution before calling @clpt[disunify]). Accordingly,
@clpt[disunify] can simply return @clpt[⊤] to indicate that the disequation
was redundant. 

Ignoring the call to @clpt[param-elim] in the second case of @clpt[disunify] for
a moment, consider the case where @clpt[unify] returns an empty conjunct. This means
that @clpt[unify]'s argument is guaranteed to be true and thus the given disequation
is guaranteed to be false. In this case, we have failed to generate a valid
derivation because one of the negated disequations must be false (in terms of the original
Redex program, this means that we attempted to use some later case in a metafunction
with an input that would have satisfied an earlier case) and so @clpt[disunify] must
return @clpt[⊥]. 

But there is a subtle point here. Imagine that @clpt[unify] returns
only a single clause of the form @clpt[(x = p)] where @clpt[x] is one of the 
universally quantified variables. We know that in that case, the corresponding
disequation @clpt[(∀ (x) (x ≠ p))] is guaranteed to be false because
every pattern admits at least one concrete term. This is where
@clpt[param-elim] comes in. It cleans up the result of @clpt[unify]
by eliminating all clauses that, when negated and placed back
under the quantifier would be guaranteed false, so the reasoning
in the previous paragraph holds and the second case of @clpt[disunify]
behaves properly.

The last case in @clpt[disunify] covers the situation
where @clpt[unify] composed with @clpt[param-elim] returns a non-empty substitution. 
In this case, we do not yet know if the disequation is true or false, so we collect
the substitution that @clpt[unify] returned back into a disequation and return it,
to be saved in the constraint store.

This brings us to @clpt[param-elim], in 
@figure-ref["fig:dis-help"]. Its first argument is a
unifier, as produced by a call to @clpt[unify] to handle a
disequation, and the second argument is the universally
quantified variables from the original disequation. Its goal
is to clean up the unifier by removing redundant and useless
clauses. 

There are two ways in which clauses can be false. In addition
to clauses of the form @clpt[(x = p)] where
@clpt[x] is one of the universally quantified variables, 
it may also be the case that we have a clause of the form
@clpt[(x_1 = x)] and, as before, @clpt[x] is one of
the universally quantified variables. This clause also must
be dropped, according to the same reasoning (since @clpt[=] is symmetric).
But, since variables on the right hand side of an equation may also appear elsewhere,
some care must be taken here to avoid losing transitive inequalities.
The function @clpt[elim-x] (not shown) handles this situation, constructing a new
set of clauses without @clpt[x] but, in the case that we also have
@clpt[(x_2 = x)], adds back the equation @clpt[(x_1 = x_2)]. For the
full definition of @clpt[elim-x] and a proof that it works correctly,
we refer the reader to the first author's masters dissertation@~cite[burke-masters].

Finally, we return to @clpt[check], shown in @figure-ref["fig:dis-help"],
which is passed the updated disequations after
a new equation has been added in @clpt[solve] (see @figure-ref["fig:solve"]).
It verifies the disequations and maintains
their canonical form, once the new substitution has been applied.
It does this by applying @clpt[disunify] to any non-canonical disequations.

@section[#:tag "sec:search"]{Search Heuristics}

To pick a single derivation from the set of candidates, our
implementation must make explicit choices when there are
differing states that a single reduction state
reduces to. Such choices happen only in the
@rule-name{reduce} rule, and only because there may be
multiple different clauses, @clpt[((d p) ← a ...)], that could
be used to generate the next reduction state.

To make these choices, our implementation collects all of
the candidate cases for the next definition to explore. It
then randomly permutes the candidate rules and chooses the
first one of the permuted rules, using it as the next piece
of the derivation. It then continues to search for a
complete derivation. That process may fail, in which case
the implementation backtracks to this choice and picks the
next rule in the permuted list. If none of the choices
leads to a successful derivation, then this attempt
is failure and the implementation either backtracks
to an earlier such choice, or fails altogether.

There are two refinements that the implementation applies to
this basic strategy. First, the search process has a depth 
bound that it uses to control which production to choose.
Each choice of a rule increments the depth bound and when
the partial derivation exceeds the depth bound, then the
search process no longer randomly permutes the candidates.
Instead, it simply sorts them by the number of premises they have, 
preferring rules with fewer premises in an attempt to finish
the derivation off quickly.

@figure["fig:d-plots" 
        @list{Density functions of the distributions used for the depth-dependent 
              rule ordering, where the depth limit is @(format "~a" max-depth)
              and there are @(format "~a" number-of-choices) rules.}
        @(centered (d-plots 420))]

The second refinement is the choice of how to randomly
permute the list of candidate rules, and the generator uses
two strategies. The first strategy is to just select
from the possible permutations uniformly at random. The
second strategy is to take into account how many premises
each rule has and to prefer rules with more premises near
the beginning of the construction of the derivation and
rules with fewer premises as the search gets closer to the
depth bound. To do this, the implementation sorts all of the possible
permutations in a lexicographic order based on the number of
premises of each choice. Then, it samples from a
binomial distribution whose size matches the number of
permutations and has probability proportional to the ratio of
the current depth and the maximum depth. The sample determines
which permutation to use.

More concretely, imagine that the depth bound was 
@(format "~a" max-depth) and there are 
@(if (= max-depth number-of-choices) "also" "")
@(format "~a" number-of-choices) rules available.
Accordingly, there are @(format "~a" nperms) different ways
to order the premises.  The graphs in 
@figure-ref["fig:d-plots"] show the probability of choosing
each permutation at each depth. Each graph has one
x-coordinate for each different permutation and the height
of each bar is the chance of choosing that permutation. The
permutations along the x-axis are ordered lexicographically
based on the number of premises that each rule has (so
permutations that put rules with more premises near the
beginning of the list are on the left and permutations that
put rules with more premises near the end of the list are
on the right). As the graph shows, rules with more premises
are usually tried first at depth 0 and rules with fewer premises
are usually tried first as the depth reaches the depth bound.

These two permutation strategies are complementary, each
with its own drawbacks. Consider using the first strategy
that gives all rule ordering equal probability with the
rules shown in @figure-ref["fig:types"]. At the initial step
of our derivation, we have a 1 in 4 chance of choosing the
type rule for numbers, so one quarter of all expressions
generated will just be a number. This bias towards numbers
also occurs when trying to satisfy premises of the other,
more recursive clauses, so the distribution is skewed toward
smaller derivations, which contradicts commonly held wisdom
that bug finding is more effective when using larger terms.
The other strategy avoids this problem, biasing the
generation towards rules with more premises early on in the
search and thus tending to produce larger terms.
Unfortunately, our experience testing Redex program suggests
that it is not uncommon for there to be rules with large
number of premises that are completely unsatisfiable when
they are used as the first rule in a derivation (when this
happens there are typically a few other, simpler rules that
must be used first to populate an environment or a store
before the interesting and complex rule can succeed). For
such models, using all rules with equal probability still
is less than ideal, but is overall more likely to produce
terms at all. 

Since neither strategy for ordering rules is always
better than the other, our implementation decides between
the two randomly at the beginning of the search
process for a single term, and uses the same strategy
throughout that entire search. This is the approach
the generator we evaluate in @secref["sec:evaluation"]
uses.

Finally, in all cases we terminate searches that appear to
be stuck in unproductive or doomed parts of the search space
by placing limits on backtracking, search depth, and a
secondary, hard bound on derivation size. When these limits
are violated, the generator simply abandons the current
search and reports failure.

@section[#:tag "sec:pats"]{A Richer Pattern Language}

@figure["fig:full-pats" 
        @list{The subset of Redex's pattern language supported by the generator.
           Racket symbols are indicated by @italic{s}, and 
           @italic{c} represents any Racket constant.}
        @(centered(pats-supp-lang-pict))]

The model we present in @secref["sec:semantics"] uses a much simpler pattern language 
than Redex itself. 
The portion of Redex's internal pattern language supported by the generator@note{The 
   generator is not able to handle parts of the
   pattern language that deal with evaluation contexts or 
   ``repeat'' patterns (ellipses).} is shown in @figure-ref["fig:full-pats"].
We now discuss briefly the interesting differences between this language and
the language of our model and how we support them in Redex's implementation.

Named patterns of the form @slpt[(:name s p)]
correspond to variables @italic{x} in the simplified version of the pattern
language from @figure-ref["fig:clp-grammar"], except that the variable @slpt[s]
is paired with a pattern @slpt[p].
From the matcher's perspective, this form is intended to match a 
term with the pattern @slpt[p] and then bind the matched term to the name @slpt[s]. 
The generator pre-processes all patterns with a first pass that extracts
the attached pattern @slpt[p] and attempts to update the current
constraint store with the equation @slpt[(s = p)], after which @slpt[s] can
be treated as a logic variable.

The @slpt[b] and @slpt[v] non-terminals are built-in patterns that match subsets of
Racket values. The productions of @slpt[b] are straightforward; @slpt[:integer], for example,
matches any Racket integer, and @slpt[:any] matches any Racket s-expression.
From the perspective of the unifier, @slpt[:integer] is a term that
may be unified with any integer, the result of which is the integer itself.
The value of the term in the current substitution is then updated.
Unification of built-in patterns produces the expected results; 
for example unifying @slpt[:real] and @slpt[:natural] produces @slpt[:natural], whereas
unifying @slpt[:real] and @slpt[:string] fails.

The productions of @slpt[v] match Racket symbols in varying and commonly useful ways;
@slpt[:variable-not-otherwise-mentioned], for example, matches any symbol that is not used
as a literal elsewhere in the language. These are handled similarly to the patterns of
the @slpt[b] non-terminal within the unifier.

Patterns of the from @slpt[(mismatch-name s p)]  match the pattern 
@slpt[p] with the constraint that two occurrences of the same name @slpt[s] may never
match equal terms. These are straightforward: whenever a unification with a mismatch takes
place, disequations are added between the pattern in question and other patterns
that have been unified with the same mismatch pattern.

Patterns of the form @slpt[(nt s)] refer to a user-specified grammar, and
match a term if it can be parsed as one of the productions of the non-terminal
@slpt[s] of the grammar. It is less obvious how such
non-terminal patterns should be dealt with in the unifier. 
To unify two such patterns, the intersection of two non-terminals should
be computed, which reduces to the problem of computing the intersection 
of tree automata, for which there is no efficient algorithm@~cite[tata].
Instead a conservative check is used at the time of unification.
When unifying a non-terminal with another pattern, we attempt
to unify the pattern with each production of the non-terminal, 
replacing any embedded non-terminal references with the pattern @slpt[:any]. 
We require that at least one of the unifications succeeds.
Because this is not a complete check for pattern intersection, we save the names
of the non-terminals as extra information embedded in the constraint store
until the entire generation process is complete.
Then, once we generate a concrete term, we check to see if any of the
non-terminals would have been violated (using a matching algorithm). 
This means that we can get failures at this stage of generation, but it
tends not to happen very often for practical Redex models.@note{To be more
  precise, on the Redex benchmark (see @secref["sec:benchmark"]) such failures
  occur on all ``delim-cont'' models 2.9±1.1% of the time, on all ``poly-stlc''
  models 3.3±0.3% of the time, on the ``rvm-6'' model 8.6±2.9% of the time,
  and are not observed on the other models.}
  
