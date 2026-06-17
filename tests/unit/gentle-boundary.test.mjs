import test from "node:test";
import assert from "node:assert/strict";
import { componentsForProfile, loadManifest } from "../../scripts/manifest-utils.mjs";

test("full profile does not include gentle-ai runtime", async () => {
  const manifest = await loadManifest();
  const ids = componentsForProfile(manifest, "full").map((component) => component.id);
  assert.ok(!ids.includes("gentle-ai-runtime"));
});

test("gentle-alignment profile is documentation only", async () => {
  const manifest = await loadManifest();
  const components = componentsForProfile(manifest, "gentle-alignment");
  assert.ok(components.every((component) => ["docs", "template"].includes(component.type)));
});

test("ponytail-code-gate does not install Ponytail plugin by default", async () => {
  const manifest = await loadManifest();
  const ids = componentsForProfile(manifest, "ponytail-code-gate").map((component) => component.id);
  assert.ok(!ids.includes("ponytail-plugin"));
});
