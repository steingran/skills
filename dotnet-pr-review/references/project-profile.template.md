# Project profile — template

Fill this in per organization or repository set and keep the filled version **outside this repository** if it names internal systems. Paste it into the conversation, drop it in the repo as `AGENTS.md`, or keep it in a private skills overlay.

The point is to give the review concrete conventions to check against, so findings are about this codebase rather than generic .NET advice.

```markdown
## Stack
- Runtime / framework:               e.g. .NET 9, ASP.NET Core
- Hosting & regions:                 e.g. AWS Fargate, eu-north-1
- Tooling language:                  e.g. TypeScript/Node
- Data access:                       e.g. EF Core / Dapper
- Messaging / scheduling:            e.g. Quartz, SQS

## Repositories
| Repo | Role | CI gates worth knowing |
|---|---|---|
| <name> | <what it does> | <blocking vs advisory checks> |

## Shared packages
- Package names, registry, and which repos consume them
- Versioning policy (pinned? floating? semver enforced?)

## Established patterns (deviations are findings)
- <e.g. typed I<Entity>Client + Mapperly mappers, replacing legacy OData access>
- <e.g. the reference implementation to mirror: X>

## Cross-cutting infrastructure
- Feature flags:                     e.g. Unleash, instanceTag bound to HOSTNAME
- Logging:                           e.g. Serilog → hosted log backend, structured only
- Authorization:                     e.g. SpiceDB, Caveats for conditional access
- Search:                            e.g. Typesense
- External connectors:               <systems and protocols>

## Constraints that make findings HIGH
- Data residency rules
- Multi-tenancy isolation requirements
- Anything with regulatory exposure

## Merge conventions
- Squash / rebase policy, review requirements, coverage gate threshold
```
