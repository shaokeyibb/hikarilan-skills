# hikarilan-skills

**English** | [简体中文](README.zh-CN.md)

Agent skills for [Claude Code](https://claude.com/claude-code), distilled from long, multi-agent development sessions — each one is the discipline that stopped a recurring failure from coming back.

Most of them push against the same drift: a codebase that keeps growing entities nobody needs, tests and gates that measure the wrong thing, fixes that patch an instance and leave the class alive. The remedies are deliberately structural — rules a reviewer can check, ledgers that can be reconciled, gates that fail in both directions — rather than reminders to be careful.

## Install

```bash
npx skills add shaokeyibb/hikarilan-skills
```

This reads every skill in the repository and lets you pick some or all of them.

To install one directly:

```bash
npx skills add shaokeyibb/hikarilan-skills --skill e2e-first-testing
```

## Skills

### Keeping the codebase lean

#### `minimal-design-gate`

A gate against over-design, run on the proposal and again on the delivery.

- Five questions before proposing — structural? new burden on callers? determinable by the system itself? gratuitous? overfitted? — and a minimal-first statement of why nothing simpler works
- A delivery checklist: single-caller abstractions, two paths behind one flag, the same rule enforced twice, fallbacks for unobserved scenarios, config nobody reads, compatibility shims, product code that only a test harness uses
- Net line change on every delivery, and no "no over-design" verdict on anything not read in full

#### `capability-pruning`

Slim a project by capability, with the owner deciding each removal.

- A full inventory from specs and public entry points, never a top-N by some metric
- One evidence card per capability — purpose, origin, size, real use, main-path necessity — asked in batches with a recommendation
- "Never used" only with the full search scope written down; removals deleted top-down until a repository-wide search for the name comes back empty

#### `structural-fix`

Fix a defect so its whole class disappears, not just the reported instance.

- Name the class and the rule it violates, then sweep the whole tree for every site and fix them in one change
- Look at the data structure first: when two kinds of data share one structure, split it rather than filter it
- Fix the input, not the output; no special cases keyed on a name, kind or text; choose the failure direction explicitly; retire capabilities all the way down

### Tests, gates and audits

#### `e2e-first-testing`

Which tests to write, keep or delete.

- End-to-end scenarios through production entry points as the default, finishing with a reproducible run directory and normalised result manifest
- Test doubles only at external boundaries, each behind one registered injection seam; isolated tests only with their failure modes written before the code
- Tautological and change-detector tests deleted on sight; regression tests only for a real behavioural gap; legacy suites pruned by per-test coverage, with a bundled script for coverage.py

#### `site-annotated-gates`

Enforce architectural rules with static gates whose exceptions live at the code site.

- Structural rules as AST-based lint-stage checks, criteria derived from production definitions, not tests that read source
- Exceptions annotated in place — `# gate-<rule>: <category> — <reason>` — with a closed set of categories and a mandatory reason
- A ratchet that fails on stale annotations as well as unannotated sites, with a bundled standard-library implementation and an example rule

#### `repo-audit-loop`

Audit a repository, or a batch of finished work, until a round finds nothing.

- A coverage ledger reconciled to 100% of `git ls-files`, and a defect ledger that takes every unfixed defect the moment a report mentions it
- Orthogonal lenses: a full quality dimension list, spec–code sync classified requirement by requirement, every public entry actually run, and the gate's blind spots
- Confirmed findings fixed by whoever found them, plausible ones sent to a refuter first; acceptance runs in parallel instead of waiting for the audit to reach zero

### Building LLM agents

#### `llm-agent-surface`

Where an agent framework stops and the model decides.

- Semantics belong to the model: no word lists or substring tests in decision paths, with four precise exceptions and how to gate them
- Measurements from the framework, choices from the model; a lean model-side schema that never repeats what the model can already see
- Rejections that state only the violated rule, no branches that second-guess the model, prompt changes that survive removing the instance, typed hard boundaries, one retry layer

### Parallel work and tooling

#### `concurrent-worktrees`

Run several lines of work in parallel with git worktrees, and merge them back without losing anyone's changes.

- What a worktree actually buys, what it costs (a tree has no environment), and the batching rule that follows
- The orchestrator pattern: who creates trees, who merges, and why destructive git is never delegated
- Uncommitted work is not storage; pin a base SHA rather than a branch name; judge parallelism by the shared gate rather than by file overlap

#### `matt-skills-on-openspec`

Wire [Matt Pocock's engineering skills](https://github.com/mattpocock/skills) onto a repository whose work items are [OpenSpec](https://github.com/Fission-AI/OpenSpec) changes.

- Which skill maps to which change artifact or `/opsx` command, section by section — and each section applies only if you installed that skill
- The template conflicts worth knowing about: splitting a spec across three artifacts, carrying blocking edges in a flat checklist
- The nine skills that need no wiring at all

## License

[MIT](LICENSE)
