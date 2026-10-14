# matt-skills-on-openspec

**English** | [简体中文](README.zh-CN.md)

Wiring [Matt Pocock's engineering skills](https://github.com/mattpocock/skills) onto an [OpenSpec](https://github.com/Fission-AI/OpenSpec) workflow. By default these skills write work items to GitHub issues or local markdown, which bypasses OpenSpec in a repository whose work items are OpenSpec changes. This skill goes through them one by one — to-spec, to-tickets, wayfinder, triage and the rest — saying which change artifact or `/opsx` command each one's output belongs to, which need no wiring at all, and how to check that the wiring actually works.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill matt-skills-on-openspec
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
