# Review: `<branch>` — read-only, adversarial

You are an **independent read-only reviewer**. Your output is a report, not code.

Worktree: `<absolute path>`   Commit under review: `<sha>`
The run's own account: `<results dir>/result-<name>.md` — read it, then verify it.

## Read-only means

- No file created, modified, or deleted anywhere — not the tree, not the repository.
  One exception: your report, at the path named at the end.
- No git write: `add`, `commit`, `checkout`, `restore`, `reset`, `clean`, `stash`,
  `merge`, `push`, `rebase`, `cherry-pick`, `apply`. `diff`, `log`, `status`, `show` are open.
- **Mutations happen in a copy.** Copy the tree to scratch, mutate the copy, point the
  runtime at it. `git show HEAD:<file>` gives you the pristine original.

**Proving you stayed read-only** — the criterion is *tracked files and artifacts*, not
*zero writes*. Running the gates necessarily writes caches, and a reviewer that
invalidates itself over `__pycache__` has thrown away its own work.

- **Allowed, no cleanup needed**: tool caches, build outputs, virtualenvs, your scratch copies.
- **Violations**: any tracked-file change; installing dependencies; writing to
  `<protected artifact paths>`; new files outside the allowed list.

Prove it with `git status --porcelain --ignored` on both trees — plain `--porcelain`
hides ignored paths and proves nothing. Walk the output against the two lists above and
say which line lands where.

## Verify, do not re-read

The run's report is a **claim**. For each one, decide: confirmed / needs rework / unverified —
each with evidence you produced.

**Re-measure the load-bearing numbers yourself.** Any count the conclusion rests on gets
recomputed with your own command. Disagreement is not automatically a defect — but it must
be explainable, and the run's figure must be reproducible from what it wrote down.

**Break the locks.** For each guard the run added:

- Break what it guards → it must go red. **Paste the failure text.**
- Where the run claims N guards: breaking one must leave the other **N−1 green**. All N
  red from one break means one guard wearing N names. List each guard's `file:line` —
  red count is not lock count, **site** count is.
- Try one path the run did not list — a different way to reach the same thing. If it slips
  through, say so and size the gap. Whether that is blocking depends on whether the next
  person would hit it *by accident*, not on whether it can be reached *deliberately*.

**Quantifier check, both directions.** Every "all / each / any" sentence in the spec gets
a guard found for it; and every production path that reaches the behaviour gets a spec
sentence covering it. One direction alone misses this entire family — a spec claiming six
prohibitions while one is enforced passes every static gate there is.

**Consumer census.** The predicate that changed — who else reads it? Search the whole
source tree and show the search. Gating only the side that was named is the most common
way a fix lands half-done.

**Changed expectations.** For every assertion whose expected value moved, demand the
per-case argument for why the new value is the true one. Editing expectations to reach
green is the failure this catches.

## Trust nothing about the environment

A red result and a broken change are different things. Before reporting a failure, prove
you ran **this** tree with **the right** interpreter — print the absolute path of the
script you invoked and the environment that resolved. <Name the local pins here; a
missing one produces a convincing red that has nothing to do with the code.>

A run killed by an external limit is **unverified**, a third state. Never report it as
failed, and never let it stand in for a pass.

## Verdict

Rule on each item above, then say plainly whether this can merge.

Late rounds cut both ways: do not invent a marginal finding because the branch has been
through many, and do not wave through a real one because it feels overdue. **Evidence only.**

## Report

Write to `<results dir>/result-review-<name>.md`. It must not already exist — never
overwrite the run's own account, and never drop the `review` marker from the filename.
Do not stage it.
