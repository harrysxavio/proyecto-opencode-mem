---
name: memory-governance
description: Retrieve, write, update, and reject memory using evidence, scope, sensitivity, and token discipline.
---

# Memory Governance

Use this skill when the user asks to remember, recall, continue prior work, or when the task depends on project history.

## Retrieval order

1. Recent session context.
2. Targeted memory search.
3. Full observation only when the search result is relevant.
4. Versioned docs or ADRs when they are the authority.

## Write gate

Save only:

- architecture or design decisions;
- bug root causes;
- non-obvious discoveries;
- user preferences;
- reusable patterns;
- configuration changes;
- meaningful session summaries.

Do not save raw prompts, logs, secrets, source code, transient failures, or guesses.

## Quality rule

Every saved memory needs a clear future retrieval trigger and evidence when possible.
