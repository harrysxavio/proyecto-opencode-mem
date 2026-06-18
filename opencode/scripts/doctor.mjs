#!/usr/bin/env node
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

function argValue(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : fallback;
}

function positionalTarget() {
  const args = process.argv.slice(2);
  const positional = [];
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === "--target") { index += 1; continue; }
    if (!arg.startsWith("--")) positional.push(arg);
  }
  return positional.at(-1);
}

async function readIfExists(filePath) {
  if (!existsSync(filePath)) return "";
  return readFile(filePath, "utf8");
}

export async function runOpenCodeDoctor(options = {}) {
  const target = path.resolve(options.target ?? path.join(process.env.USERPROFILE ?? ".", ".config", "opencode"));
  const failures = [];
  const warnings = [];

  const agents = await readIfExists(path.join(target, "AGENTS.md"));
  if (!agents) failures.push("AGENTS.md not found");
  if (agents.length > 65536) warnings.push("AGENTS.md exceeds 64 KiB — consider splitting gates");
  if (/[A-Z]:\\/.test(agents)) warnings.push("AGENTS.md contains Windows absolute path — not portable");
  if (agents && !/Manager/.test(agents)) failures.push("AGENTS.md does not reference Manager");

  const engramFiles = ["engram.db", "engram.sqlite", ".engram/"];
  const hasEngram = engramFiles.some(f => existsSync(path.join(target, f)));
  if (!hasEngram) warnings.push("Engram database not detected — memory may not persist");

  return { target, failures, warnings };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const target = argValue("--target", null) ?? positionalTarget();
  const result = await runOpenCodeDoctor({ target });
  console.log("OpenCode doctor");
  console.log(`Target: ${result.target}`);
  for (const warning of result.warnings) console.log(`Warning: ${warning}`);
  if (result.failures.length) {
    console.error("OPencode DOCTOR FAIL");
    for (const failure of result.failures) console.error(`- ${failure}`);
    process.exit(1);
  }
  console.log("OPencode DOCTOR PASS");
}
