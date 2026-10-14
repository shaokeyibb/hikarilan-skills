# site-annotated-gates

**English** | [简体中文](README.zh-CN.md)

Static gates for architectural rules. LLMs like to "lock" architecture with tests that read source code and assert its structure, which then fail on ordinary refactors; and a central exemption list grows until nobody remembers why each entry is there. This skill turns architectural rules into AST checks in the lint stage and writes each exception at its code site as `# gate-<rule>: <category> — <reason>`. Unannotated sites and stale annotations both fail. A standard-library implementation is included.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill site-annotated-gates
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
