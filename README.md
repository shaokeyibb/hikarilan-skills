# hikarilan-skills

**English** | [简体中文](README.zh-CN.md)

Agent skills for [Claude Code](https://claude.com/claude-code), distilled from things that actually went wrong during long, multi-agent development sessions.

Five of the six share one property: **every failure they address points toward "looks successful."** A green test suite, a confident agent report, a clean `git status`, an audit that reads as thorough — none of them raise an error. Problems that raise errors don't need discipline; they surface on their own. These don't.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills
```

This reads every skill in the repository and lets you pick some or all of them.

To install one directly:

```bash
npx skills add shaokeyibb/hikarilan-skills --skill false-green
```

## Skills

### `false-green`

Build checks whose green can be trusted, and prove one before reporting it.

- Three properties a check needs before its green means anything — failure observable through the path you actually run, a distinct **not verified** outcome that never shares an exit code with *passed*, and one definition invoked by every entry point
- The known shapes that silently invert a red into a green: pipes eating exit codes, absence read as zero, vacuously-true aggregates, truncated searches, and code under test resolved from outside your tree
- How to tell whether a test locks what it claims — mutate the exact semantic, not the feature switch

### `delegating-to-agents`

Decide what to hand to a subagent, structure the brief so its constraints hold, and self-check what comes back.

- One test for delegability: **can the result be verified without redoing the work?**
- Three behaviours no wording can buy — read-only, waiting on a background job, staying inside a directory — and the structural substitute for each
- Why a prohibition without an alternative gets routed around, and what to verify before an agent's report becomes evidence

### `concurrent-worktrees`

Run several lines of work in parallel with git worktrees, and merge them back without losing anyone's changes.

- What a worktree actually buys, what it costs (a tree has no environment), and the batching rule that follows
- The orchestrator pattern: who creates trees, who merges, and why destructive git is never delegated
- Uncommitted work is not storage; pin a base SHA rather than a branch name; judge parallelism by the shared gate rather than by file overlap

### `batch-closeout`

Close out a batch of finished work before it reaches acceptance.

- A batch is work sharing **one acceptance signal** — and one deferred defect contaminates that signal for everything in it
- The defect ledger: entries the moment a report mentions them, cleared before acceptance, with whatever remains written down as bounded debt
- A multi-lens final audit whose lenses must fail *differently*, plus adversarial confirmation before anything gets fixed

### `codex-delegation`

Run the Codex CLI as a detached background worker on a git worktree — dispatch, watch, relay, and prove what it claims.

- A **sentinel quartet** on disk (`.log` / `.out` / `.before` / `.exit`) so a run's state is answerable without asking the agent — plus the check that catches a run which died *without* writing its exit code, where anything waiting on that file waits forever
- **Relay** a finished read-only reviewer into fixing what it found, keeping its context, under one invariant: the run that changed the code is never the run that approves it
- Why a passing suite proves nothing about a lock just written, and the two sharper demands — **independence** (`1 failed, N-1 passed`) and **reachability** (assertion sites, because red count is not lock count)

### `matt-skills-on-openspec`

Wire [Matt Pocock's engineering skills](https://github.com/mattpocock/skills) onto a repository whose work items are [OpenSpec](https://github.com/Fission-AI/OpenSpec) changes.

- Which skill maps to which change artifact or `/opsx` command, section by section — and each section applies only if you installed that skill
- The template conflicts worth knowing about: splitting a spec across three artifacts, carrying blocking edges in a flat checklist
- The nine skills that need no wiring at all

## License

[MIT](LICENSE)
