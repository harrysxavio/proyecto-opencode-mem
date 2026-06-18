import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readdir, readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("opencode manager template defines full orchestration protocol", async () => {
  const doc = await readFile(path.join(repoRoot, "opencode/manager.template.md"), "utf8");

  assert.match(doc, /Manager global/i);
  assert.match(doc, /Clasificación de Solicitudes|Request Classification/i);
  assert.match(doc, /SDD Pipeline/i);
});

test("opencode overlay dry-run writes nothing to target", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "opencode-overlay-dry-run-"));
  const result = spawnSync(
    process.execPath,
    ["opencode/scripts/install-overlay.mjs", "--dry-run", "--target", target],
    { cwd: repoRoot, encoding: "utf8" }
  );
  const entries = await readdir(target);

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /DRY RUN OpenCode overlay plan/);
  assert.deepEqual(entries, []);
});

test("opencode overlay rejects update-managed application directories", () => {
  const appDir = path.join("Users", "example", "AppData", "Local", "Programs", "OpenCode");
  const result = spawnSync(
    process.execPath,
    ["opencode/scripts/install-overlay.mjs", "--dry-run", "--target", appDir],
    { cwd: repoRoot, encoding: "utf8" }
  );

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /update-managed OpenCode application directory/);
});

test("opencode overlay refuses real install until the Codex phase is stable", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "opencode-overlay-real-"));
  const result = spawnSync(process.execPath, ["opencode/scripts/install-overlay.mjs", "--target", target], {
    cwd: repoRoot,
    encoding: "utf8"
  });

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /dry-run only/);
});