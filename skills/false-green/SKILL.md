---
name: false-green
description: Build checks whose green can be trusted, and prove one before reporting it. Use when about to report tests, checks, or gates as passing; when designing a gate or CI step; when an absence from a search is about to justify a deletion; when a test claims to lock a behaviour; or when another skill needs the false-green checks.
---

# False Green

A **false green** is a broken measurement that fails toward pass. It is worse than a red — a red stops you, a false green ships.

Before calling anything passing, answer one question:

> **If this were failing right now, would the command I just ran show me?**

Unless the output in front of you answers yes, you have not verified. You have guessed.

## What a check needs before its green means anything

Three properties. A check missing any of them can report success while measuring nothing.

**Failure has to be observable through the path you actually run.** Not observable in principle — observable in the command you type and the output you read. Most of the shapes below are violations of exactly this.

**Three outcomes, not two.** Pass, fail, and **not verified** are distinct results, and *not verified* must carry its own exit code. Collapsing skipped into passed is the single most productive source of false greens: credentials absent, a suite never collected, a tool not installed — each renders as success, and each is a lie in the direction that ships. Reserve a third code (conventionally `2`) and make callers treat it as "unknown", never as "fine".

**One definition, many callers.** Define what the gate *is* in exactly one place, and let every entry point — task runner, hook, CI config, local script — invoke that one definition rather than inline its own copy. Copies drift, and a drifted gate does not announce itself: each entry point keeps passing, while they no longer check the same things. If a discipline is what keeps your copies in sync, they are already out of sync.

Not every check earns this rigour. Apply it where a green drives something **hard to walk back** — shipping, deleting, declaring a batch done. A scratch script you'll read the output of by eye needs none of it.

## Known shapes

Each of these converts a failure into a pass silently, with no error raised anywhere.

**The pipe eats the exit code.** In `cmd | tail; echo $?`, `$?` is `tail`'s status, and `tail` always succeeds. The same holds for the last link of any chain: `cmd > log 2>&1; echo $?` reports `echo`. Background-job completion notices share the defect — they carry the status of the final link, not of the work.
→ For an exit code, drop the pipe: `cmd > out.log 2>&1; echo "EXIT=$?"`, then read the log. Or take `${PIPESTATUS[0]}`.

**Absent reads as zero.** A counter that never incremented, a metric never emitted, a rule never loaded — each renders as `0 failures`.

**The empty set is vacuously true.** `all()` over nothing is `True`; a validator holding zero rules passes everything. When an aggregate reports success, confirm the collection it aggregated was non-empty.

**The search was truncated.** Any capped or paginated result set makes an absence claim worthless. Before concluding "nothing calls this, it can go," re-run the search uncapped. Then layer what comes back — runtime callers, test references, and documentation mentions carry different weight, and a symbol with a dedicated test file is live code nobody happens to invoke.

**The code under test isn't the code you changed.** An interpreter, package, or binary resolved from outside your working tree answers confidently about the wrong source. The symptom is diagnostic: *edits to the test change the outcome, edits to the production code don't.* Before trusting a run in any non-default environment, print the resolved path of the module under test and confirm it sits in the tree you edited.

## Does the test lock what it claims?

"It ran and it's green" and "this would catch that behaviour breaking" are different facts. One way to tell them apart:

**Break the exact semantic the test claims to lock, and watch it go red.**

Breaking something coarser proves nothing — disabling a whole feature reds everything, which is noise, not signal. So does an assertion that cannot fail: comparing a value to itself, asserting a type, or matching a message string all survive a total inversion of the logic they supposedly guard.

- Mutate at runtime — monkeypatch, injection, a swapped binding — rather than by editing files. Nothing to clean up, nothing to lose.
- Report mutations concretely: *what I broke → which test went red*. "Mutation testing was performed" is not a finding.
- Watch the sentinel: when one narrow mutation reds a broad swath of unrelated tests, the mutation harness broke, not the code.
- Reviewing someone else's mutation evidence means running a different mutation yourself.

## Spend the loop wisely

Verification you avoid running verifies nothing. Keep it cheap enough that you run it:

- Run the full suite **once**, redirect it to a file, and mine that file afterwards for every count, failure list, and duration. Re-running to read a number is pure waiting.
- While iterating, run the affected tests only. Decide "affected" by grepping for consumers of the symbols you touched — broadly — rather than running only the tests you wrote.
- Save the full gate for the commit boundary, and run it in the authoritative environment.
- Timing-sensitive checks contend with parallel load. A red there earns one exclusive re-run before you judge it — and then you judge it, either way.
