---
name: gather-suggestions
description: Collect delivery-discipline SUGGESTIONS entries (ADR candidates, missing checks, other recommendations) from a GitHub issue and its sub-issues, and post them as one consolidated comment on that issue. Use when asked to "gather suggestions", "roll up suggestions", "collect suggestions from an issue and sub-issues", or "post a suggestions summary" — for the issue currently being discussed or a specified issue number/URL. Pairs with `implement-suggestions` for acting on what's found.
---

# Gather Suggestions

Rolls up `SUGGESTIONS:` lines left by [delivery-discipline](../delivery-discipline/SKILL.md) close-out blocks — scattered across an issue and its sub-issues — into one comment, so nothing sits unread in a thread nobody revisits.

## Scope

- **Target issue is always explicit** — a number or URL. Do not guess "the current issue" from branch name or recent context; ask if it isn't clear which issue is meant.
- **Sources scanned**: the target issue's description and comments, plus the description and comments of its direct sub-issues (one level — a sub-issue's own sub-issues are not recursed into).
- **Not scanned in this version**: PR descriptions/comments linked to the issue, even though `SUGGESTIONS` typically originates there. Naming this as a known gap is enough — do not build PR-scanning into this skill unprompted; that's a separate, larger change (auth/pagination across PRs) and belongs in its own work item if wanted.

## Finding sub-issues

```bash
gh api repos/{owner}/{repo}/issues/{issue_number}/sub_issues --jq '.[].number'
```

If that 404s (native sub-issues not enabled on the repo/plan), fall back to parsing the issue body for a task list of issue references (`- [ ] #123`, `- [x] #123`) and treat those as the sub-issue set instead.

## Extracting suggestions

Pull the target issue's and each sub-issue's body plus all comments:

```bash
gh issue view {number} --repo {owner}/{repo} --json body,comments,url
```

In each body/comment, look for a line matching `SUGGESTIONS:` (case-insensitive), typically inside a close-out block. Capture that line and any immediately following indented continuation lines, stopping at a blank line, the next `ALL-CAPS FIELD:` label, or a closing code fence. Treat `SUGGESTIONS: none` (or empty) as nothing to report — do not list it.

## Posting the rollup

- Post **on the target issue**, even when a suggestion came from a sub-issue — always roll up to the top-level issue given as the target, not wherever the suggestion happened to surface.
- If nothing was found anywhere, **do not post an empty comment** — report that back to the user instead. An empty rollup is a process artifact with no gate.
- Mark the comment with a hidden marker so re-runs update it instead of duplicating:

```
<!-- SUGGESTIONS-ROLLUP:{issue_number} -->
## Suggestions rollup

- **From #{source_issue}** ([comment]({url})): {suggestion text}
- **From #{source_issue}** ([comment]({url})): {suggestion text}
```

Before posting, check for an existing comment carrying that marker (`gh issue view {number} --json comments --jq '.comments[] | select(.body | contains("<!-- SUGGESTIONS-ROLLUP"))'`); if found, edit it in place via `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{comment_id} -f body=...` rather than posting a second one.

## Output

Tell the user how many suggestions were found, from how many sub-issues, and link the posted (or updated) comment. If nothing was found, say so plainly instead of posting.
