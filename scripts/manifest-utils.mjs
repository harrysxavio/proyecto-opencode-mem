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
  "templates",
  "templates/profiles",
  "agents",
  "agents/manager",
  "agents/sdd",
  "skills",
  "skills/examples",
  "plugins",
  "scripts",
  "tests",
  "tests/fixtures/clean",
  "tests/fixtures/dirty",
  "tests/unit",
  "tests/integration",
  "examples/minimal",
  "examples/agents",
  "examples/sdd",
  "examples/memory-enabled",
  "examples/full",
  ".github/workflows"
];

export const requiredTemplates = [
  "templates/opencode.example.jsonc",
  "templates/AGENTS.example.md",
  "templates/env.example",
  "plugins/engram.template.ts",
  "agents/manager/manager.template.md",
  "agents/sdd/sdd-init.template.md",
  "agents/sdd/sdd-explore.template.md",
  "agents/sdd/sdd-propose.template.md",
  "agents/sdd/sdd-spec.template.md",
  "agents/sdd/sdd-design.template.md",
  "agents/sdd/sdd-tasks.template.md",
  "agents/sdd/sdd-apply.template.md",
  "agents/sdd/sdd-verify.template.md",
  "agents/sdd/sdd-archive.template.md",
  "agents/sdd/sdd-onboard.template.md"
];

export const requiredScripts = [
  "scripts/doctor.mjs",
  "scripts/validate.mjs",
  "scripts/sanitize-check.mjs",
  "scripts/install.mjs",
  "scripts/install-temp.mjs",
  "scripts/backup.mjs",
  "scripts/rollback.mjs",
  "scripts/export-inventory.mjs"
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
