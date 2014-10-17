#lang scribble/base

@(require scriblib/figure
          scribble/core
          scribble/manual
          scriblib/footnote
          (only-in slideshow/pict scale-to-fit scale)
          (only-in "models/stlc.rkt" stlc-type-pict-horiz)
          (only-in pict vl-append)
          "citations.rkt"
          "typesetting.rkt"
          "models/clp.rkt"
          (except-in "models/typesetting.rkt" lang-pict)
          "pat-grammar.rkt"
          "common.rkt"
          (only-in pict hbl-append)
          "dist-pict.rkt")

@title[#:tag "sec:semantics"]{Derivation Generation in Detail}


This section describes a formal model of the derivation generator.
The centerpiece of the model is a relation that rewrites programs consisting
of metafunctions and judgment forms into the set of possible derivations 
that they can generate. Our implementation has a structure similar to the
model, except that it uses randomness and heuristics to select just one
of the possible derivations that the rewriting relation can produce.
Our model is based on @citet[clp-semantics]'s constraint logic programming
semantics.

@figure["fig:clp-grammar"
        @list{The syntax of the derivation generator model.}
              @(init-lang)]

The grammar in @figure-ref["fig:clp-grammar"] describes the language of the model.
A program @clpt[P] consists of  definitions @clpt[D] and each definition consists 
of a set of inference rules @clpt[((d p) ← a ...)], here written
horizontally with the conclusion on the left and premises on the right. (Note that
ellipses are used in a precise manner to indicate repetition of the immediately
previous expression, following Scheme tradition. They do not indicate elided text.)
Definitions can express both judgment forms and metafunctions. They are a strict
generalization of judgment forms, and metafunctions are compiled
into them via a process we discuss in @secref["sec:mf-semantics"].

The conclusion of each rule has the form @clpt[(d p)], where @clpt[d] is an 
identifier naming the definition and @clpt[p] is a pattern.
The premises @clpt[a] may consist of literal goals @clpt[(d p)] or disequational
constraints @clpt[δ]. We dive into the operational meaning behind
disequational constraints later in this section, but as their form suggests, they are
the negation of an equation, in which some variables are universally quantified.
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

@figure["fig:clp-red"
        @list{Reduction rules describing generation of the complete
              tree of derivations.}
        @(clp-red-pict)]

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
is ordering. Specifically, when the second clause in a metafunction fires,
the then the pattern in the first clause must not match, but there is no
ordering on rules in the model. Accordingly,
the compilation process that translates metafunctions into the model must
insert disequation constraints that capture the ordering of the cases
in metafunctions.

As an example, consider the
metafunction definition of @clpt[g] on the left and some example applications on the right:
@centered{@(f-ex-pict)}
The first clause matches any two-element list, and the second clause matches
any pattern at all. Since the clauses apply in order, an application where the
argument is a two-element list will reduce to @clpt[2] and an argument of any
other form will reduce to @clpt[1]. To generate conclusions of the judgment
corresponding to the second clause, we have to be careful not to generate
anything that matches the first.

@;{
Leaving this here for reference...
Suppose p are patterns, t are terms (essentially patterns with no variables from this perspective), 
and s are substitutions (finite maps from variables to patterns). s(p) applies a substitution
to a pattern.

1. Matching is easy to define:
Matches[p,t] <=> \exists s, s(p) = t

2. If a match doesn’t exist:
\not Matches[p,t] <=> \not \exists s, s)p) = t <=> \forall s, s(p) =/= t

3: Finally, given two patterns, there is a notion of it being possible to cause the 
match to fail by instantiating the second pattern in some way, call it “excludable”:
Excludable[p_1, p_2] <=> \exists s, \not Matches[p_1, s(p_2)]

Expanding out the final definition, it becomes the more complicated looking:
\exists s_1, \forall s, s(p_1) =/= s_1(p_2)}

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

@figure["fig:solve"
        @list{The Solver for Equations}
        @(vl-append
          20
          (solve-pict)
          (unify-pict))]

@section[#:tag "sec:solve"]{The Constraint Solver}

The constraint solver maintains a set of equations and
disequations that captures invariants of the current
derivation that it is building. These contraints are called
the constraint store and are kept in the canonical form 
@clpt[C], as shown in @figure-ref["fig:clp-grammar"], with
the additional constraint that the equational portion of the
store is idempotent (when applied as a substitution) and
that @clpt[C] is always satisfiable. Whenever a new
constraint is added to the set, consistency is checked again
and the new set is simplified to maintain the canonical
form.

@Figure-ref["fig:solve"] shows @clpt[solve], the entry point to the solver
for new equational constraints. It accepts an equation and a constraint
store and either returns a new constraint store that is equivalent to
the conjunction of the constraint store and the equation or @clpt[⊥], indicating
that adding @racket[e] is inconsistent with the constraint store. It
applies the equational portion of the constraint store as a substitution and
then performans syntactic unification@~cite[baader-snyder] to build a new equational 
portion of the constraint. It then calls @clpt[check], which simplifies the disequational constraints
and checks their consistency. Finally, if all that succeeds, @clpt[check] 
returns a constraint store that combines the results of
@clpt[unify] and @clpt[check]. If either @clpt[unify] or @clpt[check] fails, then
@clpt[solve] returns @clpt[⊥].

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
derivation because one of the disequations must be false (in terms of the original
Redex program, this means that we attempted to use some later case in a metafunction
with an input that would have satisfied an earlier case) and so @clpt[diunify] must
return @clpt[⊥]. And finally, the last case in @clpt[disunify] covers the situation
where @clpt[unify] composed with @clpt[param-elim] returns a non-empty substitution. 
In this case, we do not yet know if the disequation is true or false, so we collect
the substitution that @clpt[unify] returned back into a disequation and return it,
to be saved in the contraint store.

This brings us to @clpt[param-elim], in 
@figure-ref["fig:dis-help"]. It accepts a most-general
unifier, as produced by a call to @clpt[unify] to handle a
disequation, and all of the universally quantified variables
in the original disequation. It removes equations
of the unifier when they correspond to disequtions that will be
false in the newly constructed disequation. There are two ways in which this can happen.
First, if one of the clauses has the form @clpt[(x = p)] and
@clpt[x] is one of the universally quantified variables, then we know that
the corresponding clause in the disequation @clpt[(x ≠ p)] must
be false, since every pattern matches at least one ground term. 
Furthermore, since the result of @clpt[unify] is idempotent, we know
that simply dropping that clause does not affect any of the other 
clauses. 

The other case is a bit more subtle. When one of the clauses
is simply @clpt[(x_1 = x)] and, as before, @clpt[x] is one of
the universally quantified variables, then this clause also must
be dropped, according to the same reasoning (since @clpt[=] is symmetric).
But some care must be taken here to avoid losing transitive inequalities.
The function @clpt[elim-x] (not shown) handles this situation, constructing a new
set of clauses without @clpt[x] but, in the case that we also have
@clpt[(x_2 = x)], adds back the equation @clpt[(x_1 = x_2)]. For the
full definition of @clpt[elim-x] and a proof that it works correctly,
we refer the reader to the first author's masters dissertation@~cite[burke-masters].

Finally, we return to @clpt[check], shown in @figure-ref["fig:dis-help"],
which is passed the updated disequations after 
a new equation has been added in @clpt[solve] (see @figure-ref["fig:solve"]).
It is used to verify the disequations and maintain 
their canonical form, once the new substitution has been applied.
It does this by using @clpt[disunify] on each of the disequations that
are not in the canonical form.

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
next rule in the permuted list. If none of the choices in
the list leads to a successful derivation, then this attempt
is itself a failure and the implementation either backtracks
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

@figure["fig:d-plots" 
        @list{Density functions of the distributions used for the depth-dependent 
              rule ordering, where the depth limit is @(format "~a" max-depth)
              and there are @(format "~a" number-of-choices) rules.}
        @(centered(d-plots 420))]

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

Our model uses a much simpler pattern language than the one actually available
in Redex. Although the derivation generator is not yet able to handle
Redex's full pattern language@note{The generator is not able to handle parts of the
   pattern language that deal with evaluation contexts or 
   ``repeat'' patterns (ellipses).}, it does support a richer language than 
the model, as shown in @figure-ref["fig:full-pats"].
We now discuss briefly the interesting differences and how we support them.

Named patterns of the form @slpt[(:name s p)]
correspond to variables @italic{x} in the simplified version of the pattern
language from @figure-ref["fig:clp-grammar"], except that the variable is attached to a sub-pattern.
From the matcher's perspective, this form is intended to match a 
term with a pattern @slpt[p] and then bind the matched term to the name @slpt[s]. 
In the generator, named patterns are treated essentially as logic variables. When two patterns are
unified, they are both pre-processed to extract the pattern @slpt[p] for each
named pattern, which is rewritten into a logic variable with the
identifier @slpt[s], unifying the new pattern with the current
value for @slpt[s] (if it exists).

The @slpt[b] and @slpt[v] non-terminals are built-in patterns that match subsets of
Racket values. The productions of @slpt[b] are straightforward; @slpt[:integer], for example,
matches any Racket integer, and @slpt[:any] matches any Racket s-expression.
From the perspective of the unifier, @slpt[:integer] is a term that
may be unified with any integer, the result of which is the integer itself.
The value of the term in the current substitution is then updated.
Unification of built-in patterns produce the expected results; 
for example unifying @slpt[:real] and @slpt[:natural] produces @slpt[:natural], whereas
unifying @slpt[:real] and @slpt[:string] fails.

The productions of @slpt[v] match Racket symbols in varying and commonly useful ways;
@slpt[:variable-not-otherwise-mentioned], for example, matches any symbol that is not used
as a literal elsewhere in the language. These are handled similarly to the patterns of
the @slpt[b] non-terminal within the unifier.

Patterns of the from @slpt[(mismatch-name s p)]  match the pattern 
@slpt[p] with the constraint that two occurrences of of the same name @slpt[s] may never
match equal terms. These are straightforward: whenever a unification with a mismatch takes
place, disequations are added between the pattern in question and other patterns
that have been unified with the same mismatch pattern.

Patterns of the form @slpt[(nt s)] are intended to successfully match a term 
if the term matches one of the productions of the non-terminal @slpt[s]. (Redex
patterns are always constructed in relation to some language.) It is less obvious how
non-terminal patterns should be dealt with in the unifier. 
Finding the intersection of two such patterns reduces to the problem of computing
the intersection of tree automata, for which there is no efficient algorithm@~cite[tata].

Instead a conservative check is used at the time of unification.
When unifying a non-terminal with another pattern, we
unfold each non-terminal once, replacing any 
embedded non-terminal references with the pattern @slpt[:any]. Then
we check that the pattern unifies with at least one of the non-terminal 
expansions, failing if none of them unify.

Because this is not a complete check for pattern intersection, we save the names
of the non-terminals as extra information in the result of each unification
involving a non-terminal until the entire generation process is complete.
Then, once we generate a concrete term, check to see if any of the
non-terminals would have been violated (using a matching algorithm). 
This means that we can get failures at this stage of generation, but it
tends not to happen very often for practical Redex models.
