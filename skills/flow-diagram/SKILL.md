---
name: flow-diagram
description: Create text or Mermaid diagrams of request and system flows. Trigger: flow, diagram, sequence, architecture map, or explain step by step.
---

# flow-diagram

## When to use

Create text or Mermaid diagrams of request and system flows. Trigger: flow, diagram, sequence, architecture map, or explain step by step.

## Runtime contract

Use this skill to turn a process into a small flow diagram with actors, decisions, inputs, outputs, and failure paths.

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