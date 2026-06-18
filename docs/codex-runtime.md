# Codex Runtime Orchestrator

This guide explains how the kit should improve Codex first, then adapt the proven architecture to OpenCode.

## What this is

The Codex Runtime Orchestrator is the Codex-first version of the Manager architecture. It keeps the always-loaded contract small and moves deeper behavior into lazy skills, scripts, docs, and validated context packs.

Beginner version: Codex should not carry the whole toolbox for every job. It should first decide what kind of job this is, then bring only the tools and notes needed for that job.

Senior version: the orchestrator separates policy, retrieval, execution, persistence, and verification. That gives us better token control, safer memory, and clearer failure boundaries.

## User-owned overlay

Codex improvements must be installed as a user-owned overlay. The kit should write only to explicit Codex overlay targets chosen by the installer or test fixture.

The overlay may include:

- a compact `AGENTS.md` style Manager contract;
- repo-managed Codex skills;
- generated skill registry data;
- validation metadata;
- backup and rollback records.

It must not write into update-managed application directories.

## Install safety

Every real installer must support:

1. dry run;
2. target validation;
3. backup before write;
4. rollback metadata;
5. sanitizer check;
6. clear report of created, skipped, and unchanged files.

No installer should require private paths to be committed to this repository.

## Rollback

Rollback means restoring the previous user-owned overlay state from the backup created by the installer.

A rollback report should include:

- backup id;
- files restored;
- files left untouched;
- failures;
- next manual action if needed.

## Memory layers

The Codex-first memory model has six practical layers:

| Layer | Purpose |
|---|---|
| Current context | The active request and files being worked on |
| Explicit instructions | Small Manager contract and project rules |
| Codex local memories | Local learned context from eligible prior work |
| Engram observations | Decisions, findings, bugs, patterns, preferences |
| Markdown docs | Versioned source of truth for architecture and ADRs |
| Optional external memory | Future Mem0, Letta, Zep, or graph memory experiments |

Memory is a library, not a trash bin. Save only what will help future work.

## Beginner workflow

1. User asks for work.
2. Manager classifies the request.
3. Manager decides whether memory, docs, skills, tools, or subagents are needed.
4. Manager builds a small Context Pack.
5. Codex executes or delegates bounded work.
6. Verification checks the result.
7. Useful discoveries are saved; noise is discarded.

## OpenCode adaptation

OpenCode comes later. The same contracts should be ported only after Codex has working profiles, templates, skills, memory checks, token reports, and installer proof.

OpenCode adaptation must use config overlays and portable templates. It must not modify application installation files.

## Success criteria

Codex support is real only when a fresh clone can:

1. validate the manifest;
2. run a dry-run Codex overlay install;
3. verify the overlay with a doctor script;
4. generate or validate a skill registry;
5. check context pack budgets;
6. lint memory fixtures;
7. report token footprint;
8. pass sanitizer and test gates.
