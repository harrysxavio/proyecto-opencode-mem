#!/usr/bin/env node
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { repoRoot } from "./manifest-utils.mjs";

const includedExtensions = new Set([".md", ".json", ".jsonc", ".mjs", ".js"]);
const ignoredDirs = new Set([".git", "node_modules", "tests/tmp"]);

function toPosix(value) {
  return value.split(path.sep).join("/");
}

function isIgnored(relativePath) {
  const normalized = toPosix(relativePath);
  return Array.from(ignoredDirs).some((ignored) => normalized === ignored || normalized.startsWith(`${ignored}/`));
}

async function walk(root, current = root) {
  const entries = await readdir(current, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(current, entry.name);
    const relative = path.relative(root, full);
    if (isIgnored(relative)) continue;
    if (entry.isDirectory()) files.push(...await walk(root, full));
    else if (entry.isFile() && includedExtensions.has(path.extname(entry.name).toLowerCase())) files.push(full);
  }
  return files;
}

export async function buildTokenBudgetReport(root = repoRoot, options = {}) {
  const limit = options.limit ?? 10;
  const files = await walk(root);
  const rows = [];

  for (const file of files) {
    const info = await stat(file);
    if (info.size > 1024 * 1024) continue;
    const text = await readFile(file, "utf8").catch(() => "");
    rows.push({
      path: toPosix(path.relative(root, file)),
      characters: text.length,
      estimatedTokens: Math.ceil(text.length / 4)
    });
  }

  rows.sort((a, b) => b.characters - a.characters || a.path.localeCompare(b.path));
  const totalCharacters = rows.reduce((sum, row) => sum + row.characters, 0);
  const largestFiles = rows.slice(0, limit);
  const lazyLoadCandidates = rows
    .filter((row) => row.characters >= 1000 && /^(docs|templates|skills|agents)\//.test(row.path))
    .slice(0, limit);

  return {
    totalFiles: rows.length,
    totalCharacters,
    estimatedTokens: Math.ceil(totalCharacters / 4),
    largestFiles,
    lazyLoadCandidates
  };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = await buildTokenBudgetReport();
  console.log(JSON.stringify(report, null, 2));
}
