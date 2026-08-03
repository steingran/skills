---
name: implementation-handoff
description: Generate an implementation handoff package — a self-contained implementation brief that a fresh Claude Code session can execute without access to this conversation. Use this skill whenever the user says "handoff package", "handoff for Claude Code", "brief for implementation", asks to prepare a spec for building something, or when a planning conversation reaches the point where an artifact (scanner, website, service, CLI) is ready to be built. Also use it to structure specs the user's Paperclip agents will execute.
---

# Claude Code Handoff Package

A handoff package must survive total context loss: the executing session knows nothing about this conversation. Every decision already made goes in as a locked decision; every open question goes in explicitly as a decision-required — never leave an ambiguity for the implementer to guess silently.

## Package structure

ALWAYS use this exact template, one markdown file per buildable artifact:

```
# Handoff: <artifact name> (<venture/project>)

## 1. Mission
One paragraph: what to build, for whom, and the definition of done.

## 2. Context the implementer needs
Who the user is (senior architect, .NET/TS), which repo/org this lives in,
how this artifact relates to sibling artifacts.

## 3. Decisions — LOCKED
Bulleted, each with a one-line rationale. Naming, stack, hosting,
license, package names, API shapes already agreed. These are not
to be revisited by the implementer.

## 4. Decisions — REQUIRED (implementer must ask or choose explicitly)
Each with the options considered and the user's leanings if known.

## 5. Technical architecture
Components, data flow, storage, external services. Include concrete
file/repo layout when known.

## 6. Constraints (non-negotiable)
- EU data sovereignty: EU-resident services only, no CLOUD Act-exposed
  vendors in the data path (Hetzner/Scaleway defaults; Mistral or
  EUrouter for inference). Include the project-specific version.
- Anything security/compliance/licensing specific to this artifact.

## 7. Milestones
Ordered, each independently verifiable. v0 scope ruthlessly minimal.

## 8. Verification
How the implementer proves each milestone works (commands, expected
output, test strategy). Include any CI gates (e.g., an "irony check"
pattern: build fails if a US-hosted resource appears in the output).

## 9. Out of scope
Explicit non-goals, to prevent scope creep.

## 10. Assumptions
Everything asserted without verification, so the implementer can
re-check what's load-bearing.
```

## Writing rules

- Concrete over abstract: exact package names, exact domains, exact env var names, exact cron strings. "Use a database" is a failure; "Postgres 16 on Hetzner, schema in §5" is the standard.
- Established stack defaults unless the conversation overrode them: TypeScript/Node or .NET 8+, Astro for static sites, Hetzner+Coolify or Scaleway for hosting, Plausible analytics, self-hosted fonts, GitHub Actions CI.
- If the artifact calls an LLM, specify provider, region, and DPA status — never leave inference routing implicit.
- Flag anything in the source conversation that was uncertain or version-sensitive (API flags, tool versions) with an instruction to verify (`--help`, `--version`) rather than trust.
- Target length: complete but lean — a package the implementer can hold in context alongside the codebase. Split into multiple packages rather than exceeding ~600 lines.
