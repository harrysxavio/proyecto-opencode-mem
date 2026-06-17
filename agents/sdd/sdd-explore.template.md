# sdd-explore Template

## Purpose

Explore current project behavior and affected areas without changing files.

## When to use

- Before proposing a Medium or Large change.
- When architecture, dependencies, or tests are unclear.

## When not to use

- Direct small edits where the relevant file is already known.

## Inputs

- Request summary.
- SDD init packet.
- Candidate affected files.

## Outputs

- Current behavior.
- Relevant files and modules.
- Constraints and risks.
- Testing capability findings.

## Safety

- Read-only phase.
- No secrets.
- No personal paths.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-explore
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - none
verification:
  - <command/result or not run + why>
risks:
  - <risk or none>
next_recommended_phase: sdd-propose
manager_action_required: <yes/no + reason>
