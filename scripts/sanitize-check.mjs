#!/usr/bin/env node
import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { repoRoot } from "./manifest-utils.mjs";

const forbiddenFragments = [
  ["C:", "Users", "harry"].join("\\"),
  ["harry", "syusti"].join(""),
  ["g", "h", "p", "_"].join(""),
  ["s", "k", "-"].join(""),
  ["A", "K", "I", "A"].join("")
];

const forbiddenPathExtensions = new Set([".db", ".sqlite", ".sqlite3", ".bak", ".log"]);
const windowsAbsolutePathPattern = /[A-Z]:\\(?!\$\{)/;
const emailPattern = /[A-Z0-9._%+-]+@(?!example\.com\b)[A-Z0-9.-]+\.[A-Z]{2,}/iu;

function toPosix(relativePath) {
  return relativePath.split(path.sep).join("/");
}

function isIgnored(relativePath) {
  const normalized = toPosix(relativePath);
  return normalized === ".git" || normalized.startsWith(".git/") ||
    normalized === "node_modules" || normalized.startsWith("node_modules/") ||
    normalized === "tests/tmp" || normalized.startsWith("tests/tmp/");
}

function isDirtyFixture(relativePath) {
  return toPosix(relativePath).startsWith("tests/fixtures/dirty/");
}

async function walk(root, current = root) {
  const entries = await readdir(current, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(current, entry.name);
    const relative = path.relative(root, full);
    if (isIgnored(relative)) continue;
    if (entry.isDirectory()) files.push(...await walk(root, full));
    else if (entry.isFile()) files.push(relative);
  }
  return files;
}

export async function scanPath(root = repoRoot, options = {}) {
  const allowDirtyFixtures = options.allowDirtyFixtures ?? true;
  const failures = [];
  const files = await walk(root);

  for (const relative of files) {
    const normalized = toPosix(relative);
    const dirtyAllowed = allowDirtyFixtures && isDirtyFixture(relative);
    const extension = path.extname(relative).toLowerCase();
    const basename = path.basename(relative);

    if (!dirtyAllowed) {
      if (basename === ".env" || /^\.env\./.test(basename)) failures.push(`${normalized}: real env file is forbidden`);
      if (forbiddenPathExtensions.has(extension)) failures.push(`${normalized}: forbidden file extension ${extension}`);
    }

    const info = await stat(path.join(root, relative));
    if (info.size > 1024 * 1024) continue;
    const text = await readFile(path.join(root, relative), "utf8").catch(() => "");
    if (!text || dirtyAllowed) continue;

    for (const fragment of forbiddenFragments) {
      if (text.includes(fragment)) failures.push(`${normalized}: forbidden fragment detected`);
    }
    if (windowsAbsolutePathPattern.test(text)) failures.push(`${normalized}: absolute Windows path detected`);
    if (emailPattern.test(text)) failures.push(`${normalized}: non-example email detected`);
  }

  return failures;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const failures = await scanPath();
  if (failures.length) {
    console.error("SANITIZE CHECK FAIL");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
  }
  console.log("SANITIZE CHECK PASS");
}
