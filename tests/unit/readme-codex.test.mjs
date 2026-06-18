import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const readme = await readFile("README_CODEX.md", "utf8");

test("README_CODEX explains Codex architecture for beginners and technical users", () => {
  assert.match(readme, /# Codex Runtime Architecture/i);
  assert.match(readme, /Beginner model/i);
  assert.match(readme, /Technical model/i);
  assert.match(readme, /Manager/i);
  assert.match(readme, /memory/i);
  assert.match(readme, /token/i);
});

test("README_CODEX documents usage, rollback, audit and implementation state", () => {
  assert.match(readme, /How to use it/i);
  assert.match(readme, /Rollback/i);
  assert.match(readme, /OpenCode audit/i);
  assert.match(readme, /Current state/i);
});

test("README_CODEX stays portable", () => {
  assert.doesNotMatch(readme, /[A-Z]:\\/);
  assert.doesNotMatch(readme, /harry/i);
});