---
name: concurrent-worktrees
description: Run several lines of work in parallel using git worktrees — when a tree is worth creating, how to split roles between an orchestrator and its agents, and how to merge back without losing anyone's changes. Use when work will run alongside other sessions or agents, when spawning agents into worktrees, or when merging a worktree branch back to the trunk.
---

# Concurrent Worktrees

Parallel work needs physical isolation, because one shared working tree fails two ways at once:

- **Mutual arrest** — a pre-commit gate inspects the whole tree, so a neighbour's half-finished edit fails *your* commit even with zero file overlap between you.
- **Mutual destruction** — anyone who wants a clean tree runs `clean` or `restore`, and uncommitted work belonging to someone else disappears.

A worktree answers both: its own checkout on disk, sharing one object store. Every branch, commit, and ref is visible from every tree; only the files on disk are private. That is the whole trade — and it's why a **commit** is the unit that crosses between trees, while an uncommitted edit is stranded in the tree that holds it.

## When a tree is worth creating

**Default to a worktree for any change you won't commit within minutes.** The exception is a single-point fix committed immediately; spinning up a tree for that costs more than it saves.

Price the cost honestly: a fresh checkout has **no environment**. Dependencies, virtualenvs, build outputs — none of it comes along, and installing it is most of the setup time. That cost is per *tree*, not per change, which settles how to batch: **group changes by file neighbourhood, one tree per neighbourhood**, with changes that touch the same files done sequentially inside it. One tree per change is the beginner's mistake; it multiplies setup and merge cost for nothing.

## The orchestrator pattern

One session owns the trunk and coordinates. Every other line of work happens inside its own tree.

- **The orchestrator creates the trees**, not the agents. It chooses the base commit, prepares the environment, and hands over an absolute path. An agent that creates its own tree will get the base wrong (see below).
- **Every command an agent runs names its tree explicitly** — `git -C <absolute path>`, absolute paths for file writes. A bare command is a bug waiting for the moment the shell's location isn't what anyone assumed.
- **Destructive git stays with the orchestrator.** `reset --hard`, `checkout --`, `clean`, `stash drop` are never delegated — see the next section for why the delegated case is worse than it looks.
- **The orchestrator merges, one tree at a time.** Serial merging is what makes conflicts tractable: each branch rebases onto a trunk that isn't moving underneath it. Rebasing rather than merging also keeps the history linear, so parallel work reads afterwards as if it had been done in sequence.
- **Authority lives on the trunk.** A green result inside a worktree is a smoke signal; the gate re-run after merging is the verdict.

## Destructive git, and why delegation makes it worse

Worktrees get torn down while an agent is still running, and a shell whose location vanishes **falls back silently** to the trunk. A command approved for a worktree then lands on the shared tree instead — a `reset --hard` aimed at a branch nobody minds, wiping the trunk's uncommitted work instead.

So the orchestrator runs these itself, `-C <absolute path>` pinned, after reading that tree's `git status`. And while uncommitted work sits in the shared tree, that tree is **hot**: approve no mutating git from anyone until it's committed.

## Uncommitted work is not storage

The shared tree is not yours, even when you're the only one who meant to touch it. Another session wanting a clean tree runs `git clean -fd`; your uncommitted edits and untracked directories go with it, no message, `git status` clean afterwards.

Anything worth keeping becomes **a real commit on a branch** — commits live in the object store and the reflog, where a clean can't reach them. A patch written outside the repository is the minimum. "I'll commit it once it's verified" is how work gets lost.

## Start the tree at the right commit

Worktree tooling commonly branches from the *remote* default branch rather than local HEAD — silently, and regardless of what local configuration appears to say. The tree then lacks every unpushed commit, and uncommitted planning artifacts never arrive at all.

Immediately after creating one, run `git rev-parse HEAD` and confirm the commit. If the tree is clean and your target is a descendant, reset onto it and confirm again.

## Results from a worktree don't transfer

A fresh worktree rarely has the environment the trunk has, and the failure mode is a confident wrong answer rather than an error:

- An empty virtual environment resolves the package from the trunk installation — you test code you didn't change. The symptom is diagnostic: *edits to the test change the outcome, edits to the production code don't.*
- An editable install pointing at the trunk makes a type checker see one module at two physical paths, emitting batches of phantom errors. Phantom errors don't merely annoy; they **bury the real ones**.
- A formatter or linter resolved outside the lockfile reformats differently than the trunk will.

Whatever an agent couldn't get running in its tree, run yourself after merging — formatting and line-ending checks included.

## Pin the base, never the branch name

`git diff <branch>` drifts, because concurrent merges move the branch ref underneath you, and reviewing against a moving ref invents phantom changes — whole files appearing deleted. **Diff against a pinned commit SHA**, for the whole life of a review.

## Merging back, in four steps

1. **Re-read the scene**: `git log --oneline -1` and `git status --short`. A HEAD you learned an hour ago is stale.
2. **Yield to others' uncommitted work.** Changes in the tree that aren't yours stay untouched — no stash, no `add -A`. Wait for them to be committed, or stop and ask.
3. **Stage your paths explicitly**, one at a time. A blanket `git add -A` sweeps in whoever is mid-edit.
4. **Audit the staged set** with `git diff --cached --stat` before committing. Every path should be one you named.

Resolve conflicts additively when both sides append to a shared list — keep both. When two sides changed the same function, or the resolution needs a semantic judgement, stop and ask rather than guess.

## Judge parallelism by the gate, not the files

Deciding whether two changes can share a tree: they collide when they **share a gate**, not when they share files. A pre-commit hook inspects the entire working tree, so a neighbour's half-finished work fails your commit with no file overlap at all — and a hook failure caused by a neighbour is a reason to wait for them, never a reason to bypass the hook.
