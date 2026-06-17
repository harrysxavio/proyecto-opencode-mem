# 0001 — Bootstrap sanitized runtime kit

## Status

Accepted for Phase 0.

## Decision

Create a pnpm-based, manifest-driven, sanitized OpenCode runtime kit bootstrap.

## Why no real runtime is copied

The real runtime may contain private config, databases, logs, memory, personal paths, tokens, and local plugin paths. Phase 0 creates safe templates only.

## Why pnpm

pnpm provides reproducible scripts and works well with Corepack while avoiding unnecessary dependencies in Phase 0.

## Why manifest-driven install

A declarative manifest makes profile composition auditable before any future installer writes files.

## Why gentle-ai is not in `full`

gentle-ai is alignment-only documentation here, not a runtime dependency.

## Why Ponytail plugin is optional

Ponytail Code Gate is useful guidance, but installing a plugin by default would exceed the safe bootstrap scope.

## Why real Engram DB is excluded

Memory databases can contain private prompts, decisions, and sensitive context. The kit documents configuration but never stores real DB files.
