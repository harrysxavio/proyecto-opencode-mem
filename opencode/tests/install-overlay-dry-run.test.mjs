import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readdir, readFile, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";
import { installOpenCodeOverlay } from "../scripts/install-overlay.mjs";
import { buildOpenCodeRollbackPlan, rollbackOpenCodeOverlay } from "../scripts/rollback-overlay.mjs";
import { runOpenCodeDoctor } from "../scripts/doctor.mjs";

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
  assert.match(result.stdout, /DRY RUN OpenCode overlay install plan/);
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

test("opencode overlay installs a complete, verifiable overlay", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "opencode-overlay-real-"));
  const result = await installOpenCodeOverlay({ target, backupId: "install-test" });
  const agents = await readFile(path.join(target, "AGENTS.md"), "utf8");
  const registry = await readFile(path.join(target, ".atl", "skill-registry.md"), "utf8");
  const doctor = await runOpenCodeDoctor({ target });

  assert.equal(result.dryRun, false);
  assert.match(agents, /Manager global/i);
  assert.match(registry, /skills\/opencode-runtime-kit\/manager-router\/SKILL\.md/);
  assert.deepEqual(doctor.failures, []);
});

test("opencode rollback restores pre-existing files", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "opencode-overlay-rollback-"));
  await writeFile(path.join(target, "AGENTS.md"), "original manager", "utf8");
  await installOpenCodeOverlay({ target, backupId: "rollback-test" });

  const result = await rollbackOpenCodeOverlay({ target });
  const agents = await readFile(path.join(target, "AGENTS.md"), "utf8");

  assert.equal(result.backupId, "rollback-test");
  assert.equal(agents, "original manager");
});

test("opencode rollback rejects backup ids that escape the target", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "opencode-overlay-rollback-"));
  await installOpenCodeOverlay({ target, backupId: "safe-backup" });
  await assert.rejects(
    () => buildOpenCodeRollbackPlan({ target, backupId: "../outside", dryRun: true }),
    /invalid backupId/
  );
});
