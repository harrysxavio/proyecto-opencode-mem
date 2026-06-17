# sdd-archive Template

## Purpose

Archive verified changes, sync final specs, and record durable learnings.

## When to use

- After verification passes or is explicitly waived.

## When not to use

- Before verification.

## Inputs

- Final verified state.
- Verification report.
- Files changed.

## Outputs

- Archived change summary.
- Updated docs/specs if applicable.
- Memory save recommendation.

## Safety

- No secrets.
- No personal paths.
- Do not change implementation code.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-archive
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - <path or none>
verification:
  - archive-only phase
risks:
  - <risk or none>
next_recommended_phase: none
manager_action_required: <yes/no + reason>
