---
name: e2e-first-testing
description: Test strategy for a repository — which tests to write, keep, or delete. Use when adding tests for a change or a bug fix, designing fakes, mocks or test doubles, reviewing a diff that adds or edits tests, deciding whether a regression test is warranted, or pruning a slow or brittle test suite.
---

# E2E-first testing

A test earns its place by going red when behaviour a caller depends on breaks, and staying green
when it holds. Every rule below follows from that. A test that cannot catch a behavioural
regression, or that fails when only the implementation moved, costs maintenance and gate time and
buys nothing — and a suite full of them trains everyone to treat red as noise.

## The default: a scenario through the production path

Write an end-to-end scenario first, and treat it as the only coverage that counts for a feature.

- **Enter where a real caller enters**: a CLI command, an SDK call, an HTTP route, an MCP tool, a
  queue consumer — or a port that production code itself calls.
- **Wire with production composition**: the same factory, registry and dependency assembly the
  real entry uses.
- **Feed production-shaped input**: real fixture data from the repo (example projects, recorded
  payloads). Derive intermediate values through the production functions that compute them;
  a hand-written "correct" value silently stops matching what production produces.
- **Finish with a reproducible artifact**: a run directory plus a normalised result manifest
  (stable keys, sorted, volatile fields such as timestamps and generated ids stripped). Assert
  against the manifest; reviewers read it; two runs of the same scenario diff cleanly.

A scenario whose path diverges from the production path proves nothing — the bug lives exactly in
the divergence. A branch reachable only by bypassing the production path is dead code: delete
the branch.

## Doubles live at external boundaries

An **external boundary** is something the repo does not own: an LLM or model provider transport,
a device, browser or desktop driver, a remote service, the wall clock, randomness.

- Each boundary has **one registered injection seam** in production code — a constructor
  argument, a host-boundaries object, a configured base URL. The double implements the same
  public protocol as the real thing and enters through that seam.
- Prefer an out-of-process fake the production client talks to unchanged (a local HTTP fake
  provider reached through the configured base URL). Use in-process injection only when the
  out-of-process fake costs too much.
- The repo's own collaborators stay real: the test calls the entry point and lets the real
  internals run. Patching internal modules, hand-assembling internal DTOs, and calling
  mid-pipeline helpers directly all create a path production never takes.
- Production code carries no test-only branches, and doubles never surface as user
  configuration (`backend: replay`, `world: fake`). Offline worlds and recordings arrive through
  the SDK or host injection seam; the test reads the double it injected as ground truth.
- Check this mechanically where you can: a static check derives the allowed seams from the
  production registration and flags tests that patch anything else.

When the double sits at a seam production already has, debugging the real path and debugging the
test path are the same activity, and the boundary of the system stays visible.

## Isolated tests: failure modes first

Some logic deserves isolation — a pure algorithm with a large input space, a parser, scheduling
arithmetic. For these, **write the complete list of ways the code can fail before writing the
code**: each input class, each boundary, malformed input, ordering, concurrency, resource
exhaustion. Turn each item into a test, then implement.

The order matters. A list written after the code describes the code that exists, bugs included;
a list written before it describes the ways it can break. Unit tests added afterwards "for
coverage" are the after-the-fact kind, and they freeze whatever the code happens to do.

Isolated tests do not count as end-to-end coverage of the feature they sit inside.

## Harmful tests

Delete these on sight; the deletion needs no replacement:

- **Tautological** — the expected value is computed the way the code computes it, a constant is
  asserted equal to itself, a mock returns X and the test asserts X.
- **Change-detector** — goes red when code changes and behaviour does not:
  - reads source text or walks the AST to assert structure, imports or names;
  - byte, hash or digest snapshots of output that nobody reviews semantically;
  - reaches into private symbols;
  - asserts message wording, log text or prompt prose;
  - maintains provenance — which change introduced what, history in fixtures.
- **Recipe restatement** — asserts that a Makefile target or wrapper script passes certain flags.
  Wiring errors in a thin caller show up the first time it runs; test the callee through its
  public entry instead.
- **Always skipped** — skipped on every platform the project actually runs on, so it can only
  ever report "unverified".
- **Overfitted to a model's reaction** — in systems that drive an LLM or another agent, the test
  scripts one specific reaction as the expectation ("after the rejection it switches to tool Y").
  Assert the system's own behaviour (rejected, not dispatched, reason fed back) and script the
  model's retry as any valid answer.

Architectural constraints — layering, import boundaries, banned patterns, dead code, suppression
budgets — are worth enforcing, and the right home for them is a static gate in the lint stage
(import-linter contracts, a custom AST checker). There they are explicit, fast, and separate from
the behaviour suite.

## Bug fixes and regression tests

Ask one question: **did an existing behavioural scenario have a gap that let this bug through?**

- Yes → extend that scenario, or add one, to cover the gap, and name the gap in the test or the
  commit message.
- No — the area was covered and the bug sat elsewhere, or a static check is the real guard → fix
  without adding a test.

Proof that a fix works is the original failure reproduced through the production path before the
fix and passing after it. "The suite is green" is a different, weaker statement.

## Reviewing a test diff

- **An assertion value flipped, or an expected manifest changed**: treat it as a regression until
  a contract (spec, ADR, recorded decision) justifies the new value. "It became random" or "the
  fixture was stale" needs evidence, and the investigation often finds a real regression.
- **A test that records a defect's current behaviour as expected** — typical when whoever found
  the bug was only writing tests: the expectation becomes the specified behaviour, and the defect
  gets fixed rather than enshrined.
- **New test directories and helpers**: check whether they exist to sidestep the seam check.
- **Probes outside the test tree** do not count as tests; evidence files go under the fixtures
  directory and are read by repo-relative path, never by absolute machine path.

## Pruning a legacy suite

Use **coverage per test**, not an aggregate threshold. An aggregate percentage barely moves when
a deletion removes the one test covering a particular branch.

1. Run the suite you keep (scenarios plus failure-mode tests) with branch coverage.
2. Run the legacy suite with one coverage context per test.
3. A legacy test whose every covered branch is also covered by the kept suite is deletable, and
   all such tests can go together.
4. For the rest, the uncovered branches are the gap. Write a scenario through a public entry for
   that behaviour, re-measure, then delete. Where several legacy tests share the same gap
   branches, keeping one of them is enough until the scenario exists.
5. Prefer deleting to rewriting. Tautological and change-detector tests are deletable at any time,
   whatever they cover.
6. Work in batches by package: one commit per batch, full gates green each time.

For Python, `scripts/exclusive_coverage.py` performs steps 3–4 from two coverage.py data files:

```bash
COVERAGE_FILE=.coverage.keep   pytest tests/e2e  --cov=<pkg> --cov-branch --cov-report=
COVERAGE_FILE=.coverage.legacy pytest tests/unit --cov=<pkg> --cov-branch --cov-context=test --cov-report=
python scripts/exclusive_coverage.py --keep .coverage.keep --legacy .coverage.legacy --json prune.json
```

It needs only the standard library. Without branch data on both sides it compares lines. In other
ecosystems, use the coverage tool's per-test mode where it has one; otherwise run each legacy test
alone under coverage — slow, but it yields the same per-test sets.

## Done

For a change: every behaviour change is exercised by a scenario through a production entry, and
the run leaves a reproducible manifest; the diff adds no harmful tests; every isolated test traces
to a failure-mode list written before the code; every new regression test names its gap.
