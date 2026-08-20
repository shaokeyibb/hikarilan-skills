---
name: codex-delegation
description: Run Codex CLI as a detached background worker on a git worktree — dispatch it, watch the sentinel it writes, relay a finished reviewer into its own fix, and prove what it claims. Use when handing a long task to Codex, when a dispatched run needs watching or has gone quiet, when a review's findings should become the next run, or when a run reports a lock it never proved.
---

# Codex Delegation

A subagent shares your context budget and your turn; Codex does neither. It gets its own
window, runs for hours after your turn ends, and costs you only the brief you write and
the result you read. That makes it the right shape for work measured in hours — and the
wrong shape for anything you'd rather just do.

This skill covers the **running** of such a worker. Two neighbours cover the rest:
what is safe to hand over and how to shape a brief live in **delegating-to-agents**;
when a tree is worth creating and how to merge it back live in **concurrent-worktrees**.

## Preflight

**Never dispatch into a path you have not made git resolve.** A worktree removal that
fails partway leaves the files but drops the `.git` pointer, and from then on git walks
*up* and resolves that directory to the **main repository**. An existence check passes.
A dispatch into it edits the trunk.

`scripts/dispatch.sh` (and `.ps1`) makes git resolve the path and refuses to launch when
`rev-parse --show-toplevel` disagrees with the directory it was handed. Keep that check
if you write your own launcher; it is the difference between an isolated run and a run
that quietly rewrites your trunk.

## The sentinel quartet

Every run writes four files named for it. They exist so the run's state is answerable
from disk rather than from the agent's own account:

| file | written | what it answers |
|---|---|---|
| `.log` | streaming | what happened, in full |
| `.out` | at the end | the deliverable — the run's final message |
| `.before` | at dispatch | the tree's `git status --porcelain --ignored` |
| `.exit` | **last** | it finished, and with what code |

`.exit` is written after everything else precisely so its existence *is* the completion
signal. `scripts/watch.sh` reads the quartet and reports one state per run.

**Watch for the run that died without writing `.exit`.** A rate limit, an auth failure,
or a dropped stream ends the process with the sentinel incomplete, and anything waiting
on `.exit` waits forever. The check that catches it is counting: live `codex exec`
processes below unfinished sentinels means one is gone. Wire your monitor to that
comparison, not to `.exit` alone.

That count is the one platform-dependent part — `pgrep`, `tasklist`, and `ps` are not all
present everywhere. When no probe works, `watch.sh` reports the sentinel and marks
liveness unavailable rather than guessing: an honest unknown beats a confident `DEAD`.

**Requirements:** the `codex` CLI on `PATH`, a git repository, and either bash or
PowerShell. Set `CODEX_RUNS` to relocate the sentinel directory (default `.codex-runs/`
at the repository root) and `CODEX_MODEL` to change the default model.

## Wiring it into Claude Code

**Arm one persistent Monitor for all runs, before the first dispatch:**

```
Monitor({command: "bash <skill>/scripts/watch-loop.sh", persistent: true,
         timeout_ms: 3600000, description: "codex runs finishing or dying"})
```

One monitor covers every run, including ones dispatched later — `watch-loop.sh` baselines
the runs that already finished, then emits only state changes. Per-run monitors multiply
notifications for nothing and risk the flood cut-off.

It emits `DONE` **and** `DEAD` deliberately. A monitor that only reports success stays
silent through a death, and silence is indistinguishable from still-running.

**Never block on a run.** Not `TaskOutput`, not a foreground wait, not a sleep loop. Runs
last hours; the Monitor is what tells you, and your turn ends long before they do. Dispatch,
then go do other work in the same turn.

**The notification is a pointer, not the content.** `DONE <name> exit=0 result=12268` says
a deliverable exists — it does not say what it concluded. Read `.out` before deciding
anything. `result=MISSING` means the run produced nothing regardless of the exit code.

**Refill the slot the moment one frees.** The costly failure is not running too many at
once — it is several finishing together, you harvesting them all, and nothing new going
out while you write up results. Dispatch the next brief *before* writing the summary of
the last.

How many run in parallel is a property of your account and provider, not of this skill.
Find your own ceiling: raise the count until runs start failing on rate limits, then stay
one below. A run rejected that way usually dies without writing `.exit`, so the `DEAD`
events are how you notice you have crossed it.

**When you kill a run yourself, delete its sentinel files.** A stopped run leaves `.log`
without `.exit`, which is exactly the signature of a death — the monitor will report it as
`DEAD` and the process count will look short. Clearing `.log`/`.out`/`.before` keeps that
signal honest.

## The loop

Each `DONE` event runs the same cycle, and the cycle is what makes a hours-long run
trustworthy:

1. **Read `.out`.** Missing or empty → treat as failed, whatever the exit code says.
2. **Harvest** (below) — diff the tree against `.before`, verify the claims.
3. **Route** by what you find:
   - clean → dispatch a **fresh** run to review it (`templates/review.md`)
   - review found real defects → **relay** that reviewer into fixing them
   - review passed → merge, and dispatch the next piece of work
4. **Refill** the slot in the same turn.

The invariant that holds the loop together: **the run that changed the code is never the
run that approves it.** Everything else here is machinery serving that one rule.

## Harvest

**Read `.out` first, and treat a missing `.out` as a failed run even when `.exit` is 0.**
The transcript is not the deliverable; a run that ended without producing one produced
nothing.

**Diff `.before` against the tree's `git status --porcelain --ignored` now.** Plain
`--porcelain` hides ignored paths — a run that wrote 100 MB of `node_modules` shows a
clean tree, and the snapshot proves nothing. Read the two lists against a stated
allowance: tool caches (`.pytest_cache`, `__pycache__`, `.ruff_cache`, build outputs) are
expected and need no cleanup; installed dependencies, writes outside the tree, and any
tracked-file change the brief did not authorise are violations.

State that allowance **in the brief**, as two explicit lists. "Modify nothing" and "run
the test suite" contradict each other, and a run given both will either skip the tests or
declare its own work invalid over a cache directory.

## Relay

When a read-only reviewer finishes and its findings *are* the follow-up work, resume that
same session rather than briefing a fresh one. It already holds the whole branch in
context; a new run re-reads all of it to reach the same place. `scripts/relay.sh` extracts
the session id from the previous `.log` and continues it with a new brief.

**The one invariant: whoever changed the code is never the one who signs off on it.**
Relaying a reviewer into a fix is sound — its review was written and harvested before it
gained write access, so the fix cannot have coloured a conclusion that already exists on
disk. Relaying *again* to bless that fix is not. Dispatch a fresh run to review it.

A relay that cannot find the session id must fail loudly. Starting a fresh session
instead looks identical from the outside while carrying none of the context that
justified relaying at all.

## Prove it broke

**Green is the default state.** A test suite that passes proves nothing about a lock that
was just written — an assertion that checks nothing passes exactly as loudly as one that
guards the invariant.

So require, in the brief and again when reading the result: **break the thing the lock
guards, and show it going red.** Paste of the failure text, not a claim that it failed.
This one demand catches the whole family of assertions that exist but hold nothing.

Two sharper forms, for when a run reports N locks:

- **Independence.** Breaking guard *i* must turn guard *i* red **and leave the other N−1
  green**. `1 failed, N-1 passed` is the shape that proves the guards can tell the cases
  apart; N reds from one break means one guard wearing N names.
- **Reachability.** Ask for the assertion sites as `file:line` **before** asking about
  mutations. A run that mutated N times and went red N times will otherwise report "N
  locks" when it has two. Red count is not lock count; **site** count is.

## Writing the brief

Start from `templates/brief.md` (implementation) or `templates/review.md` (read-only
review). Both encode the demands above; fill in the task-specific parts.

Two things belong in every brief and are easy to leave out:

**Falsify first.** Open with a probe that reproduces the defect on the current trunk, and
an instruction to stop and report if it is already fixed. Work dispatched against a
defect that no longer exists comes back as a plausible change to something else.

**Invite the rebuttal.** End with "tell me where this brief is wrong — argue it and show
evidence." Briefs carry the author's causal guesses, and those fail far more often than
the numbers in them do. A run that can contradict its brief is the cheapest correction
available; one that cannot will faithfully implement your mistake.
