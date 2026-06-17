import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { repoRoot } from "../../scripts/manifest-utils.mjs";

const names = ["init", "explore", "propose", "spec", "design", "tasks", "apply", "verify", "archive", "onboard"];

test("SDD templates exist and contain SUBAGENT_RESULT", async () => {
  for (const name of names) {
    const file = path.join(repoRoot, "agents", "sdd", `sdd-${name}.template.md`);
    const text = await readFile(file, "utf8");
    assert.match(text, /SUBAGENT_RESULT/);
  }
});

test("sdd-init template contains SDD_INIT_PACKET", async () => {
  const text = await readFile(path.join(repoRoot, "agents", "sdd", "sdd-init.template.md"), "utf8");
  assert.match(text, /SDD_INIT_PACKET/);
});
