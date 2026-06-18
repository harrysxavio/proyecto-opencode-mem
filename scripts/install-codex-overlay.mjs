#!/usr/bin/env node
import { access, cp, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { repoRoot } from "./manifest-utils.mjs";

const overlayFiles = [
  {
    source: "templates/codex/AGENTS.codex.example.md",
    destination: "AGENTS.md"
  },
  {
    source: ".atl/skill-registry.md",
    destination: ".atl/skill-registry.md"
  },
  {
    source: "skills/manager-router",
    destination: "skills/opencode-runtime-kit/manager-router"
  },
  {
    source: "skills/memory-governance",
    destination: "skills/opencode-runtime-kit/memory-governance"
  },
  {
    source: "skills/noise-gate",
    destination: "skills/opencode-runtime-kit/noise-gate"
  },
  {
    source: "skills/context-pack-builder",
    destination: "skills/opencode-runtime-kit/context-pack-builder"
  },
  {
    source: "skills/token-budgeter",
    destination: "skills/opencode-runtime-kit/token-budgeter"
  },
  {
    source: "skills/work-unit-commits",
    destination: "skills/opencode-runtime-kit/work-unit-commits"
  },
  {
    source: "skills/chained-pr",
    destination: "skills/opencode-runtime-kit/chained-pr"
  },
  {
    source: "skills/branch-pr",
    destination: "skills/opencode-runtime-kit/branch-pr"
  },
  {
    source: "skills/issue-creation",
    destination: "skills/opencode-runtime-kit/issue-creation"
  },
  {
    source: "skills/judgment-day",
    destination: "skills/opencode-runtime-kit/judgment-day"
  },
  {
    source: "skills/deploy-security-gate",
    destination: "skills/opencode-runtime-kit/deploy-security-gate"
  },
  {
    source: "skills/cognitive-doc-design",
    destination: "skills/opencode-runtime-kit/cognitive-doc-design"
  },
  {
    source: "skills/flow-diagram",
    destination: "skills/opencode-runtime-kit/flow-diagram"
  },
  {
    source: "skills/web-design-guidelines",
    destination: "skills/opencode-runtime-kit/web-design-guidelines"
  },
  {
    source: "skills/skill-improver",
    destination: "skills/opencode-runtime-kit/skill-improver"
  },
  {
    source: "skills/bigquery-table-cleaning",
    destination: "skills/opencode-runtime-kit/bigquery-table-cleaning"
  },
  {
    source: "skills/sandbox-data-loader",
    destination: "skills/opencode-runtime-kit/sandbox-data-loader"
  },
  {
    source: "skills/sql-learning",
    destination: "skills/opencode-runtime-kit/sql-learning"
  }
];

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

export function validateCodexOverlayTarget(target) {
  if (!target || typeof target !== "string") throw new Error("target is required");
  const normalized = normalizeForPolicy(path.resolve(target));
  if (normalized.includes("/appdata/local/programs/opencode")) {
    throw new Error("Refusing update-managed OpenCode application directory");
  }
  return path.resolve(target);
}

export async function buildCodexOverlayPlan(options = {}) {
  const target = validateCodexOverlayTarget(options.target ?? path.join(process.env.USERPROFILE ?? process.env.HOME ?? ".", ".codex"));
  const backupId = options.backupId ?? new Date().toISOString().replace(/[:.]/g, "-");
  return {
    dryRun: Boolean(options.dryRun),
    target,
    backupId,
    backupDir: path.join(target, ".opencode-kit-backups", backupId),
    actions: overlayFiles.map((file) => ({
      source: file.source,
      destination: path.join(target, file.destination),
      relativeDestination: file.destination
    }))
  };
}

async function copyIfExists(source, destination) {
  await mkdir(path.dirname(destination), { recursive: true });
  await cp(source, destination, { recursive: true, force: true });
}

async function pathExists(candidate) {
  try {
    await access(candidate);
    return true;
  } catch {
    return false;
  }
}

async function backupDestinationIfExists(action, backupDir) {
  if (!await pathExists(action.destination)) return null;
  const backupPath = path.join(backupDir, action.relativeDestination);
  await mkdir(path.dirname(backupPath), { recursive: true });
  await cp(action.destination, backupPath, { recursive: true, force: true });
  return action.relativeDestination;
}

export async function installCodexOverlay(options = {}) {
  const plan = await buildCodexOverlayPlan(options);
  if (plan.dryRun) return plan;

  await mkdir(plan.backupDir, { recursive: true });
  const written = [];
  const backedUp = [];

  for (const action of plan.actions) {
    const source = path.join(repoRoot, action.source);
    const backup = await backupDestinationIfExists(action, plan.backupDir);
    if (backup) backedUp.push(backup);
    await copyIfExists(source, action.destination);
    written.push(action.relativeDestination);
  }

  const metadata = {
    backupId: plan.backupId,
    installedAt: new Date().toISOString(),
    files: written,
    backedUp
  };
  const metadataPath = path.join(plan.target, ".opencode-kit", "last-install.json");
  await mkdir(path.dirname(metadataPath), { recursive: true });
  await writeFile(metadataPath, JSON.stringify(metadata, null, 2), "utf8");
  await writeFile(path.join(plan.backupDir, "manifest.json"), JSON.stringify(metadata, null, 2), "utf8");

  return { ...plan, dryRun: false, written };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const dryRun = process.argv.includes("--dry-run");
  const explicitTarget = argValue("--target", null) ?? positionalTarget();
  const target = explicitTarget ?? path.join(process.env.USERPROFILE ?? process.env.HOME ?? ".", ".codex");
  try {
    if (!dryRun && !explicitTarget) {
      throw new Error("Real install requires explicit --target to avoid accidental writes");
    }
    const result = await installCodexOverlay({ target, dryRun });
    console.log(`${dryRun ? "DRY RUN " : ""}Codex overlay install plan`);
    console.log(`Target: ${result.target}`);
    console.log(`Backup: ${result.backupDir}`);
    for (const action of result.actions) {
      console.log(`- ${action.source} -> ${action.relativeDestination}`);
    }
    if (dryRun) console.log("No files were written.");
    else console.log(`Installed files: ${result.written.length}`);
  } catch (error) {
    console.error(`Codex overlay install failed: ${error.message}`);
    process.exit(1);
  }
}
