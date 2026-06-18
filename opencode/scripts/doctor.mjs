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
  const home = process.env.USERPROFILE ?? process.env.HOME ?? ".";
  const target = path.resolve(options.target ?? path.join(home, ".config", "opencode"));
  const failures = [];
  const warnings = [];
  const required = [
    "AGENTS.md",
    ".atl/skill-registry.md",
    "skills/opencode-runtime-kit/manager-router/SKILL.md",
    "skills/opencode-runtime-kit/memory-governance/SKILL.md",
    "skills/opencode-runtime-kit/noise-gate/SKILL.md",
    "skills/opencode-runtime-kit/context-pack-builder/SKILL.md",
    "skills/opencode-runtime-kit/token-budgeter/SKILL.md",
    ".opencode-kit/last-install.json"
  ];

  for (const relative of required) {
    if (!existsSync(path.join(target, relative))) failures.push(`Missing ${relative}`);
  }

  const agents = await readIfExists(path.join(target, "AGENTS.md"));
  if (agents.length > 65536) warnings.push("AGENTS.md exceeds 64 KiB; consider moving details to skills");
  if (/[A-Z]:\\/.test(agents)) failures.push("AGENTS.md contains a non-portable Windows absolute path");
  if (agents && !/Manager global/i.test(agents)) failures.push("AGENTS.md does not declare the OpenCode Manager contract");

  const registry = await readIfExists(path.join(target, ".atl", "skill-registry.md"));
  if (registry && !/skills\/opencode-runtime-kit\/manager-router\/SKILL\.md/.test(registry)) {
    failures.push("skill registry has invalid installed paths");
  }
  const registeredSkills = [...registry.matchAll(/\|\s*[^|\n]+\s*\|\s*[^|\n]+\s*\|\s*([^|\n]+SKILL\.md)\s*\|/g)]
    .map((match) => match[1].trim());
  if (registry && registeredSkills.length !== 18) {
    failures.push(`skill registry must contain 18 skills, found ${registeredSkills.length}`);
  }
  for (const relative of registeredSkills) {
    if (!existsSync(path.join(target, relative))) failures.push(`Registry target missing ${relative}`);
  }

  return { target, failures, warnings };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const target = argValue("--target", null) ?? positionalTarget();
  const result = await runOpenCodeDoctor({ target });
  console.log("OpenCode doctor");
  console.log(`Target: ${result.target}`);
  for (const warning of result.warnings) console.log(`Warning: ${warning}`);
  if (result.failures.length) {
    console.error("OPENCODE DOCTOR FAIL");
    for (const failure of result.failures) console.error(`- ${failure}`);
    process.exit(1);
  }
  console.log("OPENCODE DOCTOR PASS");
}
