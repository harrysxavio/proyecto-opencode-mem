import test from "node:test";
import assert from "node:assert/strict";
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
