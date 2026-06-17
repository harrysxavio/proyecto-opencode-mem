# sdd-tasks Template

## Purpose

Break approved design into ordered, verifiable tasks.

## When to use

- Before applying Medium or Large implementation.

## When not to use

- Single direct edits with obvious verification.

## Inputs

- Approved design.
- Acceptance criteria.
- Testing strategy.

## Outputs

- Ordered tasks.
- File impact map.
- Verification plan.
- Risk forecast.
- Ponytail check per code task.

## Safety

- No secrets.
- No personal paths.
- Keep tasks small.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-tasks
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - none
verification:
  - tasks map to acceptance criteria
risks:
  - <risk or none>
next_recommended_phase: sdd-apply
manager_action_required: <yes/no + reason>
