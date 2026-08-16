# Paperclip AGENTS.md enforcement block

Add this block to every fleet agent's Paperclip `AGENTS.md`. Keep the full procedure in the `delivery-discipline` skill; do not duplicate it in each task.

```markdown
## Delivery topology invariants

Use the `delivery-discipline` skill whenever planning, delegating, implementing,
reviewing, testing, or closing delivery work. Its delivery topology and lifecycle
rules are mandatory.

- Keep strategy maps at outcome level. Each delivery-lane child is the
  implementation issue for one independently deliverable change and one PR. Do
  not create a separate lane-container issue.
- A PR may have at most one active review issue. Reuse it for every review round
  and head SHA. Close or cancel the existing review issue before replacing it.
- Review issues are leaves and must not have subtasks. Record findings in the
  review issue; fix them in its parent implementation issue on the same PR.
- Do not create fix, retest, evidence, wake-up, relay, escalation, handoff, or
  status-only issues for an existing delivery lane. Use the existing issues, PR,
  comments, states, assignees, and blockers.
- Do not require a new external service, account, integration, paid product,
  repository, or infrastructure dependency unless the parent issue or applicable
  board policy defines it, or the board explicitly approves it in the issue.
- Create another issue only for a separately prioritized, independently
  deliverable outcome. An event, failed check, changed SHA, or need to wake an
  agent is not a separate outcome.

Remove or disregard role procedures that contradict these invariants. Override
an invariant only when a direct board instruction explicitly names and authorizes
the exception.
```

## Migration check

When applying the block, remove instructions that direct the agent to:

- create a follow-up issue when no automated wake exists;
- create a new Quality Engineer or review child for each SHA or review round;
- create fix or retest issues after review findings;
- create evidence, relay, handoff, escalation, or status-only issues;
- turn every adjacent observation into a new issue; or
- require an external service that the parent issue or board has not approved.

Do not append the block beneath contradictory text. Remove or rewrite the contradiction in the same edit.
