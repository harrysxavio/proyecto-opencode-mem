#!/usr/bin/env node
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  componentsForProfile,
  loadManifest,
  repoRoot,
  requiredDirectories,
  requiredProfiles,
  requiredScripts,
  requiredTemplates
} from "./manifest-utils.mjs";

export async function validate(root = repoRoot) {
  const failures = [];
  const manifest = await loadManifest(root);

  if (manifest.schemaVersion !== "0.1") failures.push("manifest schemaVersion must be 0.1");
  if (manifest.kitName !== "proyecto-opencode-mem") failures.push("manifest kitName mismatch");

  for (const profile of requiredProfiles) {
    if (!manifest.profiles?.[profile]) failures.push(`Missing profile: ${profile}`);
  }

  const ids = (manifest.components ?? []).map((component) => component.id);
  const uniqueIds = new Set(ids);
  if (ids.length !== uniqueIds.size) failures.push("Component ids must be unique");

  for (const profile of Object.keys(manifest.profiles ?? {})) {
    try {
      componentsForProfile(manifest, profile);
    } catch (error) {
      failures.push(error.message);
    }
  }

  for (const dir of requiredDirectories) {
    if (!existsSync(path.join(root, dir))) failures.push(`Missing directory: ${dir}`);
  }

  for (const file of [...requiredTemplates, ...requiredScripts, "README.md", "package.json", ".github/workflows/validate.yml"]) {
    if (!existsSync(path.join(root, file))) failures.push(`Missing file: ${file}`);
  }

  return { failures, manifest };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { failures } = await validate();
  if (failures.length) {
    console.error("VALIDATE FAIL");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
  }
  console.log("VALIDATE PASS");
}
