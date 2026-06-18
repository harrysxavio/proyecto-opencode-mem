import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

test("Memory governance contract defines write rules, retrieval and quality", async () => {
  const text = await readFile(path.join(repoRoot, "contracts", "memory-governance.md"), "utf8");
  assert.match(text, /memoria persistente|persistent memory/i);
  assert.match(text, /Reglas de escritura|write rules/i);
  assert.match(text, /recupera|retrieval|recuperación/i);
  assert.equal(text.includes(["C:", "Users"].join("\\")), false);
});
