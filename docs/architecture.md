# Architecture

`proyecto-opencode-mem` is a manifest-driven OpenCode runtime kit. It separates portable templates from private runtime state.

## Core components

| Component | Role | Phase 0 status |
|---|---|---|
| Manifest | Declares profiles and components | Created |
| Templates | Sanitized examples for config, agents, env | Created |
| Manager | Primary orchestration pattern | Template only |
| SDD agents | Phase executors | Templates only |
| Engram | Memory governance | Template and docs only |
| Ponytail | Code-task simplification | Guidance only |
| gentle-ai | Architecture alignment | Documentation only |

## Boundary

No real runtime is copied in Phase 0. Future import phases must pass sanitizer checks before adding real-derived artifacts.
