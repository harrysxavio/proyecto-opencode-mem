#!/usr/bin/env node
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { repoRoot, requiredDirectories, requiredTemplates } from "./manifest-utils.mjs";

const failures = [];
const warnings = [];

const major = Number.parseInt(process.versions.node.split(".")[0], 10);
if (major < 20) failures.push(`Node >=20 required, found ${process.versions.node}`);

let pnpm = spawnSync("pnpm", ["--version"], { encoding: "utf8", shell: true });
if (pnpm.status !== 0) {
  pnpm = spawnSync("corepack", ["pnpm", "--version"], { encoding: "utf8", shell: true });
}
if (pnpm.status !== 0) warnings.push("pnpm not found; try `corepack enable`.");

for (const dir of requiredDirectories) {
  if (!existsSync(path.join(repoRoot, dir))) failures.push(`Missing directory: ${dir}`);
}

for (const file of ["README.md", "opencode-kit.manifest.json", ...requiredTemplates]) {
  if (!existsSync(path.join(repoRoot, file))) failures.push(`Missing required file: ${file}`);
}

console.log("Doctor checks");
console.log(`- Node: ${process.versions.node}`);
console.log(`- pnpm: ${pnpm.status === 0 ? pnpm.stdout.trim() : "not available"}`);
console.log(`- Repo root: ${path.basename(repoRoot)}`);

if (warnings.length) {
  console.log("Warnings:");
  for (const warning of warnings) console.log(`- ${warning}`);
}

if (failures.length) {
  console.error("Failures:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log("DOCTOR PASS WITH WARNINGS" + (warnings.length ? "" : " (none)"));
