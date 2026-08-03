# Word and phrase watchlist

## Filler and inflation words — cut or replace

| Instead of | Use |
|---|---|
| leverage | use |
| utilize | use |
| seamless / seamlessly | smooth, works without extra steps |
| robust | solid, reliable — or state the specific property |
| delve into | look into, check |
| unlock | enable, allow |
| streamline | simplify, shorten |
| facilitate | help, let |
| in order to | to |
| a variety of / a number of | state the actual count, or "several" |
| it is important to note that | (delete — just state the fact) |
| comprehensive | full, complete — or name what's covered |
| cutting-edge / state-of-the-art | (delete, or name the actual capability) |
| holistic | (delete, or state what's included) |
| synergy / synergize | (name the actual effect) |
| bespoke | custom |

## Invented abbreviations — the core failure mode

Don't do this:

> The Deployment Verification Workflow (DVW) checks the Build Artifact Manifest (BAM) before the Release Gate Controller (RGC) approves promotion.

Nothing here is a real, externally recognized abbreviation — three acronyms were invented in one sentence, and a reader has to hold all three in memory with no prior exposure to them.

Do this instead:

> The deployment check verifies the build artifact list before release is approved.

If a term truly recurs dozens of times in one long document, define it once in full the first time, keep the full term where it's not disruptive, and only abbreviate where already standard in the field (API, URL, ID, CI, PR). When in doubt, don't abbreviate — spelling it out costs a few words; a made-up acronym costs the reader a lookup.

## Noun-cluster breakup examples

| Before | After |
|---|---|
| distributed database connection pool timeout retry handler | the part that retries a database connection after a pool timeout |
| user authentication token refresh failure notification system | the system that warns when a login token fails to refresh |
| multi-tenant configuration override precedence resolution logic | the logic that decides which tenant's config setting wins |

## Passive-to-active examples

| Passive | Active |
|---|---|
| The request is processed by the handler before validation is performed. | The handler processes the request, then validates it. |
| Errors were encountered during the build. | The build failed with these errors. |
| The file will be deleted once processing has been completed. | The system deletes the file after processing finishes. |
