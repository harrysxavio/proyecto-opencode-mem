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
  assert.ok(ids.includes("manager-template"));
  assert.ok(ids.includes("sdd-templates"));
  assert.ok(ids.includes("engram-template"));
  assert.ok(ids.includes("ponytail-guidance"));
});
