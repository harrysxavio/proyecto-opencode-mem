import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("Engram template has memory governance sections and no personal paths", async () => {
  const text = await readFile(path.join(repoRoot, "plugins", "engram.template.ts"), "utf8");
  assert.match(text, /noiseGate/);
  assert.match(text, /memContextGuidance/);
  assert.match(text, /f4cScore/);
  assert.equal(text.includes(["C:", "Users"].join("\\")), false);
});
