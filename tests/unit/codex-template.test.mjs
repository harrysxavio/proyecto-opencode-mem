import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

const templatePath = path.join(repoRoot, "templates/codex/AGENTS.codex.example.md");
const guidePath = path.join(repoRoot, "docs/codex-runtime.md");

async function readProjectFile(filePath) {
  return readFile(filePath, "utf8");
}

test("Codex Manager overlay template defines the required runtime contract", async () => {
  const text = await readProjectFile(templatePath);
  assert.match(text, /Manager is the single primary orchestrator/i);
  assert.match(text, /default to short answers/i);
  assert.match(text, /Memory retrieval/i);
  assert.match(text, /lazy-load skills/i);
  assert.match(text, /Context Pack/i);
  assert.match(text, /Do not modify update-managed application directories/i);
});

test("Codex runtime guide explains install safety, rollback and beginner workflow", async () => {
  const text = await readProjectFile(guidePath);
  assert.match(text, /Codex Runtime Orchestrator/i);
  assert.match(text, /user-owned overlay/i);
  assert.match(text, /backup/i);
  assert.match(text, /rollback/i);
  assert.match(text, /beginner workflow/i);
  assert.match(text, /OpenCode/i);
});

test("Codex template and guide stay portable", async () => {
  const texts = [await readProjectFile(templatePath), await readProjectFile(guidePath)];
  const forbiddenPatterns = [
    /[A-Z]:\\/,
    /AppData\\Local\\Programs\\OpenCode/i,
    /OneDrive\\Documentos/i
  ];
  for (const text of texts) {
    for (const pattern of forbiddenPatterns) {
      assert.equal(pattern.test(text), false, `matched forbidden pattern ${pattern}`);
    }
  }
});
