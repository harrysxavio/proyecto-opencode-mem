import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";
import { scanPath } from "../../scripts/sanitize-check.mjs";

test("sanitizer does not fail on clean fixtures", async () => {
  const failures = await scanPath(path.join(repoRoot, "tests", "fixtures", "clean"), { allowDirtyFixtures: false });
  assert.deepEqual(failures, []);
});

test("sanitizer detects fake secrets in dirty fixtures when not allowed", async () => {
  const failures = await scanPath(path.join(repoRoot, "tests", "fixtures", "dirty"), { allowDirtyFixtures: false });
  assert.ok(failures.length >= 1);
});

test("sanitizer allows innocent task-by-task text", async (t) => {
  const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-clean-"));
  t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
  await writeFile(path.join(fixtureRoot, "plan.md"), "Implement this plan task-by-task.\n", "utf8");

  const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

  assert.deepEqual(failures, []);
});

test("sanitizer rejects a sufficiently long synthetic sk-prefixed key", async (t) => {
  const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-secret-"));
  t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
  const prefix = ["s", "k", "-"].join("");
  await writeFile(path.join(fixtureRoot, "secret.txt"), `${prefix}${"a".repeat(32)}\n`, "utf8");

  const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

  assert.ok(failures.some((failure) => failure.includes("forbidden fragment detected")));
});
