#!/usr/bin/env bash
# afk waker, for agents without a built-in timed wake-up (Claude Code has cron).
# Usage: ticker.sh <ledger path> <check-in interval in seconds> <delivery command>
#   Delivery command: a shell command that appends one message to the agent's own current session.
#                     The message text is in the environment variable AFK_MSG.
#                     SKILL.md ("Wake-up") lists the command for each agent.
# Delivers [AFK-TICK] every interval and one [AFK-END] at the ledger's deadline, then exits.
# It also exits as soon as the ledger's status is no longer active. The deadline is re-read every
# round, so changing the duration does not require restarting this process.
set -u
ledger=${1:?ledger path}; every=${2:?interval seconds}; cmd=${3:?delivery command}
log=${ledger%.md}.ticker.log

field() { sed -n "s/^$1: *//p" "$ledger" | head -1 | sed 's/ *#.*//'; }
deadline_epoch() { date -d "$(field deadline)" +%s; }

deliver() {
  AFK_MSG=$1 bash -c "$cmd" >>"$log" 2>&1 || echo "$(date '+%F %T') delivery failed: $cmd" >>"$log"
}

tick="[AFK-TICK] afk check-in. Ledger: $ledger. Follow the \"Check-in procedure\" in the ledger."
end="[AFK-END] afk deadline reached. Ledger: $ledger. Follow the afk skill's \"Wrap up (deadline version)\"; run date first and treat anything within 2 minutes of the deadline as reached."

echo "$(date '+%F %T') started pid=$$ cmd=$cmd" >>"$log"

while [ "$(field status)" = active ]; do
  left=$(( $(deadline_epoch) - $(date +%s) ))
  if [ "$left" -le 0 ]; then deliver "$end"; exit 0; fi
  sleep $(( left < every ? left : every ))
  [ "$(field status)" = active ] || exit 0
  if [ "$(date +%s)" -ge "$(deadline_epoch)" ]; then deliver "$end"; exit 0; fi
  deliver "$tick"
done
