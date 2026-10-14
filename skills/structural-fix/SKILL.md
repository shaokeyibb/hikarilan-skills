---
name: structural-fix
description: How to fix a defect so its whole class disappears, not just the reported instance. Use when fixing a bug, writing a fix brief for another agent, reviewing someone's fix, or when a fix is tempting to write as a guard, special case, retry cap or fallback.
---

# Structural fix

A reported bug is one instance of a class. Patching the instance leaves its siblings live, and
each patch adds a branch the next reader has to understand. A structural fix names the class,
removes it everywhere it occurs, and changes the code so the wrong state can no longer be
written. It usually deletes more than it adds.

## Steps

### 1. Name the class

Write two sentences before touching code: **what class of defect this is**, and **what general
rule the buggy code violates**. "The dialog closes twice" is an instance; "two owners both decide
the dialog's lifecycle" is a class; "lifecycle has exactly one owner" is the rule.

Done when the rule can be stated without naming the reported screen, input, app, or message.

### 2. Sweep for every site

Search the whole source tree — plus the modules upstream and downstream of the buggy one — for
every site of the same pattern. Search by the shape of the mistake (the call, the field, the
idiom), not only by the name in the bug report. Fix every hit in the same change.

Report the sweep: the exact search commands, each hit, and its disposition (fixed / not an
instance, with the reason). A fix that touches only the named site is a half-landed fix and comes
back later from a different direction.

Done when every hit has a disposition and the search is reproducible from the report.

### 3. Find the data structure at fault

Look at the data before the control flow. A common root cause is **two kinds of data mixed in one
structure**: protocol fields declared on every business DTO, user content and system metadata in
one dict, two lifecycles in one object. The fix is to split the structure into two. Filtering by
field name, branching on context, or excluding at the reader leaves the mix in place, and the
next consumer trips over it again.

Say in the fix description which data structure changed and how.

### 4. Fix the input, not the output

When behaviour is wrong, improve what produces it — the evidence passed in, the information
available, the stated constraint, the type boundary — so the system makes the right decision on
its own. Counters, circuit breakers, retry caps and keyword guards that intercept the wrong
outcome hide the defect and often freeze a bad value in place.

Prefer changes that make the wrong call unwritable: a required argument instead of an optional
one whose default implies the opposite rule, a closed enum instead of a free string, one entry
point that decides a field instead of N setters scattered across callers.

### 5. Prove it through the production path

Reproduce the original failure through the production entry point before the fix and watch it
pass after. A green suite is weaker evidence; it may never have exercised the failing path.

## Rules that apply throughout

**Special cases are the class surviving.** Branching on a name, kind, application, platform key,
message text or one specific capability makes the fix work for the instance and nowhere else.
Design around the general fact — "the action that was actually dispatched", "the field the
producer set" — and treat every capability the same way. Before proposing a fix, check whether it
names a concrete tool, key, screen or element; if it does, it is a special case.

**One phenomenon, first ask about the precondition.** When a single observed failure suggests a
new branch in the framework, first check whether the input, test case or configuration demanded
something nothing guaranteed. Often the right change is in the case (add the missing step) rather
than in the framework. Self-check for a proposed rule or prompt line: remove the concrete
instance — is what remains still a rule worth stating, and does it avoid enumerating element
categories? If not, it is overfitted.

**Choose the failure direction explicitly.** When a heuristic is unavoidable, decide in writing
which way it fails, and make it fail towards **doing one more unit of work** — one more retry,
one more sample, one more candidate kept — never towards an early verdict such as "exhausted",
"passed", or "equivalent". Extra work is bounded by budgets and visible; an early verdict is
silent and permanent.

**Retire a capability top-down, all the way.** Deleting only the consumer leaves producers,
protocol methods, adapter implementations, config keys, tuning constants, spec clauses, docs,
glossary entries, example comments and doc generators behind, and the capability creeps back.
Delete the whole chain in one change and verify with a repo-wide search for the capability's
name across source, specs, docs, examples, scripts and frontend. Name-based dead-code tools are
not proof: an unrelated helper with the same name keeps a dead chain looking alive.

**Data nobody reads gets deleted.** Before fixing how a value is written, ask who reads it. A
field, state or event with no production reader is removed outright — no new rules for it, no
spec text. Code used only by scripts or tests has no production reader.

**Regressions back to an old rule.** When a fix keeps getting reverted to old semantics, look for
what invites it: a docstring, a default parameter, an optional type that implies the opposite
rule (a default of `None` suggesting "no filter" where the rule is "absent never matches").
Tighten the interface so the old reading cannot be expressed.

**One implementation per behaviour.** Two weak implementations of the same thing are harder to
fix than one strong one; a fix that adds a second path "for this case" is a new defect.

## Done

The class and its rule are written down; the sweep is reported with commands, hits and
dispositions; no new branch keys on a name, kind, platform or text; the changed data structure
is named; the original failure reproduces through the production path before the fix and passes
after it.
