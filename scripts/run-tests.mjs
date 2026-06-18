#!/usr/bin/env node
/**
 * run-tests.mjs — Cross-platform test runner.
 *
 * Uses node --test's built-in runner with explicit file paths,
 * working around Windows shell glob limitations.
 */
import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { readdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

const dirs = process.argv.slice(2).length
  ? process.argv.slice(2)
  : ["tests", "codex/tests", "opencode/tests"];

function findTestFiles(rootDir, subDir) {
  const fullDir = path.join(rootDir, subDir);
  if (!existsSync(fullDir)) return [];
  const files = [];
  const entries = readdirSync(fullDir, { withFileTypes: true, recursive: true });
  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith(".test.mjs")) {
      const parent = entry.parentPath ?? entry.path;
      files.push(path.join(parent, entry.name));
    }
  }
  return files;
}

function main() {
  const files = dirs.flatMap((dir) => findTestFiles(root, dir));

  if (files.length === 0) {
    console.log("No test files found.");
    process.exit(0);
  }

  try {
    execSync(
      `node --test ${files.map((f) => JSON.stringify(f)).join(" ")}`,
      { cwd: root, stdio: "inherit", shell: true }
    );
    process.exit(0);
  } catch {
    process.exit(1);
  }
}

main();
