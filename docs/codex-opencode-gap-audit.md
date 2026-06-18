# Codex vs OpenCode Gap Audit

This audit compares the portable Codex runtime kit against the observed OpenCode architecture inventory.

## Scope

- Source architecture: `opencode-architecture` documents, especially tools/MCP/skills, SDD subagents, Noise Gate, and token-reduction plans.
- Target runtime: user-owned Codex overlay under `<CODEX_HOME>`.
- Safety rule: do not write to Codex, OpenCode, Node, or editor application install directories.

## Findings

### Already covered in Codex kit

| Capability | Codex kit state |
| --- | --- |
| Primary Manager contract | Installed as the Codex overlay `AGENTS.md`. |
| Memory governance | Covered by `memory-governance` skill plus Engram protocol. |
| Context packs | Covered by `context-pack-builder` and validator script. |
| Token budgets | Covered by `token-budgeter` and token report script. |
| Safe install | Implemented by explicit-target installer with real backups. |
| Rollback | Implemented as a rollback script using backup metadata. |

### OpenCode capabilities added to Codex kit

These were present in the OpenCode architecture or registry and are now represented as portable Codex skills:

| Area | Added skills |
| --- | --- |
| Review slicing | `work-unit-commits`, `chained-pr` |
| GitHub collaboration | `branch-pr`, `issue-creation` |
| Quality gates | `judgment-day`, `deploy-security-gate` |
| Documentation | `cognitive-doc-design`, `flow-diagram` |
| UI quality | `web-design-guidelines` |
| Skill maintenance | `skill-improver` |
| Data workflows | `bigquery-table-cleaning`, `sandbox-data-loader`, `sql-learning` |

### Not copied directly

| OpenCode item | Decision | Why |
| --- | --- | --- |
| OpenCode TypeScript plugins | Do not copy into Codex directly. | Runtime APIs differ; copying would be brittle and update-sensitive. |
| OpenCode app install folder | Do not write. | It is update-managed. |
| Node/Corepack global shim folder | Do not write. | It is installation-managed; use user-scoped pnpm instead. |
| OpenCode MCP config secrets | Do not copy. | MCP auth must be configured per runtime without hardcoded secrets. |
| Ponytail plugin runtime | Keep as future optional integration. | Documented as useful, but not confirmed as installed runtime. |

## MCP strategy

Codex already has a plugin/tool discovery layer. The kit should not blindly copy OpenCode MCP entries. Instead:

1. Use Engram when memory is needed.
2. Use Context7 or official docs only when current library/API documentation matters.
3. Use Playwright/browser tooling only for UI verification.
4. Add external MCPs only through explicit user-owned config and without embedded secrets.

## Subagent strategy

OpenCode has an explicit SDD subagent runtime. Codex has dynamic subagent tooling available when the user explicitly authorizes delegation.

The portable kit therefore models subagents as:

- Manager routing rules;
- SDD phase contracts;
- skill paths injected into delegated workers;
- review gates before commit or PR;
- compact return envelopes.

## Result

The Codex kit now captures the useful OpenCode architecture patterns while avoiding the risky parts:

- no update-managed writes;
- no copied secrets;
- no direct OpenCode plugin transplant;
- no always-on token-heavy protocols;
- portable, reviewable skills instead of machine-specific paths.
