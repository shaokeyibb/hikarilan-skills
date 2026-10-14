# capability-pruning

**English** | [简体中文](README.zh-CN.md)

Slimming a project one capability at a time. Long-lived projects collect capabilities nobody uses any more, some of which even the owner has forgotten. An LLM hunting for dead code by technical symptoms finds only a few of them, and it is quick to claim something was "never used" without checking. So this skill inventories every capability from the specs and public entry points, writes an evidence card for each (purpose, origin, size, real use), and has the owner decide them in batches. Approved removals are deleted top-down in one go.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill capability-pruning
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
