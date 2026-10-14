# repo-audit-loop

**English** | [简体中文](README.zh-CN.md)

Auditing a repository in rounds. An LLM audit easily samples a third of the code and reports that it "reviewed the codebase", and defects mentioned in passing in a report often go unfixed. This skill reconciles a coverage ledger to 100% of the scope, catches every unfixed problem in a defect ledger, and runs non-overlapping lenses in parallel: code quality, spec–code sync, running every public entry point, and the gate's blind spots. Whoever finds a problem fixes it, and the rounds continue until one finds nothing.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill repo-audit-loop
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
