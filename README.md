# hikarilan-skills

**English** | [简体中文](README.zh-CN.md)

A collection of agent skills for [Claude Code](https://claude.com/claude-code) and other coding agents that read the [Agent Skills](https://agentskills.io) format. Each skill stands on its own, so install only the ones you need.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills
```

This lists every skill in the repository and lets you choose which ones to install. To install a single skill:

```bash
npx skills add shaokeyibb/hikarilan-skills --skill structural-fix
```

Add `-g` to install for your user rather than for the current project.

## Skills

| Skill | What it does |
|---|---|
| [`capability-pruning`](skills/capability-pruning/SKILL.md) | Slims a project one capability at a time. It builds a full inventory, writes an evidence card for each capability, and has the owner decide every removal. |
| [`concurrent-worktrees`](skills/concurrent-worktrees/SKILL.md) | Runs several lines of work in parallel with git worktrees, then merges them back without losing anyone's changes. |
| [`e2e-first-testing`](skills/e2e-first-testing/SKILL.md) | Decides which tests to write, keep or delete. Its default is an end-to-end scenario through the production entry point, with test doubles only at external boundaries. Includes a coverage script for pruning legacy suites. |
| [`llm-agent-surface`](skills/llm-agent-surface/SKILL.md) | Sets out what an LLM sees inside an agent framework (tool schemas, prompts, rejection messages) and where the framework stops and the model decides. |
| [`matt-skills-on-openspec`](skills/matt-skills-on-openspec/SKILL.md) | Wires [Matt Pocock's engineering skills](https://github.com/mattpocock/skills) onto a repository whose work items are [OpenSpec](https://github.com/Fission-AI/OpenSpec) changes. |
| [`minimal-design-gate`](skills/minimal-design-gate/SKILL.md) | Checks for over-design twice: on the proposal before building, and on the delivery after. |
| [`repo-audit-loop`](skills/repo-audit-loop/SKILL.md) | Audits a whole repository, or a batch of finished work, in rounds until one finds nothing. It keeps a coverage ledger and a defect ledger throughout. |
| [`site-annotated-gates`](skills/site-annotated-gates/SKILL.md) | Enforces architectural rules with static checks. Each exception is annotated at its code site, and the check fails on stale annotations too. Includes a standard-library implementation. |
| [`structural-fix`](skills/structural-fix/SKILL.md) | Fixes a defect so that its whole class goes away, not just the instance that was reported. |

## License

[MIT](LICENSE)
