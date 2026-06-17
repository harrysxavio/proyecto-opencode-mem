# sdd-spec Template

## Purpose

Define testable behavior and acceptance criteria.

## When to use

- After proposal approval.
- Before technical design.

## When not to use

- Exploratory discussion without a planned change.

## Inputs

- Approved proposal.
- User constraints.
- Known edge cases.

## Outputs

- Functional requirements.
- Non-functional requirements.
- Given/When/Then scenarios.
- Error states.
- Acceptance criteria.

## Safety

- Specify behavior, not private data.
- No secrets.
- No personal paths.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-spec
summary:
  - <brief result>
files_read:
  - <path or none>
files_changed:
  - none
verification:
  - criteria are testable
risks:
  - <risk or none>
next_recommended_phase: sdd-design
manager_action_required: <yes/no + reason>
