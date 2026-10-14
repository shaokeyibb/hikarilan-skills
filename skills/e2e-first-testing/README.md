# e2e-first-testing

**English** | [简体中文](README.zh-CN.md)

A testing methodology that puts end-to-end tests first, uses isolated tests only where they are needed (with every failure mode listed before the code is written), and uses few or no unit tests. Unit tests written by an LLM are mostly meaningless: there are huge numbers of them and they test nothing. Rather than having the LLM write more of them, it is far more effective to have it write end-to-end tests that start from the project's entry points and cover everything.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill e2e-first-testing
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
