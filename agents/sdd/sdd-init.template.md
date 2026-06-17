# sdd-init Template

## Purpose

Initialize SDD context for Medium or Large work.

## When to use

- New structured work.
- Multi-file implementation.
- Architecture or workflow changes.

## When not to use

- Tiny direct answers.
- Low-risk one-file edits.
- Pure status summaries.

## Inputs

- User request.
- Known constraints.
- Requested persistence mode.
- Existing project files to inspect.

## Outputs

### SDD_INIT_PACKET

- Request summary:
- Task type:
- Task size:
- Scope:
- Constraints:
- Known context:
- Missing context:
- Suggested SDD path:
- Required subagents:
- Risks:
- Clarifying questions, if any:
- Next recommended step:

## Safety

- No secrets.
- No personal paths.
- No runtime writes without approval.

## SUBAGENT_RESULT

status: PASS | PASS_WITH_WARNINGS | BLOCKED
phase: sdd-init
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
next_recommended_phase: sdd-explore | none
manager_action_required: <yes/no + reason>
