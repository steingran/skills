# skills

Claude skills for .NET architecture work, multi-agent development with Paperclip, and EU-regulatory vendor vetting.

Each directory is one skill: a `SKILL.md` with YAML frontmatter (`name`, `description`) and optional `references/` loaded on demand.

## Skills

| Skill | Purpose |
|---|---|
| `delivery-discipline` | Scope contracts, anti-over-engineering rules, and PR lifecycle enforcement for GPT-5.6-family agents |
| `gather-suggestions` | Roll up delivery-discipline `SUGGESTIONS` entries from a GitHub issue and its sub-issues into one comment |
| `implement-suggestions` | Turn one gathered suggestion into a tracked work item and implement it via delivery-discipline |
| `paperclip-routine-author` | Routine design, agent assignment, and fleet configuration for Paperclip AI |
| `dotnet-pr-review` | Structured .NET/C# and TypeScript PR review, with a diff-access decision tree |
| `implementation-handoff` | Self-contained implementation briefs for a fresh Claude Code session or agent |
| `eu-jurisdiction-vet` | CLOUD Act / GDPR / data-residency vetting of vendors, models, and hosting |

## Layout

```
<skill-name>/
├── SKILL.md          # frontmatter + instructions, kept under ~500 lines
└── references/       # loaded only when SKILL.md points at them
```

## Conventions

- The `description` field is the only trigger mechanism — it states both what the skill does and when to reach for it. Skills under-trigger far more often than they over-trigger, so descriptions are written to be explicit about entry points.
- Keep `SKILL.md` short enough to sit in context comfortably; push detail, tables, and paste-ready blocks into `references/`.
- Prefer imperative instructions and concrete thresholds over principles. Explain why a rule exists when the reasoning is load-bearing.
- Skills are written to be organization-neutral. Project-specific conventions belong in a filled-in profile kept outside this repository — see `dotnet-pr-review/references/project-profile.template.md` — or in the repo's own `AGENTS.md`.
- No employer, client, venture, or agent names appear in any skill. Anything organization-specific — repository names, agent rosters, vendor approvals tied to a named project — goes in a private profile or overlay, not here.

## Packaging

```bash
# zip a single skill for upload to claude.ai
cd <skill-name> && zip -r ../<skill-name>.skill . && cd ..
```

## Installing locally

Point the runtime's skills path at this checkout, or symlink individual skills:

```bash
ln -s "$PWD/delivery-discipline" ~/.claude/skills/delivery-discipline
```
