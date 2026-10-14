---
name: capability-pruning
description: Prune a codebase by capability — inventory every capability, give each an evidence card, and let the owner decide removals item by item. Use when simplifying or slimming a project, hunting for unused features or dead mechanisms, or before claiming that something is unused, never used, or safe to delete.
---

# Capability pruning

Long-lived projects accrete capabilities: each was added for a reason, many outlived it, and the
owner often no longer knows some of them exist. Hunting for technical symptoms — write-only
fields, dead branches, the biggest files — finds a few of these and misses the rest, because a
capability can be healthy code that nobody needs. The reliable unit is the **capability**, and
the reliable judge is its **owner**, given evidence.

## Steps

### 1. Inventory every capability

Build the list from the authoritative surfaces: specifications, public entry points (CLI
commands, SDK methods, HTTP routes, tools exposed to other systems), configuration keys, and the
README. List them all. Ranking by a metric and taking the top N decides in advance what the owner
will never see.

Done when every spec section and every public entry maps to at least one capability on the list.

### 2. Write a card for each

One card per capability, in plain language:

| Field | What goes in it |
|---|---|
| Purpose | What it does for a user, in one or two sentences without internal names |
| Origin | Why it was built — the change that introduced it (`git log -S <symbol>`, `git log --follow`) |
| Size | Lines in source, tests and docs, counted separately |
| Real use | How often it fired in real runs, and whether it ever changed an outcome |
| Main path | Whether the core workflow needs it to function |
| Recommendation | Keep, remove or simplify — with what each option costs |

**Real use** carries the most weight and is the easiest to get wrong; step 3 is how it is
gathered.

### 3. Gather usage evidence across the whole scope

A claim of "unused", "never enabled" or "no consumer" is only as good as the search behind it.
Before making one:

- Check the records first — status logs, run ledgers, notes and decision logs often state
  outright that a mechanism was used, and when.
- Search **every** place it could have run: all run and artifact directories, every example or
  sample project, remote hosts, CI history — not just the main project's latest runs.
- Write the search commands and the scope into the card.

When the search covered only part of the scope, the claim is "not seen within X", never "never".
A wrong "never used" is expensive: it is the claim most likely to delete something the owner
relies on.

**Production reachability** is judged from product source and public entry points only. A field,
state or flag that only scripts or tests set has no production producer, and is retireable even
though something references it.

### 4. Ask the owner, in batches

Group the cards by subsystem. For each candidate the owner may not need, ask one question: the
card's purpose and origin, the recommendation listed first, and what each choice costs. Ask a
few at a time, wait for answers, act on them, then send the next batch.

Leave the decision with the owner. The cards exist because the owner's judgement of "useful to
me" differs from what code metrics can show. Anything the owner has explicitly asked to keep
stays, whatever its usage numbers say; record that so the next sweep does not ask again.

Symptom hunts — write-only data, attempts that never succeed, trigger count × line count — are a
good way to find candidates the inventory missed. Feed what they find into cards; they do not
replace the cards.

### 5. Remove top-down, all the way

For each approved removal, delete the whole chain in one change: producers and consumers,
protocol methods and their implementations, configuration keys and constants, spec clauses,
docs, glossary entries, example comments, and anything that generates docs from them. Then
search the whole repository — source, specs, docs, examples, scripts, frontend — for the
capability's name. A name-based dead-code tool is not proof of a complete removal: an unrelated
helper with the same name keeps a dead chain looking alive.

## Done

Every capability in the inventory has a card; every removal candidate has an owner decision;
every "unused" claim states its search scope; every approved removal leaves zero hits in a
repository-wide search for its name.
