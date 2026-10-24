#!/usr/bin/env bash
# Create an afk ledger and print its path.
# Usage: new-ledger.sh <deadline "YYYY-MM-DD HH:MM[:SS]"> <agent name> <task, one or two sentences> [session id]
# Ledger directory: $AFK_DIR, default /tmp/afk-<uid>. Codex's default sandbox only lets you write the cwd
# and /tmp, and everything under ~/.agents is read-only, so the ledger does not live there.
# The caller passes its own session id (each agent names its variable differently); empty if none.
set -eu
deadline=${1:?deadline}; agent=${2:?agent name}; task=${3:?task}; session=${4:-}
dir=${AFK_DIR:-/tmp/afk-$(id -u)}
mkdir -p "$dir"
f=$dir/$(date +%Y%m%d-%H%M%S).md
cat >"$f" <<EOF
---
status: active   # active | ended (the afk is over)
agent: $agent
session: $session
cwd: $PWD
started: $(date '+%F %H:%M')
deadline: $deadline
wake: pending   # cron tick=<id> end=<id> | ticker cmd=<recipe name> | selfloop
---
# afk ledger
Task: $task
## Check-in procedure (run on every [AFK-TICK], or at each check-in point of a self-driven loop)
1. If this ledger's status is not active (ended), this is a late check-in: ignore it and answer in one sentence.
2. Run date. If the deadline has passed, follow the afk skill's "Wrap up (deadline version)": the afk limits end and the work carries on.
3. Align progress: what was done since the last check-in, what is stuck, what is next. Append one line under "Progress".
4. Re-check "Parked" items; unpark any whose blocker has gone (CI finished, dependency arrived, ...).
5. Continue with the most valuable unblocked item. If there is nothing to do, do not invent work: log it and end the turn.
6. Do not ask the user and do not request elevation or approval (nobody is there). Sort decisions into A decide yourself / B do first, rule later (reversible) / C park (irreversible, outward-facing, missing material, ambiguous requirement, needs authorization or elevation). Record each one on the spot. Keep output short.
7. If the user is present and says they are back, or runs /afk with no argument, follow the afk skill's "Wrap up (user-present version)". When unsure of a rule, read the afk skill's SKILL.md.
## Progress
- $(date '+%H:%M') started
## Decided (A)
## Pending ruling (B, already done)
## Parked (C)
## Instruction changes
EOF
echo "$f"
