---
name: minimal-design-gate
description: A gate against over-design, applied before and after a change. Use when proposing a design or a fix, writing a brief for another agent, reviewing a diff or an agent's delivery, or when a change adds fields, options, abstractions, fallbacks, compatibility paths or dependencies.
---

# Minimal design gate

Complexity is cheap to add and expensive to remove: every field, option and fallback is read by
every future maintainer and kept alive by every refactor. Over-design rarely arrives as one big
mistake — it accumulates one reasonable-looking addition at a time, each patching the previous
one. This gate runs twice: on the proposal, before any code exists, and on the delivery, before
it merges.

## Before: the proposal

### Five questions

Answer each in a sentence before proposing:

1. **Structural?** Does it fix the class of problem, or only this instance?
2. **Burden?** Does it give callers — users, other modules, a model filling a schema — new
   fields to fill or choices to make?
3. **Determinable?** Is anything left to the caller that the system could measure or derive
   itself? What the system can determine deterministically, the system determines; the caller
   only chooses.
4. **Gratuitous?** Does it make the system more complex than the problem requires?
5. **Overfitted?** Does it serve one observed case, one input, one named component?

### Minimal first

State the smallest change that solves the problem, and **why nothing simpler works**. When the
proposal fixes a wrong decision, compare two directions before choosing: narrowing the choice so
the system derives the answer, versus adding information or fields for the decider. The first is
usually smaller and more robust; the second is where mechanisms start to bloat.

If the proposal patches a mechanism that was itself patched recently, stop and ask whether the
mechanism is over-designed. Adding a field, then a fallback for the field, then an anchor for
the fallback is the sign.

### Prefer what already exists

Before building a general capability — retry, JSON repair, schema parsing, caching, rate
limiting, validation — check the standard library, the dependencies you already have, and mature
open-source libraries. Use what covers the need and delete the private version; keep private
code only for the part no library provides, and write that gap into the design. After the swap,
check that the result actually got simpler: two stacks side by side is worse than either alone.

- **One direct dependency per capability.** A library that arrives transitively through a
  higher-level one is not imported directly.
- **When an SDK validates first, follow the SDK.** Delete in-repo checks the SDK makes
  unreachable instead of building a looser parser around it.

## After: the delivery

### Checklist

Each hit must be removed, or carry a written reason it cannot be:

- a new field or option a caller must fill or choose;
- an abstraction with a single caller;
- two paths behind an optional parameter that switches implementations;
- the same rule enforced in more than one place;
- a branch or fallback for a scenario nobody has observed;
- a new configuration key with no reader;
- data written that nothing in production reads;
- derived information the consumer can already see for itself — a "rounds without progress"
  counter for a reader that has the whole history in front of it;
- a compatibility path — alias, legacy reader, migration shim, `legacy_` / `compat` /
  `deprecated` code, a second format accepted "for now";
- a parameter, field or path in product code that only tests or a benchmark harness ever sets.

Compatibility paths have one fix: change every call site to the new shape in the same commit and
delete the old one. A harness that needs control (a call budget, a fake clock) gets it at an
external boundary it already uses, such as a counting proxy in front of the provider, not
through a product-code parameter.

### Net lines

Report the net line change of the delivery, split by area. Growth needs a reason it could not be
smaller; the default question is "can this not be added, or can something old be deleted to make
room?" Over a series of simplification changes, watch the trend: net growth while the goal is
reduction means new entities are creeping back in.

### Read it all before judging it

A verdict of "no over-design" covers only the files actually read, line by line. When a delivery
is too large to read in one sitting, say which parts were read and mark the rest **unreviewed**.
Sampling the first half of a large change misses exactly the stacked recovery and validation
code that over-design hides in.

## Removing what is already there

Entities need a reason to exist. A complex mechanism that fires rarely in real use and rarely
changes the outcome is a removal candidate; base the case on usage data from real runs, and keep
anything its owner has explicitly asked to keep.

## Done

On the proposal: the five answers and the minimal-first statement are written. On the delivery:
every checklist hit is removed or justified in writing, the net line change is reported, and the
review states exactly which files it read.
