---
name: cognitive-doc-design
description: Write documentation that reduces cognitive load. Trigger: README, guide, onboarding, RFC, architecture doc, or beginner explanation.
---

# cognitive-doc-design

## When to use

Write documentation that reduces cognitive load. Trigger: README, guide, onboarding, RFC, architecture doc, or beginner explanation.

## Runtime contract

Use this skill to structure docs for beginners and seniors: start with the mental model, then flow, examples, commands, and troubleshooting.

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