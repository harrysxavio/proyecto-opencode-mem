---
name: issue-creation
description: Create actionable issues with evidence and acceptance criteria. Trigger: bug reports, feature requests, or backlog items.
---

# issue-creation

## When to use

Create actionable issues with evidence and acceptance criteria. Trigger: bug reports, feature requests, or backlog items.

## Runtime contract

Use this skill to write concise issues with problem, evidence, expected behavior, acceptance criteria, and risk.

## Output

Return a compact result with:

- decision or recommendation;
- evidence checked;
- risks and tradeoffs;
- next action.

## Boundaries

- Do not include private local paths in generated artifacts.
- Do not make destructive changes without an explicit user request.
- Prefer small, reviewable outputs over broad audits.