import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export const requiredProfiles = [
  "minimal",
  "agents",
  "sdd",
  "memory-enabled",
  "ponytail-code-gate",
  "gentle-alignment",
  "full",
  "codex",
  "codex-full"
];

export const requiredDirectories = [
  "docs",
  "docs/decisions",
  "docs/codex",
  "docs/plan-unificacion",
  "contracts",
  "opencode",
  "opencode/scripts",
  "opencode/tests",
  "opencode/gates",
  "codex",
  "codex/scripts",
  "codex/tests",
  "codex/tests/integration",
  "skills",
  "skills/examples",
  "scripts",
  "tests",
  "tests/fixtures/clean",
  "tests/fixtures/dirty",
  "tests/unit",
  "tests/integration",
  ".github/workflows"
];

export const requiredTemplates = [
  "templates/opencode.example.jsonc",
  "templates/AGENTS.example.md",
  "templates/env.example",
  "opencode/manager.template.md",
  "codex/manager.template.md",
  "contracts/manager.md",
  "contracts/sdd-pipeline.md",
  "contracts/memory-governance.md",
  "contracts/noise-gate.md",
  "contracts/token-discipline.md",
  "contracts/context-pack-schema.md",
  "contracts/ponytail.md"
];

export const requiredScripts = [
  "scripts/doctor.mjs",
  "scripts/validate.mjs",
  "scripts/sanitize-check.mjs",
  "scripts/install.mjs",
  "scripts/install-temp.mjs",
  "scripts/backup.mjs",
  "scripts/rollback.mjs",
  "scripts/export-inventory.mjs",
  "codex/scripts/install-overlay.mjs",
  "codex/scripts/doctor.mjs",
  "codex/scripts/rollback-overlay.mjs",
  "codex/scripts/skill-registry-generate.mjs",
  "opencode/scripts/install-overlay.mjs",
  "opencode/scripts/doctor.mjs",
  "opencode/scripts/rollback-overlay.mjs"
];

export async function loadManifest(root = repoRoot) {
  const raw = await readFile(path.join(root, "opencode-kit.manifest.json"), "utf8");
  return JSON.parse(raw);
}

export function componentsForProfile(manifest, profileName) {
  const profile = manifest.profiles?.[profileName];
  if (!profile) throw new Error(`Unknown profile: ${profileName}`);
  const byId = new Map((manifest.components ?? []).map((component) => [component.id, component]));
  return profile.components.map((id) => {
    const component = byId.get(id);
    if (!component) throw new Error(`Profile ${profileName} references missing component ${id}`);
    return component;
  });
}
