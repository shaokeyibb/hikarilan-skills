# structural-fix

**English** | [简体中文](README.zh-CN.md)

Systematic, structural code design for both feature work and bug fixes. When proposing a feature or a fix, first ask whether the same pattern appears elsewhere in the repository or in its upstream and downstream dependencies, and change all of them together rather than touching a single facet. Avoid covering a problem up with a fallback; work from the bottom up to see whether there is a better solution.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill structural-fix
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
