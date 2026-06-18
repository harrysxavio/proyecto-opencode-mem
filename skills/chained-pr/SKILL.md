---
name: chained-pr
description: Split oversized work into chained or stacked review slices. Trigger: PRs over 400 lines, large refactors, or review budget risk.
---

# chained-pr

## When to use

Split oversized work into chained or stacked review slices. Trigger: PRs over 400 lines, large refactors, or review budget risk.

## Runtime contract

Use this skill when a change is too large for one review. Define boundaries, dependency order, rollback points, and what each slice proves.

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