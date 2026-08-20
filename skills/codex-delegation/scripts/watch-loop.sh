#!/usr/bin/env bash
# Emit one line per run that *changes* state. Built for Claude Code's Monitor tool:
#
#   Monitor({command: "bash <skill>/scripts/watch-loop.sh", persistent: true,
#            description: "codex runs finishing or dying"})
#
# Two event kinds, because silence must never be mistaken for progress:
#   DONE <name> exit=<code> result=<bytes|MISSING>
#   DEAD <name> — no .exit and no live process; nothing will ever write its exit code
#
# Runs dispatched after this starts are picked up automatically.
set -uo pipefail

RUNS="${CODEX_RUNS:-.codex-runs}"
INTERVAL="${CODEX_WATCH_INTERVAL:-20}"
[[ -d "$RUNS" ]] || { echo "watch-loop: no runs directory: $RUNS" >&2; exit 1; }

# Baseline every run that has already finished. Without this the first pass replays the
# entire history as fresh notifications — and a monitor that floods gets shut off.
declare -A REPORTED
shopt -s nullglob
for f in "$RUNS"/*.exit; do n="${f##*/}"; REPORTED["${n%.exit}"]=1; done
echo "watch-loop: armed on $RUNS (${#REPORTED[@]} already finished, not replayed)"

live_codex() {
  if command -v pgrep   >/dev/null 2>&1; then pgrep -f 'codex exec' 2>/dev/null | wc -l
  elif command -v tasklist >/dev/null 2>&1; then tasklist //FI "IMAGENAME eq codex.exe" 2>/dev/null | grep -ci 'codex.exe'
  elif command -v ps    >/dev/null 2>&1; then ps -e 2>/dev/null | grep -c '[c]odex'
  else echo -1; fi
}

while true; do
  for f in "$RUNS"/*.exit; do
    name="${f##*/}"; name="${name%.exit}"
    [[ -n "${REPORTED[$name]:-}" ]] && continue
    REPORTED["$name"]=1
    code="$(tr -d '[:space:]' < "$f")"
    if [[ -s "$RUNS/$name.out" ]]; then
      echo "DONE $name exit=$code result=$(wc -c < "$RUNS/$name.out" | tr -d ' ')"
    else
      # exit 0 with no result file still means the run delivered nothing.
      echo "DONE $name exit=$code result=MISSING"
    fi
  done

  # A run whose process is gone but whose .exit never appeared will never complete.
  # Anything blocking on .exit would wait forever, so this has to be its own event.
  procs="$(live_codex)"
  if (( procs == 0 )); then
    for log in "$RUNS"/*.log; do
      name="${log##*/}"; name="${name%.log}"
      [[ -f "$RUNS/$name.exit" || -n "${REPORTED[$name]:-}" ]] && continue
      REPORTED["$name"]=1
      echo "DEAD $name — no exit code and no live process (rate limit, auth, or dropped stream)"
    done
  fi

  sleep "$INTERVAL"
done
