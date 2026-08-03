# Security Policy

This repository holds `SKILL.md` files: natural-language instructions that get loaded directly into an agent's context and can influence its behavior. That makes the main risk here different from a typical code repo — a malicious or careless contribution doesn't need to compile or run to cause harm, it just needs to be read by an agent.

Report the following privately rather than opening a public issue:

- A `SKILL.md` or reference file containing hidden or obfuscated instructions (e.g. prompt injection, instructions to exfiltrate data, disable safety behavior, or act against the user's interest) that made it past review.
- Any skill that instructs an agent to run code, hit a network endpoint, or take an action it doesn't clearly disclose in the skill's visible description.
- Any other supply-chain concern with a skill in this repo (e.g. typosquatting a well-known skill name).

## Reporting

Email **stein.gran@pm.me** with a description of the issue and, if applicable, the file/PR in question. Please don't file a public issue for anything that could be actively exploited before a fix lands (e.g. a merged skill with hidden malicious instructions) — report it privately first so it can be pulled.

## Scope

This policy covers the content of this repository (skill instructions and any scripts under `references/`). It does not cover the Claude Code product itself — for that, see [Anthropic's security disclosure process](https://www.anthropic.com/responsible-disclosure-policy).
