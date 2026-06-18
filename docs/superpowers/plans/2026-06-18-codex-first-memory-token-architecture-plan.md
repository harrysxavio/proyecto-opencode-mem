# Codex-First Memory and Token Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan stepwise. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing OpenCode architecture kit into a Codex-first, update-safe runtime architecture with governed memory, token budgets, skills, subagents, validation scripts, and later OpenCode portability.

**Architecture:** Keep Manager as the only primary orchestrator. Move depth into lazy-loaded skills, context packs, memory governance scripts, and bounded subagents. Install into user-owned Codex/OpenCode overlay locations only; never modify update-managed binaries.

**Tech Stack:** Node.js >=20, ESM scripts, Markdown contracts, Codex `AGENTS.md`, Codex skills, Engram/Codex memories, existing manifest profiles, Node test runner.

---

## File structure

- Create: `docs/proposals/2026-06-18-codex-first-memory-token-architecture.md` â€” strategic proposal and comparison.
- Create: `docs/superpowers/plans/2026-06-18-codex-first-memory-token-architecture-plan.md` â€” implementation plan.
- Modify later: `opencode-kit.manifest.json` â€” add Codex-first profiles/components.
- Create later: `docs/codex-runtime.md` â€” user-facing Codex install/runtime guide.
- Create later: `templates/codex/AGENTS.codex.example.md` â€” minimal Codex Manager overlay.
- Create later: `skills/manager-router/SKILL.md` â€” Manager routing skill.
- Create later: `skills/memory-governance/SKILL.md` â€” memory retrieve/write/update skill.
- Create later: `skills/context-pack-builder/SKILL.md` â€” context pack builder skill.
- Create later: `skills/token-budgeter/SKILL.md` â€” token budget analysis skill.
- Create later: `scripts/install-codex-overlay.mjs` â€” dry-run/install Codex overlay.
- Create later: `scripts/codex-doctor.mjs` â€” validate Codex overlay.
- Create later: `scripts/context-pack-check.mjs` â€” validate context pack fixtures.
- Create later: `scripts/memory-lint.mjs` â€” detect memory quality issues.
- Create later: `scripts/token-budget-report.mjs` â€” estimate fixed/dynamic token cost.
- Create later: `scripts/skill-registry-generate.mjs` â€” generate project skill registry.
- Modify later: `package.json` â€” expose new scripts.
- Create later: tests under `tests/unit/` and fixtures under `tests/fixtures/`.

---

### Task 1: Lock the Codex-first proposal

**Files:**
- Create: `docs/proposals/2026-06-18-codex-first-memory-token-architecture.md`
- Create: `docs/superpowers/plans/2026-06-18-codex-first-memory-token-architecture-plan.md`

- [x] **Step 1: Write proposal document**

Include:
- current vs target model;
- beginner explanation;
- senior architecture;
- memory layers;
- token budgets;
- scripts/skills/subagents to create;
- security and QA model;
- external references.

- [x] **Step 2: Write implementation plan**

Include concrete phases, files, tests, and commands.

- [x] **Step 3: Run documentation checks**

Run:

```powershell
node scripts/docs-check.mjs
```

Expected: PASS.

- [x] **Step 4: Run sanitizer**

Run:

```powershell
node scripts/sanitize-check.mjs
```

Expected: PASS or only known/intentional warnings. If a proposal path triggers absolute-path sanitizer, update sanitizer allowlist only if the path appears in documentation as user-local evidence and not exportable config.

- [x] **Step 5: Commit**

```powershell
git add docs/proposals/2026-06-18-codex-first-memory-token-architecture.md docs/superpowers/plans/2026-06-18-codex-first-memory-token-architecture-plan.md
git commit -m "docs: add codex-first memory token architecture plan"
```

---

### Task 2: Add Codex-first manifest profile

**Files:**
- Modify: `opencode-kit.manifest.json`
- Test: `tests/unit/manifest.test.mjs`
- Test: `tests/unit/profiles.test.mjs`

- [x] **Step 1: Add failing tests**

Add assertions that profiles `codex` and `codex-full` exist and reference only portable paths.

Expected profile intent:

```json
{
  "codex": {
    "description": "Codex-first Manager, skills and memory governance overlay",
    "components": ["docs-core", "codex-manager-template", "codex-skills", "codex-memory-governance"]
  },
  "codex-full": {
    "description": "Codex-first full runtime kit with Manager, SDD, memory, context packs and validation harness",
    "components": ["docs-core", "templates-core", "codex-manager-template", "codex-skills", "sdd-templates", "memory-governance", "validation-harness"]
  }
}
```

- [x] **Step 2: Run tests to verify failure**

```powershell
node --test tests/unit/manifest.test.mjs tests/unit/profiles.test.mjs
```

Expected: FAIL because profiles/components do not exist.

- [x] **Step 3: Update manifest minimally**

Add `codex`, `codex-full`, and components pointing to future files.

- [x] **Step 4: Run tests to verify pass**

```powershell
node --test tests/unit/manifest.test.mjs tests/unit/profiles.test.mjs
node scripts/validate.mjs
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add opencode-kit.manifest.json tests/unit/manifest.test.mjs tests/unit/profiles.test.mjs
git commit -m "feat: add codex runtime profiles"
```

---

### Task 3: Create Codex Manager overlay template

**Files:**
- Create: `templates/codex/AGENTS.codex.example.md`
- Create: `docs/codex-runtime.md`
- Test: `tests/unit/codex-template.test.mjs`

- [x] **Step 1: Write failing tests**

Test that the template contains:
- Manager as single primary orchestrator;
- short response contract;
- memory retrieval rules;
- skill lazy-loading rule;
- context pack rule;
- no OpenCode binary paths;
- no private absolute paths.

- [x] **Step 2: Run test to verify failure**

```powershell
node --test tests/unit/codex-template.test.mjs
```

Expected: FAIL because file does not exist.

- [x] **Step 3: Create template**

The template must be short. It should reference skills/docs instead of embedding all protocols.

- [x] **Step 4: Create user guide**

`docs/codex-runtime.md` must explain install targets, rollback, memory layers, and beginner workflow.

- [x] **Step 5: Run tests**

```powershell
node --test tests/unit/codex-template.test.mjs
node scripts/docs-check.mjs
node scripts/sanitize-check.mjs
```

Expected: PASS.

- [x] **Step 6: Commit**

```powershell
git add templates/codex/AGENTS.codex.example.md docs/codex-runtime.md tests/unit/codex-template.test.mjs
git commit -m "feat: add codex manager overlay template"
```

---

### Task 4: Add project skill registry generator

**Files:**
- Create: `scripts/skill-registry-generate.mjs`
- Create: `tests/unit/skill-registry-generate.test.mjs`
- Create: `skills/manager-router/SKILL.md`
- Create: `skills/memory-governance/SKILL.md`
- Create: `skills/context-pack-builder/SKILL.md`
- Create: `skills/token-budgeter/SKILL.md`
- Modify: `package.json`

- [x] **Step 1: Write failing tests**

Test that generator reads `skills/*/SKILL.md` and writes `.atl/skill-registry.md` with name, description, trigger, and path.

- [x] **Step 2: Run test to verify failure**

```powershell
node --test tests/unit/skill-registry-generate.test.mjs
```

Expected: FAIL.

- [x] **Step 3: Implement minimal generator**

Use Node `fs/promises` and parse frontmatter conservatively.

- [x] **Step 4: Add initial skills**

Each `SKILL.md` must be narrow and point to docs instead of copying full docs.

- [x] **Step 5: Add package script**

Add:

```json
"skills:registry": "node scripts/skill-registry-generate.mjs"
```

- [x] **Step 6: Run tests and generator**

```powershell
node --test tests/unit/skill-registry-generate.test.mjs
npm run skills:registry
node scripts/sanitize-check.mjs
```

Expected: PASS and `.atl/skill-registry.md` generated without private paths.

- [x] **Step 7: Commit**

```powershell
git add scripts/skill-registry-generate.mjs tests/unit/skill-registry-generate.test.mjs skills package.json .atl/skill-registry.md
git commit -m "feat: add codex skill registry generator"
```

---

### Task 5: Add context pack validator

**Files:**
- Create: `scripts/context-pack-check.mjs`
- Create: `tests/unit/context-pack-check.test.mjs`
- Create: `tests/fixtures/context-packs/valid-small.json`
- Create: `tests/fixtures/context-packs/invalid-over-budget.json`
- Modify: `package.json`

- [x] **Step 1: Write failing tests**

Test valid pack passes and over-budget pack fails.

- [x] **Step 2: Implement validator**

Rules:
- required fields: `request_id`, `classification`, `token_budget`, `included`, `excluded`;
- `token_budget` positive integer;
- no included item with `sensitivity: high`;
- included item must have `kind`, `ref`, `reason`;
- max included default: 8.

- [x] **Step 3: Add package script**

```json
"context:check": "node scripts/context-pack-check.mjs"
```

- [x] **Step 4: Run tests**

```powershell
node --test tests/unit/context-pack-check.test.mjs
npm run context:check -- tests/fixtures/context-packs/valid-small.json
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/context-pack-check.mjs tests/unit/context-pack-check.test.mjs tests/fixtures/context-packs package.json
git commit -m "feat: add context pack validator"
```

---

### Task 6: Add memory lint and token budget report

**Files:**
- Create: `scripts/memory-lint.mjs`
- Create: `scripts/token-budget-report.mjs`
- Create: `tests/unit/memory-lint.test.mjs`
- Create: `tests/unit/token-budget-report.test.mjs`
- Create: `tests/fixtures/memory-lint/`
- Modify: `package.json`

- [x] **Step 1: Write failing tests**

Memory lint must detect:
- secret-like strings;
- raw prompt dumps;
- duplicate topic keys;
- missing evidence for decisions.

Token report must output:
- estimated fixed docs/instruction size;
- largest files by character count;
- recommended lazy-load candidates.

- [x] **Step 2: Implement minimal scripts**

Keep them deterministic and offline. No model calls.

- [x] **Step 3: Add package scripts**

```json
"memory:lint": "node scripts/memory-lint.mjs",
"tokens:report": "node scripts/token-budget-report.mjs"
```

- [x] **Step 4: Run tests**

```powershell
node --test tests/unit/memory-lint.test.mjs tests/unit/token-budget-report.test.mjs
npm run memory:lint -- tests/fixtures/memory-lint
npm run tokens:report
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add scripts/memory-lint.mjs scripts/token-budget-report.mjs tests/unit/memory-lint.test.mjs tests/unit/token-budget-report.test.mjs tests/fixtures/memory-lint package.json
git commit -m "feat: add memory lint and token reporting"
```

---

### Task 7: Add Codex overlay installer and doctor

**Files:**
- Create: `scripts/install-codex-overlay.mjs`
- Create: `scripts/codex-doctor.mjs`
- Create: `tests/unit/install-codex-overlay.test.mjs`
- Create: `tests/integration/codex-overlay-dry-run.test.mjs`
- Modify: `package.json`

- [x] **Step 1: Write failing tests**

Tests must prove:
- dry-run writes nothing;
- install target is user-owned `.codex` or temp fixture;
- backup plan is produced before write;
- OpenCode binary directory is rejected;
- rollback metadata is created.

- [x] **Step 2: Implement dry-run first**

Support:

```powershell
node scripts/install-codex-overlay.mjs --dry-run --target tests/tmp/codex-home
```

- [x] **Step 3: Implement temp install**

Support install into fixture target only during tests.

- [x] **Step 4: Implement doctor**

Doctor checks:
- required files exist;
- skill registry exists;
- AGENTS template size below configured limit;
- no private absolute paths;
- rollback metadata exists after install.

- [x] **Step 5: Add package scripts**

```json
"install:codex:dry-run": "node scripts/install-codex-overlay.mjs --dry-run",
"codex:doctor": "node scripts/codex-doctor.mjs"
```

- [x] **Step 6: Run tests**

```powershell
node --test tests/unit/install-codex-overlay.test.mjs tests/integration/codex-overlay-dry-run.test.mjs
pnpm install:codex:dry-run
```

Expected: PASS.

- [x] **Step 7: Commit**

```powershell
git add scripts/install-codex-overlay.mjs scripts/codex-doctor.mjs tests/unit/install-codex-overlay.test.mjs tests/integration/codex-overlay-dry-run.test.mjs package.json
git commit -m "feat: add codex overlay installer"
```

---

### Task 8: Add OpenCode overlay plan only after Codex is stable

**Files:**
- Create later: `docs/opencode-adaptation.md`
- Create later: `scripts/install-opencode-overlay.mjs`
- Create later: `tests/integration/opencode-overlay-dry-run.test.mjs`

- [x] **Step 1: Confirm Codex gates pass**

Run:

```powershell
pnpm test:all
pnpm codex:doctor
pnpm tokens:report
```

Expected: PASS.

- [x] **Step 2: Write OpenCode adaptation doc**

State explicitly: do not write to `<OPENCODE_APP_INSTALL_DIR>`.

- [x] **Step 3: Implement dry-run-only OpenCode overlay installer**

Installer must reject binary install path and accept only config overlay target.

- [x] **Step 4: Run tests**

```powershell
node --test tests/integration/opencode-overlay-dry-run.test.mjs
node scripts/sanitize-check.mjs
```

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add docs/opencode-adaptation.md scripts/install-opencode-overlay.mjs tests/integration/opencode-overlay-dry-run.test.mjs
git commit -m "feat: add opencode overlay adaptation plan"
```

---

## Self-review

- Spec coverage: This plan covers Codex-first architecture, memory, tokens, scripts, skills, agents/subagents, QA, security, OpenCode later, beginner/senior explanation, and replicability.
- Placeholder scan: No task relies on an undefined â€œdo the right thingâ€; future files and commands are named explicitly.
- Risk: The plan intentionally delays external memory engines until local governance is measurable. That is a feature, not a limitation.


