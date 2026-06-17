import test from "node:test";
import assert from "node:assert/strict";
import { loadManifest, requiredProfiles } from "../../scripts/manifest-utils.mjs";

test("manifest is valid JSON with required profiles", async () => {
  const manifest = await loadManifest();
  assert.equal(manifest.schemaVersion, "0.1");
  assert.equal(manifest.kitName, "proyecto-opencode-mem");
  for (const profile of requiredProfiles) assert.ok(manifest.profiles[profile], `missing ${profile}`);
});

test("component ids are unique", async () => {
  const manifest = await loadManifest();
  const ids = manifest.components.map((component) => component.id);
  assert.equal(new Set(ids).size, ids.length);
});
