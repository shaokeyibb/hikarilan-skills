# <one line: the defect or the change, stated as a fact>

Worktree: `<absolute path>`   Branch: `<name>`   Base: `<commit>`

## The defect (I measured this; measure it again yourself)

`<file:line>`

```
<the offending code, quoted>
```

<Why it is wrong, and what it causes downstream.>

## Step 0 — falsify

1. Confirm the code above still reads that way on this base.
2. **Build a behavioural probe**: drive the real production path until the defect is
   observable, and assert it. Paste the output.
3. **If it is already fixed, stop.** Say so and end the run. A zero-hit search is not
   proof it is fixed — only the probe is.

## The judgement call

<State the decision you are NOT making for them, and the criterion for making it.
If there is a tempting wrong answer, name it and say why it is tempting.
If you have a view, mark it as yours and invite refutation:
"This is my read, not a fact — refute it or adopt it.">

## Acceptance

1. **Positive** — <the fixed behaviour>, measured.
2. **Negative** — <the neighbouring case that must NOT change>. No collateral damage.
3. **Census the consumers** — this predicate serves how many call sites? Search the
   whole source tree, not the directory named above, and show the search. Gating only the
   side that was named is the most common way a fix lands half-done.
4. **Mutation** — revert the fix; the new assertion **must go red**. Paste the failure.
   Write the assertion and break it immediately; do not wait for review to discover it
   never held. Green is the default state.
5. **Regression** — every test touching the changed surface. If an existing expectation
   changes, explain **per case** why the new value is the true one. Do not edit
   expectations to reach green.

## Ground rules

- Work only inside the worktree above. Confirm the working directory before creating
  any file or directory.
- Results go to `<results dir>/result-<name>.md`. Never overwrite an existing result file.
- Allowed to appear in `git status --porcelain --ignored`: tool caches, build outputs,
  virtualenvs. Forbidden: installing dependencies, writing outside the tree, any tracked
  change not required by this task.
- Forbidden git verbs: `push`, `checkout`, `restore`, `reset`, `clean`, `stash`, `merge`.
  `rebase` is allowed. Never bypass a failing pre-commit hook.
- Read-only, no exceptions: `<paths that must not change — fixtures, run artifacts, data>`.
- Never read or print secrets; never touch `<credential files>`.
- Do not pipe when you need an exit code — the pipe's status is what you get back.
- <Machine-specific traps: temp dir conventions, environment pins, commands with
  pathological runtimes. Concurrent runs need non-colliding scratch paths.>

## Report back

Commit first, then write the result file:

Step 0 probe output / the judgement and its reasoning / positive and negative measurements /
consumer census with the search / **mutation failure text** / per-case explanation of any
changed expectation / gate exit codes / test tail lines / `git log --oneline -3` /
`git status --porcelain --ignored` for both the worktree and the main repo /
**where this brief is wrong — argue it and show evidence.**
