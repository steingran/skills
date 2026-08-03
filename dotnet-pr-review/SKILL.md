---
name: dotnet-pr-review
description: Perform structured code reviews of pull requests or diffs in .NET/C# microservice repositories and their TypeScript tooling. Use this skill whenever the user asks to "review a PR", "code review", shares a GitHub PR URL, pastes a diff, or asks about best practices, robustness, resiliency, or test coverage of a change — even if they don't say "review" explicitly. Also use it when a PR review request fails because the diff can't be retrieved, since this skill contains the access decision tree.
---

# .NET PR Review

Structured code review for .NET/C# microservices and the TypeScript tooling around them.

**Standing rule:** results are delivered in the chat only. Never post comments, reviews, or any content to the PR itself, even when a GitHub tool with write access is available. Do not ask for confirmation of this.

## Step 0: Get the diff (access decision tree)

Access is historically the failure point, not the review. Resolve it in this order and stop at the first that works:

1. **Pasted diff or attached patch** — most reliable path. If the user pasted `gh pr diff` output or attached a patch, go straight to the review. Suggest this early rather than after three failed attempts.
2. **GitHub connector in the current session** — check the tool registry (`tool_search` for "github pull request"). Note: an MCP server configured locally for Claude Code or Claude Desktop will **never** surface in a claude.ai web session — those are separate tool registries. If no GitHub tool appears, say so once, clearly, and point at Settings → Connectors. Do not re-search repeatedly.
3. **Claude Code session** — the locally configured GitHub MCP server is available here; use `get_pull_request`, `get_pull_request_files`, `get_pull_request_diff`.
4. **Browser extension fallback** — works but fragile. `https://github.com/<org>/<repo>/pull/<n>.diff` redirects to `patch-diff.githubusercontent.com` with a `?token=` parameter, and large text slices trigger content filtering. If used: read the diff in small chunks (<2KB) immediately after fetch, before any navigation, and never navigate to a different origin (session storage is lost). Prefer targeted DOM extraction (`querySelectorAll('[data-tagsearch-path]')`) over full page text on `/files` views.
5. **web_fetch** — fails on private repositories (404). Don't spend a turn on it.

If every path fails, offer exactly two options — paste `gh pr diff <n> --repo <org>/<repo>`, or run the review in Claude Code — and then stop.

## Review scope

Evaluate every PR against three pillars, in this order:

1. **Correctness & robustness** — error handling, retry and circuit-breaker behavior, cancellation token propagation, guard clauses, idempotency, concurrency, transaction boundaries, resource disposal.
2. **Coding best practices** — consistency with established repository patterns, naming, layering, dependency direction, async hygiene, logging quality.
3. **Test coverage** — unit tests for new logic (especially mappers, classifiers, and anything with branching business rules), integration test parity when refactoring, negative-path tests, cancellation assertions, and the coverage gate on new code. Zero coverage on new code is always a finding.

`references/dotnet-review-checklist.md` has the per-area detail: resiliency, typed-client refactors, async and threading, logging and observability, tests, security and residency. Read it before writing findings.

## Project context

Repository-specific conventions beat generic best practice, and inventing conventions is worse than asking. Establish context in this order:

1. A project profile supplied by the user or present in the repo — see `references/project-profile.template.md` for the shape. Keep filled-in profiles outside this repository if they contain employer-internal detail.
2. `AGENTS.md`, `CONTRIBUTING.md`, `.editorconfig`, or an architecture doc in the repo.
3. The surrounding code in the diff itself — an established pattern visible in neighboring files is a convention.

If a change deviates from a pattern the codebase clearly uses elsewhere, that is a finding. If no pattern is discoverable, review against general .NET practice and say which conventions you assumed.

## Output format

ALWAYS use this exact structure:

```
# Review: <repo> PR #<n> — <title>

## Verdict
One paragraph: merge-ready / merge with fixes / needs work, and why.

## Findings
### 1. <Short title> — [HIGH|MEDIUM|LOW]
What, where (file:line if known), why it matters, recommended fix.
(repeat per finding)

## Test coverage assessment
What's covered, what's missing, specific tests to add.

## Summary table
| # | Finding | Priority | Action |
```

Rules: severity reflects production risk, not style taste. Praise briefly what's done well — one or two lines, no more — because it calibrates trust in the criticisms. If reviewing from partial context (PR description, bot summaries, no full diff), state that limitation at the top and mark inferred findings as inferred.
