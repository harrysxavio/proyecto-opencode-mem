---
name: token-budgeter
description: Estimate and reduce fixed and dynamic token cost by moving detail into lazy-loaded docs, skills, scripts, and context packs.
---

# Token Budgeter

Use this skill when a request mentions token cost, context size, many skills, large docs, or slow agent work.

## Principles

1. Stable instructions should be short.
2. Long docs should be loaded on demand.
3. Skills should be lazy-loaded by trigger.
4. Tools and MCP surfaces should be activated only when needed.
5. Subagents should receive compact context packs.

## Report shape

Return:

- fixed context candidates;
- dynamic context candidates;
- largest files or instruction blocks;
- safe lazy-load moves;
- verification commands.

## Warning

Do not remove safety, security, accessibility, tests, or auditability just to save tokens.
