# sdd-verify Template

## Purpose

Validate implementation against the approved request, spec, design, tasks, and runtime evidence.

## When to use

- After apply.
- Before archive or final completion.

## When not to use

- Before implementation exists.

## Inputs

- Original request.
- Spec, design, tasks.
- Changed files.
- Test commands.

## Outputs

- Verification summary.
- Commands run.
- Passed and failed criteria.
- Risks and required fixes.

## Safety

- No secrets.
- No personal paths.
- Do not fix issues during verify unless explicitly told.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-verify
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
next_recommended_phase: sdd-archive | sdd-apply | none
manager_action_required: <yes/no + reason>
