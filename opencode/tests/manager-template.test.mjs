import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const dir = path.dirname(fileURLToPath(import.meta.url));
const templatePath = path.resolve(dir, "../manager.template.md");

test("OpenCode Manager template defines all required sections", async () => {
  const text = await readFile(templatePath, "utf8");
  assert.match(text, /Manager/i);
  assert.match(text, /Clasificación/i);
  assert.match(text, /Brainstorming/i);
  assert.match(text, /Diseño y Aprobación/i);
  assert.match(text, /Graphify/i);
  assert.match(text, /SDD/i);
  assert.match(text, /Frontend Design/i);
  assert.match(text, /TDD/i);
  assert.match(text, /Code Review/i);
  assert.match(text, /GPT-5\.5/i);
  assert.match(text, /Debugging/i);
  assert.match(text, /Engram/i);
  assert.match(text, /Ponytail/i);
  assert.match(text, /Fast-Track/i);
  assert.match(text, /Default Behavior/i);
  assert.match(text, /Completion Contract/i);
});

test("OpenCode Manager template stays portable", async () => {
  const text = await readFile(templatePath, "utf8");
  const forbidden = [/[A-Z]:\\/, /AppData\\Local\\Programs\\OpenCode/i, /OneDrive\\Documentos/i];
  for (const pattern of forbidden) {
    assert.equal(pattern.test(text), false, `matched forbidden pattern ${pattern}`);
  }
});

test("OpenCode Manager template does not exceed size budget", async () => {
  const text = await readFile(templatePath, "utf8");
  assert.ok(text.length < 65536, `template too large: ${text.length} chars`);
});
