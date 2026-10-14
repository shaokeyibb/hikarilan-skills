# concurrent-worktrees

**English** | [简体中文](README.zh-CN.md)

Using git worktrees when several agents work in parallel. When agents share one working tree, a neighbour's half-finished file fails your pre-commit hook, and one `git clean` from someone else wipes out your uncommitted changes. This skill covers when a worktree is worth creating, batching by file neighbourhood, having one orchestrator create the trees and merge them, why destructive git is never delegated, and how to merge back to the trunk without losing anyone's changes.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill concurrent-worktrees
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
