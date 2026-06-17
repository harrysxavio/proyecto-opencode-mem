import test from "node:test";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("install-temp installs full profile into tests tmp only", () => {
  const result = spawnSync(process.execPath, ["scripts/install-temp.mjs", "--profile", "full"], {
    cwd: repoRoot,
    encoding: "utf8"
  });
  assert.equal(result.status, 0, result.stderr);
  const target = path.join(repoRoot, "tests", "tmp", "install-temp");
  assert.ok(existsSync(path.join(target, "templates", "opencode.example.jsonc")));
  assert.ok(existsSync(path.join(target, "agents", "sdd", "sdd-init.template.md")));
  assert.ok(!result.stdout.includes(".config/opencode"));
});
