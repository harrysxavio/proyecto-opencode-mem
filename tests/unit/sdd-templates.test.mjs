import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("SDD pipeline contract defines all 8 phases", async () => {
  const text = await readFile(path.join(repoRoot, "contracts", "sdd-pipeline.md"), "utf8");
  assert.match(text, /Explore|Exploración/i);
  assert.match(text, /Proposal|Propuesta/i);
  assert.match(text, /Spec|Especificación/i);
  assert.match(text, /Design|Diseño/i);
  assert.match(text, /Tasks|Tareas/i);
  assert.match(text, /Apply|Aplicación/i);
  assert.match(text, /Verify|Verificación/i);
  assert.match(text, /Archive|Archivo/i);
});
