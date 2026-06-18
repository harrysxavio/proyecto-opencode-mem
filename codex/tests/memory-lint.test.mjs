import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { lintMemoryPath } from "../../codex/scripts/memory-lint.mjs";

async function writeMemory(root, name, content) {
  const filePath = path.join(root, name);
  await writeFile(filePath, content, "utf8");
  return filePath;
}

test("lintMemoryPath detects secret-like strings", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "memory-lint-"));
  await writeMemory(
    root,
    "secret.md",
    "title: Bad memory\ncontent: password = hunter2\n"
  );

  const result = await lintMemoryPath(root);

  assert.ok(result.failures.some((failure) => failure.includes("secret-like string")));
});

test("lintMemoryPath detects raw prompt dumps", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "memory-lint-"));
  await writeMemory(
    root,
    "raw-prompt.md",
    "USER PROMPT: please paste this whole conversation into memory\nASSISTANT: ok\n"
  );

  const result = await lintMemoryPath(root);

  assert.ok(result.failures.some((failure) => failure.includes("raw prompt dump")));
});

test("lintMemoryPath detects duplicate topic keys", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "memory-lint-"));
  await writeMemory(root, "one.md", "topic_key: architecture/manager\ncontent: first\n");
  await writeMemory(root, "two.md", "topic_key: architecture/manager\ncontent: duplicate\n");

  const result = await lintMemoryPath(root);

  assert.ok(result.failures.some((failure) => failure.includes("duplicate topic_key architecture/manager")));
});

test("lintMemoryPath requires evidence for decisions", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "memory-lint-"));
  await writeMemory(root, "decision.md", "type: decision\ntopic_key: architecture/codex\ncontent: Manager is primary\n");

  const result = await lintMemoryPath(root);

  assert.ok(result.failures.some((failure) => failure.includes("decision memory missing evidence")));
});

test("lintMemoryPath accepts clean memory notes", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "memory-lint-"));
  await writeMemory(
    root,
    "clean.md",
    "type: decision\ntopic_key: architecture/codex\nevidence: docs/codex/getting-started.md\ncontent: Manager is primary\n"
  );

  const result = await lintMemoryPath(root);

  assert.deepEqual(result.failures, []);
});
