#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const allowedClassifications = new Set(["tiny", "small", "memory", "docs", "code", "sdd", "research", "security", "qa"]);

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function requireString(value, field, failures) {
  if (typeof value !== "string" || value.trim() === "") failures.push(`${field} must be a non-empty string`);
}

function validateIncludedItem(item, index, failures) {
  if (!isPlainObject(item)) {
    failures.push(`included[${index}] must be an object`);
    return;
  }
  requireString(item.kind, `included[${index}].kind`, failures);
  requireString(item.ref, `included[${index}].ref`, failures);
  requireString(item.reason, `included[${index}].reason`, failures);
  if (item.sensitivity === "high") failures.push(`included[${index}] has high sensitivity and cannot be injected`);
}

function validateExcludedItem(item, index, failures) {
  if (!isPlainObject(item)) {
    failures.push(`excluded[${index}] must be an object`);
    return;
  }
  requireString(item.ref, `excluded[${index}].ref`, failures);
  requireString(item.reason, `excluded[${index}].reason`, failures);
}

export function validateContextPack(pack, options = {}) {
  const maxIncluded = options.maxIncluded ?? 8;
  const failures = [];

  if (!isPlainObject(pack)) return { failures: ["context pack must be a JSON object"] };

  requireString(pack.request_id, "request_id", failures);
  requireString(pack.classification, "classification", failures);
  if (typeof pack.classification === "string" && !allowedClassifications.has(pack.classification)) {
    failures.push(`classification must be one of ${Array.from(allowedClassifications).join(", ")}`);
  }

  if (!Number.isInteger(pack.token_budget) || pack.token_budget <= 0) {
    failures.push("token_budget must be a positive integer");
  }

  if (!Array.isArray(pack.included)) {
    failures.push("included must be an array");
  } else {
    if (pack.included.length > maxIncluded) failures.push(`included must contain at most ${maxIncluded} items`);
    pack.included.forEach((item, index) => validateIncludedItem(item, index, failures));
  }

  if (!Array.isArray(pack.excluded)) {
    failures.push("excluded must be an array");
  } else {
    pack.excluded.forEach((item, index) => validateExcludedItem(item, index, failures));
  }

  return { failures };
}

export async function validateContextPackFile(filePath, options = {}) {
  const text = await readFile(filePath, "utf8");
  let pack;
  try {
    pack = JSON.parse(text);
  } catch (error) {
    return { failures: [`invalid JSON: ${error.message}`] };
  }
  return validateContextPack(pack, options);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const files = process.argv.slice(2);
  if (files.length === 0) {
    console.error("Usage: node scripts/context-pack-check.mjs <context-pack.json> [...]");
    process.exit(1);
  }

  const allFailures = [];
  for (const file of files) {
    const { failures } = await validateContextPackFile(file);
    for (const failure of failures) allFailures.push(`${file}: ${failure}`);
  }

  if (allFailures.length) {
    console.error("CONTEXT PACK CHECK FAIL");
    for (const failure of allFailures) console.error(`- ${failure}`);
    process.exit(1);
  }

  console.log("CONTEXT PACK CHECK PASS");
}
