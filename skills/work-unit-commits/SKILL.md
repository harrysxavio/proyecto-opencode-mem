---
name: work-unit-commits
description: Plan implementation as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code.
---

# work-unit-commits

## When to use

Plan implementation as reviewable work units. Trigger: implementation, commit splitting, chained PRs, or keeping tests and docs with code.

## Runtime contract

Use this skill when a change needs to be split into small commits that reviewers can understand. Keep tests and docs with the code they prove. Prefer one concern per commit.

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