import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { buildTokenBudgetReport } from "../../scripts/token-budget-report.mjs";

test("buildTokenBudgetReport estimates largest files and lazy-load candidates", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "token-report-"));
  await mkdir(path.join(root, "docs"), { recursive: true });
  await mkdir(path.join(root, "templates"), { recursive: true });
  await writeFile(path.join(root, "README.md"), "short readme\n", "utf8");
  await writeFile(path.join(root, "docs", "large.md"), `${"large content ".repeat(300)}\n`, "utf8");
  await writeFile(path.join(root, "templates", "AGENTS.example.md"), `${"instruction ".repeat(120)}\n`, "utf8");

  const report = await buildTokenBudgetReport(root, { limit: 2 });

  assert.ok(report.totalCharacters > 0);
  assert.equal(report.largestFiles.length, 2);
  assert.equal(report.largestFiles[0].path, "docs/large.md");
  assert.ok(report.lazyLoadCandidates.some((candidate) => candidate.path === "docs/large.md"));
  assert.ok(report.estimatedTokens > 0);
});
