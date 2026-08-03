---
name: implement-suggestions
description: Pick one suggestion gathered from a GitHub issue (or its sub-issues) — an ADR candidate, a missing check, or another delivery-discipline SUGGESTIONS entry — turn it into a tracked work item in whatever issue tracker the project actually uses, and implement it. Use when asked to "start implementing suggestions", "act on a suggestion", "pick a suggestion to work on", or "implement the suggestion from issue #X". Builds on `gather-suggestions` for the list and hands execution off to `delivery-discipline`.
---

# Implement Suggestions

Bridges a gathered suggestion (recommendation-only, per [delivery-discipline](../delivery-discipline/SKILL.md)) into real, tracked, delivered work — one suggestion per run.

## 1. Get the list

- Target issue is always explicit (number or URL), same as `gather-suggestions`.
- If a `<!-- SUGGESTIONS-ROLLUP:{issue_number} -->` comment already exists on the target issue, read it. If not, run `gather-suggestions` first — do not re-derive the extraction logic here.
- If there are zero suggestions, say so and stop. There is nothing to implement.

## 2. Ask which one

List every suggestion found, numbered, with its source. **Ask the user which single one to act on now** — never implement more than one per run, even if several are listed. Working through the rest is a future, separate run, not a queue to batch through here.

## 3. Determine the tracker in use

Do not default to GitHub Issues just because the suggestion was found there. Check, in order:

1. `CLAUDE.md` / `AGENTS.md` in the repo for a stated tracker or project key convention.
2. Signals in existing issues/PRs: a Jira-style key (`PROJ-123`) in titles, a Linear branch-naming pattern (`username/eng-123-...`), or an existing sync integration comment on the issue.
3. If still ambiguous, ask the user once which tracker to file the work item in. Don't ask again later in the same run.

## 4. Create the work item

Create it nested under the parent issue where the tracker supports that (GitHub sub-issue, Linear sub-issue via parent, Jira sub-task via parent field). Title: a short imperative summary of the suggestion. Body: the full suggestion text plus a link back to the source comment. Check first whether a matching work item already exists (someone tracked this suggestion already) and reuse it instead of creating a duplicate.

## 5. Implement it

Hand off to `delivery-discipline` for everything from here: scope contract, narrowest-reading implementation, PR referencing the new work item, terminal PR state, close-out block (including its own `SUGGESTIONS` line for anything newly noticed — that's the same mechanism, not a special case). This skill does not restate those rules; it only gets the work item to the point where they apply.

## Boundaries

- One suggestion implemented per run. The rest stay listed (and, once step 4 has run for them in a later invocation, tracked) — not built ahead of being asked.
- If the chosen suggestion turns out to be bigger than a single work item once scoped, that's a normal delivery-discipline footprint-divergence stop, not a reason to have skipped tracking it first.
