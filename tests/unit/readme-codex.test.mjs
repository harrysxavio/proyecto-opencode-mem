import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const readme = await readFile("README_CODEX.md", "utf8");

test("README_CODEX explains the architecture in Spanish for non-technical readers first", () => {
  assert.match(readme, /# Arquitectura Codex/i);
  assert.match(readme, /personas no técnicas/i);
  assert.match(readme, /modelo mental/i);
  assert.match(readme, /Codex normal/i);
  assert.match(readme, /Codex con esta arquitectura/i);
  assert.ok(readme.indexOf("personas no técnicas") < readme.indexOf("Vista técnica"));
});

test("README_CODEX documents memory files, Noise Gate, token flow and evidence", () => {
  assert.match(readme, /Manager/i);
  assert.match(readme, /memoria/i);
  assert.match(readme, /archivos de memoria/i);
  assert.match(readme, /Noise Gate/i);
  assert.match(readme, /ruido/i);
  assert.match(readme, /tokens/i);
  assert.match(readme, /flujo/i);
  assert.match(readme, /evidencia/i);
  assert.match(readme, /OpenCode/i);
});

test("README_CODEX documents usage, rollback, audit, improvements and implementation state", () => {
  assert.match(readme, /Cómo usarlo/i);
  assert.match(readme, /Rollback/i);
  assert.match(readme, /Auditoría OpenCode/i);
  assert.match(readme, /Estado actual/i);
  assert.match(readme, /Puntos de mejora/i);
  assert.match(readme, /Qué se mejoró/i);
});

test("README_CODEX stays portable", () => {
  assert.doesNotMatch(readme, /[A-Z]:\\/);
  assert.doesNotMatch(readme, /harry/i);
});
