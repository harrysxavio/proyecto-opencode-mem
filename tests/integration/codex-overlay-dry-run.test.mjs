import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readdir } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("codex overlay dry-run writes nothing to target", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-dry-run-"));
  const result = spawnSync(
    process.execPath,
    ["scripts/install-codex-overlay.mjs", "--dry-run", "--target", target],
    { cwd: repoRoot, encoding: "utf8" }
  );
  const entries = await readdir(target);

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /DRY RUN Codex overlay install plan/);
  assert.deepEqual(entries, []);
});

test("codex overlay dry-run accepts positional target for npm-run compatibility", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-dry-run-"));
  const result = spawnSync(
    process.execPath,
    ["scripts/install-codex-overlay.mjs", "--dry-run", target],
    { cwd: repoRoot, encoding: "utf8" }
  );

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, new RegExp(target.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&")));
});

test("codex overlay real install refuses missing explicit target", () => {
  const result = spawnSync(process.execPath, ["scripts/install-codex-overlay.mjs"], {
    cwd: repoRoot,
    encoding: "utf8"
  });

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /explicit --target/);
});

test("codex doctor accepts positional target for npm-run compatibility", async () => {
  const target = await mkdtemp(path.join(os.tmpdir(), "codex-overlay-doctor-"));
  const install = spawnSync(process.execPath, ["scripts/install-codex-overlay.mjs", target], {
    cwd: repoRoot,
    encoding: "utf8"
  });
  assert.equal(install.status, 0, install.stderr);

  const doctor = spawnSync(process.execPath, ["scripts/codex-doctor.mjs", target], {
    cwd: repoRoot,
    encoding: "utf8"
  });

  assert.equal(doctor.status, 0, doctor.stderr);
  assert.match(doctor.stdout, /CODEX DOCTOR PASS/);
});
