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
          "common.rkt")

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

@figure["fig:clp-red"
        @list{Reduction rules describing generation of the complete
              tree of derivations.}
        @(clp-red-pict)]

The grammar in @figure-ref["fig:clp-grammar"] describes the language of the model.
A program @clpt[P] consists of  definitions @clpt[D] and each definition consists 
of a set of inference rules @clpt[((d p) ← a ...)], here written
horizontally with the conclusion on the left and premises on the right. (Note that
ellipses are used in a precise manner to indicate repetition of the immediately
previous expression, following Scheme tradition. They do not indicate elided text.)
Definitions can express both judgment forms and metafunctions, which are compiled
to definitions via a process we discuss in @secref["sec:mf-semantics"].

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
that must be satisfied. A consistent
constraint store @clpt[C] is a set of 
simplified equations and disequations, where the precise definition of ``simplified''
is given in @secref["sec:solve"].

In general, the rewriting relation
takes a single step, based on the first entry in the goal stack.
This means that some reduction sequences are ultimately
doomed, but may still reduce for a while. In our implementation,
discovery of such doomed reduction sequences causes backtracking. Reduction
sequences that lead to valid derivations
always end with a state of the form @clpt[(P ⊢ () ∥ C)], and the derivation 
itself can be read off of the reduction sequence that reaches that state.

There are two rules in the relation.
When a literal goal @clpt[(d p)] is the first element
of the goal stack (as is the root case, when the initial goal is the
sole element), then the @rule-name{reduce} rule applies. For every
rule of the form @clpt[((d p_r) ← a_r ...)] in the program such
that the definition's id @clpt[d] agrees with the goal's, a reduction
step can occur. The reduction step first freshens the variables in
the rule, asks the solver to combine the equation @clpt[(p_f = p_g)] 
with the current constraint store, and reduces to a new state with
the new constraint store and a new goal state. 
(The solver may fail, in which case this is an invalid derivation.)
The new goal state has
all of the previously pending goals as well as the new ones introduced
by the premises of the rule.

The second rule covers the case where a disequational constraint @clpt[δ] 
is the first element in the goal
stack. In that case, the disequational solver is called with the
current constraint store and the disequation. If it returns a new constraint
store, then the disequation is consistent and the new constraint store is
used. Otherwise, reduction terminates without producing a derivation.

The remainder of this section fills in the details in this model and
discusses the correspondence between the model and the implementation
in more detail.
Metafunctions are added via a procedure generalizing the 
process used for @clpt[lookup] in @secref["sec:deriv"], 
which we explain in @secref["sec:mf-semantics"]. 
@Secref["sec:solve"] describes how our solver solves
equations and disequations.
@Secref["sec:search"] discusses the heuristics our implementation
uses and @secref["sec:pats"] describes how our implementation
scales up to support features in Redex that are not covered in this model.


@;{
TODO: 
- get rid of π
- C, no bottom, change reduction relation to use C_1 and C_2 
- remove top and bottom from δ -- requires changes to 'check' (etc)
- in solve, don't use question mark as a subscript, how about "new"?
- call to check in solve should use new substitution, not old one
- run test suite in 'make'
- 'lst' constructor in call to disunify not necessary
- get rid of appendix before sending on
- change 'solve' (and maybe elsewhere?) to avoid simple pattern-matching
  side-conditions.

- delete 4, replace with meta comment saying what will be there later
- review changes to 3.0. 

Send out draft to everyone as pdf attachment. Name the pdf file with the
date.

In email, remind people that abstract deadline and real deadline are
approaching. Ask for comments on current draft. Promise more drafts with
more stuff.

}

@section[#:tag "sec:mf-semantics"]{Compiling Metafunctions}

The idea behind metafunction compilation  is to generate a definition @(clpt D)
that contains one rule for each clause of the metafunction, and add
constraints as necessary to ensure that the resulting rules are consistent with
the original definition. As an illustrative example, consider the following
metafunction definition, alongside some example applications:
@(centered (f-ex-pict))
The first clause matches any two-element list, and the second clause matches
any pattern at all. Since the clauses apply in order, an application where the
argument is a two-element list will reduce to @(clpt 2) and an argument of any
other form will reduce to @(clpt 1). To generate conclusions of the judgment
corresponding to the second clause, we have to be careful not to generate
anything that @italic{matches} the first.

@;{
Leaving this here for reference...
Suppose p are patterns, t are terms (essentially patterns with no variables from this perspective), 
and s are substitutions (finite maps from variables to patterns). s(p) applies a substitution to a pattern.

1. Matching is easy to define:
Matches[p,t] <=> \exists s, s(p) = t

2. If a match doesn’t exist:
\not Matches[p,t] <=> \not \exists s, s)p) = t <=> \forall s, s(p) =/= t

3: Finally, given two patterns, there is a notion of it being possible to cause the 
match to fail by instantiating the second pattern in some way, call it “excludable”:
Excludable[p_1, p_2] <=> \exists s, \not Matches[p_1, s(p_2)]

Expanding out the final definition, it becomes the more complicated looking:
\exists s_1, \forall s, s(p_1) =/= s_1(p_2)}

For the metafunction @(g-p) shown above, then, the compiled form
would be:
@(centered (g-jdg-pict))
The rule on the left captures the first clause of the metafunction,
and the rule on the right captures the second. The added premise of
the right-hand rule ensures that it is impossible for @(clpt p), the 
pattern variable to be unified with the argument of @(g-p), to be
@italic{any} two-element list. Thus when we choose the second rule,
we know that the argument will never be able to match the first clause.

To see more clearly why we need the universal quantification here, consider
that without it, we would have a constraint of the form @(fneqt (lst p_1 p_2) p).
However, we could then choose @(feqt (lst p_1 p_2) (lst 1 2)) and @(feqt p (lst 3 4)),
which satisfies the constraint but allows @(clpt p) to match the left-hand
side of the first clause of @(g-p).

In general, when compiling a metafunction clause, we add a disequational
constraint for each previous clause in the metafunction definition.
The disequality is between the left-hand side patterns of the previous
clause and the left-hand side of the current clause, and is quantified 
over all variables in the previous clause's left-hand side.




@figure["fig:solve-dissolve"
        @list{The interface of the constraint solver.}
        @(vl-append
          20
          (solve-pict)
          (dis-solve-pict))]

@section[#:tag "sec:solve"]{The Constraint Solver}

The constraint solver maintains a set of equations and disequations between
patterns, subject to the requirement that a substitution exists that satisfies
the equations and does not violate the disequations. Whenever a new constraint
is added to the set, consistency is checked again and the new set is simplified,
if possible.

@Figure-ref["fig:solve-dissolve"] shows the two metafunctions, @clpt[solve]
and @clpt[dis-solve], that constitute the interface of the constraint solver 
as seen by the derivation generator. Both take a single new constraint (an
equation in @clpt[solve]'s case, and a disequation in @clpt[dis-solve]'s) along
with the current consistent constraints and attempt to add the new constraint.
Both first apply the current substitution@note{The simplified form of
   the equational constraints is an idempotent substitution.} to the
new constraint. @clpt[solve] then updates the equational constraints with
@clpt[unify] and applies the resulting substitution to the disequational
constraints. The updated disequational constraints are passed to
@clpt[check] which simplifies them if necessary, verifying their consistency.
@clpt[dis-solve], on the other hand, checks a new disequation for consistency 
(and simplifies) with @clpt[disunify]. 

@figure["fig:unify"
        @list{@clpt[unify] adds a new equation to the equational constraints. (The first
               argument is assumed to be up to date with the current substitution.)}
        @(unify-pict)]

@figure["fig:disunify"
        @list{Metafunctions used to process disequational constaints.}
        @(vl-append
          20
          (disunify-pict)
          (check-pict)
          (param-elim-pict))]

The portion of the constraint solver that deals with equations, specified by
@clpt[unify] as shown in @figure-ref["fig:unify"], simply performs
familiar syntactic unification@~cite[baader-snyder], and the consistent set of 
simplified equations is the usual result, a most general unifier (mgu) for the equations 
passed as arguments to the solver. In our definition of @clpt[unify], the first
argument acts as an accumulator for equations to be processed, and the second
holds a set of simplified equations in the form of an idempotent substitutions.
The details are well known and standard. For that reason, we concentrate on explaining
the parts of the solver that deal with disequational constraints in detail.


A new disequation is checked for consistency with @clpt[disunify], shown
in @figure-ref["fig:disunify"], which returns a simplified form
of the disequation (or @clpt[⊥] if it cannot be satisfied).
All of @clpt[disunify]'s clauses dispatch on the result
of unifying the @italic{equations}
@clpt[((p_1 = p_2) ...)], corresponding to the disequations
in the constraint's disjunction.
If that succeeds, the result is passed along with the quantified 
variables @(clpt (x ...)) to the auxiliary metafunction @(clpt param-elim). 
This unification essentially performs the transformation from @clpt[(∨ (p_1 ≠ p_2) ...)]
to @clpt[¬]@clpt[(∧ (p_1 = p_2) ...)].
The first clause of @clpt[disunify] deals with the case where this unification 
fails, in which case the two patterns can never be equal, so this is 
always satisified and @clpt[disunify] just returns @clpt[⊤].

If the unification succeeds, it returns an mgu for the patterns in question.
This substitution is used to construct a simplified set of disequations
that excludes the mgu, since any substitution equating the two patterns must
be an instance of the mgu. 
To add universal quantification, the resulting substitution is
passed to @(clpt param-elim) which removes assignments to universally 
quantified variables.
Informally, we can justify this step by noting that we cannot satisfy the
disequation by instantiating any such variables, 
so we are essentially restricting the substitution to
the other (existentially quantified) variables, since we must be able to
satisfy the disequation by picking values for them only.

If, after @(clpt param-elim) is applied, an empty environment is the result
(the second clause), then it is impossible to satisfy the disequation through
assignments to existentially quantified variables, 
so @clpt[disunify] returns @clpt[⊥].
In the third case, @(clpt param-elim) returns some conjunction of equations, 
which represent an idempotent substitution, i.e. are between variables and 
terms which do not contain the variables on the left-hand side. 
These equations are equations are then combined into a disequational
constraint, reversing the transformation of passing them into @clpt[unify].

Finally, @clpt[check] is used to verify that the disequational constraints
remain in a simplified form, where simplified means that at least one
disequation in the disjunction has an (existentially quantified) variable
on the right-hand side. In this form, the constraints remain consistent
because we can always choose a value for the variable that does not unify 
with the left-hand side. Otherwise, the constraint is passed to disunify
once again, and the set of disequations is updated accordingly.

@section[#:tag "sec:search"]{Search Heuristics}

@bold{@italic{Haven't written this section yet.}}

@section[#:tag "sec:pats"]{A Richer Pattern Language}


@figure["fig:full-pats" 
        @list{The subset of Redex's pattern language supported by the generator.
           Racket symbols are indicated by @italic{s}, and 
           @italic{c} represents any Racket constant.}
        @(centered(pats-supp-lang-pict))]

Our model uses a much simpler pattern language than the one actually available
in Redex. Although the derivation generator is not yet able to handle
Redex's full pattern language@note{ The generator is not able to handle parts of the
   pattern language that deal with evaluation contexts, compatible closure, or 
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
Racket values. The productions of @slpt[b] are self-explanatory; @slpt[:integer], for example,
matches any Racket integer, and @slpt[:any] matches any Racket s-expression.
From the perspective of the unifier, @slpt[:integer] is a term that
may be unified with any integer, the result of which is the integer itself.
The value of the term in the current substitution is then updated.
Equalities between built-in patterns have the obvious relationship; the result
of an equality between @slpt[:real] and @slpt[:natural], for example, is @slpt[:natural], whereas
an equality between @slpt[:real] and @slpt[:string] simply fails.
As equalities of this type are processed, the values of terms in the current
substitution are refined.

The proudctions of @slpt[v] match Racket symbols in varying and commonly useful ways;
@slpt[:variable-not-otherwise-mentioned], for example, matches any symbol that is not used
as a literal elsewhere in the language. These are handled similarly to the patterns of
the @slpt[b] non-terminal within the unifier.

Patterns of the from @slpt[(mismatch-name s p)]  match the pattern 
@slpt[p] with the constraint that two mismatches of the same name @slpt[s] may never
match equal terms. These are straightforward: whenever a unification with a mismatch takes
place, disequations are added between the pattern in question and other patterns
that have been unified with the same mismatch pattern.

Patterns of the form @slpt[(nt s)] are intended to successfully match a term 
if the term matches one of the productions of the non-terminal @slpt[s]. (Redex
patterns are always constructed in relation to some language.) It is less obvious how
non-terminal patterns should be dealt with in the unifier. It would be nice to have
an efficient method to decide if the terms defined by some pattern intersected with
those defined by some non-terminal, but this reduces to the problem of computing
the intersection of tree automata, which is known to have exponential complexity.@~cite[tata] 
Instead a conservative check is used at the time of unification and the
non-terminal information is saved.

When a pattern is equated with a non-terminal, the non-terminal is unfolded
by retrieving all of its productions which are normalized by replacing any 
recursive positions of the non-terminal with the pattern @slpt[:any]. The pattern
is similarly normalized, and it is verified that at least one of the normalized 
production unifies with the pattern. 
The results of this check can be cached. 

Becuase this is not a complete check for pattern intersection, a later check
remains necessary.
When a pattern successfully unifies with a non-terminal, the pattern is annotated
with the name of the non-terminal. The intention of this
is that once a pattern becomes fully instantiated (once it becomes a term), it
becomes simple to verify that it does indeed match one of the non-terminal's productions.
All annotated non-terminals are verified when result patterns are instantiated as terms.

The result of the derivation generation process is a pattern that corresponds to the
original goal, an environment that corresponds to the substitution generated by the
generation process, and a set of disequational constraints. 
The final step is to perform the necessary random instantiations of pattern
variables to produce a term as the result.
Variables in the environment will resolve to patterns consisting of @slpt[:list]
constructors, racket constants, non-terminals, and built-in patterns.
The portion of the environment necessary to instantiate the goal pattern is
processed to eliminate built-in patterns and non-terminals by using
a context-free generation method, and @slpt[:list] terms are converted to Racket lists.
Then the disequational constraints are checked for consistency with the new environment.
Finally, the goal pattern is converted to a term by using the same process and resolving
the necessary variables.














@; here be dragons















@; leftover from previous draft...
@; contains some useful stuff though
@;{
   
@(define (mymath start end . strs)
   (make-element (make-style "relax" '(exact-chars)) `(,start ,@strs ,end)))

@(define (math-in . strs) (apply mymath "\\(" "\\)" strs))

@(define (math-disp . strs) (apply mymath "\\[" "\\]" strs))

This chapter explains the method used to generate terms satisfying
judgment forms and metafunctions,
starting with a subset of Redex's pattern and term languages, which is
used as a basis for describing judgment-form based generation.
The generation method works by searching for derivations that satisfy
the relevant relation definitions, using a constraint
solver to maintain consistency during the search.

Following the explanation of the basic generation method, 
metafunction generation is introduced along with some
necessary extensions to the constraint solver. Then the 
constraint solver is explained in some detail. Finally
the methods used to handle Redex's full pattern language 
are discussed.

@section{Patterns and Terms in Redex}

Redex handles two s-expression-based grammars internally: patterns and
terms. Simplified forms of both are shown in @figure-ref["fig:pat-terms"].
Terms @italic{t} are essentially s-expressions built from Racket
constants @italic{a}, except that Redex provides a term
environment with bindings for
term variables@note{Variables are just Racket symbols that are bound
   or in binding positions in Redex's term context. In pattern they 
   are in a binding position, and are bound when they appear in
   a term.} 
@italic{x} and metafunctions @italic{f}. When a metafunction
is a applied in a term, the result will be a term, and the result term
is inserted in place of the application. Term variables are simply bound to 
other terms and are replaced by their values. They are bound at the
successful match of a pattern variable.

Patterns @italic{p} are used to match against and decompose terms. They are 
composed of literals @italic{a} which match themselves only, and built in patterns
@italic{b} which match some set of literals --- @tt{number}, which matches
any Racket number, is one example. Pattern variables @tt{x} match against
a term and bind the variable to the term. 
Finally, lists of patterns may be matched against lists of terms.

@figure*["fig:pat-terms" 
        (list @"Simplified grammar for Redex patterns ("
              @italic{p}
              @") and terms ("
              @italic{t}
              @").")]{
  @centered[r-lang-pict]}

The term generator actually operates on patterns and produces a pattern as
an intermediate result. The conversion of the resulting pattern to a term is
straightforward. As a first step in generation, then, terms in judgment form 
and metafunction definitions are converted into corresponding patterns
(as described in more detail below).

@section{Judgment Form Generation}
A judgment form in Redex is defined in the following manner, as a set of
inference rules:
@centered[judgment-pict]
Where the @italic{J} non-terminals indicate judgment form ids, and a single
judgment form is defined by a set of rules with matching ids in the conclusion.
Note that that the number of patterns and terms in the conclusion of a single 
judgment form  must be a constant @italic{k}. 
The premise of a single rule (above the line) consists of the conjunction
of some further set of judgments. 
To derive the conclusion of a judgment, there must exist derivations
of all of its premises; the complete derivation of a judgment is the tree
generated by satisfying all such recursive derivations.
A judgment form @italic{J} then inductively defines a relation over a k-tuple of terms, such
that the k-tuple @italic{@math-in{\langle}t@subscript{1}, ... ,t@subscript{k}@math-in{\rangle}} 
is in the relation if there  exists a complete derivation of 
@italic{(J t@subscript{1} ... t@subscript{k})} using the available inference rules.

In Redex, judgment forms are required to have a specified mode determining
which positions in the judgment definition are inputs, and which are outputs.
(These are also sometimes referred to as positive and negative positions.)
In the conclusion of a judgment, input mode positions are patterns, which deconstruct
input terms, and in the premises, input positions are considered terms, which are
used as inputs to recursive attempts to satisfy the judgment. Output positions in premises are
patterns which deconstruct the results of recursive calls, and in the conclusion output positions 
are terms which are the result of trying to satisfy the judgment for some set of inputs. Pattern
positions may bind parts of a successful match for use in building terms in the term
positions. Thus a judgment may be executed as a function
by providing input terms, the result of which will be
some (possibly empty) set of term tuples corresponding to possible values of 
the output positions of the judgment.

For random generation of terms satisfying a judgment, however, it isn't practical to maintain
the distinction between modes of different judgment positions, because it is very
difficult to successfully pick a set of input terms that will satisfy a judgment.
Instead we choose to attempt to construct a random derivation tree, maintaining the invariant 
that a partial derivation is valid as we do so. Since this precludes choosing values
for term position, all positions of the judgment must be treated as patterns. 
Thus the judgment is pre-processed by traversing all pattern
positions in the appropriate order to extract binding identifiers, which are used to
rewrite terms in term positions into patterns. Binding identifiers then create constraints
between the patterns in the rule, as the same identifier may appear in multiple patterns.
Metafunction applications are also transformed during this this step, as is
explained in the next section on metafunction generation.

To try to generate terms satisfying a given judgment @italic{J}, 
we can attempt to construct some random derivation that ends with
of one the rules defining @italic{J}. A randomly chosen rule will have the form:
@centered[j-pict/p]
(Where the @italic{p}'s are meant to reflect that all positions have now been
rewritten as patterns.)
If this rule is chosen, in order to complete the derivation,
@italic{m} sub-derivations must be generated as well, 
one for each judgment @italic{(J@subscript{k} p@subscript{k} ...)}
in @italic{k = 1...m}. Generation thus proceeds recursively, generating
goals of the form @italic{(J@subscript{g} p@subscript{g} ...)} which are to be filled in with
subderivations. In general, a rule with a conclusion @italic{(J@subscript{c} p@subscript{c} ...)}
can be used to attempt to generate a derivation for the goal
@italic{(J@subscript{g} p@subscript{g} ...)}
if rule defines the correct judgment, i.e. @italic{J@subscript{c} = J@subscript{g}}, and
the set of equations @italic{@"{"p@subscript{c} = p@subscript{g}, ...@"}"} 
has solutions. Thus a derivation
will generate a set of equational constraints, which are solved by successively
unifying the patterns in each equation. The result of unification is a substitution
for the pattern variables that satisfies the constraints, or failure, if
such a substitution does not exist.
(Unification and disunification over Redex patterns are addressed in more 
detail Section 3.5.)
The final substitution can be applied
to the original goal to extract terms satisfying the judgment.


The derivation procedure is presented as a set of reduction rules in @figure-ref["fig:derivation"].
The rules presented here are based on the operational semantics for constraint logic 
programming@~cite[clp-semantics], used for their clarity and extensibility with respect 
to the constraint domain, as it will
be necessary to add some new constraints to deal with metafunctions. The rules shown correspond
exactly to those in @citet[clp-semantics], meaning the derivation generator is actually a random constraint
logic programming system.

@figure*["fig:derivation" "Derivation generation"]{
  @centered[clp-pict]}
   
The rules operate on a program state @italic{S}, which consists of the program @italic{P}, the current
goal @italic{G}, and the current constraint store @italic{C}. A ``program'' corresponds to 
judgment form definitions in Redex, and consists of a set of
inference rules @italic{(L ← L ...)}, written here such that the conclusion is left of the arrow
and the premises are on the right. The current goal is a list of literals @italic{L}, which 
correspond to subderivations yet to be completed, and constraints @italic{c}, which are just
equations between terms. The constraint store is either @italic{C}, which represents a consistent
set of constraints, or @italic{⊥}, which represents inconsistent constraints and indicates a failed
derivation. (For simplicity the constraint store is kept opaque for the moment.)

The rules process the current goal and modify the constraint store until the goal is empty, at which
point the derivation process is finished. When a constraint is the first element in the goal, it is checked
for consistency with the procedure @tt{add-constraint}, which returns an updated current constraint 
store on success or @italic{⊥} on failure (rules @tt{new constraint} and @tt{invalid constraint}).

When a literal @italic{(J p@subscript{g} ...)} is the first element of the goal, 
the procedure @tt{select} is used to choose a rule from the
program that can be used to satisfy the indicated subderivation. The rule must be from the correct
judgment (the judgment id of its conclusion must match that of the literal), and if such a rule
cannot be found @tt{select} may fail (rule @tt{invalid literal}). Otherwise, the @tt{reduce} rule
applies and the rule is freshened to yield an instance 
@italic{((J p@subscript{f} ...) ← L@subscript{f} ...)} of the rule with uniquely named variables.
Then constraints @italic{p@subscript{g} = p@subscript{f} ...} equating the patterns in the 
goal literal and the conclusion of the rule
are added to the current goal, along with
the premises @italic{L@subscript{f} ...} of the chosen rule, which all must now be satisfied to
complete the derivation.

The specification of the @tt{select} function is especially important from the standpoint
of random generation.
The rules for derivation generation are deterministic aside from the behavior of
@tt{select}, which may affect the form of a derivation by varying the rule used
to attempt to satisfy a literal.
To generate a @italic{random} derivation, @tt{select} simply chooses randomly among the set
of valid candidate rules for a given literal goal. However, this behavior can easily lead to 
non-terminating or inconveniently large derivations, since the @tt{reduce} rule may expand
the size of the goal. To account for this, once a certain depth bound is reached, rules
are selected according to the number of premises they have, from least to greatest. This
makes it much more likely for a derivation to terminate finitely. 

Finally, the model shown in @figure-ref["fig:derivation"] doesn't address the search
behavior of the implementation. Specifically, when an attempted derivation results in 
failure, the generator @italic{backtracks} to the state before most recent application 
of the @tt{reduce} rule and tries again, with the constraint that @tt{select} is no
longer allowed to choose the rule that led to the failed derivation. This introduces 
the possibility of the search getting stuck in an arbitrarily long cycle, which is
avoided by introducing a bound on the number of times such backtracking can occur
in a single attempt to generate a derivation. 
@;{
The implementation thus maintains a stack of derivation states that precede calls to
@tt{select}, sometimes referred to as the failure continuation. The current goal
is sometimes called the success continuation.}

@section[#:tag "sec:metafunctions"]{Metafunction Generation}
In this section the requirements of adding support for metafunctions to term 
generation are considered.
Aside from generating inputs and outputs of metafunctions directly, we have to
handle the fact that metafunction application may be embedded inside any term, 
specifically term positions in judgment forms and metafunctions themselves.
This is dealt with during the preprocessing phase that transforms terms into patterns by
lifting out all metafunction applications and providing variable bindings for the result of the
application. The applications are then added as premises of the 
rules used by the term generator. Exactly what it means for a metafunction application
to be the premise of a rule will become clear as metafunction compilation and generation
is explained.

Metafunctions are defined in Redex as a sequence of cases, each of which has some
sequence of left-hand-side patterns and a right-hand-side, or result, term:
@centered[f-pict]
Where the @italic{p}'s are the left-hand-side patterns, and the @italic{t}'s are the result
terms for the @italic{n} clauses.
Metafunctions are applied to terms, and metafunction application attempts to match the argument
term against the left-hand-side patterns in order from @italic{1} to @italic{n}. The
result is the term corresponding to the first successful match, i.e. if the pattern
@italic{p@subscript{k}} from clause @italic{k} matches the input term, 
and none of the patterns @italic{p@subscript{1}} ... @italic{p@subscript{k-1}} does,
then the term @italic{t@subscript{k}} is the result.
The pattern may bind parts of the match for use in constructing the result term.

To handle metafunctions in the derivation generation framework discussed in the
previous section, the strategy of treating them as relations is adopted. First metafunctions
are preprocessed in the same way as judgment forms, transforming terms into patterns and
lifting out metafunction applications. Then, for a clause with left-hand side @italic{p@subscript{l}}
and right-hand side @italic{p@subscript{r}}, a rule with the conclusion 
@italic{(f p@subscript{l} p@subscript{r})} is added, where @italic{f} is the metafunction name.
For a metafunction application of @italic{(f p@subscript{input})} with result @italic{p@subscript{output}},
a premise of the form @italic{(f p@subscript{input} p@subscript{output})} is added, and 
@italic{p@subscript{output}} is inserted at the location of the application:
@centered[f-comp-pict]
The lifting of applications to premises occurs in both metafunction and judgment-form compilation,
and transforms recursive metafunctions into recursive judgments. For example, if
the term @italic{t@subscript{r}} in the illustration above contained a call to @italic{f}, that
call would become a premise of the resulting judgment, and its position in the pattern @italic{p@subscript{r}}
would be replaced by the variable in the output position of the premise.

This translation accomplishes the goal of producing judgments as inputs for the generation
scheme, but it doesn't preserve the semantics of metafunctions. Treating a metafunction 
definition as a relation ignores the ordering of the metafunction clauses. For a metafunction
@italic{f} with  left-hand-side patterns @italic{p@subscript{1}...p@subscript{n}}, if the generator
attempts to satisfy a goal of the form @italic{(f p@subscript{g})} with clause @italic{k}, a constraint
of the form @italic{p@subscript{k} = p@subscript{g}} will be added. But it is possible that
@italic{p@subscript{g}} is eventually instantiated as some term that would have matched some previous pattern
@italic{p@subscript{j}, 1 ≤ j < k}. In this case, an application of @italic{f} to the term in question
@italic{should} have used clause @italic{j}, but the generator has instead generated an application that
used clause @italic{k}. To avoid this situation, constraints that exclude the possibility of matching
clauses @italic{1} through @italic{k - 1} must be added; to generate an application that uses clause
@italic{k} the necessary condition becomes 
@italic{p@subscript{k} = p@subscript{g} ∧ p@subscript{1} ≠ p@subscript{g} ∧ ... ∧ p@subscript{k-1} ≠ p@subscript{g}}.

This seems sufficient at first, but further thought shows this constraint is not quite correct. 
Consider the following definition of the metafunction @italic{g}:
@(newline)
@centered[f-ex-pict]
Where in this context we can consider @italic{p} to be pattern variable that will match any pattern, equivalent
to @code{any} in Redex.
Suppose when generating an application @italic{(g p@subscript{in})} of this metafunction the second clause is chosen. 
This will generate the constraint @italic{p@subscript{in} = p ∧ p@subscript{in} ≠ (p@subscript{1} p@subscript{2})}.
(The fact that variables aside from @italic{p@subscript{in}} will be freshened is elided.) Now suppose that later on
in the generation process, the constraint @italic{p@subscript{in} = (p@subscript{3} p@subscript{4})} is added, so
the relevant part of the constraint store will be equivalent (after a bit of simplification) to:
@centered{@italic{p@subscript{in} = (p@subscript{3} p@subscript{4}) ∧ p@subscript{1} ≠ p@subscript{3} ∧ p@subscript{2} ≠ p@subscript{4}}}
The problem at this point is that it is possible to satisfy these constraints simply by choosing 
@italic{p@subscript{3}} to be anything other than
@italic{p@subscript{1}}, or @italic{p@subscript{4}} anything other than @italic{p@subscript{2}}, but @italic{p@subscript{in}} will still
be a two element list and thus would match the first clause of the metafunction. 

The constraint excluding the first clause must
be strong enough to disallow @italic{any} two element list, which can be satisfied by requiring that:
@centered{@italic{∀ p@subscript{1} ∀ p@subscript{2} p@subscript{in} ≠ (p@subscript{1} p@subscript{2})}}
This suggests the general recipe for transforming metafunctions into judgments suitable for use in
the derivation generator. Each clause is transformed into a rule as described above, with the addition
of premises that are primitive constraints excluding the previous rules. For example, if clause @italic{k} is
being processed, the constraints will be of the form @italic{∀ x ... p@subscript{k} ≠ p@subscript{i}}, for
@italic{i = 1...k-1}, where @italic{p@subscript{k}} is the left hand side of clause @italic{k}.
There will be one constraint for each previous clause where the disallowed pattern
@italic{p@subscript{i}} is the left hand side pattern of clause @italic{i}, and all of the variables in
@italic{p@subscript{i}} must be universally quantified, i.e. for constraint @italic{i}, 
@italic{@tt{Variables}(p@subscript{i})=@tt{@"{"}x ...@tt{@"}"}}.

The derivation generation framework of @figure-ref["fig:derivation"] can easily be modified to handle the addition of the new
constraints, the @italic{c} non-terminal is simply extended with a single new production to be:
@centered[c-ext-pict]
Disequational constraints in a judgment resulting from a metafunction transformation are added to
the goal by the @tt{reduce} rule and
are handled in the same way as the equational constraints by the
@tt{new constraint} rule, provided that the constraint solver, no longer a simple
unification algorithm, can deal with both types of constraints. 
The constraint solver and its extension to deal with disequations is
discussed in the next section.

@section{Equational and Disequational Constraints}

This section presents a model of the constraint solver that operates on a simplified language.
First, the operation of the solver on exclusively equational constraints, where it performs
straightforward syntatic unification, is presented.
Then the extension of the unifier to handle the form of disequational
constraints introduced in the previous section is discussed. Finally issues specific to Redex's full
pattern language are addressed.

The grammar for the constraint solver model is shown in @figure-ref["fig:language"]. The 
model operates on the simplified term language of the @italic{t} non-terminal, which has
only two productions, one for @tt{f}, a single multi-arity term constructor, and one for variables
@italic{x}. This corresponds closely to the Redex pattern language, which also has one multi-arity
constructor, @tt{list}. For now other complexities of the pattern language are ignored, as they
don't directly impact the operation of the constraint solver.
A problem @italic{P} is a list of constraints @italic{c}, which can be equations between terms
@italic{eq} or disequations @italic{dq} (where some variables in the disequations are considered
to be universally quantified). Given a problem, the solver constructs (and maintains, as the problem 
is extended) a substitution @italic{S} that validates the equations and a set of
simplified disequations @italic{D}, such that @italic{S} also validates @italic{D}, and if @italic{D}
is valid, so are all the original disequations in @italic{P}. The substitution@note{To be more precise, 
                                                  @italic{S} is actually the 
                                                  equational representation of some substitution
                                                  @italic{γ}, where @italic{γ} is defined by its
                                                  operation on terms. We will refer to the two
                                                  interchangeably unless it is necessary to
                                                  differentiate between them.} is written
as a set of equations @italic{x=t} between variables and terms, with the understanding that
it can be @italic{applied} to a term by, for each equation, finding each occurrence of @italic{x}
in the term and replacing it with @italic{t}. 
A substitution validates an equation if both
sides of the equation are syntactically identical after the substitution is applied.

@figure*["fig:language" "Grammar for the constraint solver model."]{
  @centered[lang-pict]
}

@subsection{Syntactic Unification}

The portion of the solver that deals with equational constraints performs
straightforward syntactic unification of patterns. The algorithm is well
known; @citet[baader-snyder] provide a particularly good survey of theory
in this area, including a similar presentation of syntactic unification
that goes into greater detail.


@figure*["fig:unify-func"
        @list{@literal{The metafunction } @tt{U} 
               @literal{ performs unification over the language of } @figure-ref["fig:language"]
               @literal{. (Cases apply in order.)}}
         @(centered (unify-func-pict/contract))]

The metafuction that performs unfication, U, is shown in @figure-ref["fig:unify-func"].
It operates on a problem @italic{P}, a current substitution (or solution) @italic{S}, and 
a current set of disequational constraints @italic{D}, which is ignored by U.
(Except in one case that will be addressed along with the disequational portion 
of the solver.) The result of U is either the the pair @italic{(S : D)} of the substitution 
@italic{S} and the disequations @italic{D} that validate the entire problem, or @italic{⊥}, 
if the problem is inconsistent.

The cases of U apply in order and dispatch on the first equation in @italic{P}.
In the first case, the equation is between two identical terms, and the equation is
dropped before recurring on the rest of @italic{P}.
In the second case, the equation is between two terms applying the function
constructor @tt{f} to the same number of arguments; here the arguments in each position
are equated and added to @italic{P} before recurring.
In the third case, two terms are contructed with @tt{f} but have different numbers
of arguents, in this case U fails and returns @italic{⊥} since it is impossible to
make the terms equal.
The fourth case equates a variable @italic{x} with a term that contains the variable, which
again leads to failure. (The metafunction @tt{occurs?} takes a variable and a term, and
returns true if the term contains the variable, false otherwise.)
The fifth case equates a variable @italic{x} and a term @italic{t}, where it is known (because
the fourth case has already been attempted) that @italic{x} does not occur in @italic{t}.
In this case @italic{t} is substituted for @italic{x} in the remaining equations of the problem
@italic{c...}, the equations of the current substitution @italic{c@subscript{s}...}, and the
current disequations @italic{dq...}, after which the equation @italic{x=t} itself is added
to the current substitution before recurring.
The second to last case of U simply commutes an equation with a variable on the right hand
side before recurring, after which the equation in question will be handled by one of the
previous two cases.
The final case returns @italic{S} and @italic{D} as the solution if the problem is empty.

To make a precise statement about the correctness of U, a few definitions are necessary.
In the following, for a term @italic{t} and substitution @italic{σ}, @italic{σt} is written
to mean the application of @italic{σ} to @italic{t}.

Given two substitutions @italic{σ = ((x@subscript{σ} = t@subscript{σ}) ...)} and 
@italic{θ = ((x@subscript{θ} = t@subscript{θ}) ...)}, their @italic{composition}, 
written @italic{θσ}, is
@italic{θσ = ((x@subscript{σ} = θt@subscript{σ}) ... (x@subscript{θ} = t@subscript{θ}) ...)},
where trivial bindings of the form @italic{(x = x)} are removed and when there is a duplicate
binding @italic{(x@subscript{σ} = θt@subscript{σ})} and @italic{(x@subscript{θ} = t@subscript{θ})}
where @italic{x@subscript{σ} = x@subscript{θ}}, then 
@italic{(x@subscript{θ} = t@subscript{θ})} is removed.

Two substitutions @italic{σ} and @italic{θ} are @italic{equal}, @italic{σ = θ}, if for any variable @italic{x},
@italic{σx = θx}. A substitution @italic{σ} is @italic{more general} than a substitution @italic{θ}, written
@italic{σ ≤ θ}, if there exists some substitution @italic{γ} such that @italic{θ = γσ}. 

A substitution @italic{σ} is called the @italic{most general unifier} of two terms @italic{s}
and @italic{t} if @italic{σs = σt} and
for any substitution @italic{γ} such that @italic{γs = γt}, @italic{σ ≤ γ}.
Similarly, @italic{σ} is a unifier for a unification problem @italic{P = ((s = t) ...)}
if for every equation @italic{s = t} in @italic{P}, @italic{σs = σt}. It is a
most general unifier for @italic{P} if for every @italic{γ} that is a unifier of @italic{P},
@italic{σ ≤ γ}.

@(define inline-init-pict
   (text-scale
    (unify-init-pict)))

Finally, we can state that U is correct (again, ignoring the @italic{D} part of the
result for now):
@nested[ #:style 'inset]{@bold{Theorem 1} 
                          For any problem @italic{P}, @inline-init-pict terminates with
                          ⊥ if the equations in @italic{P} have no unifier. Otherwise, it terminates
                          with @italic{(S@subscript{mgu} : D)} where @italic{S@subscript{mgu}} is
                          a most general unifier for @italic{P}.}
Proofs of this proposition can be found in many references on unification, for example @citet[baader-snyder].

The version of U shown in @figure-ref["fig:unify-func"] corresponds fairly closely with the
implementation in Redex, except that the current substitution is represented as a hash table and the function 
recurs on the structure of input terms instead of using the current problem as a stack (as in 
the decomposition rule). As shown here, U has exponential complexity in both time and space. 
The space complexity arises because the substitution may have many identical terms, so by using 
a hash table it may be represented as a DAG (instead of a tree) with
sharing between identical terms and linear space. However the worst-case running time is still
exponential. Interestingly, this is still the most common implementation of unification because
in practice the exponential running time never occurs, and in fact it is usually faster than algorithms
with polynomial or near-linear worst-case complexity.@~cite[unification-comparison]

@subsection{Solving Disequational Constraints}

This section extends the constraint solver of the previous section to process 
disequational constraints of the form @italic{(∀ (x ...) (s ≠ t))} as well as the 
equational constraints already discussed. To handle disequations, U is extended with
four new clauses. The new function is called DU, as this form of constraint solving
is sometimes referred to as disunification@~cite[equational-problems]. The new clauses are shown in 
@figure-ref["fig:du-func"] along with the auxiliary metafunction @tt{param-elim}.
We now provide an informal explanation of DU's operation. A formal justification
can be found in Appendix A.

@figure*["fig:du-func"
        @list{@literal{Extensions to } @figure-ref["fig:unify-func"] 
               @literal{ to handle disequational constraints.
                        DU extends U with four new clauses.}}
        @(centered (du-pict))]

The first three clauses of DU all address the situation where the first constraint
in the problem @italic{P} is a disequation of the form @italic{(∀ (x ...) (s ≠ t))}.
Actually in all three cases, the metafunction U (recall that U is the portion of the
solver that applies exclusively to equations) is called with a problem
containing the single equation @italic{(s = t)} and an empty substitution. The result of
this call is passed to the metafunction @tt{param-elim} along with a list of the
parameters, which is where special
handling of the universally quantified variables takes place. (Borrowing the
terminology of @citet[equational-problems], the universally quantified
variables are referred to as ``parameters''.) It is the result of this process
that determines which of the first three cases of DU applies. Of course, in the
Redex implementation, the calls to U and @tt{param-elim} occur only once.

The call to U will return either @italic{⊥} or @italic{(S : ()))}.
If the result is @italic{⊥}, then @tt{param-elim} does nothing and DU simply
drops the constraint in question and recurs. 
(This is the second clause of DU.)
The reasoning here is that it is impossible to unify the terms, 
so the disequation will always be satisfied.

If U returns a value of the form @italic{(S : ()))}, then @italic{S} is 
a most general unifier for the equation in question, 
so for any substitution @italic{γ} such that 
@italic{γs = γt}, @italic{S ≤ γ}. Thus S is used to create a new constraint
excluding all such @italic{γ}. In the absence of parameters, for 
@italic{S = ((x = t@subscript{x}) ...)}, this would involve simply
adding a constraint of the form @italic{(x ≠ t@subscript{x}) ∨ ...}, since 
validating any one of the disequations excludes @italic{S} (and by 
doing so excludes all @italic{γ} where @italic{γ ≤ S}). If @italic{S}
contains any parameters not underneath a function constructor, they
are eliminated by @tt{param-elim}, the intuition being that it is 
impossible to satisfy a disequation of the form @italic{(∀ (x) (x ≠ t))} 
since @italic{x} cannot be chosen to be a term other than @italic{t}.

The auxiliary metafunction @tt{param-elim} takes a substitution @italic{S}
and a list of parameters @italic{(x ...)} as its arguments, and returns a 
modified substitution @italic{S'} such that the intersection of both the domain 
and the range of @italic{S'} with @italic{(x ...)} is empty. (Although either
may contain terms that contain variables in @italic{(x ...)}).
A parameter @italic{x} is eliminated by @tt{param-elim} by simply dropping
the disequation @italic{x ≠ t}, if @italic{x} does not occur as the right or
left-hand side of any other equation in @italic{S}. Otherwise if there are equations
@italic{@"{"x ≠ t@subscript{1}, ..., x ≠ t@subscript{n}@"}"}, 
it is eliminated by replacing those
equations with @italic{@"{"t@subscript{i} ≠ t@subscript{j}, ...@"}"}, where
@italic{i ≤ i,j ≤ n, i ≠ j}.
@note{The @tt{elim-x} metafunction, seen in the specification of @tt{param-elim}
      in @figure-ref["fig:du-func"], implements this find/pair operation.}

If after this process @italic{S} is empty, then DU fails (the first clause), 
since it is impossible to find a substitution to make @italic{s} and
@italic{t} different. Otherwise (DU's third clause), a constraint of the form
@italic{(∀ (x@subscript{a} ...) (f x ...) ≠ (f t ...))} is added.
This is equivalent to the disjunction @italic{(x ≠ t) ∨ ...},
under the quantifier with parameters @italic{x@subscript{a} ...} (which may
remain because we have only eliminated them at the top level of the terms 
@italic{t ...}).

Finally, if it is ever the case that a constraint in @italic{D} no longer
has at least one disequation @italic{x ≠ t} where the right hand side is
a variable, then it is removed and added to the top of the current
problem @italic{P} (DU's final clause). The intuition is that as long as one disequation in a 
constraint looks like @italic{x ≠ t}, where @italic{x} is not a parameter,
it can be satisfied by simply choosing
@italic{x} to be something other than @italic{t}. Otherwise it may be
invalid so it must be checked by applying U and @tt{param-elim} once again.

@(define inline-du-pict
   (text-scale (du-init-pict)))

@nested[ #:style 'inset]{@bold{Theorem 2} 
                          For any problem @italic{P}, @inline-du-pict terminates with
                          ⊥ if the equations in @italic{P} have no unifier consistent
                          with the disequational constraints in @italic{P}. 
                          Otherwise, it terminates
                          with @italic{(S@subscript{Ω} : D)} where @italic{S@subscript{Ω}} is
                          a most general unifier for the equations in @italic{P}, and 
                          @italic{S@subscript{Ω}} is consistent with the 
                          disequational constraints in @italic{P}. The constraints in
                          @italic{D} are equivalent to the originals in @italic{P}.}

A proof of this theorem is given in Appendix A.
This method of solving disequational constraints is based on the approaches
detailed in @citet[colmerauer-inequations] and @citet[equational-problems].
@citet[colmerauer-inequations] shows how to solve disequational constraints
by using a unifier to simplify them, as we do here, however his constraints
do not include universal quantifiers. @citet[equational-problems], on the other
hand, show how to solve the more general case of problems
of the form @italic{∃ x... ∀ y... φ} where @italic{φ} is a formula consisting of term
equalities and their negation,
disjunction, and conjunction. They give their solution as a set of rewrite rules,
and although their approach will solve the same constraints as ours, the equivalence 
of the two isn't completely trivial. One advantage of the approach we take is 
that it can be easily understood and implemented as an extension to the unifier.

@section{Handling More of the Pattern Language}

}