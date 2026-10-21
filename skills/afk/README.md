# afk

**English** | [简体中文](README.zh-CN.md)

Keeps an agent working while you are away. Tell it how long you will be gone (8 hours by default). It decides small things on its own, does reversible work first and lets you rule on it later, and parks anything irreversible or outward-facing until you are back. A check-in every 30 minutes keeps it aligned with a ledger, and when you return it hands you one summary with every open decision.

## Usage

| You type | What happens |
|---|---|
| `/afk` | Starts an 8-hour afk. Typed again during one, it wraps up. |
| `/afk 1h` | Starts a 1-hour afk. Typed during one, it changes the deadline to one hour from now. |
| `/afk 2h only touch docs/` | A duration plus instructions. Other text during an afk is followed as an instruction. |
| "I'm back" | Wraps up: a summary, then every pending decision handed to you to rule on. |

Decisions fall into three tiers: **A** decide yourself, **B** do it in a reversible form and let the user rule later, **C** park. Everything is recorded in a ledger under `/tmp/afk-<uid>/`, so it survives a context compaction.

## How it works on each agent

The timed check-in is the part that differs, and the skill picks the right one:

- **Claude Code** uses `CronCreate`.
- **Codex** uses `scripts/ticker.sh` with `codex queue`. Codex's default sandbox blocks it, so the waker is started once with an elevation you approve before you leave.
- **Any agent inside tmux** can use `scripts/ticker.sh` with `tmux send-keys`.
- **Anything else** falls back to a self-driven loop that never ends its turn. The skill's table of delivery commands is where you add a recipe for another agent.

The session has to stay open: if it exits or the machine sleeps, check-ins stop.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill afk
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
