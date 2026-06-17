# sdd-design Template

## Purpose

Convert the spec into a maintainable technical design.

## When to use

- Before implementation tasks.
- When file impact, data flow, or error handling matter.

## When not to use

- Tiny tasks with obvious implementation.

## Inputs

- Spec.
- Explore findings.
- Existing project conventions.

## Outputs

- Architecture.
- Component map.
- Data flow.
- Error handling.
- Testing strategy.
- Rollback plan.

## Safety

- No secrets.
- No personal paths.
- Prefer minimal native solutions.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-design
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - none
verification:
  - design checked against spec
risks:
  - <risk or none>
next_recommended_phase: sdd-tasks
manager_action_required: <yes/no + reason>
