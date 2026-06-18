---
name: noise-gate
description: Classify user prompts as instruction, question, confirmation, navigation, or noise before deciding what deserves memory. Use when Codex is about to save memory, summarize a session, compact context, or reduce noisy prompt capture inspired by the OpenCode Noise Gate design.
---

# Noise Gate

Apply this gate before saving a user prompt, adding session memory, or expanding context from chat history.

## Purpose

Keep durable memory useful by filtering out conversational noise. The goal is not to remember less; the goal is to remember only information that will help a future agent make a better decision.

## Classify the prompt

Use the smallest fitting class:

| Class | Meaning | Default action |
| --- | --- | --- |
| `instruction` | The user asks for work, sets a constraint, changes scope, or gives a reusable preference. | Consider memory if it has future value. |
| `question` | The user asks for explanation, status, validation, or comparison. | Do not save by default unless it reveals a reusable preference or project state. |
| `confirmation` | Short approval or rejection such as "yes", "ok", "continue", "no". | Do not save unless it includes new constraints or decisions. |
| `navigation` | The user asks to show, open, move, list, or inspect something transient. | Do not save unless it names durable project structure. |
| `noise` | Chatter, duplicated text, accidental paste, empty content, or content with no future value. | Do not save. |

## Save only when useful

Save memory only if at least one condition is true:

1. A durable decision was made.
2. A bug was fixed and the root cause is known.
3. A reusable workflow, convention, or preference was established.
4. A non-obvious codebase discovery was verified.
5. A configuration or environment setup changed.
6. A session summary is needed to preserve handoff state.

Reject memory when:

- it only repeats the current prompt;
- it is a simple confirmation;
- it is a temporary navigation request;
- it lacks evidence;
- it may contain secrets, credentials, or private raw logs;
- it duplicates an existing memory without adding a clearer topic or newer evidence.

## Output format

When asked to report the gate result, use:

```text
classification: instruction | question | confirmation | navigation | noise
should_save: yes | no
reason: one sentence
memory_shape: preference | decision | architecture | bugfix | discovery | pattern | config | session_summary | none
evidence: file, command, test, or user statement that supports saving
```

## Relationship to OpenCode

This skill is the portable Codex version of the OpenCode Noise Gate concept. OpenCode can place the gate near prompt-capture hooks. Codex uses it as an explicit governance step in Manager, memory, and session-summary flows unless a dedicated lifecycle hook is added later.
