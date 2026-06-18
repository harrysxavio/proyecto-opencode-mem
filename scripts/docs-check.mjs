#!/usr/bin/env node

/**
 * docs-check.mjs — Documentation integrity check for OpenCode Kit.
 *
 * Verifies:
 * 1. All required dedicated docs exist.
 * 2. All required README sections exist (by heading text).
 * 3. No absolute Windows paths (e.g. `{KIT_ROOT}`).
 * 4. No placeholder text like TODO or FIXME in new docs.
 *
 * Returns PASS, PASS WITH WARNINGS, or BLOCKED.
 */

import { readFile, access } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");

const REQUIRED_DOCS = [
  "docs/getting-started.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/decisions/0002-phase-documentation-standard.md",
  "ARCHITECTURE.md",
  "QUICKSTART_OPENCODE.md",
  "QUICKSTART_CODEX.md",
];

const REQUIRED_README_SECTIONS = [
  "personas no t?cnicas",
  "Arquitectura para OpenCode",
  "Arquitectura para Codex",
  "memoria",
  "Noise Gate",
  "Tokens",
  "Ponytail",
  "Estado actual",
  "Rollback",
  "C?mo validar",
];

const REQUIRED_README_HEADINGS_PATTERNS = [
  /^##+\s+.*personas no t.cnicas/im,
  /^##+\s+.*Arquitectura para OpenCode/im,
  /^##+\s+.*Arquitectura para Codex/im,
  /^##+\s+.*memoria/im,
  /^##+\s+.*Noise Gate/im,
  /^##+\s+.*Tokens/im,
  /^##+\s+.*Ponytail/im,
  /^##+\s+.*Estado actual/im,
  /^##+\s+.*Rollback/im,
  /^##+\s+.*C.mo validar/im,
];

/**
 * Forbidden content patterns.
 * - BLOCKED: must be fixed before pass.
 * - WARNING: should be reviewed.
 *
 * Important: patterns that match `pnpm rollback` use negative lookahead
 * to allow `pnpm rollback:plan` without flagging it.
 */
const FORBIDDEN_PATTERNS = [
  // ── Paths and placeholders ─────────────────────────────────────────
  { pattern: /C:[\\]Users[\\]/g, severity: "BLOCKED", label: "Windows absolute path" },
  { pattern: /\btu-usuario\b/g, severity: "BLOCKED", label: "Placeholder repo owner" },
  { pattern: /github\.com\/harry\/opencode-kit/g, severity: "BLOCKED", label: "Wrong CI/links repo" },
  { pattern: /github\.com\/tu-usuario\/opencode-kit/g, severity: "BLOCKED", label: "Placeholder repo URL" },

  // ── Wrong commands ─────────────────────────────────────────────────
  { pattern: /\bcd opencode-kit\b/g, severity: "BLOCKED", label: "Wrong directory name" },
  { pattern: /pnpm rollback(?!:(?:plan|codex))/g, severity: "BLOCKED", label: "pnpm rollback (use rollback:plan or rollback:codex)" },
  { pattern: /pnpm backup\b(?!:plan)/g, severity: "BLOCKED", label: "pnpm backup (use backup:plan)" },

  // ── False claims about Ponytail ────────────────────────────────────
  // Only flag unambiguously wrong claims; negations are handled by test suite.
  { pattern: /Ponytail se aplica automáticamente/g, severity: "BLOCKED", label: "Ponytail auto claim (it's guidance)" },

  // ── False claims about gentle-ai ───────────────────────────────────
  // Subtle negations ("no incluye") are handled by the test suite, not here.
  { pattern: /gentle-ai.*(?:est[aá] instalado|es un runtime|es runtime)/gi, severity: "BLOCKED", label: "gentle-ai runtime claim (alignment-only)" },

  // ── False claims about Codex ───────────────────────────────────────
  { pattern: /Codex soportado(?!.*futur|.*pendiente)/g, severity: "WARNING", label: "Codex support claim (future only)" },

  // ── Placeholder markers (code-style TODO/FIXME) ────────────────────
  // Avoids Spanish "TODO" (everything) as false positive.
  { pattern: /(?:@TODO|TODO:|FIXME:)/g, severity: "WARNING", label: "Code placeholder (TODO/FIXME)" },
];

const NEW_DOCS = [
  "docs/getting-started.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/codex/getting-started.md",
  "docs/codex/overlay-install.md",
  "docs/codex/troubleshooting.md",
];

/** Files to scan for forbidden patterns (README + all new docs marked for checks). */
const SCAN_FILES = [
  "README.md",
  ...NEW_DOCS,
];

function escapeRegex(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function fileExists(filePath) {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function checkRequiredDocs() {
  const results = [];
  for (const doc of REQUIRED_DOCS) {
    const exists = await fileExists(path.join(repoRoot, doc));
    results.push({
      name: doc,
      pass: exists,
      message: exists ? "✅ Present" : "❌ MISSING",
    });
  }
  return results;
}

async function checkReadmeSections() {
  const readmePath = path.join(repoRoot, "README.md");
  let content;
  try {
    content = await readFile(readmePath, "utf8");
  } catch {
    return REQUIRED_README_SECTIONS.map((section) => ({
      name: section,
      pass: false,
      message: "❌ README not found",
    }));
  }

  const results = [];
  for (let i = 0; i < REQUIRED_README_SECTIONS.length; i++) {
    const section = REQUIRED_README_SECTIONS[i];
    const pattern = REQUIRED_README_HEADINGS_PATTERNS[i];
    const found = pattern.test(content);
    results.push({
      name: section,
      pass: found,
      message: found ? "✅ Found" : "❌ Missing heading",
    });
  }
  return results;
}

async function checkForbiddenPatterns() {
  const results = [];
  for (const doc of SCAN_FILES) {
    const docPath = path.join(repoRoot, doc);
    if (!(await fileExists(docPath))) continue;

    let content;
    try {
      content = await readFile(docPath, "utf8");
    } catch {
      continue;
    }

    for (const { pattern, severity, label } of FORBIDDEN_PATTERNS) {
      const matches = content.match(pattern);
      if (matches) {
        results.push({
          file: doc,
          severity,
          label,
          count: matches.length,
          message: `${severity === "BLOCKED" ? "🔴" : "🟡"} ${label} ×${matches.length} in ${doc}`,
        });
      }
    }
  }
  return results;
}

async function main() {
  console.log("── Docs Check ──────────────────────────────\n");

  // 1. Required docs
  console.log("Required docs:");
  const docResults = await checkRequiredDocs();
  let docPass = true;
  for (const r of docResults) {
    console.log(`  ${r.message} — ${r.name}`);
    if (!r.pass) docPass = false;
  }

  // 2. README sections
  console.log("\nREADME sections:");
  const sectionResults = await checkReadmeSections();
  let sectionPass = true;
  for (const r of sectionResults) {
    console.log(`  ${r.message} — ${r.name}`);
    if (!r.pass) sectionPass = false;
  }

  // 3. Forbidden patterns
  console.log("\nForbidden patterns:");
  const forbiddenResults = await checkForbiddenPatterns();
  let blockedFound = false;
  let warningFound = false;
  if (forbiddenResults.length === 0) {
    console.log("  ✅ No forbidden patterns found");
  } else {
    for (const r of forbiddenResults) {
      console.log(`  ${r.message}`);
      if (r.severity === "BLOCKED") blockedFound = true;
      if (r.severity === "WARNING") warningFound = true;
    }
  }

  // Summary
  console.log("\n── Result ──────────────────────────────────");

  if (!docPass || !sectionPass || blockedFound) {
    console.log("\n🔴 BLOCKED");
    if (!docPass) console.log("  - Missing required docs");
    if (!sectionPass) console.log("  - Missing README sections");
    if (blockedFound) console.log("  - Blocked patterns found (placeholders, wrong commands, false claims)");
    process.exitCode = 1;
  } else if (warningFound) {
    console.log("\n🟡 PASS WITH WARNINGS");
    console.log("  - Warning-level patterns found (Codex claim, Ponytail default, TODOs)");
  } else {
    console.log("\n✅ PASS");
  }
}

main();
