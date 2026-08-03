---
name: eu-jurisdiction-vet
description: Vet any vendor, cloud service, AI model provider, SaaS tool, or hosting option for EU data sovereignty — CLOUD Act exposure, GDPR/Article 28 DPA availability, data/inference residency, and EU AI Act relevance. Use this skill whenever the user asks "is X CLOUD Act clean", "can we use X for production or customer data", "EU alternative to X", evaluates a new tool/provider/model endpoint, or mentions data residency, jurisdiction, sovereignty, or subprocessors — even in passing during an architecture discussion.
---

# EU Jurisdiction Vet

Standard procedure for assessing whether a vendor is safe for EU-sovereign workloads. The baseline requirement for employer production code and data, and for venture customer data: EU-resident processing, Article 28 DPA available, and **no CLOUD Act reach** — meaning no US parent, subsidiary, or "possession, custody, or control" chain that a US court order could traverse.

## Vetting procedure

Run these checks in order. Search the web for current facts — corporate structures and subprocessor lists change; never assert from memory alone for a verdict.

1. **Ultimate corporate parent.** Trace ownership to the top. A US parent anywhere in the chain = CLOUD Act exposed, regardless of where servers sit. EU subsidiaries of US companies do not escape (Microsoft Ireland precedent → CLOUD Act codified exactly this reach).
2. **"Sovereign cloud" claims.** Hyperscaler sovereign offerings (AWS European Sovereign Cloud, Azure EU Data Boundary, Google sovereign partnerships) *reduce* but do not *eliminate* exposure — the US parent retains legal control. Classify as CONDITIONAL at best.
3. **Processing/inference residency.** Where does the data actually go at runtime? Model providers: where is inference served (not just where the company is domiciled)? Verify region pinning is contractual, not best-effort.
4. **Article 28 DPA.** Is a signable DPA available at the user's tier? SCCs alone with a US processor don't clear the bar post-Schrems II reasoning.
5. **Subprocessor chain.** Read the current subprocessor list. An EU vendor running on AWS/GCP/Azure re-imports exposure (the "Vercel pattern": US company + US-hyperscaler infra = double exposure).
6. **Regulatory overlay.** Note EU AI Act obligations if AI is involved (full enforcement Aug 2, 2026; Annex III high-risk obligations deferred to Dec 2027 — relevant to AI-assisted decision support in public-funding and grant workflows) and the proposed CADA regulation where relevant.

## Verdict tiers

ALWAYS conclude with exactly one:

- **CLEAR** — EU/EEA-domiciled top to bottom, EU-resident processing, DPA available, no US links in the subprocessor chain for the data path in question.
- **CONDITIONAL** — usable with specific mitigations (e.g., region pinning + no customer data, or only for non-sensitive workloads). State the exact conditions.
- **EXPOSED** — CLOUD Act reachable or residency unverifiable. State the shortest path a US order would take.

## Known verdicts (prior assessments — re-verify if load-bearing)

| Vendor | Verdict | Notes |
|---|---|---|
| Mistral | CLEAR | French-domiciled, no US parent, inference in Sweden. Cleanest frontier-adjacent option. |
| EUrouter | CLEAR (preferred) | EU-domiciled OpenAI-compatible gateway for open-weight models; Article 28 DPA available. |
| Hetzner | CLEAR | German. Approved migration target (+ Coolify). |
| Scaleway / OVHcloud | CLEAR | French. Scaleway Serverless Containers is an approved deployment target. |
| Vercel | EXPOSED | Double exposure: US company on AWS. Migration away planned. |
| AWS European Sovereign Cloud | CONDITIONAL/EXPOSED | US parent retains control. |
| Ollama Cloud | EXPOSED | Serves GLM-class models from the US. |
| Proton Mail | CLEAR but incompatible with IMAP workflows | E2E encryption blocks native IMAP (broke Instantly.ai warmup). |
| Domeneshop / mailbox.org | CLEAR | Approved registrar/mail options. |

## Output format

```
# Jurisdiction vet: <vendor>
## Verdict: CLEAR | CONDITIONAL | EXPOSED
## Ownership chain
## Data path & residency
## DPA status
## Subprocessors of concern
## Conditions / mitigations (if CONDITIONAL)
## Sources
```

Keep it under a screen and a half unless asked for depth. Cite sources for corporate-structure and residency claims. If the assessment is for self-hosted open weights on an EU provider, note that this remains the strongest position for full CLOUD Act immunity.
