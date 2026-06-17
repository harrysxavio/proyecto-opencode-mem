# 0002 — Phase 1 Documentation Standard

**Date:** 2026-06-17
**Status:** Accepted
**Deciders:** Manager (automated decision following Phase 0 mandate)

---

## Context

Phase 0 bootstrapped the OpenCode Kit with the minimum viable structure, scripts,
templates, and profiles. However, the documentation was:

1. **In English** — while acceptable for the bootstrap, the target audience is
   Spanish-speaking developers.
2. **Incomplete** — missing dedicated guides for getting started, profiles,
   installation targets, safety, and roadmap.
3. **Too technical** — assumed familiarity with OpenCode, SDD, Engram, and
   related concepts.
4. **No integrity checks** — there was no automated way to verify documentation
   completeness.

The Phase 0 mandate explicitly required Phase 1 to address these gaps and produce
a documentation standard that all future phases must follow.

---

## Decision

We will adopt a **Documentation Standard** with the following rules:

### Rule 1: Language

All user-facing documentation MUST be written in **Spanish (Rioplatense)** with
voseo and a warm, didactic tone. Code comments, identifiers, and technical
artifacts remain in English.

### Rule 2: README completeness

The README MUST include all 27 required sections:

1. Title + badge
2. Description (¿Qué es?)
3. Table of Contents
4. Prerequisites
5. Architecture Overview
6. Manager Orchestrator role
7. SDD pipeline explanation
8. Engram persistent memory
9. Ponytail Code Gate
10. gentle-ai alignment
11. Profiles + comparison table
12. Quick Start
13. Installation targets
14. Safety & sanitization
15. Phase roadmap
16. FAQ
17. Glossary
18. Environment variables reference
19. OpenCode version compatibility
20. Uninstall instructions
21. Troubleshooting
22. Community / support channels
23. Project status / maturity badge
24. Example walkthrough link
25. Contributing
26. License

These 26 numbered items plus the title/badge section = 27.

### Rule 3: Dedicated docs

The following dedicated documents MUST exist:

- `docs/getting-started.md` — step-by-step beginner tutorial.
- `docs/profiles.md` — detailed profile descriptions with use cases.
- `docs/installation-targets.md` — VS Code, Cursor, CLI, project-local, agent.
- `docs/safety-and-sanitization.md` — security practices, secret detection,
  dry-run, backup, rollback.
- `docs/phase-roadmap.md` — project evolution across 5 phases.

### Rule 4: Decision records

Significant Phase 1 decisions MUST be recorded in `docs/decisions/` following
the ADR format established in `0001-bootstrap-sanitized-runtime-kit.md`.

### Rule 5: Automated integrity checks

A `docs:check` script MUST:

- Verify all required dedicated docs exist.
- Verify all required README sections exist (by heading text).
- Verify no absolute Windows paths (unresolved drive-rooted paths).
- Verify no placeholder text like `TODO` or `FIXME`.
- Exit with a clear PASS / PASS WITH WARNINGS / BLOCKED status.

### Rule 6: CI integration

The `docs:check` script MUST be part of `test:all` and run in GitHub Actions.

### Rule 7: Audit-first approach

Before any documentation work, a `PHASE-1-DOCUMENTATION-AUDIT.md` MUST be
produced classifying all issues as CRITICAL, MAJOR, or MINOR. This audit
serves as the source of truth for what needs to change.

### Rule 8: Prohibited content

Documentation MUST NOT:

- Claim the gentle-ai runtime is installed (it is alignment-only).
- Contain absolute Windows paths (unresolved `%USERPROFILE%` style paths).
- Claim Codex is a supported installation target.
- Claim the Ponytail plugin is installed by default (it is a protocol, not a plugin).
- Include emojis unless explicitly requested by the user.

### Rule 9: Phase completion report

Each phase MUST produce a `PHASE-<N>-<NAME>-REPORT.md` in `docs/` documenting
what was done, what passed, what failed, and what remains.

---

## Consequences

### Positive

- All documentation follows a consistent standard.
- Beginners can follow the getting-started guide without prior knowledge.
- Automated checks prevent documentation drift.
- The audit provides a clear baseline and progress tracker.
- Future phases have a template to follow.

### Negative

- Increased documentation surface area to maintain.
- The `docs:check` script requires updates when documentation structure changes.
- Spanish-only docs may limit contribution from non-Spanish speakers (mitigated
  by keeping code artifacts in English).

### Neutral

- Phase 1 produces approximately 8 new files and modifies 3 existing ones.

---

## Compliance

This standard applies to Phase 1 and all future phases unless explicitly
overridden by a subsequent ADR.

---

## References

- `0001-bootstrap-sanitized-runtime-kit.md` — Phase 0 bootstrap decision.
- `PHASE-1-DOCUMENTATION-AUDIT.md` — Audit that drove this standard.
- `opencode-architecture/ARCHITECTURE-ASSURANCE-REPORT.md` — Source architecture
  constraints.
- `opencode-architecture/PRE-RUNTIME-KIT-READINESS-REPORT.md` — Pre-runtime
  readiness requirements.
