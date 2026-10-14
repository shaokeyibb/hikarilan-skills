---
name: llm-agent-surface
description: Design rules for what an LLM sees inside an agent framework — tool schemas, rejection messages, prompts — and for where the framework stops and the model decides. Use when building or changing an LLM agent, adding a tool or a schema field, writing a rejection or validation message, fixing a wrong model decision, or adding validation, retries or guards around model output.
---

# LLM agent surface

An agent framework has two jobs: put complete, accurate evidence in front of the model, and carry
out what the model decides within hard boundaries. Trouble starts when it drifts into a third
job — deciding in the model's place. Hidden heuristics that second-guess the model, schemas that
make it fill in what the framework already knows, and prompt lines patched in after each failure
all make the system harder to reason about and the model's output worse.

## Semantics belong to the model

Logic whose result affects control flow, a verdict or an identity — whether an assertion passes,
two states are equivalent, an action is safe, a response is valid — does not infer meaning from
natural language. No word lists, substring tests, word-overlap ratios or hard-coded code-point
ranges in those paths. Building natural language is a different matter: a word list inside a
prompt or a report is data; the same list driving an `if` is the defect.

Word lists can never be completed: after Chinese comes English, after "and" comes "as well as".
The failure is not that the list is incomplete, it is that the list is in the decision path at
all. The fixes, in order of preference:

1. **Give the evidence to the model.** If it already saw the evidence, a string rule overriding
   it adds no information.
2. **Move to an abstraction a specification defines** — Unicode categories instead of code-point
   ranges.
3. **Have the model declare it in structured output.** Information the model had when it decided
   (how two conditions combine, which time window it meant) belongs in a field, not in text the
   code later parses.

The four legitimate exceptions, and how to gate this mechanically, are in
[references/no-lexical-guessing.md](references/no-lexical-guessing.md).

## Measurements from the framework, choices from the model

What the framework can measure or derive deterministically — colours, geometry, counts,
thresholds, which frame is which — the framework supplies. The model chooses: whether to use a
mechanism, which mode, over what range. Vision and language models report exact values poorly,
and asking them to fill in measurable data lowers both accuracy and repeatability.

Map deterministically wherever the input allows it: when the model names a visible label, the
framework resolves it to the underlying value by exact match, and rejects with the candidate list
only when the match is ambiguous or empty.

## Keep the model-side surface lean

Every field, required item, enum value, few-shot example and policy paragraph costs the model
reasoning on every call. Schemas that keep growing reach a point where the model can no longer
produce a valid output at all.

- Before adding anything the model must fill in, ask whether the framework can derive it or
  default it — a conjunction by default, a nested tree rather than a post-order list,
  structured feedback rather than long prose.
- Anything the framework can settle itself (bookkeeping, absences, control outcomes) stays out of
  the model's output.
- The schema grows only with evidence that it must, and is audited periodically for fields to
  remove.
- Leave out what the model can already see. In a continuous conversation the model has every
  previous turn; a derived counter such as "rounds without progress" repeats it. When a model
  with the full history still loops, look for a tool result that misleads it before adding a
  hint.

## Rejections state the rule

When a parameter, schema or boundary check rejects model output, the reason names the violated
rule — which field, under what condition, must be what. It does not guess what the model meant
or suggest which other tool to use; that is the framework making the model's decision. Tests
assert the framework's behaviour (rejected, not dispatched, reason returned to the model) and
script the model's retry as any valid answer, never as one specific reaction.

## Assume the model's output is right

The framework settles the model's conclusion as the model gave it. It does not add branches that
guess the model was wrong and then downgrade, overrule or quietly release the result: the
framework has no better information than the model had, and every such branch hides a real
problem behind an outcome that looks plausible. Recomputing a structural fact the model reported,
or folding results by a quantifier the model declared, is verification, not rewriting.

What is allowed is improving the output: better input and evidence, better knowledge, contracts
and boundary validation the model can see, and explicit mechanisms the model invokes itself (such
as asking to re-plan). When existing code second-guesses the model, list those branches and remove
them.

## Prompt changes from a single failure

A failure in one run invites a prompt line about that run. Before adding it, remove the concrete
instance from the sentence: is what remains still a general rule, and does it avoid listing
element categories ("don't judge by a badge or a summary marker")? A category list is a word list
in disguise, and it often forbids evidence that is legitimate elsewhere. State the structural
criterion instead (for example, "the result appears before or after this step's starting point").
Replay the failing case and unrelated cases before and after the change; if the abstract wording
pushes the model into a different mistake, sharpen the criterion rather than adding a ban.

When a single phenomenon suggests a new framework branch, first ask whether the input demanded
something nothing guaranteed. Often the case or the input should change, not the framework.

Design around general facts — the action that was actually dispatched — rather than any named
tool, key or screen element. A special path for one capability breaks on the next platform.

## Soft guidance, hard boundaries

Intent is expressed in bounded natural language (guidance the model reads); authorisation is
expressed in typed metadata (a risk level on the tool's registration). They do not stand in for
each other: guidance shapes the choice between actions that are already allowed and never
widens a boundary, and the boundary is decided at registration without reading any prose.

- A tool is high-risk only when no lower-risk path reaches the same effect. If `press_home` and
  `press_key("home")` land on the same device call, blocking one name blocks nothing; put the
  protection on the state it guards instead.
- Admission applies unconditionally. A switch that turns it off for some callers becomes the
  default for every new caller that forgets it.

## Retries

Use the agent library's own validation-and-retry layer, once. When it is exhausted, that is one
invalid call, and the layer above does not reopen the request for the same class of error —
stacked retries multiply into identical failures. Put constraints into the schema the model
receives, so it sees them before answering instead of learning them from rejections.

## Done

No decision path reads meaning from natural-language text; measurable data comes from the
framework; every new model-side field has a reason the framework cannot derive it; rejections
name only the violated rule; no branch second-guesses a model conclusion; prompt changes survived
the instance-removal check and a before/after replay; risk is typed metadata with unconditional
admission; there is one retry layer.
