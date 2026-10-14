---
name: repo-audit-loop
description: Audit a whole repository, or a batch of finished work, until a round finds nothing — coverage ledger over every tracked file, orthogonal lenses, spec–code sync, every public entry actually run, and a defect ledger cleared as you go. Use when asked to audit, review or health-check a project, when closing out a batch of changes, before a release or handover, or when checking that specs and code still agree.
---

# Repo audit loop

An audit fails quietly in two ways: it covers less than it claims, and its findings evaporate
before anyone fixes them. A report that "reviewed the codebase" after sampling a third of it
reads exactly like one that read everything; a defect mentioned in paragraph six of a report
from four changes ago is as good as unreported. This loop makes coverage countable and findings
durable, and repeats until a full round turns up nothing.

## Scope

Two entry points, one procedure:

- **Whole repository** — the scope is every file `git ls-files` lists: source, scripts, tests,
  fixtures, frontend, docs, specs, examples, configuration.
- **Batch closeout** — the scope is the files a batch of finished changes touched, plus the seams
  where that work meets the code around it.

## Steps

### 1. Open two ledgers

- **Coverage ledger** — one row per file in scope, marked when audited. For any file of 200 lines
  or more, the row records which line ranges were read in full.
- **Defect ledger** — one entry per known defect, kept where work is tracked, never only in a
  report's prose. Seed it with what earlier reports already mentioned and left unfixed,
  including tests reported as "already failing on the base".

From here on, the moment any report — audit, implementation, review — mentions a defect it did
not fix, that defect becomes a ledger entry and appears in the next status update.

### 2. Run orthogonal lenses, read-only

Send each lens to its own auditor. Auditors read and report first; nothing is changed until the
findings are triaged. Lenses must **fail differently**: three auditors given the same question
return three copies of one report that read like thorough coverage.

- **Quality lens** — the code against the dimension list in
  [references/dimensions.md](references/dimensions.md). Split the scope between auditors by area,
  and give every auditor the full dimension list; a lens narrowed to "only report these" misses
  everything else. Auditors may add dimensions.
- **Spec–code sync lens** — go through the specification requirement by requirement and classify
  each against the code: **in sync**, **spec stale**, **code drifted**, or **unimplemented**.
  Then scan in reverse: every contract-level behaviour in code (public entry points, closed sets
  of values, events, persisted fields, error codes) needs a requirement that states it. For each
  "unimplemented" requirement, run `git log -S` to learn whether it was deliberately removed
  (delete the clause) or never built (ask the owner).
- **Feature lens** — list the features and public entry points from the README and the specs,
  and **run each one** end to end. Existing code, a spec, and passing unit tests are not evidence
  that a feature works; a gesture parameter that was never wired through survives all three.
  Mark what offline runs cannot show — real adapter I/O, the gap between a fake and the real
  system — as unverified.
- **Gate blind-spot lens** — list what the merge gate does not run (a frontend toolchain, tests
  marked slow, benchmark datasets, platform-specific jobs) and run those.

### 3. Reconcile and triage

- **Coverage**: reconcile the coverage ledger against `git ls-files` to 100%. A row without
  read line ranges for a large file, or an area that was sampled, goes back for a re-read.
- **Findings**: split into two kinds. A **confirmed** finding names the input, the path and the
  wrong result; it goes into the defect ledger to be fixed. A **plausible** finding gets a
  separate auditor whose job is to refute it, defaulting to refuted when the evidence runs out.
  What survives is confirmed; what does not is dropped with the refutation noted.

### 4. Fix, then audit again

The auditor that found a problem fixes it — it already holds the context — working from its
own report, then self-checks. The code it changed is reviewed by a different auditor than the
one that wrote the fix.

Then run another round: the full scope again, or at least every changed surface plus a sample of
the rest. Repeat until a round finds **zero visible problems**.

## Ordering against acceptance

Acceptance — the real end-to-end run, the release candidate, the handover check — runs as soon as
a batch of fixes has merged and passed the gate, **in parallel** with the next audit round.
Acceptance results are the main evidence of progress, so failures it exposes are fixed first,
ordered by their effect on outcomes. Findings that affect only code quality go into the defect
ledger and do not block acceptance.

## Done

The coverage ledger reconciles to 100% of the scope with read ranges for every large file; the
spec–code lens has classified every requirement and found a requirement for every contract-level
behaviour; every public entry has been run; the defect ledger is empty, or what remains is
written down as bounded debt — what it is, why it is acceptable, what it blocks; and the latest
round found nothing.
