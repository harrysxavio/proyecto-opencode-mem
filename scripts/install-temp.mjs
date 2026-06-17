#!/usr/bin/env node
import { cp, mkdir, rm, stat } from "node:fs/promises";
import path from "node:path";
import { componentsForProfile, loadManifest, repoRoot } from "./manifest-utils.mjs";

const profileName = process.argv.includes("--profile")
  ? process.argv[process.argv.indexOf("--profile") + 1]
  : "full";

const targetRoot = path.join(repoRoot, "tests", "tmp", "install-temp");
await rm(targetRoot, { recursive: true, force: true });
await mkdir(targetRoot, { recursive: true });

const manifest = await loadManifest();
const components = componentsForProfile(manifest, profileName);
const copied = [];

for (const component of components) {
  for (const item of component.paths) {
    const source = path.join(repoRoot, item);
    const destination = path.join(targetRoot, item);
    const sourceStat = await stat(source);
    await mkdir(path.dirname(destination), { recursive: true });
    await cp(source, destination, { recursive: sourceStat.isDirectory() });
    copied.push(item);
  }
}

console.log(`TEMP INSTALL PASS profile=${profileName}`);
for (const item of copied) console.log(`- ${item}`);
console.log("Target: tests/tmp/install-temp");
