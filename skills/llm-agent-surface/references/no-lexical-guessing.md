# No lexical guessing in decision paths

## What counts as a decision path

Logic whose result changes control flow, a verdict or an identity: whether an assertion passes,
whether two states or strategies are the same, whether an option is exhausted, whether an action
is safe, whether a response is valid.

The test is what is being judged, not whether something looks like text. `status == "completed"`
compares a state-machine value and is fine; `"error" in reason` judges what a sentence means and
is not.

## The four legitimate exceptions

1. **Reserved words of an external specification** — JSON Schema keywords, HTML tags and ARIA
   roles, HTTP methods, MIME types.
2. **Structured identifiers produced by the system under observation** — class names, resource
   ids, DOM attribute names, structure-tree state values.
3. **Protocol markers the code produces itself and later recognises** — provided that producing
   the marker does not itself depend on splitting natural language. A self-produced marker whose
   creation splits on a language's separators inherits that language binding.
4. **Enum and literal values** — internal state values, configuration enums, CLI answers such as
   `y` / `yes`, boolean literals.

## Choose the failure direction

When a heuristic truly cannot be avoided, decide in writing which way it fails, and make it fail
towards doing one more unit of work — one more attempt, one more sample, two entries kept apart —
never towards an early verdict such as "exhausted", "passed" or "equivalent".

Example: should strategy identity strip generic words like "button" or "icon"? Stripping fails by
treating two different controls as the same, so a control that was never tried is declared dead.
Not stripping fails by recording the same control twice under two phrasings, so it is tried once
more and the budget bounds the cost. Keep the phrasings apart.

## Gating it

- **Scan the syntax tree**, not text: find every place a string literal takes part in a
  condition, so renamed constants, inline literals, regex branches and code-point ranges are
  caught alike.
- **Narrow the predicate for signal**: flag a site when the subject being tested carries natural
  language *and* the literal looks like natural language. Comparisons against enums and
  specification identifiers fall outside it.
- **Annotate allowed sites in place** with the exception category and a reason, and make the gate
  fail on stale annotations as well as unannotated sites, so the list of exceptions always
  mirrors the code.
