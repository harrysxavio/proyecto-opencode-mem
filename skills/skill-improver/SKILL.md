---
name: skill-improver
description: Audit and improve existing skills. Trigger: improve skills, audit skills, refactor skills, or skill quality.
---

# skill-improver

## When to use

Audit and improve existing skills. Trigger: improve skills, audit skills, refactor skills, or skill quality.

## Runtime contract

Use this skill to keep skills narrow, triggerable, testable, portable, and free of local paths or huge embedded protocols.

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