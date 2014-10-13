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
The premises may consist of literal goals @clpt[(d p)] or disequational
constraints @clpt[δ]. We dive into the operational meaning behind
disequational constraints later in this section, but as their form suggests, they are
the negation of an equation, in which some variables are universally quantified.
The remaining variables in a disequation are (implicitly) existentially
quantified, as are the variables in equations.

The reduction relation shown in @figure-ref["fig:clp-red"] generates
the complete tree of derivations for the program @clpt[P]
with an initial goal of the form @clpt[(d p)], where
@clpt[d] is the identifier of some definition
in @clpt[P] and @clpt[p] is a pattern
that matches the conclusion of all of the generated derivations.
The relation acts on states of the form @clpt[(P ⊢ (a ...) ∥ C)],
where @clpt[(a ...)] represents a stack of goals, which can
either be incomplete derivations of the form @clpt[(d p)], indicating a
goal that must be satisfied to complete the derivation, or disequational constraints 
that must be satisfied. A constraint store @clpt[C] is a set of 
simplified equations and disequations that are guaranteed to be satisfiable.
The notion of equality we use here is purely syntactic; two ground terms are equal
to each other only if they have the same shape.

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

There are two rules in the relation.
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

The second rule covers the case where a disequational constraint @clpt[δ] 
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
such constraint in the model. Accordingly,
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

@Figure-ref["fig:dissolve"] shows @clpt[dissolve], the counterpart to
@clpt[solve], but for disequations. It applies the equational part
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
that the given formula is guaranteed to be true and thus the given disequation
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
in the original disequation. It's job is to remove clauses
of the unifier when the correspond to clauses that will be
false in the newly constructed disequation. There are two ways in which this can happen.
First, if one of the clauses has the form @clpt[(x = p)] and
@clpt[x] is one of the universally quantified variables, then we know that
the corresponding clause in the disequation is @clpt[(x ≠ p)] must
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

Finally, we return to @clpt[check], deferred from the second
paragraph in this section. It is used to verify that the
verify the disequations and maintain their canonical form, once a new equation comes in.
It does this by using @clpt[disunify] on each of the disequations that
are not in the canonical form.

@section[#:tag "sec:search"]{Search Heuristics}

Instead of generating every possible derivation, as the rewriting 
relation in @figure-ref["fig:clp-red"] does, our implementation
attempts to find a single random valid derivation. To do so, we
introduce randomness at the choice points represented by the
relation's @rule-name{reduce} rule. Given a goal
of the form @clpt[(d p_r)] at the top of the goal stack, if
there are multiple rules @clpt[((d p) ← a ...)] in the program
such that the definition ids @clpt[d] match, then a reduction
step may occur for each of those rules. 
The implementation randomizes its search by varying the order
in which the matching rules are attempted. 
We employ two ways of randomizing the rule order, and choose
equally between the two before attempting to generate a
single derivation. (The chosen strategy is then used for
the entire search attempt.)

The first strategy simply chooses a random order for the
rules at every choice point, with no regard for the structure
of the rules or the search state. The initial rule is tried,
and if it fails, either immediately or if we attempt to fulfill
its premises and find that none of them are valid (i.e., we have to
backtrack), then we continue with the remaining rules. 
We cannot continue to use random ordering indefinitely, however,
because if we try more recursive rules (those with more premises)
too often, the derivation's size can become unbounded, and the
search will never terminate. Accordingly, the search is
parameterized with a depth bound, which places a limit on the
number of times recursive rules can be unfolded before
the search begins to use a termination strategy to bound
the size of the unfinished parts of the derivation.
The termination strategy is simple: we just order
rules from least to most recursive and attempt to satisfy
goals with the least recursive rules first.

However, giving all rule orderings equal probability gives us a 
distribution of derivations that is far from ideal. To see why,
imagine that we are again choosing from the rules shown in
@figure-ref["fig:types"], and attempting to generate a derivation
for an expression of any type. At the initial step of our derivation,
we have a 1 in 4 chance of choosing the number type rule, so one
quarter of all expressions generated will just be a number. We run
into the same problem again when attempting to satisfy premises of
more recursive clauses, so the distribution is extremely skewed
toward smaller derivations.

@figure["fig:d-plots" 
        @list{Density functions of the distributions used for the depth-dependent 
              rule ordering, where the depth limit is five and there are 4 rules.
              The x-axis ranges from 0 to 23.
              (The scale of the y-axis on the leftmost
              plot is larger.)}
        @(centered(d-plots 430))]

Our second strategy attempts to avoid favoring smaller
derivations while still allowing for some randomization.
The idea is straightforward: at smaller depths in the search,
we prefer more recursive rules, and we prefer less
recursive rules as the search depth increases.

To implement this, we need some notion of how recursive
a given permutation of the rules is. Suppose there are 4
such rules. We first order the rules by decreasing recursiveness,
and map them into the natural numbers in that order.
We form the natural lexicographic ordering of the 
permutations of 0 through 3, i.e. @clpt[(0 1 2 3)],
@clpt[(0 1 3 2)], @clpt[(0 2 1 3)], up to @clpt[(3 2 1 0)]. 
(There are 4! such permutations.)
We then index into the permutations, preferring earlier
elements in the ordering at smaller depths and later elements
at larger depths. 
To do this, we select the index from a binomial distribution
@italic{B(n,p)} where @italic{n} is the number of permutations
and @italic{p} scales with the current search depth, approaching
1 with the depth limit.
@Figure-ref["fig:d-plots"] plots the distributions we use
for depths 0 thorough 4 with a limit of 5, and 4!
elements in the permutation ordering.
Once the depth limit is reached, we once again switch to the
termination ordering of the rules as before.

Finally, in all cases we terminate searches that appear to
be stuck in unproductive or doomed parts of the search space 
by placing limits on backtracking, search depth, and derivation size.
When these limits are violated, the generator simply
abandons the current search and reports failure.

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
non-terminal patterns should be dealt with in the unifier. It would be nice to have
an efficient method to decide if the terms defined by some pattern intersected with
those defined by some non-terminal, but this reduces to the problem of computing
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
