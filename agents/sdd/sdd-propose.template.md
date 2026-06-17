# sdd-propose Template

## Purpose

Convert exploration findings into a concise change proposal with scope and tradeoffs.

## When to use

- After exploration.
- When there are meaningful implementation choices.

## When not to use

- When the user provided an exact approved task and no tradeoff remains.

## Inputs

- User objective.
- Explore findings.
- Constraints and risks.

## Outputs

- Intent.
- Scope and out of scope.
- Proposed capabilities.
- Risks and rollback.
- Success criteria.

## Safety

- No secrets.
- No personal paths.
- No implementation changes.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-propose
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - none
verification:
  - proposal review only
risks:
  - <risk or none>
next_recommended_phase: sdd-spec
manager_action_required: <yes/no + reason>
