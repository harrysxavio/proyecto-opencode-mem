---
name: sql-learning
description: Capture reusable SQL lessons and business rules. Trigger: completed SQL cleanup, inferred rule, repeated query issue, or reusable pattern.
---

# sql-learning

## When to use

Capture reusable SQL lessons and business rules. Trigger: completed SQL cleanup, inferred rule, repeated query issue, or reusable pattern.

## Runtime contract

Use this skill after SQL work to record reusable transformations, caveats, validation rules, and evidence without storing secrets.

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