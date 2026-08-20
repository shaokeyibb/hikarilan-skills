#!/usr/bin/env bash
# Report the state of every dispatched run, once. Loop it from a monitor or a cron.
#
#   watch.sh [--runs <dir>]
#
# Exit 0 always; the output is the signal. Three states per sentinel:
#   DONE  <name> exit=<code> result=<bytes|MISSING>   .exit exists
#   LIVE  <name>                                      no .exit, a codex process is up
#   DEAD  <name>                                      no .exit, no codex process
#
# DEAD is the state worth wiring an alert to: a run that died without writing .exit
# (rate limit, auth error, dropped stream) leaves no exit code, so anything that waits
# for .exit waits forever. Comparing live processes against unfinished sentinels is
# what surfaces it.
set -uo pipefail   # deliberately not -e: probing for absent tools must not end the run

RUNS="${CODEX_RUNS:-.codex-runs}"
[[ "${1:-}" == "--runs" ]] && RUNS="$2"
[[ -d "$RUNS" ]] || { echo "no runs directory: $RUNS" >&2; exit 0; }

# Process counting is best-effort and platform-dependent: pgrep is absent on Git Bash for
# Windows, and ps output differs everywhere. When no probe works, report the sentinels and
# say the liveness column is unavailable — an unknown is worth more than a wrong DEAD.
count_codex() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f 'codex exec' 2>/dev/null | wc -l | tr -d ' '
  elif command -v tasklist >/dev/null 2>&1; then
    tasklist //FI "IMAGENAME eq codex.exe" 2>/dev/null | grep -ci 'codex.exe' | tr -d ' '
  elif command -v ps >/dev/null 2>&1; then
    ps -e 2>/dev/null | grep -c '[c]odex' | tr -d ' '
  else
    echo "unknown"
  fi
}

PROCS="$(count_codex)"
UNFINISHED=0

shopt -s nullglob
for log in "$RUNS"/*.log; do
  name="${log##*/}"; name="${name%.log}"
  if [[ -f "$RUNS/$name.exit" ]]; then
    code="$(tr -d '[:space:]' < "$RUNS/$name.exit")"
    # A result file is the deliverable; the transcript is not. Report its absence loudly —
    # exit 0 with no result means the run ended without producing anything.
    if [[ -s "$RUNS/$name.out" ]]; then
      echo "DONE  $name exit=$code result=$(wc -c < "$RUNS/$name.out" | tr -d ' ')"
    else
      echo "DONE  $name exit=$code result=MISSING"
    fi
  else
    UNFINISHED=$((UNFINISHED + 1))
    if [[ "$PROCS" == "unknown" ]]; then echo "OPEN  $name (liveness unavailable)"
    elif (( PROCS > 0 ));            then echo "LIVE  $name"
    else                                  echo "DEAD  $name"
    fi
  fi
done

if [[ "$PROCS" != "unknown" ]] && (( PROCS < UNFINISHED )); then
  echo "WARN  $PROCS live processes < $UNFINISHED unfinished sentinels — a run died without writing .exit"
fi
