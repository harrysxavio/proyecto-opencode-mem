import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { loadManifest, requiredProfiles } from "../../scripts/manifest-utils.mjs";
import { readFile } from "node:fs/promises";

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

test("manifest declares Codex-first runtime profiles", async () => {
  const manifest = await loadManifest();
  assert.deepEqual(
    manifest.profiles.codex.components,
    ["docs-core", "codex-manager-template", "codex-skills", "codex-memory-governance"]
  );
  assert.deepEqual(
    manifest.profiles["codex-full"].components,
    [
      "docs-core",
      "templates-core",
      "codex-manager-template",
      "codex-skills",
      "sdd-pipeline-contract",
      "memory-governance-contract",
      "validation-harness"
    ]
  );
});

test("manifest component paths stay portable", async () => {
  const manifest = await loadManifest();
  const windowsAbsolutePathPattern = /[A-Z]:\\/;
  for (const component of manifest.components) {
    for (const componentPath of component.paths ?? []) {
      assert.equal(path.isAbsolute(componentPath), false, `${component.id} has absolute path ${componentPath}`);
      assert.equal(
        windowsAbsolutePathPattern.test(componentPath),
        false,
        `${component.id} has Windows absolute path ${componentPath}`
      );
      assert.equal(componentPath.includes(".."), false, `${component.id} escapes repo via ${componentPath}`);
    }
  }
});

test("manifest includes portable Codex Noise Gate skill", async () => {
  const manifest = await loadManifest();
  const codexSkills = manifest.components.find((component) => component.id === "codex-skills");

  assert.ok(codexSkills, "missing codex-skills component");
  assert.ok(codexSkills.paths.includes("skills/noise-gate"));
});

test("package exposes real install, doctor and rollback commands for both runtimes", async () => {
  const packageJson = JSON.parse(await readFile(new URL("../../package.json", import.meta.url), "utf8"));
  for (const runtime of ["codex", "opencode"]) {
    assert.ok(packageJson.scripts[`${runtime}:install:dry-run`]);
    assert.ok(packageJson.scripts[`${runtime}:install`]);
    assert.ok(packageJson.scripts[`${runtime}:doctor`]);
    assert.ok(packageJson.scripts[`${runtime}:rollback:dry-run`]);
    assert.ok(packageJson.scripts[`${runtime}:rollback`]);
  }
});
