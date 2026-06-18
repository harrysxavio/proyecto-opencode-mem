import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const readme = await readFile("README_CODEX.md", "utf8");
const mainReadme = await readFile("README.md", "utf8");

test("README.md references the unified architecture and runtime quickstarts", () => {
  assert.match(mainReadme, /Runtime Kit/i);
  assert.match(mainReadme, /OpenCode/);
  assert.match(mainReadme, /Codex/);
  assert.match(mainReadme, /contracts\//);
  assert.match(mainReadme, /QUICKSTART_OPENCODE/);
  assert.match(mainReadme, /QUICKSTART_CODEX/);
});

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

test("README_CODEX explains persistent memory across sessions with concrete retrieval and save flows", () => {
  assert.match(readme, /memoria entre sesiones/i);
  assert.match(readme, /memoria persistente/i);
  assert.match(readme, /sesi[oó]n 1/i);
  assert.match(readme, /sesi[oó]n 2/i);
  assert.match(readme, /mem_context/i);
  assert.match(readme, /mem_search/i);
  assert.match(readme, /mem_get_observation/i);
  assert.match(readme, /mem_save/i);
  assert.match(readme, /session summary/i);
});

test("README_CODEX includes expanded end-to-end orchestration examples beyond having skills", () => {
  assert.match(readme, /flujo explosivo/i);
  assert.match(readme, /llamado del usuario/i);
  assert.match(readme, /entrega de la respuesta/i);
  assert.match(readme, /agentes y subagentes/i);
  assert.match(readme, /SUBAGENT_RESULT/i);
  assert.match(readme, /no es solo tener skills/i);
  assert.match(readme, /contexto fijo/i);
  assert.match(readme, /contexto din[aá]mico/i);
  assert.match(readme, /presupuesto de tokens/i);
});


test("README_CODEX stays portable", () => {
  assert.doesNotMatch(readme, /[A-Z]:\\/);
  assert.doesNotMatch(readme, /harry/i);
});
