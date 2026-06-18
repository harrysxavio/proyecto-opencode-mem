---
name: branch-pr
description: Prepare branches and pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs.
---

# branch-pr

## When to use

Prepare branches and pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs.

## Runtime contract

Use this skill to verify branch state, summarize scope, list tests, and avoid hidden unrelated changes before PR creation.

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