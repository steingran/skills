---
name: delivery-discipline
description: Enforce narrow scope, minimal implementations, and clean PR lifecycle for GPT-5.6-family coding agents (Codex/opencode adapters in the Paperclip fleet if running Paperclip). Use this skill whenever work is being handed to a GPT-5.6 agent, when writing or revising AGENTS.md / routine instructions / task prompts for the fleet, when a task risks growing into process artifacts or new abstractions, when reviewing whether a change is over-engineered, and whenever open PRs are piling up, going stale, or being superseded by fresh PRs instead of being finished. Also use it when the user complains about scope creep, ceremony, "too much process", gold-plating, or messy/abandoned PRs — even if they don't name this skill.
---

# Delivery Discipline (GPT-5.6 family)

The output of a task is working, deployable software delivered in the smallest increment compatible with correctness, performance, and reliability. Process serves that outcome and never becomes the product.

GPT-5.6-family models fail in three specific directions under vague instructions: they **expand process** (docs, ledgers, dashboards, meta-plans), they **over-build** (abstractions, config, frameworks nobody asked for), and they **abandon** work in progress (a new PR instead of finishing the old one). This skill exists to make those three failures structurally impossible rather than discouraged.

## 1. Scope contract — emit before writing code

Every task starts with a contract, stated in the reply, before any file is touched:

```
SCOPE CONTRACT
Task: <one sentence>
In scope: <≤5 bullets, each a runnable behavior change>
Out of scope: <everything adjacent that was noticed and will NOT be done>
Expected footprint: <files/directories likely to change — or "unknown, reporting after read">
```

Rules that make the contract binding:

- **Narrowest reading wins.** When instructions are ambiguous, pick the smallest defensible interpretation, state it in the contract, and proceed. Do not ask for clarification on a detail that can be decided narrowly and reversed cheaply.
- **Adjacent work goes on the list, not into the diff.** Anything discovered while working — a bug, a smell, a missing test elsewhere — is recorded under `OUT OF SCOPE (observed)` at the end and, if it matters, becomes its own work item. It never enters the current PR.
- **Footprint divergence is a stop condition.** The signal is not size — a migration can legitimately touch 3,000 lines. The signal is the diff **leaving the shape that was declared**: new files, directories, projects, or modules that weren't in the footprint; a second subsystem pulled in; the change growing well past its own declared shape. When that happens, stop, report what pulled the diff outward, and propose a split. Do not discover it in the close-out after the fact.

## 2. Anti-ceremony: process artifacts require a gate

A process artifact is any deliverable that does not change runtime behavior: status documents, certificates, ledgers, dashboards, migration plans, meta-reports, README rewrites, ADRs, checklists, summaries-of-summaries.

- Create one **only** when it is a hard gate for a named feature or capability. A conformance validator that blocks release qualifies. A "Phase 2 readiness report" does not.
- Every process item must name the feature work it gates. **An item that gates nothing does not get created.**
- Process/ops items are capped at **~5% of open work items**. If the queue is above that, the correct action is to close process items, not to add one.
- Choosing a process artifact because it is easy, safe, and looks like output is reward hacking. Treat it as a failure, not a contribution.
- Do not write a plan document when a plan can be three bullets in the reply. Do not write a completion report when the PR description is the report.

## 3. Anti-over-engineering: build the smallest thing that works

Default to the **most boring implementation that passes the tests and meets the stated non-functional requirements**. Complexity must be requested or justified by a measured constraint, never anticipated.

Do not introduce, unless the task explicitly asks or a measurement forces it:

- an interface, base class, or generic type with exactly one implementation
- a new abstraction layer, "manager", "provider", "strategy", or plugin point for a single caller
- configuration or a feature flag for a value that has never needed to vary
- retry, caching, batching, pooling, or async pipelines where no latency or throughput target exists
- a new NuGet/npm dependency where the framework already covers it (state the alternative considered if adding one)
- a new project, module, or repository
- rewriting adjacent code to a different pattern "while in there"

**Rule of three:** duplication is cheaper than the wrong abstraction. Do not extract until the third real occurrence exists in the codebase today — not the third one imagined.

**Test proportionality:** cover the behavior changed and its failure modes. Do not build fixtures, harnesses, or builder DSLs larger than the code under test.

If a simpler-but-worse option was rejected, say so in one line in the PR description. One line, not a design document.

## 4. PR lifecycle: nothing is abandoned, ever

Abandonment is the most expensive of the three failures because it leaves ambiguity in the repository. The rules are mechanical.

**Before opening any PR**, query open PRs on the repo authored by the same agent and touching the same paths. Then use this table:

| Situation | Action |
|---|---|
| An open PR already covers this work item | Push to that branch. **Never** open a second PR. |
| The open PR has unresolved review comments | Fix on that branch. A new PR is not an escape from review. |
| The open PR's approach was wrong | Reset/force-push the branch, or supersede it (below). Do not leave it open. |
| No related PR exists | Open one, referencing the work item ID. |

**Supersede protocol** — the only legitimate way to replace a PR:

1. Open the replacement, referencing the work item.
2. Comment on the old PR: what changed in approach, why, and a link to the successor.
3. Close the old PR immediately, in the same turn. A superseded PR left open is an incident.
4. Carry over any unmerged commits or review decisions that still apply.

**Standing constraints:**

- One open PR per work item. **Parallel PRs are fine and expected** — there is no cap on how many run at once. The constraint is on unfinished ones: every open PR must have a live owner, a current state, and a next step. Breadth is fine; orphans are not.
- Every PR references a work item. A PR that references nothing gets closed, not adopted.
- Every PR ends its turn in one of exactly four states: **merged**, **closed with reason**, **awaiting review (CI green, no unresolved comments)**, or **blocked with a named blocker and owner**. "In progress" at end of turn is not a state; it is an abandoned PR waiting to happen.
- Draft PRs are for work continuing this session. A draft with no commits for 48h is stale, not draft.

See `references/pr-lifecycle.md` for the staleness ladder, labels, and paste-ready `gh` queries and Paperclip routine.

## 5. Honesty and credit

- Never fake a test, present a mock or fixture as live proof, weaken an assertion to make it pass, hard-code a success path, or close work that is not done. A false close is reopened with an incident comment on the record.
- **A refusal is not a delivery.** A correctly typed refusal beats a fabricated result and loses to the real capability. Implementing only the refusal or error path earns partial credit and never closes a feature item — mark it `refusal-only` with a follow-up item so it reads as unfinished, never as shipped.
- Report what was not done as prominently as what was. Under-claiming is free; over-claiming corrupts the queue.

## 6. Close-out block — emit at the end of every task

```
DELIVERED: <runnable behavior now working, in one or two lines>
NOT DELIVERED: <anything in the contract that didn't land, and why>
PR STATE: <#id> — merged | closed(reason) | awaiting-review | blocked(<blocker>, <owner>)
FOOTPRINT: <files/dirs actually changed> vs declared (note any divergence)
OUT OF SCOPE (observed): <adjacent issues found, as candidate work items — not fixed>
PROCESS ARTIFACTS CREATED: <none, or: name + the feature it gates>
```

`PROCESS ARTIFACTS CREATED: none` is the expected value. Anything else needs the gate named on the same line.

## 7. Applying this to the fleet

When writing task prompts, routines, or AGENTS.md sections for GPT-5.6 agents, embed these rules in the **acceptance criteria of the work item itself** — models follow item-level acceptance criteria far more reliably than repo-level policy files. `references/agents-md-block.md` has a paste-ready condensed block for AGENTS.md and for per-item acceptance criteria.

When reviewing a GPT-5.6 agent's output, check in this order: (1) did it emit a scope contract, (2) does the diff exceed it, (3) are there process artifacts without gates, (4) does it introduce single-caller abstractions, (5) is every touched PR in one of the four terminal states.
