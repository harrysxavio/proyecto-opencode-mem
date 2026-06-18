import test from "node:test";
import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { installCodexOverlay } from "../../scripts/install-codex-overlay.mjs";
import { rollbackCodexOverlay, buildCodexRollbackPlan } from "../../scripts/rollback-codex-overlay.mjs";

test("buildCodexRollbackPlan uses last install metadata by default", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-rollback-"));
  await writeFile(path.join(target, "AGENTS.md"), "existing agents", "utf8");
  await installCodexOverlay({ target, dryRun: false, backupId: "rollback-test" });

  const plan = await buildCodexRollbackPlan({ target, dryRun: true });

  assert.equal(plan.backupId, "rollback-test");
  assert.equal(plan.dryRun, true);
  assert.ok(plan.restore.some((item) => item.relativePath === "AGENTS.md"));
  assert.ok(plan.remove.some((item) => item.relativePath === ".atl/skill-registry.md"));
});

test("rollbackCodexOverlay restores backed up files and removes new installed files", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-rollback-"));
  await writeFile(path.join(target, "AGENTS.md"), "existing agents", "utf8");
  await installCodexOverlay({ target, dryRun: false, backupId: "rollback-test" });

  const result = await rollbackCodexOverlay({ target, dryRun: false });
  const agents = await readFile(path.join(target, "AGENTS.md"), "utf8");
  const rollbackMetadata = JSON.parse(await readFile(path.join(target, ".opencode-kit", "last-rollback.json"), "utf8"));

  assert.equal(result.backupId, "rollback-test");
  assert.equal(agents, "existing agents");
  assert.equal(existsSync(path.join(target, ".atl", "skill-registry.md")), false);
  assert.ok(rollbackMetadata.restored.includes("AGENTS.md"));
});

test("rollbackCodexOverlay rejects update-managed OpenCode app directories", async () => {
  await assert.rejects(
    () => buildCodexRollbackPlan({
      target: path.join("Users", "example", "AppData", "Local", "Programs", "OpenCode"),
      dryRun: true
    }),
    /update-managed/
  );
});