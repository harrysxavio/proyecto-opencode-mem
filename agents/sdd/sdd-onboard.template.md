# sdd-onboard Template

## Purpose

Guide a user through SDD on a real codebase.

## When to use

- User asks for SDD onboarding.
- User wants a guided cycle.

## When not to use

- Implementation-only tasks with an already approved plan.

## Inputs

- User goal.
- Project context.
- Learning constraints.

## Outputs

- Guided SDD path.
- Recommended first phase.
- Risks and expected decisions.

## Safety

- No secrets.
- No personal paths.
- Do not modify runtime while onboarding unless approved.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-onboard
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - <path or none>
verification:
  - onboarding guidance only
risks:
  - <risk or none>
next_recommended_phase: sdd-init | none
manager_action_required: <yes/no + reason>
