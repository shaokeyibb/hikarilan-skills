#!/usr/bin/env bash
# Relay: resume a finished Codex session with a follow-up brief, keeping its context.
#
#   relay.sh --from <sentinel> --name <new sentinel> --worktree <path> --brief <file>
#
# Use when a read-only reviewer has finished and its findings are the follow-up work.
# It already holds the whole branch in context; a fresh run would re-read all of it.
set -euo pipefail

FROM=""; NAME=""; WORKTREE=""; BRIEF=""; MODEL="${CODEX_MODEL:-gpt-5-codex}"; EFFORT="medium"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)     FROM="$2";     shift 2 ;;
    --name)     NAME="$2";     shift 2 ;;
    --worktree) WORKTREE="$2"; shift 2 ;;
    --brief)    BRIEF="$2";    shift 2 ;;
    --model)    MODEL="$2";    shift 2 ;;
    --effort)   EFFORT="$2";   shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$FROM" && -n "$NAME" && -n "$WORKTREE" && -n "$BRIEF" ]] || {
  echo "usage: relay.sh --from <sentinel> --name <sentinel> --worktree <path> --brief <file>" >&2; exit 2; }

WORKTREE="$(cd "$WORKTREE" && pwd)"
BRIEF="$(cd "$(dirname "$BRIEF")" && pwd)/$(basename "$BRIEF")"
RUNS="${CODEX_RUNS:-$(git -C "$WORKTREE" rev-parse --git-common-dir)/../.codex-runs}"
RUNS="$(cd "$RUNS" && pwd)"
FROM_LOG="$RUNS/$FROM.log"
[[ -f "$FROM_LOG" && -f "$BRIEF" ]] || { echo "missing $FROM_LOG or $BRIEF" >&2; exit 2; }

# Codex prints its own session id into the transcript. Failing to find it must stop the
# run: silently starting a fresh session would be indistinguishable, from the outside,
# from a successful relay — while carrying none of the context that justified relaying.
SID="$(grep -oiE 'session id:[[:space:]]*[0-9a-f-]{36}' "$FROM_LOG" | head -1 | grep -oiE '[0-9a-f-]{36}')"
[[ -n "$SID" ]] || { echo "no session id found in $FROM_LOG" >&2; exit 1; }

RESOLVED_RAW="$(git -C "$WORKTREE" rev-parse --show-toplevel 2>/dev/null || true)"
# Same normalisation as dispatch.sh — see the note there.
RESOLVED_TOP="$([[ -n "$RESOLVED_RAW" ]] && cd "$RESOLVED_RAW" 2>/dev/null && pwd || true)"
[[ -n "$RESOLVED_TOP" && "$RESOLVED_TOP" == "$WORKTREE" ]] || {
  echo "preflight FAILED: '$WORKTREE' resolves to '$RESOLVED_RAW'" >&2; exit 1; }
echo "preflight ok: $WORKTREE (relay $SID from $FROM)"

LOG="$RUNS/$NAME.log"; OUT="$RUNS/$NAME.out"; EXIT="$RUNS/$NAME.exit"
rm -f "$EXIT" "$OUT"
git -C "$WORKTREE" status --porcelain --ignored > "$RUNS/$NAME.before"

# `codex exec resume` carries the session's own cwd and rejects -C, so enter the tree.
nohup bash -c "
  cd '$WORKTREE'
  codex exec resume '$SID' -m '$MODEL' -c model_reasoning_effort='\"$EFFORT\"' \
    --dangerously-bypass-approvals-and-sandbox -o '$OUT' - < '$BRIEF' > '$LOG' 2>&1
  echo \$? > '$EXIT'
" >/dev/null 2>&1 &

echo "$NAME PID=$! worktree=$(basename "$WORKTREE") relayed=$SID"
