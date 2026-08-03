# Agent roster — role tiers

Roles, not names. The fleet's actual agent names live in the user's private Paperclip configuration; ask for the mapping when a routine has to be assigned to a concrete agent, and keep it out of this repository.

Model assignments below reflect a working configuration as of June 2026 — confirm before load-bearing changes.

| Role tier | Responsibility | Model / tier | Adapter | Constraints |
|---|---|---|---|---|
| heavy-implementation | Large or ambiguous .NET work | top-tier reasoning model, high effort | codex | Highest capability, highest cost — reserve for weight |
| standard-implementation (×2) | Routine .NET feature work | mid-tier model, medium effort | codex | Runs comment/AI-review resolver routines |
| light-implementation | Small, well-scoped changes | open-weight model | opencode_local | One attempt then escalate — **never** assign self-triggering routines |
| devops-primary | Infrastructure and CI | mid-tier model, medium effort | codex | |
| devops-light | Mechanical infra chores | open-weight model | opencode_local | |
| qa-review | Test and error-tracker triage | mid-tier model, medium effort | codex | Error-tracker triage has shown ~30% failure — verify before trusting |
| mechanical-QA | High-frequency, low-judgment loops | cheap codex-family variant | codex | Separate quota pool — preferred for build watchers and dependency-bot review |
| principal-reviewer | Substantive PR review | mid-tier model, high effort | codex | Default delegate for recurring review work |
| documentation | Docs and ADRs | mid-tier model, auto effort | codex | |
| orchestration (×2) | Planning and final sign-off | top/mid-tier | codex | Sign-off only — recurring reviews delegate down, never up |

## Quota & auth constraints

- Under subscription (account) auth rather than API-key auth, some model strings are rejected outright even though the model exists. Verify the exact string against the adapter before writing it into a routine.
- Cheap-model variants may sit in a **separate quota pool** from the main window — route mechanical volume there deliberately.
- The cheap-model slot must match the primary model's adapter: OpenAI-family primaries take OpenAI-family cheap models; `opencode_local` primaries take open-weight cheap models.
- Open-weight models are only as sovereign as their serving location. A permissively licensed model served from a US-controlled endpoint is still exposed — route via an EU-domiciled gateway for residency-constrained code.

## Multi-tenancy

- Per-company isolation exists from v2026.618.0 onward. Configure one company per client or venture, and ensure routines never cross company boundaries — a routine with repo access in two companies is a data-mixing incident waiting to happen.
