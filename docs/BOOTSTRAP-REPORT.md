# Runtime Kit Bootstrap Report — Phase 0

> Verdict: `RUNTIME KIT BOOTSTRAP PASS WITH WARNINGS`  
> Scope: safe bootstrap only. No real runtime import or installation.

## What was created

- pnpm Node project with `package.json` and lockfile.
- Declarative `opencode-kit.manifest.json`.
- Sanitized OpenCode, AGENTS, env, Manager, SDD, and Engram templates.
- Profile files for all required profiles.
- Base documentation, decision record, and security docs.
- Node core scripts for doctor, validate, sanitize, dry-run install, temp install, backup plan, rollback plan, and inventory.
- Node test suite with unit and integration tests.
- Basic GitHub Actions validation workflow.

## Structure created

```text
README.md
package.json
opencode-kit.manifest.json
docs/
templates/
agents/
skills/
plugins/
scripts/
tests/
examples/
.github/workflows/validate.yml
```

## Scripts available

| Script | Purpose |
|---|---|
| `doctor` | Checks Node, pnpm/Corepack, core structure, templates |
| `validate` | Validates manifest, profiles, directories, templates, scripts |
| `sanitize:check` | Blocks private paths, tokens, env files, DBs, logs, backups |
| `test` | Runs Node test suite |
| `test:all` | Runs validate, sanitize, and tests |
| `install:dry-run` | Prints profile install plan only |
| `install:temp` | Copies profile files under `tests/tmp` only |
| `backup:plan` | Prints future backup plan only |
| `rollback:plan` | Prints future rollback plan only |
| `export:inventory` | Lists manifest profiles and components |

## Profiles created

- `minimal`
- `agents`
- `sdd`
- `memory-enabled`
- `ponytail-code-gate`
- `gentle-alignment`
- `full`

## Tests created

- Manifest validity.
- Required profile existence.
- Component ID uniqueness.
- Profile resolution.
- `full` excludes gentle-ai runtime.
- `gentle-alignment` stays documentation/template only.
- `ponytail-code-gate` excludes Ponytail plugin by default.
- SDD template existence and `SUBAGENT_RESULT` marker.
- `sdd-init.template.md` includes `SDD_INIT_PACKET`.
- Engram template governance and path safety.
- Sanitizer clean and dirty fixture behavior.
- Dry-run install behavior.
- Temp install behavior.

## Validation results

| Command | Result |
|---|---|
| `corepack pnpm doctor` | PASS |
| `corepack pnpm validate` | PASS |
| `corepack pnpm sanitize:check` | PASS |
| `corepack pnpm test` | PASS — 14/14 tests |
| `corepack pnpm test:all` | PASS |
| `corepack pnpm install:dry-run -- --profile full` | PASS |
| `corepack pnpm install:dry-run -- --profile sdd` | PASS |
| `corepack pnpm install:dry-run -- --profile memory-enabled` | PASS |
| `corepack pnpm install:temp` | PASS |

## What was not copied

- No real OpenCode runtime.
- No real personal OpenCode config.
- No real memory database.
- No legacy memory database.
- No real logs or backups.
- No env file.
- No tokens, keys, private emails, or private data.
- No real plugins with local paths.
- No gentle-ai runtime.
- No Ponytail plugin by default.

## Warnings

1. The local shell did not expose a direct `pnpm` command. `corepack enable` was attempted but the system denied writing the shim, so validation used `corepack pnpm ...` successfully.
2. `templates/opencode.example.jsonc` follows the current OpenCode schema shape with `agent` and `skills.paths`; this intentionally differs from older array-style examples to avoid shipping invalid config.
3. Phase 0 uses templates only. Real installation, real runtime import, and component migration remain out of scope.

## Risks open

- Future imports could accidentally add private paths or secrets if sanitizer coverage is weakened.
- Real installation behavior is not implemented yet.
- SDD templates are minimal starter templates, not full production prompts.
- Engram plugin is conceptual and does not connect to a real database.

## Next steps

1. Review Phase 0 artifacts.
2. Decide which real components may be transformed in a future import phase.
3. Add richer profile component mappings before real install.
4. Implement real installer only after explicit approval and backup/rollback design.
5. Keep sanitizer and CI as non-negotiable gates.

## What remains before importing real components

- Define migration inventory.
- Transform real prompts into sanitized templates.
- Re-run sanitizer after every import slice.
- Add tests for any imported component.
- Keep databases, logs, backups, and personal config excluded.

## What remains before real cross-machine install

- Implement approved install mode.
- Implement backup and rollback execution.
- Add target-machine validation.
- Test on a clean temporary home/config sandbox.
- Document manual review checkpoints.
