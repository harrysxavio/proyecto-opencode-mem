import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { validateContextPackFile } from "../../scripts/context-pack-check.mjs";

async function writePack(root, name, pack) {
  const filePath = path.join(root, name);
  await writeFile(filePath, JSON.stringify(pack, null, 2), "utf8");
  return filePath;
}

function validPack(overrides = {}) {
  return {
    request_id: "20260618-1200-small",
    classification: "small",
    token_budget: 1200,
    included: [
      {
        kind: "file",
        ref: "docs/codex-runtime.md",
        reason: "Codex runtime guide defines the target behavior",
        sensitivity: "low"
      }
    ],
    excluded: [
      {
        ref: "docs/archive/old-notes.md",
        reason: "not relevant"
      }
    ],
    ...overrides
  };
}

test("validateContextPackFile accepts a valid context pack", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "context-pack-"));
  const filePath = await writePack(root, "valid-small.json", validPack());

  const result = await validateContextPackFile(filePath);

  assert.deepEqual(result.failures, []);
});

test("validateContextPackFile rejects over-budget packs", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "context-pack-"));
  const filePath = await writePack(root, "invalid-over-budget.json", validPack({ token_budget: 0 }));

  const result = await validateContextPackFile(filePath);

  assert.ok(result.failures.some((failure) => failure.includes("token_budget")));
});

test("validateContextPackFile rejects high-sensitivity included items", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "context-pack-"));
  const filePath = await writePack(
    root,
    "invalid-sensitive.json",
    validPack({
      included: [
        {
          kind: "memory",
          ref: "secret-observation",
          reason: "should not be injected",
          sensitivity: "high"
        }
      ]
    })
  );

  const result = await validateContextPackFile(filePath);

  assert.ok(result.failures.some((failure) => failure.includes("high sensitivity")));
});

test("validateContextPackFile requires included kind, ref and reason", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "context-pack-"));
  const filePath = await writePack(
    root,
    "invalid-missing-included-fields.json",
    validPack({ included: [{ kind: "doc", ref: "docs/codex-runtime.md" }] })
  );

  const result = await validateContextPackFile(filePath);

  assert.ok(result.failures.some((failure) => failure.includes("included[0].reason")));
});

test("validateContextPackFile limits included context to eight items by default", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "context-pack-"));
  const included = Array.from({ length: 9 }, (_, index) => ({
    kind: "file",
    ref: `docs/example-${index}.md`,
    reason: "bounded context fixture",
    sensitivity: "low"
  }));
  const filePath = await writePack(root, "invalid-too-many-items.json", validPack({ included }));

  const result = await validateContextPackFile(filePath);

  assert.ok(result.failures.some((failure) => failure.includes("at most 8")));
});
