#!/usr/bin/env node
import { access, cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateOpenCodeOverlayTarget } from "./install-overlay.mjs";

function argValue(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : fallback;
}

function positionalTarget() {
  const args = process.argv.slice(2);
  const positional = [];
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === "--target" || arg === "--backup-id") {
      index += 1;
      continue;
    }
    if (arg === "--dry-run") continue;
    if (!arg.startsWith("--")) positional.push(arg);
  }
  return positional.at(-1);
}

async function pathExists(candidate) {
  try {
    await access(candidate);
    return true;
  } catch {
    return false;
  }
}

async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

function defaultOpenCodeTarget() {
  return path.join(process.env.USERPROFILE ?? process.env.HOME ?? ".", ".config", "opencode");
}

function validateBackupId(value) {
  if (typeof value !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(value) || value === "." || value === "..") {
    throw new Error("invalid backupId");
  }
  return value;
}

function validateMetadataPath(value) {
  if (typeof value !== "string" || !value || path.isAbsolute(value) || value.split(/[\\/]/).includes("..")) {
    throw new Error(`invalid rollback metadata path: ${value}`);
  }
  return value;
}

export async function buildOpenCodeRollbackPlan(options = {}) {
  const target = validateOpenCodeOverlayTarget(options.target ?? defaultOpenCodeTarget());
  const installMetadataPath = path.join(target, ".opencode-kit", "last-install.json");
  const installMetadata = await readJson(installMetadataPath);
  const backupId = validateBackupId(options.backupId ?? installMetadata.backupId);

  const backupDir = path.join(target, ".opencode-kit-backups", backupId);
  if (!await pathExists(backupDir)) throw new Error(`Backup not found: ${backupDir}`);

  const backedUp = new Set((installMetadata.backedUp ?? []).map(validateMetadataPath));
  const files = (installMetadata.files ?? []).map(validateMetadataPath);
  const restore = [...backedUp].map((relativePath) => ({
    relativePath,
    source: path.join(backupDir, relativePath),
    destination: path.join(target, relativePath)
  }));
  const remove = files
    .filter((relativePath) => !backedUp.has(relativePath))
    .map((relativePath) => ({
      relativePath,
      destination: path.join(target, relativePath)
    }));

  return {
    dryRun: Boolean(options.dryRun),
    target,
    backupId,
    backupDir,
    restore,
    remove
  };
}

export async function rollbackOpenCodeOverlay(options = {}) {
  const plan = await buildOpenCodeRollbackPlan(options);
  if (plan.dryRun) return plan;

  const removed = [];
  const restored = [];

  for (const item of plan.remove) {
    if (await pathExists(item.destination)) {
      await rm(item.destination, { recursive: true, force: true });
      removed.push(item.relativePath);
    }
  }

  for (const item of plan.restore) {
    if (!await pathExists(item.source)) throw new Error(`Backup item not found: ${item.relativePath}`);
    await mkdir(path.dirname(item.destination), { recursive: true });
    await cp(item.source, item.destination, { recursive: true, force: true });
    restored.push(item.relativePath);
  }

  const metadata = {
    backupId: plan.backupId,
    rolledBackAt: new Date().toISOString(),
    restored,
    removed
  };
  const metadataPath = path.join(plan.target, ".opencode-kit", "last-rollback.json");
  await mkdir(path.dirname(metadataPath), { recursive: true });
  await writeFile(metadataPath, JSON.stringify(metadata, null, 2), "utf8");

  return { ...plan, restored, removed };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const dryRun = process.argv.includes("--dry-run");
  const target = argValue("--target", null) ?? positionalTarget() ?? defaultOpenCodeTarget();
  const backupId = argValue("--backup-id", null);
  try {
    const result = await rollbackOpenCodeOverlay({ target, backupId, dryRun });
    console.log(`${dryRun ? "DRY RUN " : ""}OpenCode overlay rollback plan`);
    console.log(`Target: ${result.target}`);
    console.log(`Backup: ${result.backupDir}`);
    for (const item of result.remove) console.log(`- remove ${item.relativePath}`);
    for (const item of result.restore) console.log(`- restore ${item.relativePath}`);
    if (dryRun) console.log("No files were changed.");
    else console.log(`Rollback complete: restored ${result.restored.length}, removed ${result.removed.length}`);
  } catch (error) {
    console.error(`OpenCode overlay rollback failed: ${error.message}`);
    process.exit(1);
  }
}

