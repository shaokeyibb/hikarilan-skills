# Audit dimensions

Every quality-lens auditor gets the whole list. It is a floor, not a ceiling: the bar is "no
significant quality problems, high readability and maintainability", and auditors add
dimensions when the code calls for them. Each finding carries its dimension, a `file:line`, and
evidence.

## Defects and debris

- **Bugs** — wrong results, crashes, unhandled states, off-by-one, wrong defaults.
- **Leftover and compatibility code** — aliases, legacy readers, migration shims, `compat` /
  `deprecated` paths, branches kept for formats nothing produces any more.
- **Non-structural patches** — guards, retry caps, special cases keyed on a name or a text that
  mask a defect instead of removing it.
- **Unclear responsibility** — two owners deciding the same thing, one module doing two jobs.

## Readability and maintainability

- **Readability** — naming, function length, nesting depth, whether comments state intent.
- **Duplication** — the same rule or logic in more than one place.
- **Abstraction** — layers with a single caller, or missing abstractions forcing repetition.
- **Boundaries** — module edges, dependency direction, public surface no larger than needed.

## Contracts and failure

- **Types and contracts** — annotations present and honest, DTO boundaries, closed sets that are
  actually closed.
- **Error handling** — swallowed exceptions, error codes owned by the right layer, failures that
  can be diagnosed from what they report.
- **Async and resources** — races, unclosed resources, cancellation and timeout behaviour.
- **Security and privacy** — secrets in code or artifacts, redaction applied at export
  boundaries.
- **Performance hotspots** — obvious quadratic loops, repeated I/O, work redone per call.

## Surroundings

- **Test quality** — tautological or change-detector tests, brittle or nondeterministic cases,
  gaps in end-to-end coverage of real behaviour.
- **Docs, specs and README** — each statement either matches current behaviour or is deleted.
- **Configuration and dependencies** — unused keys, keys without readers, unused or duplicated
  dependencies, transitive dependencies imported directly.
- **Logging and observability** — failures leave enough structured trace to diagnose.
- **Style consistency** — the change reads like the code around it.
