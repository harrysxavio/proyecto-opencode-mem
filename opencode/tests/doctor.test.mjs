import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import path from "node:path";
import os from "node:os";
import { runOpenCodeDoctor } from "../scripts/doctor.mjs";

test("OpenCode doctor reports missing AGENTS.md in empty target", async () => {
  const tmpDir = mkdtempSync(path.join(os.tmpdir(), "oc-doctor-"));
  const result = await runOpenCodeDoctor({ target: tmpDir });
  assert.ok(result.failures.length > 0);
  assert.ok(result.failures.some(f => f.includes("AGENTS.md")));
});

test("OpenCode doctor passes with valid AGENTS.md", async () => {
  const tmpDir = mkdtempSync(path.join(os.tmpdir(), "oc-doctor-ok-"));
  writeFileSync(path.join(tmpDir, "AGENTS.md"), "# Manager\nSoy el Manager.");
  const result = await runOpenCodeDoctor({ target: tmpDir });
  assert.equal(result.failures.length, 0);
});
