---
name: web-design-guidelines
description: Review UI/UX and accessibility quality. Trigger: frontend audit, UI review, accessibility, visual quality, or design gate.
---

# web-design-guidelines

## When to use

Review UI/UX and accessibility quality. Trigger: frontend audit, UI review, accessibility, visual quality, or design gate.

## Runtime contract

Use this skill to check hierarchy, spacing, contrast, keyboard flow, states, copy, responsiveness, and accessibility before shipping UI.

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