---
name: batch-closeout
description: Close out a batch of finished work before it goes to acceptance — clear the defect ledger, then run a multi-lens final audit. Use when a series of changes is complete and about to be verified end-to-end, released, or handed over, or when deciding whether a group of work is ready to be accepted at all.
---

# Batch Closeout

A **batch** is a group of work that will share **one acceptance signal** — a single end-to-end run, release, or handover. Work shares that signal because it is expensive: too slow to run per change, so changes accumulate and get validated together.

Sharing is exactly what creates the hazard. One change carrying a known defect contaminates the signal for every change in the batch: the run fails, and now nobody can tell whether the failure belongs to the new work or to something that was already understood and deferred. You lose the only clean read you were going to get.

Closeout protects that signal. It runs **after the last change merges and before acceptance**, in two actions, in this order: **clear the ledger**, then **audit**. What comes out the far side is meant to be final — not a layer to revisit.

## The ledger

Every implementation and review report carries items its author found but didn't act on — out of scope, noticed late, deemed someone else's problem. Left in prose, they disperse: nobody re-reads a report from four changes ago, and the batch reaches acceptance carrying them.

- The moment a report mentions a defect it didn't fix, it becomes a **ledger entry** — tracked where you track work, not quoted in a summary.
- Clear the ledger **before** acceptance, never after. That ordering is the whole point of the ledger: a deferred defect surfacing during acceptance is precisely the contamination this gate exists to prevent.
- What genuinely stays unfixed becomes **written, bounded debt**: what it is, why it's acceptable, what it blocks. Silence is what turns a decision into a surprise.

## The final audit

Once the ledger is clear, send parallel read-only agents across the whole batch — each with a different **lens**. Three that cover distinct ground:

- **Architecture** — the batch against its design intent, including the items marked "worth exploring" at the time and never revisited.
- **Code** — exception paths, concurrency, cache and state coherence, concentrated on the **seams** where new work meets old.
- **Contract** — every promise the work made, checked twice over: is it implemented, and is it tested?

The lenses have to be **orthogonal**. Three agents pointed at the same question return three copies of one report and read as thorough coverage while leaving the same ground unexamined. Pick lenses that fail differently.

These are review agents: constrain them structurally rather than by instruction (see `delegating-to-agents`), and read their raw findings before treating any of it as established.

## Confirm before you fix

An auditor sent to find problems is under pressure to return some. Findings arrive mixed: real defects alongside confident speculation.

Split them. A **confirmed** finding names the input, the path, and the wrong result — fix it. A **plausible** one gets a dedicated agent whose job is to *refute* it, defaulting to refuted when the evidence runs out. What survives refutation gets fixed; what doesn't gets dropped, and neither outcome costs you the batch.

## Done means

The batch is closed when the audit's severe findings are all fixed or all written down as bounded debt — no third state.

Only then does acceptance run: full suite, real end-to-end exercise in the authoritative environment, static gates green. This is the boundary the expensive full-fat gate exists for; per-change runs stay narrow so that this one gets run at all.
