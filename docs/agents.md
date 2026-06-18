# Agent Templates

The kit provides Manager templates for each runtime.

| File | Runtime | Purpose |
|------|---------|---------|
| `opencode/manager.template.md` | OpenCode | Full 15-section protocol with SDD subagents, Graphify, GPT-5.5 gates |
| `codex/manager.template.md` | Codex | Compact overlay with skills, memory, context packs |
| `contracts/manager.md` | Both | Portable Manager contract (runtime-agnostic) |

Templates are installed via overlay installers (`pnpm codex:install`, `pnpm opencode:install:dry-run`).
