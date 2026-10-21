---
name: afk
description: Autonomous work while the user is away, for any agent. Use when the user types /afk [duration or instructions], says they are going offline or leaving for N hours and you should decide for yourself (我要离线, 你自行决断), or says they are back (我回来了) during an afk. It defaults to 8 hours, decides on its own, parks what it is unsure of or does it reversibly and lets the user rule later, and schedules a check-in every 30 minutes to stay aligned. A duration given during an afk changes the deadline; no argument, or "I'm back", ends it with a summary and every open decision handed to the user.
argument-hint: "[duration like 1h / 90m / until 7am] [other instructions]; no argument: starts an 8-hour afk, or ends the running one"
---

# /afk: keep working on your own while the user is away

Arguments for this call: `$ARGUMENTS` (empty = none. If this shows a placeholder instead of the real arguments, the arguments are whatever text the user gave when invoking this skill.)

`<skill dir>` below is the directory that contains this SKILL.md.

## Capabilities by agent

Claude Code tools are used only in Claude Code; every other agent uses the equivalent in the right column.

| Need | Claude Code | Other agents |
|---|---|---|
| Timed wake-up | `CronCreate` / `CronList` / `CronDelete` | `<skill dir>/scripts/ticker.sh` (see "Wake-up"); a self-driven loop if that is unavailable |
| Ask the user | `AskUserQuestion` | Plain text: numbered questions, 2-4 options each, recommended option first and marked "(recommended)", then end the turn and wait for the reply |
| Notify the user | `PushNotification` | The agent's own notification mechanism; with none, the ledger and the final reply are the record. Also use any other notification channel the environment defines (a mail script, for example), and do not send twice through a path that already notifies automatically |
| Session id | `$CLAUDE_CODE_SESSION_ID` | The agent's own session-id variable (Codex: `$CODEX_THREAD_ID`); empty if there is none |

## Work out the state first

The ledger directory is `${AFK_DIR:-/tmp/afk-$(id -u)}`. It is not under `~/.agents` because Codex's default sandbox only lets you write the cwd and `/tmp`. A candidate ledger is one whose `session` equals this session, or whose `agent` and `cwd` equal this agent and directory. Take the newest candidate; if it is still ambiguous, ask the user. Then branch on the candidate's `status` and the arguments:

| State | Arguments | Do |
|---|---|---|
| No candidate, or all ended | none / a duration / a duration plus instructions | "Start"; with no duration, 8 hours |
| No candidate, or all ended | "I'm back" | Say there is no afk running |
| active | a duration only | "Change the duration" |
| active | none, or "I'm back" / "back" / 我回来了 | "Wrap up" (user-present version) |
| active | anything else | Do what the arguments ask (change the check-in interval, change the scope, report status, ...) and record it under "Instruction changes"; if there is also a duration, change that too |
| expired (deadline reached, waiting for rulings) | anything | First run step 2 of the user-present wrap-up, settle every ruling on the old ledger and set it to `ended`; then handle any new afk request in the arguments as "Start" |

When the state is active, also confirm the wake-up is alive. Claude Code: `CronList` shows an `[AFK-TICK]` job. Other agents: the modification time of `<ledger without .md>.ticker.log` is no older than check-in interval plus 2 minutes (`wake: selfloop` needs no check). If it is gone, the session restarted or the process was killed: tell the user and rebuild the wake-up.

**Parsing a duration**: `1h`, `1 hour`, `90m`, `half an hour` (半小时), `2.5h`; a bare number means hours; "until 7am tomorrow" is computed with `date -d 'tomorrow 07:00'`. If it cannot be parsed and does not look like a duration, treat the whole text as instructions. More than 7 days is cut to 7 and the user is told (Claude Code's recurring cron expires after 7 days). Always read the current time with `date`; never guess it.

## Start

1. **Fix the task.** Instructions in the arguments win over whatever is in progress or planned in the conversation. If there is neither, ask once what to work on (the user is still here).
2. **Ask once before starting**, and only for what you cannot start without: material, source files, credentials, scope. Ask it all in one go. Do not ask about anything else; sort other ambiguities into B or C. Missing material is never worked around with a substitute: it goes to C.
3. **Create the ledger**: `<skill dir>/scripts/new-ledger.sh "<deadline YYYY-MM-DD HH:MM[:SS]>" <agent name> "<task and limits>" "<session id, omit if none>"`. It prints the ledger path. The ledger already carries the "Check-in procedure"; do not rewrite or delete it.
4. **Set up the wake-up** (next section) and write the result on the ledger's `wake:` line.
5. **Reply briefly** (6 lines at most): the absolute deadline, the next check-in time (as the tool reports it), the task and limits as you understood them, the ledger path, and a reminder that the session has to stay open: if it exits or the machine sleeps, check-ins stop. If the agent runs in a sandbox, also state its limits (for example, Codex's default sandbox has no network, so the deadline notification cannot be mailed; a sandbox mode with network is needed for that). Then start working at once.

### Wake-up

The wake-up delivers an `[AFK-TICK]` every 30 minutes and one `[AFK-END]` at the deadline. The two prompts are the same in every method:

```
[AFK-TICK] afk check-in. Ledger: <path>. Follow the "Check-in procedure" in the ledger.
[AFK-END] afk deadline reached. Ledger: <path>. Follow the afk skill's "Wrap up (deadline version)"; run date first and treat anything within 2 minutes of the deadline as reached.
```

- **Claude Code**: two `CronCreate` jobs. The check-in is `7,37 * * * *`, recurring (it avoids :00 and :30, and the system adds an offset on top). The deadline job is `recurring: false`, pinned to the deadline's minute, hour, day and month (`date -d '+8 hours' '+%-M %-H %-d %-m'`); if that lands on :00 or :30, move it one minute later. `wake: cron tick=<id> end=<id>`. Jobs only fire while the session is idle, so a check-in that comes due during a conversation waits until the user stops talking.
- **Other agents that can deliver a message to their own current session from outside**: start `scripts/ticker.sh`, which handles both check-ins and the deadline. The script knows no agent; it only runs the "delivery command" you give it, with the message text in the environment variable `AFK_MSG`. Known delivery commands:

  | Case | Delivery command | Verified |
  |---|---|---|
  | Codex | `codex queue --thread "$CODEX_THREAD_ID" --message "$AFK_MSG"` | Yes: wakes an idle interactive session within seconds. A session the user interrupted with Esc is not woken |
  | Any TUI agent inside tmux | `tmux send-keys -t "$TMUX_PANE" -l "$AFK_MSG" && tmux send-keys -t "$TMUX_PANE" Enter` | The text arrives in the pane unchanged; how each TUI treats input that arrives while the agent is busy has not been checked one by one |
  | Another agent | Find one yourself: a queue / send / resume subcommand of its CLI, a local HTTP API, anything that appends a message to a given session | Before relying on it, send one harmless message and confirm it really wakes an idle session; then add the recipe to this table |

  **A delivery command may only point at your own session.** Take the session id or pane from your own environment variables (`$CODEX_THREAD_ID`, `$TMUX_PANE`) and never infer it from something like "the newest session file": a wrong guess queues check-ins into someone else's running session.
  ```bash
  setsid nohup <skill dir>/scripts/ticker.sh "<ledger>" 1800 "<delivery command>" </dev/null >/dev/null 2>&1 &
  ```
  **If the sandbox blocks the delivery command, run this outside the sandbox.** Codex's default sandbox blocks `codex queue` (it writes under `~/.codex`) and tmux (it connects to a socket). Then ask for elevation once, while the user is still there, with the reason "the afk waker has to deliver check-ins to this session from outside the sandbox". If it is refused or cannot be approved, use the self-driven loop.
  After `sleep 2`, read `<ledger without .md>.ticker.log`; a "started" line means success. Write `wake: ticker cmd=<recipe name>`. **Do not use `kill -0` to check**: inside a sandbox you cannot see processes outside it. Delivery failures are logged in the same file.
- **Neither works** (no usable delivery command, or elevation refused): a self-driven loop, `wake: selfloop`. **Do not end your turn.** When there is nothing unblocked to do, `sleep` (no longer than the agent's per-command timeout, usually 5 minutes at most), and on waking read `date`: if 30 minutes or more have passed since the last check-in, run the check-in procedure, and at the deadline wrap up. Ending the turn early is giving up the afk.

### The ledger

`new-ledger.sh` writes it. The header holds `status`, `deadline`, `wake` and more; below it come "Check-in procedure", "Progress", "Decided (A)", "Pending ruling (B, already done)", "Parked (C)" and "Instruction changes". Entries look like this:

```markdown
- A1 <decision>: <one-line reason>
- B1 <question> | chose X (reason) | other option Y | affects: <later work that depends on it> | revert: <git revert <sha> / restore the .bak>
- C1 <question> | stuck on <why> | preparation done | suggest: X
```

## The three tiers of deciding for yourself

| Tier | When | What to do |
|---|---|---|
| A: decide yourself | Inside the task, easy to undo, no real matter of preference | Decide; one line in the ledger |
| B: do first, rule later | Reversible, but a matter of the user's preference or a medium cost of regret | Take the recommended option and do it **in a reversible form**; later work continues on top of it; the ledger says how to revert |
| C: park | Irreversible or outward-facing (push, delete data, send a message or mail, spend money, publish, change shared infrastructure); missing material; a requirement so ambiguous that a wrong guess wastes the work; needs the user's authorization or elevation | **Do not do it.** Do only preparation that crosses no line (a local commit, a written draft) and switch to other independent work |

- Reversible form for B: in a git repository use a separate commit or branch and do not push; for files outside git, keep a `.bak` first.
- When you cannot tell the tier, it is C.
- **Record on the spot**, not at the end. After a context compaction or an interruption the ledger is the only reliable record.
- Do not ask the user while afk (a question stalls the session until they return). If the user sends an ordinary message, they are present: answer it and ask directly. The afk goes on until it is clearly wrapped up.
- **Do not request elevation or approval.** Nobody is there to grant it, and the session would stall on the prompt. When a sandbox blocks an action (writing outside it, the network, a socket), use a way that needs no elevation; if there is none, it is C. The single exception is starting the ticker during "Start", while the user is still present.
- Notify only in three cases, once each: everything unblocked is done and what remains is all waiting on rulings; the deadline; a failure you cannot recover from by yourself. Not for a check-in, not for parking an item. If a notification cannot be sent (for example, a sandbox without network), do not ask for elevation: write "notification failed" in the ledger and mention it in the summary.

## Change the duration

The new deadline is now plus the given duration; if the text starts with "extend" / "add" / "+" (再, 追加), add it to the existing deadline instead. Update `deadline` in the ledger. Claude Code must also `CronDelete` the old deadline job, create a new one for the new time and update `wake`. The ticker re-reads the ledger every round, so leave it alone. A self-driven loop picks it up the next time it reads `date`. If the new deadline has already passed, go straight to "Wrap up". Reply briefly with the new absolute deadline.

## Wrap up

First stop at a safe point: finish the atomic operation in hand and leave no half-written change. Then stop the wake-up. Claude Code: `CronDelete` both jobs. Ticker: set the ledger's `status` to `expired` or `ended` and it exits silently when it wakes (do not `kill` it; a sandbox cannot reach it). Self-driven loop: nothing to do.

**User-present version** (the user is back, or `/afk` with no argument):
1. Summarize, in the user's language, conclusion first:
   - One line: what was done and how long it took
   - Done: a few points
   - Decided (A): only those the user may want to change afterwards
   - Exceptions and risks: failures, unfinished work, anything outside the original scope
   - Pending rulings (B and C): for each, the question, the options, your recommendation, and how far a B item has gone
2. **Hand every open decision to the user.** Use the way to ask from "Capabilities by agent", recommended option first. Claude Code's `AskUserQuestion` takes at most 4 questions per round; with more than 4 items, first ask "all as recommended / one by one", and other agents do the same. With nothing to rule, say "nothing to rule" explicitly.
3. Carry out the rulings: keep a B item = finalize it, drop it = revert it as the ledger says; after a C ruling, go on with it. Set the ledger's `status: ended` and add a closing summary.

**Deadline version** (`[AFK-END]`, or a check-in finds the deadline passed; the user is probably away):
1. Write the same summary straight into the reply and into the ledger; set `status: expired`.
2. Notify once: `afk deadline: finished <highlights>, <N> items waiting for a ruling`.
3. **Do not ask**, do no more work, and wait for the user. When they return (any message, or `/afk`), if open items remain, run step 2 of the user-present version; do not repeat the summary already given at the deadline, only add what happened since.
