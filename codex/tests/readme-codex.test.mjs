import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const mainReadme = await readFile("README.md", "utf8");

test("README.md references the unified architecture and runtime quickstarts", () => {
  assert.match(mainReadme, /Runtime Kit/i);
  assert.match(mainReadme, /OpenCode/);
  assert.match(mainReadme, /Codex/);
  assert.match(mainReadme, /contracts\//);
  assert.match(mainReadme, /QUICKSTART_OPENCODE/);
  assert.match(mainReadme, /QUICKSTART_CODEX/);
});

test("README.md documents memory, Noise Gate and tokens", () => {
  assert.match(mainReadme, /memoria/i);
  assert.match(mainReadme, /Noise Gate/i);
  assert.match(mainReadme, /tok/);
  assert.match(mainReadme, /Ponytail/i);
});

test("README.md stays portable", () => {
  assert.doesNotMatch(mainReadme, /[A-Z]:\\/);
  assert.doesNotMatch(mainReadme, /\btu-usuario\b/);
});
