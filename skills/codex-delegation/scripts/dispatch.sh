#!/usr/bin/env bash
# Dispatch a Codex CLI run against a git worktree, detached, writing a sentinel quartet.
#
#   dispatch.sh --name <sentinel> --worktree <path> --brief <file> [--model M] [--effort E]
#
# Writes into $CODEX_RUNS (default: .codex-runs/ under the repo root):
#   <name>.log     full transcript      <name>.out     final message
#   <name>.exit    exit code, written last — its existence means "finished"
#   <name>.before  git status snapshot taken before dispatch
#
# The brief goes in on stdin so multi-line quoting never has to survive a shell.
set -euo pipefail

NAME=""; WORKTREE=""; BRIEF=""; MODEL="${CODEX_MODEL:-gpt-5-codex}"; EFFORT="medium"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)     NAME="$2";     shift 2 ;;
    --worktree) WORKTREE="$2"; shift 2 ;;
    --brief)    BRIEF="$2";    shift 2 ;;
    --model)    MODEL="$2";    shift 2 ;;
    --effort)   EFFORT="$2";   shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$NAME" && -n "$WORKTREE" && -n "$BRIEF" ]] || {
  echo "usage: dispatch.sh --name <sentinel> --worktree <path> --brief <file>" >&2; exit 2; }

WORKTREE="$(cd "$WORKTREE" && pwd)"
BRIEF="$(cd "$(dirname "$BRIEF")" && pwd)/$(basename "$BRIEF")"
[[ -f "$BRIEF" ]] || { echo "brief not found: $BRIEF" >&2; exit 2; }

# Preflight: a half-removed worktree keeps its files but loses its .git pointer, so git
# walks up and resolves it to the MAIN repository. Dispatching there edits the trunk.
# Test-Path style existence checks cannot see this — only git's own resolution can.
RESOLVED_RAW="$(git -C "$WORKTREE" rev-parse --show-toplevel 2>/dev/null || true)"
RESOLVED_REF="$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
# Normalise both sides through the same `cd && pwd`: git reports Windows-style paths under
# Git Bash while pwd reports POSIX ones, and a raw string compare rejects every valid tree.
RESOLVED_TOP="$([[ -n "$RESOLVED_RAW" ]] && cd "$RESOLVED_RAW" 2>/dev/null && pwd || true)"
if [[ -z "$RESOLVED_TOP" || "$RESOLVED_TOP" != "$WORKTREE" ]]; then
  echo "preflight FAILED: '$WORKTREE' resolves to '$RESOLVED_TOP' (branch '$RESOLVED_REF')." >&2
  echo "That directory is probably a half-removed worktree; dispatching would edit the main repo." >&2
  exit 1
fi
echo "preflight ok: $WORKTREE -> $RESOLVED_REF"

RUNS="${CODEX_RUNS:-$(git -C "$WORKTREE" rev-parse --git-common-dir)/../.codex-runs}"
RUNS="$(mkdir -p "$RUNS" && cd "$RUNS" && pwd)"
LOG="$RUNS/$NAME.log"; OUT="$RUNS/$NAME.out"; EXIT="$RUNS/$NAME.exit"
rm -f "$EXIT" "$OUT"

# --ignored is required: plain --porcelain hides ignored paths, so a run that wrote
# 100MB of node_modules shows a clean tree and the snapshot proves nothing.
git -C "$WORKTREE" status --porcelain --ignored > "$RUNS/$NAME.before"

nohup bash -c "
  cd '$WORKTREE'
  codex exec -m '$MODEL' -c model_reasoning_effort='\"$EFFORT\"' \
    --dangerously-bypass-approvals-and-sandbox -o '$OUT' - < '$BRIEF' > '$LOG' 2>&1
  echo \$? > '$EXIT'
" >/dev/null 2>&1 &

echo "$NAME PID=$! worktree=$(basename "$WORKTREE") model=$MODEL effort=$EFFORT"
