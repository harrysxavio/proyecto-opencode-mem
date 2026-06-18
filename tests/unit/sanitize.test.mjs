import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import os from "node:os";
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

test("sanitizer allows innocent task-by-task text", async (t) => {
  const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-clean-"));
  t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
  await writeFile(path.join(fixtureRoot, "plan.md"), "Implement this plan task-by-task.\n", "utf8");

  const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

  assert.deepEqual(failures, []);
});

test("sanitizer allows Markdown anchors with sk-prefixed substrings inside words", async (t) => {
  const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-clean-"));
  t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
  const content = [
    "#task-1-establish-the-powershell-test-harness-and-lock-contract",
    `prefixsk-${"a".repeat(32)}`
  ].join("\n");
  await writeFile(path.join(fixtureRoot, "plan.md"), `${content}\n`, "utf8");

  const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

  assert.deepEqual(failures, []);
});

test("sanitizer rejects a sufficiently long synthetic sk-prefixed key", async (t) => {
  const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-secret-"));
  t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
  const prefix = ["s", "k", "-"].join("");
  await writeFile(path.join(fixtureRoot, "secret.txt"), `${prefix}${"a".repeat(32)}\n`, "utf8");

  const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

  assert.ok(failures.some((failure) => failure.includes("forbidden fragment detected")));
});

test("sanitizer rejects synthetic sk-prefixed keys after common delimiters", async (t) => {
  const prefix = ["s", "k", "-"].join("");
  const key = `${prefix}${"a".repeat(32)}`;
  const cases = [key, `token ${key}`, `"${key}"`, `TOKEN=${key}`];

  for (const [index, content] of cases.entries()) {
    await t.test(`delimiter case ${index + 1}`, async (t) => {
      const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "sanitize-secret-"));
      t.after(() => rm(fixtureRoot, { recursive: true, force: true }));
      await writeFile(path.join(fixtureRoot, "secret.txt"), `${content}\n`, "utf8");

      const failures = await scanPath(fixtureRoot, { allowDirtyFixtures: false });

      assert.ok(failures.some((failure) => failure.includes("forbidden fragment detected")));
    });
  }
});
