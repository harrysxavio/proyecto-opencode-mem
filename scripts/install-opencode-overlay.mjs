#!/usr/bin/env node
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
    if (arg === "--target") {
      index += 1;
      continue;
    }
    if (arg === "--dry-run") continue;
    if (!arg.startsWith("--")) positional.push(arg);
  }
  return positional.at(-1);
}

function normalizeForPolicy(target) {
  return target.split(path.sep).join("/").toLowerCase();
}

export function validateOpenCodeOverlayTarget(target) {
  if (!target || typeof target !== "string") throw new Error("target is required");
  const resolved = path.resolve(target);
  const normalized = normalizeForPolicy(resolved);
  if (normalized.includes("/appdata/local/programs/opencode")) {
    throw new Error("Refusing update-managed OpenCode application directory");
  }
  return resolved;
}

export function buildOpenCodeOverlayPlan(options = {}) {
  const target = validateOpenCodeOverlayTarget(options.target);
  return {
    dryRun: true,
    target,
    status: "plan-only",
    actions: [
      {
        description: "Copy Codex-proven Manager overlay to an OpenCode configuration overlay",
        destination: path.join(target, "AGENTS.md")
      },
      {
        description: "Copy project skill registry and lazy-loaded skills",
        destination: path.join(target, ".atl", "skill-registry.md")
      },
      {
        description: "Run a future OpenCode doctor before enabling real writes",
        destination: path.join(target, ".opencode-kit", "last-install.json")
      }
    ]
  };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const dryRun = process.argv.includes("--dry-run");
  const target = argValue("--target", null) ?? positionalTarget();
  try {
    if (!dryRun) throw new Error("OpenCode overlay installer is dry-run only until the Codex phase is stable");
    const result = buildOpenCodeOverlayPlan({ target });
    console.log("DRY RUN OpenCode overlay plan");
    console.log(`Target: ${result.target}`);
    for (const action of result.actions) {
      console.log(`- ${action.description} -> ${path.relative(result.target, action.destination)}`);
    }
    console.log("No files were written.");
  } catch (error) {
    console.error(`OpenCode overlay install failed: ${error.message}`);
    process.exit(1);
  }
}
