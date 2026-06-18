---
name: manager-router
description: Classify requests, choose the smallest safe route, and decide when Codex should use memory, docs, skills, tools, SDD, or subagents.
---

# Manager Router

Use this skill when a request is non-trivial or needs routing.

## Contract

The Manager is the single primary orchestrator. It classifies the request, sets a token budget, chooses the route, and synthesizes the final answer.

## Route classes

- `tiny`: answer directly.
- `small`: inspect one to three local files, then answer or edit.
- `memory`: retrieve prior context before acting.
- `docs`: read versioned docs or ADRs.
- `code`: use TDD and focused verification.
- `sdd`: use the SDD pipeline.
- `research`: gather current external evidence.
- `security`: use evidence-first review.
- `qa`: prove completion against requirements.

## Delegation rule

Delegate when broad reading, multi-file implementation, independent review, or SDD phase work would inflate the Manager context.

Subagents return compact evidence. They do not become managers.
