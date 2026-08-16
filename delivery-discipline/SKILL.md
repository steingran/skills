---
name: delivery-discipline
description: Enforce narrow scope, minimal implementations, bounded issue topology, reusable review gates, and clean PR lifecycle for GPT-5.6-family coding agents (Codex/opencode adapters in the Paperclip fleet if running Paperclip). Use this skill whenever work is planned, delegated, implemented, reviewed, tested, or closed; when writing or revising AGENTS.md, routine instructions, or task prompts for the fleet; when work risks growing into process artifacts, issue trees, review/fix/retest loops, new abstractions, or unapproved external dependencies; and whenever open PRs are piling up, going stale, or being superseded instead of finished. Also use it when the user complains about scope creep, ceremony, "too much process", gold-plating, messy issues, or abandoned PRs, even if they do not name this skill.
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
- **Adjacent work goes on the list, not into the diff or issue tree.** Record anything discovered while working — a bug, a smell, a missing test elsewhere — under `OUT OF SCOPE (observed)` in the current implementation issue. Do not create a follow-up issue automatically. A board-authorized planner may later create a separate delivery lane only when the finding is independently deliverable and prioritized.
- **Footprint divergence is a stop condition.** The signal is not size — a migration can legitimately touch 3,000 lines. The signal is the diff **leaving the shape that was declared**: new files, directories, projects, or modules that weren't in the footprint; a second subsystem pulled in; the change growing well past its own declared shape. When that happens, stop, report what pulled the diff outward, and propose a split. Do not discover it in the close-out after the fact.

## 2. Anti-ceremony: process artifacts require a gate

A process artifact is any deliverable that does not change runtime behavior: status documents, certificates, ledgers, dashboards, migration plans, meta-reports, README rewrites, ADRs, checklists, summaries-of-summaries.

- Create one **only** when it is a hard gate for a named feature or capability. A conformance validator that blocks release qualifies. A "Phase 2 readiness report" does not.
- Every process item must name the feature work it gates. **An item that gates nothing does not get created.**
- Process/ops items are capped at **~5% of open work items**. If the queue is above that, the correct action is to close process items, not to add one.
- Choosing a process artifact because it is easy, safe, and looks like output is reward hacking. Treat it as a failure, not a contribution.
- Do not write a plan document when a plan can be three bullets in the reply. Do not write a completion report when the PR description is the report.

**Suggesting is not scope creep — building unprompted is.** Noticing that a decision deserves an ADR, that a check is missing (security, tests, observability, accessibility, migration path), or that a separate deliverable may deserve prioritization costs one line in the close-out `SUGGESTIONS` field and is always welcome, regardless of task focus. Acting on it without being asked — writing the ADR, adding the check, opening another issue or PR — is the same gate violation as any other unrequested process artifact. The bar for *naming* something is low; the bar for *building or filing* it is "the user or work item asked."

If the task involved choosing between two or more viable approaches with consequences that outlive this PR, flag it as an ADR candidate in `SUGGESTIONS` rather than writing one. Use the `engineering:architecture` skill to actually produce the ADR only when asked.

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

## 4. Delivery topology: one lane, one implementation issue, one review gate

Keep strategy structure separate from operational history.

- A strategy or outcome issue may contain outcome-level **delivery lane** children. Each delivery-lane child is the implementation issue; do not create a separate lane-container issue. Do not nest review rounds, fixes, retests, evidence collection, wake-ups, relays, or status tracking beneath the strategy map.
- One implementation issue represents one independently deliverable change and owns one PR. Keep implementation, corrections, and PR follow-through in that issue.
- A PR may have at most one active review issue. Reuse that issue for every review round and every head SHA. If replacement is genuinely necessary, close or cancel the existing review issue before creating another and link the replacement in both records.
- A review issue is always a leaf. It must not create or own subtasks.
- Record the reviewed SHA, result, findings, and next action in the existing review issue. A changed SHA starts a new round in the same issue; it does not invalidate the issue or justify a replacement.
- When review finds a problem, return the parent implementation issue to active work. The implementation owner fixes the problem on the same branch and requests another round on the same review issue.
- Do not create fix, retest, evidence, wake-up, relay, escalation, handoff, or status-only issues for an existing delivery lane. Use the implementation issue, review issue, PR, comments, state, assignee, and blocker fields as the audit trail.
- Create a separate issue only for a separately prioritized, independently deliverable outcome. Do not create one merely because an event occurred or an agent needs to be woken.

Use this loop:

1. Implement the delivery lane in its implementation issue and PR.
2. Create or reuse its single review issue and record the current head SHA.
3. If review blocks, record findings there and return work to the parent implementation issue.
4. Push fixes to the same PR, record the new SHA in the same review issue, and rerun review.
5. Complete the review issue only when the accepted result applies to the PR head that will merge.

Do not require a new external service, account, integration, paid product, repository, or infrastructure dependency unless it is defined in the parent issue, defined by an applicable board policy, or explicitly approved by the board in the implementation issue. Record a missing approval as a blocker on the existing implementation issue; do not create a coordination issue to obtain it.

## 5. PR lifecycle: nothing is abandoned, ever

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

## 6. Honesty and credit

- Never fake a test, present a mock or fixture as live proof, weaken an assertion to make it pass, hard-code a success path, or close work that is not done. A false close is reopened with an incident comment on the record.
- **A refusal is not a delivery.** A correctly typed refusal beats a fabricated result and loses to the real capability. Implementing only the refusal or error path earns partial credit and never closes the implementation issue. Mark it `refusal-only`, keep the same issue open, and record the missing capability there. Do not create a follow-up issue merely to represent unfinished work.
- Report what was not done as prominently as what was. Under-claiming is free; over-claiming corrupts the queue.

## 7. Close-out block — emit at the end of every task

```
DELIVERED: <runnable behavior now working, in one or two lines>
NOT DELIVERED: <anything in the contract that didn't land, and why>
PR STATE: <#id> — merged | closed(reason) | awaiting-review | blocked(<blocker>, <owner>)
FOOTPRINT: <files/dirs actually changed> vs declared (note any divergence)
OUT OF SCOPE (observed): <adjacent findings recorded here — not fixed and not auto-filed>
SUGGESTIONS: <none, or: recommendations noticed but not acted on — ADR candidates, missing
              checks (security/tests/observability/accessibility/migration), other observations>
PROCESS ARTIFACTS CREATED: <none, or: name + the feature it gates>
```

`PROCESS ARTIFACTS CREATED: none` is the expected value. Anything else needs the gate named on the same line. `SUGGESTIONS` is free to be non-empty — naming a recommendation costs nothing and is encouraged; it only becomes a violation if the agent builds it instead of naming it.

## 8. Applying this to the fleet

Treat this skill as the canonical detailed policy. Put the condensed mandatory invariants from `references/agents-md-block.md` in every fleet agent's Paperclip `AGENTS.md`. Remove role-specific instructions that require follow-up, fix, retest, evidence, wake-up, relay, status-only, or replacement review issues; do not leave contradictory commands in place and expect this skill to override them.

Keep task acceptance criteria specific to the requested outcome. Do not paste this entire policy into every task. A task or role instruction may override a topology invariant only when a direct board instruction explicitly names and authorizes the exception.

When reviewing a GPT-5.6 agent's output, check in this order: (1) does the issue tree preserve delivery lanes, (2) is there at most one review issue per PR and no children below it, (3) did it emit a scope contract, (4) does the diff exceed it, (5) are there process artifacts or external dependencies without approval, (6) does it introduce single-caller abstractions, and (7) is every touched PR in one of the four terminal states.
