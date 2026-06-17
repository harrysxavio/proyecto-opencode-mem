# sdd-apply Template

## Purpose

Implement approved tasks with minimal safe changes.

## When to use

- After tasks are approved or explicitly requested by the user.

## When not to use

- Before scope, design, and verification plan are clear.

## Inputs

- Approved tasks.
- Spec.
- Design.
- Verification commands.

## Outputs

- Files changed.
- Implemented tasks.
- Deviations from plan.
- Verification performed or pending.

## Safety

- No secrets.
- No personal paths.
- Do not write outside allowed scope.
- Do not touch real runtime unless explicitly approved.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-apply
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - <path or none>
verification:
  - <command/result or not run + why>
risks:
  - <risk or none>
next_recommended_phase: sdd-verify
manager_action_required: <yes/no + reason>
