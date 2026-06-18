import test from "node:test";
import assert from "node:assert/strict";
import { componentsForProfile, loadManifest } from "../../scripts/manifest-utils.mjs";

test("all profiles resolve their components", async () => {
  const manifest = await loadManifest();
  for (const name of Object.keys(manifest.profiles)) {
    assert.doesNotThrow(() => componentsForProfile(manifest, name));
  }
});

test("full profile includes expected governance components", async () => {
  const manifest = await loadManifest();
  const ids = componentsForProfile(manifest, "full").map((component) => component.id);
  assert.ok(ids.includes("manager-template-opencode"));
  assert.ok(ids.includes("manager-template-codex"));
  assert.ok(ids.includes("manager-contract"));
  assert.ok(ids.includes("sdd-pipeline-contract"));
  assert.ok(ids.includes("memory-governance-contract"));
  assert.ok(ids.includes("ponytail-guidance"));
});

test("codex profile includes only Codex-first overlay components", async () => {
  const manifest = await loadManifest();
  const ids = componentsForProfile(manifest, "codex").map((component) => component.id);
  assert.deepEqual(ids, ["docs-core", "codex-manager-template", "codex-skills", "codex-memory-governance"]);
});

test("codex-full profile adds SDD and validation without OpenCode-specific contracts", async () => {
  const manifest = await loadManifest();
  const ids = componentsForProfile(manifest, "codex-full").map((component) => component.id);
  assert.ok(ids.includes("codex-manager-template"));
  assert.ok(ids.includes("codex-skills"));
  assert.ok(ids.includes("sdd-pipeline-contract"));
  assert.ok(ids.includes("memory-governance-contract"));
  assert.ok(ids.includes("validation-harness"));
  assert.equal(ids.includes("manager-template-opencode"), false);
});
