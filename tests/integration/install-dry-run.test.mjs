import test from "node:test";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("install dry-run full does not create temp install output", () => {
  const tempTarget = path.join(repoRoot, "tests", "tmp", "dry-run-should-not-exist");
  const result = spawnSync(process.execPath, ["scripts/install.mjs", "--dry-run", "--profile", "full"], {
    cwd: repoRoot,
    encoding: "utf8"
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /DRY RUN install plan/);
  assert.equal(existsSync(tempTarget), false);
});
