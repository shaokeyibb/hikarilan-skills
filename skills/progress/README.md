# progress

**English** | [简体中文](README.zh-CN.md)

One command makes the agent report where the work stands, in the same table every time: what it is doing now, what comes next, what is not done, what is done, how long is left, and how far along it is. The report reads the real state (task list, ledger, `git`, background jobs) instead of relying on memory, estimates time only from something measurable, and starts, finishes or changes nothing while it reports.

## Usage

| You type | What you get |
|---|---|
| `/progress` | The standard report: a table of work items with a status for each (doing, next, not done, done), then a row of time left and progress. |
| `/progress any risks?` | The standard report, plus a question-and-answer table for whatever else you asked. |

Anything you pass is an extra question to answer in addition to the report. A request to act (fix, run, continue) is not answered inside the report; the agent says so and offers.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills --skill progress
```

Add `-g` to install for your user rather than for the current project.

The full skill is in [SKILL.md](SKILL.md); the rest of the collection is listed in the [repository README](../../README.md).
