---
name: context-pack-builder
description: Build minimal context packs for broad work, SDD phases, research, code review, and memory-heavy requests.
---

# Context Pack Builder

Use this skill before loading broad context or delegating to a subagent.

## Context Pack schema

```json
{
  "classification": "tiny|small|memory|docs|code|sdd|research|security|qa",
  "token_budget": 3000,
  "included": [],
  "excluded": []
}
```

## Inclusion rule

Include only items with a specific reason. Prefer references and short summaries over full content.

## Budget defaults

- `tiny`: no pack.
- `small`: local evidence only.
- `memory`: at most three memories.
- `docs`: at most three sections.
- `sdd`: phase input references, not full history.
- `research`: source summaries plus links.

## Exclusion rule

Exclude duplicate, sensitive, stale, or low-relevance context.
