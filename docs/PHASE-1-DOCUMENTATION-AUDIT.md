# Phase 1 — Documentation Audit

> **Date:** 2026-06-17
> **Scope:** proyecto-opencode-mem — all documentation, scripts, templates, and manifests.
> **Method:** Manual review of every file in the repository against the Phase 0 mandate and
> opencode-architecture source documents.

---

## Summary

| Metric | Value |
|---|---|
| Files reviewed | 15 |
| CRITICAL issues | 2 |
| MAJOR issues | 9 |
| MINOR issues | 5 |
| PASS items | 11 |

---

## CRITICAL

### C1. README claims `gentle-ai` runtime is installed

**File:** `README.md`
**Current text:** References installation steps implying the gentle-ai runtime is active.
**Risk:** A user running `gentle-ai doctor` will get a "not installed" error. This is a trust
breaker.
**Fix:** Remove all claims that gentle-ai runtime is present. State it is alignment-only and
must be installed separately if needed.

### C2. README contains absolute Windows path

**File:** `README.md`
**Risk:** Hardcoded `%USERPROFILE%\...` path (resolved at runtime) is machine-specific. Breaks portability and
exposes contributor info.
**Fix:** Replace with `${KIT_ROOT}` or `KIT_HOME` placeholder.

---

## MAJOR

### M1. README is in English — must be Spanish

**File:** `README.md`
**Requirement:** Phase 0 mandates Spanish (Rioplatense) for all user-facing docs.
**Fix:** Full rewrite in Spanish with voseo and warm didactic tone.

### M2. README missing 20 of 26 required sections

**File:** `README.md`
**Required sections present:** 6 (Description, Prerequisites, Quick Start, Profile
Reference, Contributing, License).
**Missing:**
1. Table of Contents
2. Architecture Overview
3. Manager Orchestrator role
4. SDD pipeline explanation
5. Engram persistent memory
6. Ponytail Code Gate
7. gentle-ai alignment
8. Profile comparison table
9. Installation targets (VS Code, Cursor, CLI, etc.)
10. Safety & sanitization
11. Phase roadmap
12. FAQ
13. Glossary
14. Environment variables reference
15. OpenCode version compatibility
16. Uninstall instructions
17. Troubleshooting
18. Community / support channels
19. Project status / maturity badge
20. Example walkthrough link

**Fix:** Rewrite README with all 26 sections.

### M3. No `docs/getting-started.md`

**Requirement:** Phase 0 mandates a dedicated getting-started guide.
**Fix:** Create `docs/getting-started.md` with step-by-step tutorial for beginners.

### M4. No `docs/profiles.md`

**Requirement:** Each profile must have a dedicated explanation of what it includes,
when to use it, and how to enable it.
**Fix:** Create `docs/profiles.md` with table, descriptions, use-case scenarios.

### M5. No `docs/installation-targets.md`

**Requirement:** Must document how the kit integrates with each OpenCode target
(VS Code extension, Cursor, CLI, direct agent).
**Fix:** Create `docs/installation-targets.md`.

### M6. No `docs/safety-and-sanitization.md`

**Requirement:** Phase 0 mandates a dedicated safety/sanitization doc.
**Fix:** Create `docs/safety-and-sanitization.md` with pre-flight checks, dry-run,
rollback, and security practices.

### M7. No `docs/phase-roadmap.md`

**Requirement:** Users must see the overall project roadmap across all phases.
**Fix:** Create `docs/phase-roadmap.md` with 5 phases, status, and descriptions.

### M8. No decision record `docs/decisions/0002-phase-documentation-standard.md`

**Requirement:** Phase 0 mandates a new ADR for Phase 1's documentation conventions.
**Fix:** Create `docs/decisions/0002-phase-documentation-standard.md`.

### M9. No automated documentation integrity check

**Requirement:** Must have `docs:check` script in `package.json` and CI job.
**Fix:** Add `scripts/docs-check.mjs`, update `package.json`, update
`.github/workflows/validate.yml`.

---

## MINOR

### m1. Profile descriptions in manifest are too terse

**File:** `opencode-kit.manifest.json`
**Issue:** Each profile has a single-sentence description. New users need 2-3 sentences
plus a use-case hint.
**Fix:** Expand descriptions (future phase or manifest v2).

### m2. No profile badges in README

**Issue:** Visual badges for profile maturity (stable/experimental/deprecated) help
users choose.
**Fix:** Add badges in README rewrite.

### m3. Example templates lack comments

**Files:** `templates/opencode.example.jsonc`, `templates/AGENTS.example.md`
**Issue:** Minimal inline comments make it hard for beginners to customize.
**Fix:** Add explanatory comments (future phase).

### m4. No CONTRIBUTING.md symlink or copy

**Issue:** The project has a brief "Contributing" section in README but no dedicated
contributing guide for external contributors.
**Fix:** Create CONTRIBUTING.md or reference it from README.

### m5. No architecture diagram (ASCII or Mermaid)

**Issue:** The project would benefit from a visual architecture overview.
**Fix:** Add a Mermaid diagram in the Architecture section of README.

---

## PASS (no action needed)

| Item | Status |
|---|---|
| `package.json` scripts structure | ✅ Valid |
| `opencode-kit.manifest.json` schema | ✅ Valid |
| `docs/install.md` exists | ✅ Present |
| `docs/decisions/0001-bootstrap.md` | ✅ Present |
| `templates/opencode.example.jsonc` | ✅ Present |
| `templates/AGENTS.example.md` | ✅ Present |
| `templates/env.example` | ✅ Present |
| `scripts/` directory with 8 scripts | ✅ Complete |
| `tests/unit/` directory | ✅ Present |
| `tests/integration/` directory | ✅ Present |
| `.github/workflows/validate.yml` | ✅ Present |

---

## Action Plan

| Priority | Task | File |
|---|---|---|
| P0 | C1 — Remove false gentle-ai runtime claims | README.md |
| P0 | C2 — Remove hardcoded Windows path | README.md |
| P1 | M1+M2 — Full Spanish rewrite with 26 sections | README.md |
| P1 | M3 — Create getting-started guide | docs/getting-started.md |
| P1 | M4 — Create profiles doc | docs/profiles.md |
| P1 | M5 — Create installation-targets doc | docs/installation-targets.md |
| P1 | M6 — Create safety-and-sanitization doc | docs/safety-and-sanitization.md |
| P1 | M7 — Create phase-roadmap doc | docs/phase-roadmap.md |
| P1 | M8 — Create decision record | docs/decisions/0002-phase-documentation-standard.md |
| P1 | M9 — Create docs-check script + CI | scripts/docs-check.mjs, package.json, CI |
| P2 | m1-m5 — Minor improvements | Various (post-Phase 1) |

---

*End of audit.*
