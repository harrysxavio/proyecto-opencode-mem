#!/usr/bin/env node
import { loadManifest } from "./manifest-utils.mjs";

const manifest = await loadManifest();
console.log(`Kit: ${manifest.kitName}`);
console.log("Profiles:");
for (const [name, profile] of Object.entries(manifest.profiles)) {
  console.log(`- ${name}: ${profile.components.join(", ")}`);
}
console.log("Components:");
for (const component of manifest.components) {
  console.log(`- ${component.id} (${component.type})`);
}
