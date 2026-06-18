import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

const templatePath = path.join(repoRoot, "codex/manager.template.md");
const gettingStartedPath = path.join(repoRoot, "docs/codex/getting-started.md");
const troubleshootingPath = path.join(repoRoot, "docs/codex/troubleshooting.md");

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

test("Codex install docs explain install, backup and rollback", async () => {
  const text = await readProjectFile(gettingStartedPath);
  assert.match(text, /Instalar el overlay|Dry-run/i);
  assert.match(text, /backup/i);
  assert.match(text, /Rollback/i);
  assert.match(text, /5 pasos|Getting Started/i);
  assert.match(text, /Codex|OpenCode/i);
});

test("Codex templates and docs stay portable", async () => {
  const texts = [await readProjectFile(templatePath), await readProjectFile(gettingStartedPath), await readProjectFile(troubleshootingPath)];
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
