---
name: matt-skills-on-openspec
description: Wire Matt Pocock's engineering skills onto a repo whose work items are OpenSpec changes — which skill maps to which change artifact or /opsx command, and which need no wiring at all. Use when installing or running to-spec, to-tickets, triage, wayfinder, implement, research, domain-modeling, or code-review in an OpenSpec repo.
---

# Matt Skills on OpenSpec

The engineering skills carry a **method** — how to slice work, how to advance through fog. OpenSpec is the **carrier** — where the result lives as `proposal.md`, a spec delta, `tasks.md`, and an archive entry. Keep the method; redirect its output onto the carrier.

Only `setup-matt-pocock-skills` is a prerequisite. **Every other skill is an optional install, so each section below applies only if you have that skill** — skip the rest.

## First, the gate: does this need a change?

OpenSpec is for work that alters the meaning of a SHALL/MUST clause. A typo, a pure refactor, a bug fix that leaves every clause intact — do it and commit it, no change.

This gate runs *before* any skill's output reaches the carrier. A skill handing you a plan does not oblige you to open a change for it.

## Setup

Run `/setup-matt-pocock-skills` once. Two answers matter:

**Issue tracker → "Other".** Not GitHub, not local markdown. Describe the OpenSpec workflow: work items are `openspec/changes/<kebab-name>/`, opened with `/opsx:propose`, closed with `/opsx:archive`; the issue body is `proposal.md`, the spec is `specs/<capability>/spec.md`, the checklist is `tasks.md`; state comes from `openspec status --change "<name>" --json`, never from a `Status:` line.

**Domain docs → single-context, plus one thing the template doesn't know about.** Besides `CONTEXT.md` and `docs/adr/`, the repo has `openspec/specs/` — the live capability specs. Write that into `docs/agents/domain.md`, or skills will explore the codebase without reading the specs that govern what they're about to change.

Setup then writes an `## Agent skills` block into `CLAUDE.md` or `AGENTS.md`, whichever exists, CLAUDE.md winning. **Confirm it landed in the file your harness loads at session start.** If it wrote `AGENTS.md` and the harness only loads `CLAUDE.md`, no skill ever sees the pointer — and each falls back to its own default, which for `/wayfinder` is explicitly local markdown, bypassing OpenSpec entirely. A `CLAUDE.md` containing `@AGENTS.md` fixes it.

## `/wayfinder` — the stage before a change has a shape

Use it when the destination is too big for one session and not yet knowable. `/opsx:propose` assumes you already know what to build; wayfinder is what runs before that.

One effort is one change. Put the map and its decision tickets in `openspec/changes/<effort>/wayfinding/` — deliberately clear of the artifact names OpenSpec generates (`proposal`, `design`, `tasks`, `specs`), so `/opsx:*` and wayfinder don't overwrite each other.

- **Map** → `wayfinding/map.md`, holding Destination / Notes / Decisions-so-far / Not yet specified / Out of scope. `proposal.md` carries only a destination summary and a link.
- **Tickets** → `wayfinding/NN-<slug>.md` from `01`, with `Type:` and `Status:` lines at the top.
- **Blocking** → a `Blocked by: NN, NN` line; unblocked when every listed file is resolved.
- **Frontier** → the unresolved, unclaimed, unblocked files, lowest number first.

When the map empties, run `/to-spec` to converge the decisions into `proposal.md` and `specs/`. `wayfinding/` archives with the change as decision provenance.

## `/to-spec` — split the template across three artifacts

OpenSpec already decomposes a spec, so don't paste the whole to-spec template into `proposal.md`:

| to-spec section | goes to |
| --- | --- |
| Problem Statement / Solution / Out of Scope | `proposal.md` |
| User Stories | `specs/<capability>/spec.md`, rewritten as SHALL/MUST clauses |
| Implementation Decisions / Testing Decisions | `design.md` |
| Further Notes | into whichever of the three fits |

User stories are requirements in spoken form; spec clauses are requirements in checkable form. One story often becomes several clauses — don't force a one-to-one transcription.

The skill ends by telling you to apply a `ready-for-agent` label. See `/triage` below: usually you skip it.

## `/to-tickets` — N tickets become N tasks, not N changes

Tickets land as entries in one change's `tasks.md`. Only split into a separate change when the scope is genuinely independent and archivable on its own.

`tasks.md` is a flat checklist with no native blocking, so use its numbering:

```markdown
## 2. Core predicate

- [ ] 2.1 <task>
- [ ] 2.3 <task> (blocked by 1.2, 2.1)
```

Section order should already be dependency order, so most tasks need no annotation — mark only genuine cross-section dependencies.

Keep the method intact: **OpenSpec says nothing about how to slice**, so the tracer-bullet discipline is the whole reason to run this skill. Vertical slices, each independently verifiable. The wide-refactor exception applies unchanged — expand as its own section, migrate in blast-radius batches, contract last.

Its closing line says to work the frontier with `/implement`. Use `/opsx:apply` instead.

## `/implement` — superseded by `/opsx:apply`

Installed or not, you won't use it here. Its content — use TDD, typecheck, run tests, review, commit — is what `/opsx:apply` plus the repo's own gates and commit discipline already do, and `/opsx:apply` additionally drives `tasks.md` checkbox by checkbox. Running both gives you two implementation entry points for one checklist.

## `/triage` — usually nothing to do

Changes have no labels. The five canonical roles live as a `triage:` key in `openspec/changes/<name>/.openspec.yaml`, alongside `category:`. Both are custom keys; `openspec validate` and `openspec status --json` accept them and don't interpret them.

But a change opened by `/opsx:propose` is a ticket you wrote yourself — spec finalised means ready to implement, with no assessment stage in between. **Most changes carry no `triage:` key, and that is the expected state, not an oversight.** Only two cases earn one: a raw problem nobody has decided on yet, and anything explicitly `ready-for-human` (needs a person, hardware, or an external dependency, so no unattended agent should grab it).

Archiving is closing — archived changes leave the triage queue. Query by file scan: `grep -l 'triage: ready-for-agent' openspec/changes/*/.openspec.yaml`.

## `/research` — notes are not work items

Research notes go wherever the repo already keeps documentation, **not** into a change directory — they aren't work items and they don't archive on a change's schedule. Reference the note's path from the change.

If the finding is a trade-off that shouldn't be casually reversed, that's an ADR, and the note becomes its evidence attachment.

## `/domain-modeling` — three sources, three questions

Keep the boundaries sharp, because all three describe the project and it's tempting to merge them:

- `CONTEXT.md` — what a term means
- `docs/adr/` — why it's locked this way, and at what cost; deliberately not casually reversible
- `openspec/specs/` — what the contract currently is; amended by the next change as a matter of course

New terms and new decisions land in the first two. Don't write them into a spec delta, and don't copy spec clauses into an ADR.

## `/code-review` — the Spec axis finally has a spec

Most repos give this skill nothing concrete for its Spec axis. Here, review against **this change's** `specs/` delta and `proposal.md`, not a vague sense of the requirement.

Keep the reviewing agent read-only. Given write tools it will fix things it noticed in passing, and report that it changed nothing.

## `/prototype` — throwaway, except the decision

Prototypes don't live in the change directory. When one produces a snippet that pins a decision more precisely than prose can — a state machine, a schema, a type shape — inline the decision-bearing part into `design.md` and note it came from a prototype.

## `/diagnosing-bugs` — usually ends without a change

Most diagnoses end in a fix, and a fix that leaves every clause intact doesn't get a change (see the gate above). Propose one only when the repair changes what a SHALL/MUST means.

## Skills needing no wiring

`/grilling`, `/tdd`, `/codebase-design`, `/improve-codebase-architecture`, `/resolving-merge-conflicts`, `/handoff`, `/teach`, `/find-skills`, `/writing-great-skills` produce no work items and never touch the tracker. Install and use them as-is.

## Proving the wiring conducts

Configuration written is not behaviour changed.

- **Is the pointer resident?** Only checkable in a session that started *after* you wrote it — context is fixed at session start.
- **Does an invocation land correctly?** Run `/to-spec` or `/to-tickets` for real and look at where the output went: `openspec/changes/` means it conducts, `.scratch/` means it never saw the pointer. This is the only check that proves the whole chain.

These skills are external and get updated while your adapter file is hand-written, with nothing verifying they still agree. A renamed command or restructured template leaves the adapter pointing somewhere plausible — silently.
