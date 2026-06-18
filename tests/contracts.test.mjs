import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const dir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(dir, "..");

const contracts = [
  { id: "manager", file: "contracts/manager.md" },
  { id: "sdd-pipeline", file: "contracts/sdd-pipeline.md" },
  { id: "memory-governance", file: "contracts/memory-governance.md" },
  { id: "noise-gate", file: "contracts/noise-gate.md" },
  { id: "token-discipline", file: "contracts/token-discipline.md" },
  { id: "context-pack-schema", file: "contracts/context-pack-schema.md" },
  { id: "ponytail", file: "contracts/ponytail.md" },
];

for (const contract of contracts) {
  test(`contract ${contract.id} exists and has Runtime Adaptations section`, async () => {
    const content = await readFile(path.join(repoRoot, contract.file), "utf8");
    assert.match(content, /# Contrato:/, `${contract.file}: missing title`);
    assert.match(content, /## Runtime Adaptations/, `${contract.file}: missing Runtime Adaptations section`);
    assert.ok(content.length < 5000, `${contract.file}: over 5 KiB`);
  });
}
