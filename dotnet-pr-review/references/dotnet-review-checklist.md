# .NET review checklist by area

Findings should cite the specific risk, not the rule. "Retries a permanent failure, so a 400 becomes five 400s and a delayed alert" lands; "violates retry policy" does not.

## Resiliency (retry / circuit breaker)

- Exception classification must distinguish transient from permanent. Retrying permanent failures is a HIGH finding — it multiplies load and delays the real error surfacing.
- Circuit breaker state must be shared at the intended scope (per-endpoint vs global). A breaker instantiated per-call protects nothing.
- Bounded retry counts, jitter on backoff, and no retry nested inside another retry (amplification: 3×3 is 9 calls, not 3).
- Scheduled jobs (Quartz or similar): misfire handling, and concurrent-execution guards (`[DisallowConcurrentExecution]`) where the job is not reentrant.
- Timeouts on every outbound call. A missing timeout is a latent hang, not a style issue.

## Typed client / connector refactors

Common shape: replacing a legacy generic or OData-style client with typed `I<Entity>Client` interfaces plus source-generated mappers (Mapperly or similar).

- Interface naming consistency — typos in generated interface names propagate everywhere and are cheap to catch in review (a real past example: a single-l `ICancelationReasonClient`).
- Mappers get their own unit tests. Hardcoded business rules inside a mapper (defaulting a flag, injecting a constant) are findings: that belongs in domain logic, or must be documented at the mapping site.
- Verify the old path is fully removed, not orphaned. Dead-but-reachable legacy clients are how a "completed" migration silently isn't.
- CancellationToken propagates end-to-end and is asserted in at least one test.

## Async & threading

- No `async void` outside event handlers; no `.Result` or `.Wait()`; no fire-and-forget without error capture.
- `ConfigureAwait` per repository convention — consistency matters more than which choice.
- Async methods that never await are a smell worth flagging; so is sync-over-async in a hot path.

## Logging & observability

- Structured templates (`{OrderId}`), never string interpolation into the message — interpolation destroys queryability in the log backend.
- No PII or tenant-identifying data at Information level.
- Correlation IDs preserved across connector and service boundaries.
- New failure paths should be observable: a caught-and-swallowed exception with no log is a finding.

## Shared package changes

- Changes to shared/common packages ripple to every consumer. Review semver discipline on any public API change and flag breaking-change risk explicitly, naming likely consumers if known.
- Consumers pinning versions means a breaking change is discovered at upgrade time, far from this PR — that's why it belongs in the review verdict, not a footnote.

## Tests

- xUnit conventions; new public behavior needs unit tests; connector changes need integration parity.
- Coverage gate on new code (SonarQube or equivalent): 0% on new code is always flagged.
- Long-running integration additions (Docker Compose stacks spinning up multiple containers) should note CI cost in the PR — not a blocker, but reviewers should see it.
- Negative paths and cancellation are the two most commonly missing test categories in this style of codebase.

## Security & data residency

- Authorization check on every new endpoint; conditional/attribute-based rules expressed in the authorization layer (e.g. SpiceDB Caveats), not scattered through handlers.
- New third-party calls and inference endpoints: EU residency and an Article 28 DPA required. Routing customer data to a US-controlled endpoint is a HIGH finding.
- Multi-tenant services: check tenant isolation in any prompt, context, or query construction. Cross-tenant leakage through a shared cache key or an unfiltered query is the classic failure.
- Secrets never in committed code or config; use the established secrets path (task environment or parameter store).

## Merge hygiene

- Recommend squashing before a rebase-merge when commit history is noisy.
- Flag unrelated changes bundled into the PR — they belong in their own change, and they make the diff harder to review than it needs to be.
