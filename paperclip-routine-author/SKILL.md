---
name: paperclip-routine-author
description: Design, write, or debug Paperclip AI routines, agent assignments, AGENTS.md files, convergence loops, and fleet configuration for a multi-agent coding fleet. Use this skill whenever the user mentions Paperclip, a routine, an agent in their roster, agent loops, PR automation, build watchers, review resolvers, error-tracker triage automation, model routing or quota across agents, or asks to automate any part of a high-volume concurrent PR workflow.
---

# Paperclip Routine Author

Authoring discipline for routines and agent configuration in Paperclip AI, encoding patterns already proven in production use on a fleet running 15–25 concurrent PRs across ~20 repositories.

## Platform facts (verify version before claiming features)

- Routines are **single-pass, event-triggered** — not convergence loops. Native loop primitives (Enforced Outcomes, Maximizer Mode) are roadmap items, not shipped, unless a newer release says otherwise.
- "Iterate until done" lives in the adapter layer (Codex/Claude `/goal`), not in Paperclip. A convergence-loop skill package exists in the user's Skills Store with three mandatory bounds: max-iters (default 8), no-progress stop after 2 identical iterations, machine-checkable semantic exit condition, plus mandatory exit-state recording on all four exit paths.
- Triggers: webhooks were "coming soon" as of mid-2026 — schedule polling is the mechanism. Finest granularity: every minute via custom cron. Business-hours pattern: `*/2 8-15 * * 1-5` (note: `8-16` runs through 16:58; add `0 16 * * 1-5` for a clean 4 PM final fire).
- **Version discipline:** the fetched GitHub releases page has returned stale snapshots before. Confirm the installed version with the user or `npx paperclipai --version` before asserting feature availability.
- The `codex_local` adapter ignores `OPENAI_BASE_URL` (confirmed bug) — non-OpenAI models must route through `opencode_local`. The cheap-model slot is adapter-bound (must match the primary's adapter).

## Agent roster & assignment rules

Agents are referred to here by **role tier**, not by the fleet's own agent names. Ask the user for their roster mapping, or read `references/agent-roster.md` for the tier table. Assignment rules that override convenience:

- Recurring review routines go to the **principal-reviewer** or **mechanical-QA** tier, never to an orchestration agent (prior anti-pattern: an orchestration agent burned 277M tokens on work the principal-reviewer tier handled for 11.4M).
- Mechanical and high-frequency routines target the **mechanical-QA** tier on a separate cheap-model quota pool, protecting the main context window and quota.
- Never assign self-triggering routines to escalation-constrained agents. A "one attempt, then escalate" agent is incompatible with a routine that has no escalation target — this caused a real misassignment of error-tracker triage.
- Load-balancing queries fetch only `todo,in_progress`; blocked tasks don't consume capacity and must not count toward load.
- Capability-tiered routing: heavy-implementation → standard-implementation → light-implementation. Route by task weight, not round-robin.
- **Data residency:** any agent touching client or employer code uses EU-resident, Article 28 DPA-backed inference only. Route open-weight models through an EU-domiciled OpenAI-compatible gateway. Leave EU gateway env blocks as clearly marked stubs if the account isn't provisioned yet.

## Routine design patterns (mandatory building blocks)

Every mutating routine includes ALL of:

1. **Cheap filter / early exit** — first step decides "anything to do?" using the cheapest possible check (label query, single API call) before any model reasoning.
2. **SHA-based state tracking** — act on a (comment, head-SHA) pair; a new push invalidates handled-state.
3. **Deduplication markers** — hidden HTML comments in bot output (`BUILD-FAIL-REPORT`, `AI-REVIEW-HANDLED`) so reruns detect prior work.
4. **Circuit breakers via labels** — `auto-fix-attempts:N` incremented per attempt; at threshold apply `auto-fix-blocked` and stop touching the PR. Never remove the block label automatically.
5. **Severity-gated autonomy** — define which finding severities the routine may act on autonomously vs report-only (security findings default to advisory-only).
6. **Idempotency** — commit-on-green; a rerun with nothing to do must produce zero side effects.
7. **Registry entry** — every new label/marker gets added to the fleet's label/marker registry to prevent collisions as mutating loops multiply.

No-LLM-in-irreversible-paths rule: for merge automation prefer Renovate native `automerge` + GitHub auto-merge over an agent; if agent judgment is wanted, use a dedicated merge-only credential restricted to dependency-bot-authored PRs.

## Output format for new routines

```
# Routine: <name>
Agent: <role tier> (<model/tier>) — justification per assignment rules
Trigger: <cron> (rationale)
## Instructions (paste-ready routine text)
## Labels & markers introduced (registry entries)
## Circuit breaker config
## Failure & escalation behavior
## Cost estimate (calls/day at trigger frequency)
```

Proven routines to model against: a comment/AI-review resolver (standard-implementation tier), a read-only build watcher (mechanical-QA tier), error-tracker triage (QA tier — has shown a ~30% failure rate, worth investigating before trusting it further), and dependency-bot PR review (mechanical-QA tier on the cheap pool).
