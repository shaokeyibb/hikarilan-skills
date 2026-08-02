---
name: delegating-to-agents
description: Decide what to hand to a subagent, size and structure the brief so its constraints hold, and self-check what comes back before it becomes evidence. Use when spawning subagents, when deciding whether a task is delegable at all, when a subagent's findings are about to drive a decision, or when a constraint written into a brief keeps getting violated.
---

# Delegating to Agents

Delegation hands over the work, not the responsibility. Three questions follow from that, in order: what's safe to hand over, how to shape the brief, and what you must check when it comes back.

## What to delegate

The test is one question: **can the result be verified without redoing the work?**

- **Yes** — a bounded implementation against a written spec (verify: run the tests), a search across many files (verify: spot-check the hits), a review of a fixed diff, a mechanical migration. Delegate freely.
- **No** — anything whose only evidence is the agent's own account. "Assess whether this design is sound" comes back as prose you can only check by forming the judgement yourself, so nothing was saved.

Two categories stay with you regardless of verifiability: **irreversible operations** (destructive git, publishing, deletion), because a mistaken one can't be walked back after you catch it; and **decisions needing context you can't package** — cross-cutting coordination, priority calls, anything where the relevant state lives in your head rather than in files.

## Sizing the brief

**Pack by neighbourhood.** Several related items to one agent, not one item per agent. Context reconstruction is the dominant cost of an agent, and items touching the same files share almost all of it — one-item-per-agent pays that cost N times for nothing.

**Don't queue.** Dispatch everything you can run concurrently at once, and send the next brief the moment a slot frees rather than waiting for the batch to land.

**Hand over the state you already established.** Which checks are green, which reds are known, why they're red. Without it an agent spends its run fighting environmental noise instead of doing the work — and the noise looks exactly like real findings to someone who wasn't there.

## Change the structure, not the wording

Some behaviours an agent structurally cannot deliver. Restating them more forcefully changes nothing but the length of the brief.

**"Read only — modify nothing."** A read-only tool set doesn't buy this, because the destructive path runs through the shell. The damage rarely comes from an edit; it comes from the cleanup afterwards — a `git checkout --`, `restore`, `stash`, or `clean` that erases uncommitted work belonging to somebody else.
→ Constrain **git writes**, naming them: `add`, `commit`, `stash`, `checkout`, `restore`, `reset`, `clean`, `apply`. Leave `diff`, `log`, `status`, `show` open. That line tracks the real risk, and still lets the agent construct data and test things.

**"Wait until the background job actually finishes."** An agent has no reliable way to block. It reasons, reaches the end of its turn, and returns — sincerely writing "I will now wait" on the way out.
→ Give it a blocking mechanism: park on the log and wake on a sentinel the job writes as its final act. Then read that log yourself before believing the agent *or* the notification.

**"Stay inside your working directory."** APIs redirect writes without ever disobeying an instruction. Changing a shell's location leaves the process-level current directory untouched, so a runtime's file API resolves a relative path against the original directory and lands the write there.
→ Constrain **how files get written**: absolute paths, or shell-native write commands that follow the shell's location. Same for git — every invocation carries an explicit `-C <absolute path>`.

## A ban with no alternative gets routed around

A brief that only forbids loses to a legitimate need. An agent told to run no destructive git will still reach for `stash` when it wants to know whether a failure predates its own work — a reasonable diagnostic meeting an operation it believes is reversible.

Pair every prohibition with the way to get the same answer: copy the files to a scratch directory and compare there, run the analysis against a temporary copy, mutate at runtime instead of on disk. Given a road, it takes the road.

## Verify claims before they become evidence

An agent's report is a claim. These stay unverified until you check them yourself:

- **"Restored / formatted / cleaned up."** Compare content hashes against the committed object rather than strings — line-ending differences make string comparison lie in both directions.
- **Counts and identifiers.** Totals get quoted from the wrong denominator, and a warning from one channel gets reported as an event from another. Re-read the raw artifact behind anything you plan to pass upward.
- **"The checks pass."** Re-run them in the authoritative environment. A result from an isolated or improvised environment establishes nothing.
- **The tree.** After any agent with shell access returns, run `git status --short` and `git stash list`. Separate its unrequested changes from the work you asked for and decide on them explicitly, rather than letting them ride along in your commit.

## Split the roles

Have one agent implement and a **different** agent review. An agent that wrote both the specification and the code ends up reviewing its own reasoning, and drifts into defending it.

Route the fixes by size. A trivial correction you make yourself. Anything larger goes **back to the agent that implemented it** — it still holds the context, and rebuilding that in a fresh agent costs more than the fix does.
