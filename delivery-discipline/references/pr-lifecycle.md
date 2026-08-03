# PR Lifecycle Enforcement

Mechanics for keeping 15–25 concurrent PRs from turning into a graveyard. Defaults below; tune per repo with the user.

## Staleness ladder

Age is measured from the **last commit**, not from PR creation. A comment does not reset the clock; a push does.

| Age | Action | Who |
|---|---|---|
| 48h no commits | Comment on the PR: current blocker, next concrete step, ETA. Apply `stale:nudged`. | Owning agent |
| 5 days no commits | Apply `stale:decide`. Owner must pick **finish**, **close**, or **rebase-and-finish** and state it in a comment within one working day. | Owning agent → escalate to human on silence |
| 10 days no commits | Close with reason, link the work item, reopen the item as `todo` with a note on what exists on the branch. Apply `closed:stale`. Branch retained. | Sweeper routine |
| Any age, superseded | Close immediately with a link to the successor. Never leave two live PRs for one item. | Whoever opened the successor |

Exception: PRs labeled `blocked:external` (waiting on a third party, a release, a decision) are exempt from the ladder but must carry a named blocker and owner, and get re-checked weekly. `blocked:external` without a named owner is not exempt.

## Label registry additions

Add these to the fleet label/marker registry to avoid collisions with existing auto-fix labels:

- `stale:nudged` — 48h notice sent
- `stale:decide` — decision required from owner
- `closed:stale` — closed by sweeper, work item reopened
- `blocked:external` — exempt from ladder, requires blocker + owner in the PR body
- `refusal-only` — only the refusal/error path implemented; feature item stays open
- `scope:overrun` — diff left the declared footprint (new subsystems/projects pulled in); needs split or explicit human sign-off
- `supersedes:<pr-number>` / marker comment `<!-- SUPERSEDES:#123 -->` — machine-detectable supersede link

## Duplicate detection before opening a PR

Run before every `gh pr create`. If any result overlaps the paths about to change, push to that branch instead.

```bash
# Open PRs by this agent on this repo, with changed files
gh pr list --repo "$REPO" --author "@me" --state open \
  --json number,title,headRefName,updatedAt,labels,files \
  --jq '.[] | {number, headRefName, updatedAt,
               files: [.files[].path]}'
```

Overlap test: any shared file path, or any shared top-level project/module directory. Shared directory is enough — two agents editing the same service in parallel PRs is how conflicts and abandonment start.

## Sweeper queries

```bash
# Candidates for the 5-day and 10-day rungs (no commits since cutoff)
gh pr list --repo "$REPO" --state open --json number,title,updatedAt,labels,isDraft \
  --jq --arg cut "$(date -u -d '5 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
  '[.[] | select(.updatedAt < $cut)]'

# PRs with no work-item reference in the body (candidates for close)
gh pr list --repo "$REPO" --state open --json number,body \
  --jq '[.[] | select(.body | test("(?i)(work item|closes #|refs #|[A-Z]+-[0-9]+)") | not)]'
```

`updatedAt` moves on comments, so confirm with the head commit date before acting on the 10-day rung:

```bash
gh pr view "$PR" --repo "$REPO" --json commits --jq '.commits[-1].committedDate'
```

## Sweeper routine sketch (Paperclip)

Follows the fleet's standard routine pattern — cheap filter first, dedup markers, circuit breaker, idempotent.

```
Routine: pr-staleness-sweeper
Agent: mechanical-QA tier (separate cheap quota pool — never an orchestration agent)
Trigger: 0 7 * * 1-5   (once daily, weekday mornings)

Step 1 (cheap filter, no model): list open PRs with last-commit older than 48h.
        Zero results → exit with no side effects.
Step 2: bucket by rung (48h / 5d / 10d), skipping blocked:external with a named owner.
Step 3: apply the rung action. Dedup via hidden marker <!-- STALE-SWEEP:<rung>:<sha> -->
        so a rerun on the same head SHA is a no-op.
Step 4: circuit breaker — label sweep:attempts:N; at N=3 apply sweep:blocked and stop
        touching the PR. Never auto-remove sweep:blocked.
Step 5: closes at the 10-day rung are the only mutating action; require the work item
        to be reopened in the same step or the close is skipped and escalated.
```

Closing at the 10-day rung is irreversible enough to deserve care: keep it deterministic (no LLM judgment in the close decision), and post the reason comment before the close so the record survives.

## PR description template

Enough to make state legible, short enough that nobody writes a report.

```markdown
Work item: <ID / link>
Scope: <one sentence — what runnable behavior changes>
Out of scope: <what was deliberately left>
Approach: <one line; if a simpler option was rejected, why>
Footprint: <files/dirs changed> (declared: <files/dirs>)
State: awaiting-review | blocked(<blocker>, <owner>)
Supersedes: <#id or none>
```
