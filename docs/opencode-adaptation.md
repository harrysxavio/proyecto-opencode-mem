# OpenCode Adaptation Plan

This repository is **Codex first**. OpenCode support comes only after the Codex overlay, Manager contract, memory governance, and token gates are proven with tests.

## Safety boundary

Do not write to `<OPENCODE_APP_INSTALL_DIR>`.

That directory is managed by the OpenCode application updater. Runtime changes belong in a user-owned configuration overlay, not in the application install directory. This keeps upgrades reversible and prevents a local kit from corrupting an update-managed program.

## Beginner model

Think of OpenCode as the building and this kit as removable furniture:

- the building should stay untouched;
- the furniture can be moved, replaced, or removed;
- the Manager remains the front desk that routes work to skills, scripts, and subagents.

Codex is the first room we finish. Once the Codex room works, this document defines how to place the same furniture in OpenCode without drilling into the building.

## Target OpenCode shape

- **Manager**: same single primary orchestrator contract used by Codex.
- **Skills**: copied from the repo into a user-owned configuration overlay.
- **Memory**: governed by retrieve-before-write, no raw prompt dumps, and evidence-backed decisions.
- **Token use**: fixed instructions stay short; detail moves into lazy-loaded skills and context packs.
- **Installer**: dry-run only for now, so the plan can be reviewed without writing files.

## Current implementation stage

`scripts/install-opencode-overlay.mjs` produces a dry-run plan and rejects update-managed app directories. It intentionally refuses real installs until the Codex phase has stronger production evidence.

## Promotion gate for real OpenCode writes

Before enabling real writes, require:

1. Codex doctor pass on an installed overlay.
2. OpenCode-specific doctor script.
3. Rollback metadata equivalent to the Codex overlay.
4. Tests proving the OpenCode installer cannot target the app install directory.
5. Documentation showing install, rollback, and uninstall for non-experts.
