---
name: judgment-day
description: Run adversarial review before accepting important work. Trigger: dual review, deep review, critical diff, or architecture challenge.
---

# judgment-day

## When to use

Run adversarial review before accepting important work. Trigger: dual review, deep review, critical diff, or architecture challenge.

## Runtime contract

Use this skill to challenge assumptions, compare evidence, identify false positives, and require fixes before claiming readiness.

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