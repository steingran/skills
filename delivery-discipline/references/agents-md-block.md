# Paste-ready blocks

Two forms. The AGENTS.md block sets repo-level policy; the acceptance-criteria snippet is what actually changes GPT-5.6 behavior, because item-level criteria are followed far more reliably than repo-level policy files. Use both.

---

## A. AGENTS.md section

```markdown
## Delivery Discipline

The purpose of this project is working, deployable software delivered in the
smallest increment compatible with correctness, performance, and reliability.
Process serves that outcome and never becomes the product.

**Scope contract.** Before touching a file, state: the task in one sentence, at
most five in-scope bullets, an explicit out-of-scope list, and the expected
footprint (which files or directories you expect to change). When instructions
are ambiguous, take the narrowest defensible reading and say which one you took.
Leaving the declared footprint is a stop condition — not size, but shape: new
projects, modules, or subsystems that were not declared. Stop, report what pulled
the diff outward, propose a split. Do not discover it in the close-out.

**No unearned process artifacts.** Status documents, ledgers, dashboards,
certificates, meta-reports, and plan documents are not progress. Create one only
when it is a hard gate for a named feature, and name that feature. An item that
gates nothing does not get created. Process/ops items are capped at ~5% of open
items. Picking process work because it is easy and low-risk is reward hacking.

Suggesting is not scope creep — building unprompted is. Noticing that a decision
deserves an ADR, or that a check is missing (security, tests, observability,
accessibility, migration path), costs one line in the close-out `SUGGESTIONS`
field and is always welcome. Acting on it without being asked is the same gate
violation as any other unrequested process artifact.

**Smallest thing that works.** Do not add an interface with one implementation,
an abstraction layer for one caller, config for a value that never varied,
retry/caching/pooling with no stated target, a new dependency the framework
already covers, or a new project. Do not refactor adjacent code while in there.
Rule of three: no extraction until the third real occurrence exists today. Tests
cover the behavior changed and its failure modes — no harness larger than the
code under test.

**No orphan PRs.** One open PR per work item. Parallel PRs are fine — the
constraint is that every open PR has a live owner, a current state, and a next
step. Before opening a PR, check your open PRs on this repo for path overlap; if one exists, push to that branch. A new PR is never an escape from
review comments. Replacing a PR requires the supersede protocol: open the
successor, comment on the old PR with the reason and link, close the old PR in
the same turn. Every PR ends the turn merged, closed with a reason, awaiting
review with CI green, or blocked with a named blocker and owner.

**Honesty is absolute.** Never fake a test, present a mock as live proof, weaken
an assertion to make it pass, hard-code a success path, or close work that is
not done. A false close is reopened with an incident comment. A refusal is not a
delivery: implementing only the refusal path earns partial credit, never closes
a feature item, and is labeled `refusal-only` with a follow-up item.

**Close-out.** End every task with: DELIVERED / NOT DELIVERED / PR STATE /
FOOTPRINT vs declared / OUT OF SCOPE (observed) / SUGGESTIONS / PROCESS ARTIFACTS
CREATED. The expected value of the last line is "none"; `SUGGESTIONS` is free to
be non-empty — it only becomes a violation if the agent builds the suggestion
instead of naming it.
```

---

## B. Per-work-item acceptance criteria (append to every item)

```markdown
- [ ] Scope contract stated before implementation; final diff stayed within the declared
      footprint (or the divergence was reported and a split proposed, not silently absorbed)
- [ ] Runnable behavior change an end user or consuming agent can exercise
- [ ] No new single-caller abstraction, interface with one implementation, config
      for a never-varying value, or unrequested dependency
- [ ] No process artifact created, or the gated feature is named
- [ ] No adjacent refactoring; issues found are listed as candidate items, not fixed here
- [ ] Recommendations noticed but out of scope (ADR candidates, missing checks) are named
      in `SUGGESTIONS`, not built
- [ ] Exactly one PR for this item; no open sibling PR touching the same paths
- [ ] PR ends in a terminal state: merged / closed(reason) / awaiting-review (CI green,
      no unresolved comments) / blocked(blocker, owner)
- [ ] Refusal-only implementations labeled `refusal-only` with a follow-up item; item stays open
- [ ] Close-out block emitted
```

---

## C. Task-prompt preamble (one-shot sessions)

For ad-hoc GPT-5.6 sessions that don't read AGENTS.md:

```
Before writing code, state a scope contract: task in one sentence, ≤5 in-scope
bullets, explicit out-of-scope list, and the files/directories you expect to touch.
Take the narrowest defensible reading of anything ambiguous and say which you took.

Build the smallest thing that works: no single-caller abstractions, no config for
values that never varied, no new dependencies the framework covers, no refactoring
of adjacent code, no plan or status documents.

Check my open PRs on this repo before creating a new one — if one touches the same
paths, push to that branch instead. If you notice something worth doing but out of
scope — an ADR-worthy decision, a missing check — name it, don't build it. End with
the PR in a terminal state and emit a close-out block: DELIVERED / NOT DELIVERED /
PR STATE / FOOTPRINT vs declared / OUT OF SCOPE (observed) / SUGGESTIONS /
PROCESS ARTIFACTS CREATED.
```

---

## Tuning notes

- Deliberately no line-count budget and no cap on concurrent PRs. Both punish breadth,
  which is not the failure mode here. The enforced signals are footprint *shape* and PR
  *terminal state* — a 3,000-line migration inside its declared footprint is compliant;
  a 40-line PR left open with no owner is not.
- If an agent keeps drifting outward, tighten the footprint declaration in the item
  ("touch only src/<Service>.Api/Handlers/"), not a line count.
- If an agent repeatedly produces process artifacts, the fix is usually the work item,
  not the model: items phrased as "assess", "review", "prepare", or "align" invite
  documents. Phrase items as "make X do Y", verifiable by running something.
