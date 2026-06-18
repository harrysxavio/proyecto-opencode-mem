import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync } from "node:fs";
import path from "node:path";
import os from "node:os";
import { runOpenCodeDoctor } from "../scripts/doctor.mjs";
import { installOpenCodeOverlay } from "../scripts/install-overlay.mjs";

test("OpenCode doctor reports missing AGENTS.md in empty target", async () => {
  const tmpDir = mkdtempSync(path.join(os.tmpdir(), "oc-doctor-"));
  const result = await runOpenCodeDoctor({ target: tmpDir });
  assert.ok(result.failures.length > 0);
  assert.ok(result.failures.some(f => f.includes("AGENTS.md")));
});

test("OpenCode doctor passes after a complete overlay install", async () => {
  const tmpDir = mkdtempSync(path.join(os.tmpdir(), "oc-doctor-ok-"));
  await installOpenCodeOverlay({ target: tmpDir, backupId: "doctor-test" });
  const result = await runOpenCodeDoctor({ target: tmpDir });
  assert.equal(result.failures.length, 0);
});
