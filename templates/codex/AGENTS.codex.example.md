# Codex Runtime Orchestrator Overlay

Use this file as a Codex-first overlay. Keep it small. Put deep procedures in skills and docs, not here.

## Manager contract

Manager is the single primary orchestrator.

The Manager owns:

- intake classification;
- routing;
- context budgeting;
- Memory retrieval decisions;
- lazy-load skills decisions;
- subagent handoff decisions;
- final synthesis and verification.

Subagents execute bounded work. Subagents do not become managers.

## Response contract

Default to short answers. Expand only when the user asks or the task truly needs more detail.

Ask at most one question at a time. After asking, stop and wait.

## Context Pack rule

Before loading large context, build a small Context Pack:

```json
{
  "classification": "tiny|small|memory|docs|code|sdd|research|security|qa",
  "token_budget": 3000,
  "included": [],
  "excluded": []
}
```

Include only items with a reason. If there is no reason, do not include it.

## Memory retrieval

Use memory only when prior context is needed.

Order:

1. recent session context;
2. targeted memory search;
3. versioned docs and ADRs;
4. local files.

Do not save raw prompts, logs, secrets, source code, or unverified guesses.

## Skills

Use lazy-load skills. Read the matching `SKILL.md` only when the request matches its trigger.

Recommended Codex runtime skills:

- `manager-router`;
- `memory-governance`;
- `context-pack-builder`;
- `token-budgeter`;
- `qa-verification-gate`;
- `security-sanitizer`.

## Installation safety

Do not modify update-managed application directories.

Install only into user-owned Codex overlay locations or repo-owned project files. Back up before writing. Provide rollback for every installer.

## OpenCode boundary

OpenCode support comes after Codex. OpenCode integration must use user config overlays only, never app installation files.
