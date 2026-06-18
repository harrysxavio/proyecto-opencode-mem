import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readdir, readFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
  buildCodexOverlayPlan,
  installCodexOverlay,
  validateCodexOverlayTarget
} from "../../scripts/install-codex-overlay.mjs";
import { runCodexDoctor } from "../../scripts/codex-doctor.mjs";

test("buildCodexOverlayPlan reports dry-run actions without writing files", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-"));
  const plan = await buildCodexOverlayPlan({ target, dryRun: true });
  const entries = await readdir(target);

  assert.equal(plan.dryRun, true);
  assert.ok(plan.backupId);
  assert.ok(plan.actions.some((action) => action.destination.endsWith("AGENTS.md")));
  assert.deepEqual(entries, []);
});

test("validateCodexOverlayTarget rejects update-managed OpenCode app directories", () => {
  assert.throws(
    () => validateCodexOverlayTarget(path.join("Users", "example", "AppData", "Local", "Programs", "OpenCode")),
    /update-managed/
  );
});

test("installCodexOverlay writes overlay files and rollback metadata into fixture target", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-"));
  const result = await installCodexOverlay({ target, dryRun: false });

  const agents = await readFile(path.join(target, "AGENTS.md"), "utf8");
  const metadata = JSON.parse(await readFile(path.join(target, ".opencode-kit", "last-install.json"), "utf8"));

  assert.equal(result.dryRun, false);
  assert.match(agents, /Manager is the single primary orchestrator/);
  assert.ok(metadata.backupId);
  assert.ok(metadata.files.includes("AGENTS.md"));
});

test("runCodexDoctor validates installed overlay", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-"));
  await installCodexOverlay({ target, dryRun: false });

  const result = await runCodexDoctor({ target });

  assert.deepEqual(result.failures, []);
});
