---
name: site-annotated-gates
description: Enforce architectural and code-shape rules with static gates whose exceptions are annotated at the code site. Use when adding a lint or CI check for an architectural constraint, when a test is about to lock code structure, when an allowlist or exemption list keeps growing, or when a rule needs justified exceptions.
---

# Site-annotated gates

Architectural rules — layering, import boundaries, banned patterns, dead code, type-suppression
budgets, bounds on growing collections — need enforcement, or they erode one reasonable
exception at a time. They also need exceptions, and that is where most enforcement rots: a
central allowlist grows, nobody remembers why each entry is there, and entries outlive the code
they excused. A site-annotated gate keeps both the rule and its exceptions honest by putting each
exception, with its reason, next to the code it excuses, and by failing in both directions.

## Where the rule lives

**A static gate in the lint stage, not a test.** A test that reads source text or walks the AST
to assert structure mixes a code-shape rule into the behaviour suite: it goes red on refactors
that keep behaviour, and nobody reading the suite can tell rules from behaviour. A static check
states the rule once, runs in seconds, and fails with a location and a reason. Use existing tools
where they fit (import-linter contracts, type-checker settings, dead-code finders) and write a
small AST checker for the rest.

**Parse, never grep.** Match the syntax tree, so a renamed constant, an inline literal, a regex
branch or a different spelling is caught as surely as the original. Naming conventions are not a
detection mechanism.

**Derive the criteria from production.** When the rule depends on a list — the registered
injection seams, the event registry, the public API — read that list from the production source
that defines it. A second hand-maintained list drifts from the first.

**One definition, every entry point.** The pre-commit hook, CI and the task runner all invoke
the same gate command; none inlines its own copy.

## Exceptions live at the site

Each allowed exception carries a comment at the code it excuses:

```python
# gate-broad-except: boundary — the plugin host must survive any plugin failure
# gate-continue: and keep serving the other plugins
except Exception:
```

- `broad-except` names the rule; `boundary` is a **category** from that rule's closed set; the
  text after `—` is the **reason**, and it is mandatory.
- A category set that is closed forces the exception into a known kind of justification. When a
  real case fits no category, adding one is a visible decision, not a silent entry.
- Registration is a trace, not a waiver: the reason lets the next reader decide whether it still
  holds.
- Exemption settings for third-party tools that cannot read site comments (per-file ignores,
  dead-code whitelists) carry a reason on every entry too.

## Fail in both directions

The gate reconciles the sites its check finds against the annotations in the code:

| Finding | Result |
|---|---|
| A site with no annotation | fail — fix the code or annotate it |
| An annotation whose anchor no longer has a site | fail — the exception is **stale**; delete it |
| A category outside the closed set | fail |
| An annotation with no reason | fail |

The second row is the **ratchet**. A gate that only blocks new violations lets annotations
outlive their code, and the list of exceptions grows until nobody checks it. Failing on stale
entries keeps the annotations a mirror of current fact.

## Keep the signal high

A gate people trust is one that rarely misfires; a noisy one teaches reflexive annotation, and
then the reasons mean nothing. Narrow the predicate until every hit is worth a human decision —
for example, not "any string literal in a condition" but "a string literal in a condition whose
subject carries natural language". Keep defining data separate from using it as a criterion: a
word list inside a prompt or an error message is data; the same list driving an `if` is the
thing to catch.

Lower-precision signals — "most call sites pair A with B, these two don't" — belong in an
investigation report that never blocks a merge.

## Review the exceptions

Provide a view of every annotation grouped by rule and category, and read it periodically:
categories with growing counts point at a rule that is wrong or a design that keeps fighting it.

## The bundled library

`scripts/site_annotations.py` (standard library only) does the parsing, anchoring, reconciliation
and review view. A rule supplies only the sites it finds:

```python
from site_annotations import Site, reconcile, scan

errors = reconcile("broad-except", find_sites(files, root), scan(files, root), CATEGORIES)
```

- An annotation on its own line anchors to the next line of code; one trailing code anchors to
  that line. `gate-continue:` lines extend the reason. `--` is accepted for `—`, and `//`
  comments for `#`.
- Python files are tokenized, so markers inside strings are ignored; other files are scanned line
  by line.
- `python scripts/site_annotations.py <paths> [--suffix .ts]` prints the review view.

`scripts/example_broad_except_gate.py` is a complete rule — copy it, then change `find_sites` and
`CATEGORIES`.

## Done

The rule runs as a static gate invoked by every entry point; its criteria come from production
definitions; every exception sits at its site with a category from a closed set and a reason;
the gate fails on unannotated sites, stale annotations, unknown categories and missing reasons;
and a review view lists every annotation.
