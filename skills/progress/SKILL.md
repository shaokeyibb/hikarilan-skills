---
name: progress
description: Report where the work stands, as tables in one fixed shape - what you are doing now, what comes next, what is not done, what is done, how long is left, and how far along it is. Use when the user types /progress, or asks where you are, what the status is, how far along you are, what is left, or how long this will take. Any arguments are extra questions to answer after the standard report.
argument-hint: "[extra questions to answer in addition to the standard report]"
---

# Progress report

Answer one question, "where does the work stand?", in the same shape every time, so the user can read it at a glance and compare it with the last one. This is a report, not a work session: while writing it, do not start, finish or change anything.

Arguments for this call: `$ARGUMENTS` (empty = none. If this shows a placeholder instead of the real arguments, the arguments are whatever text the user gave when invoking this skill.)

## Read before you write

Do not report from memory of the conversation alone. Look at:

- Your task list or plan, if the agent has such a tool, and any ledger or plan file you keep (an afk ledger, for example).
- The conversation: what the user asked for, what you promised, what you said you would check.
- The state of the world, with read-only commands: `git status` and `git log` for what actually changed, background commands, running subagents, scheduled jobs, CI. Memory says "finished"; the repository says whether it is.

Cheap read-only checks are fine. Do not rerun something expensive (a full test suite) just to report; say when it last ran and what it showed.

## The report

Tables, not prose: two always, a third when there are arguments. Write headings and cells in the user's language. Put nothing before the first table.

**Table 1: the work items.** Columns `| # | Item | Status | Detail |`. One row per piece of work, grouped in this order, numbered straight through:

| Status | What belongs there | Detail says |
|---|---|---|
| 🔄 Doing | The one thing in flight | Where in it you are |
| ⏸ Idle | Only when nothing is in flight: a single row, item "nothing in flight", in place of the Doing row | Why: waiting for the user, blocked, or finished |
| ⏭ Next | What comes after, in execution order | What it waits on, if anything |
| ⛔ Not done | Known unfinished and will not happen by itself: blocked, skipped, deferred, dropped, failed, left for the user to decide | The state and the reason |
| ✅ Done | Finished | How you know: a test passed, a file written, a command's output |
| ❔ Unverified | You believe it is done but have not checked | What would verify it |

Not done is not a second Next: an item belongs there when nothing in your plan will get to it. Past about eight Done rows, fold the older ones into one row ("12 earlier steps, all verified") and keep the recent ones.

**Table 2: time and progress.** One row under the header `| ⏱ Time left | 📊 Progress |`.

- *Time left*: base it on something measurable, your pace so far (time per finished item) times the items left, or a known duration of a pending command. Give a range and name the assumption. Keep the time you control apart from time spent waiting on others (CI, review, a decision from the user) and say which is which. With no basis (the first item is still in flight, the scope is unknown), write "cannot estimate yet" and what is missing; do not invent a number.
- *Progress*: "n of m <unit>" with the unit named (files, steps, tests). Add a percentage and a ten-cell bar (`████░░░░░░`) only when m is actually known. If the scope is still growing, say so and give n of m so far. An item in flight is not done; do not round it up. If the picture is worse than what you said earlier ("almost done"), say so plainly and correct the earlier figure instead of defending it.

**Table 3: extra questions**, only when there are arguments. See below.

Keep every cell to one line: no line breaks and no lists inside a cell. A cell that will not fit in a line is too long; cut it to the fact.

```
| # | Item | Status | Detail |
|---|---|---|---|
| 1 | Migrate billing tests to the new fixture | 🔄 Doing | File 5 of 9 |
| 2 | Migrate the remaining 4 files | ⏭ Next | After #1 |
| 3 | Delete the old fixture | ⏭ Next | After every file passes |
| 4 | `test_retry` is flaky | ⛔ Not done | Skipped; needs your call on quarantining it |
| 5 | Fixture module | ✅ Done | Its own tests pass |
| 6 | Files 1-4 migrated | ✅ Done | Each file's tests pass |

| ⏱ Time left | 📊 Progress |
|---|---|
| About 25-35 min of my work (about 5 min per file), plus CI ~10 min, not in my hands | `████░░░░░░` 4 of 9 files (44%) |
```

## Extra arguments

Whatever the arguments ask for, beyond the standard report, is an extra question: "which files changed?", "any risks?", "does anything need me?". Answer each one in Table 3, `| Question | Answer |`, one row per question, answers short. You may investigate to answer, read-only.

If an argument asks you to act (fix, run, continue) rather than to report, do not do it inside the report. Say so in one line below the tables and offer.

## After the report

If you were in the middle of work, carry on with it after reporting, unless the user asked you to stop.
