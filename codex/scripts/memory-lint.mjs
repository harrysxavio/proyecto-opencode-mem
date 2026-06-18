#!/usr/bin/env node
import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

function toPosix(value) {
  return value.split(path.sep).join("/");
}

async function walk(root, current = root) {
  const entries = await readdir(current, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(current, entry.name);
    if (entry.isDirectory()) files.push(...await walk(root, full));
    else if (entry.isFile() && /\.(md|txt|json|jsonl)$/i.test(entry.name)) files.push(full);
  }
  return files;
}

function extractField(text, field) {
  const match = new RegExp(`^${field}:\\s*(.+)$`, "im").exec(text);
  return match?.[1]?.trim() ?? "";
}

function hasSecretLikeString(text) {
  return /\b(password|passwd|secret|credential|auth[_-]?token)\b\s*[:=]/i.test(text);
}

function hasRawPromptDump(text) {
  return /(^|\n)\s*(user prompt|assistant|system):/i.test(text);
}

export async function lintMemoryPath(targetPath) {
  const files = await walk(targetPath);
  const failures = [];
  const topicKeys = new Map();

  for (const file of files) {
    const text = await readFile(file, "utf8");
    const relative = toPosix(path.relative(targetPath, file));
    const topicKey = extractField(text, "topic_key");
    const type = extractField(text, "type");
    const evidence = extractField(text, "evidence");

    if (hasSecretLikeString(text)) failures.push(`${relative}: secret-like string detected`);
    if (hasRawPromptDump(text)) failures.push(`${relative}: raw prompt dump detected`);

    if (topicKey) {
      const previous = topicKeys.get(topicKey);
      if (previous) failures.push(`${relative}: duplicate topic_key ${topicKey} also used by ${previous}`);
      else topicKeys.set(topicKey, relative);
    }

    if (type === "decision" && !evidence) failures.push(`${relative}: decision memory missing evidence`);
  }

  return { failures };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const target = process.argv[2] ?? ".";
  const { failures } = await lintMemoryPath(path.resolve(target));
  if (failures.length) {
    console.error("MEMORY LINT FAIL");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
  }
  console.log("MEMORY LINT PASS");
}
