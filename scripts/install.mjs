#!/usr/bin/env node
import { componentsForProfile, loadManifest } from "./manifest-utils.mjs";

function argValue(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : fallback;
}

const dryRun = process.argv.includes("--dry-run");
const profileName = argValue("--profile", "full");

if (!dryRun) {
  console.error("Real installation is blocked in Phase 0. Re-run with --dry-run.");
  process.exit(1);
}

const manifest = await loadManifest();
const components = componentsForProfile(manifest, profileName);

console.log(`DRY RUN install plan for profile: ${profileName}`);
for (const component of components) {
  console.log(`- ${component.id} (${component.type})`);
  for (const filePath of component.paths) console.log(`  - ${filePath}`);
}
console.log("No files were written outside the repository.");
