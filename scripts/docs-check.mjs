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
  "docs/profiles.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/phase-roadmap.md",
  "docs/decisions/0002-phase-documentation-standard.md",
];

const REQUIRED_README_SECTIONS = [
  "Tabla de contenidos",            // Table of Contents (Spanish)
  "Arquitectura",                   // Architecture Overview
  "Manager",                        // Manager Orchestrator
  "SDD",                            // SDD pipeline
  "Engram",                         // Engram persistent memory
  "Ponytail",                       // Ponytail Code Gate
  "gentle-ai",                      // gentle-ai alignment
  "Perfiles",                       // Profiles
  "Guía rápida",                    // Quick Start
  "Destinos de instalación",        // Installation targets
  "Seguridad y sanitización",       // Safety & sanitization
  "Hoja de ruta",                   // Phase roadmap
  "FAQ",                            // FAQ
  "Glosario",                       // Glossary
  "Variables de entorno",           // Environment variables reference
  "Compatibilidad",                 // OpenCode version compatibility
  "Desinstalación",                 // Uninstall instructions
  "Solución de problemas",           // Troubleshooting
  "Comunidad y soporte",            // Community / support
  "Ejemplo guiado",                 // Example walkthrough
  "Contribuir",                     // Contributing
  "Licencia",                       // License
];

const REQUIRED_README_HEADINGS_PATTERNS = REQUIRED_README_SECTIONS.map(
  (s) => new RegExp(`^##+\\s+.*${escapeRegex(s)}`, "im")
);

const FORBIDDEN_PATTERNS = [
  { pattern: /C:[\\]Users[\\]/g, severity: "BLOCKED", label: "Windows absolute path" },
  { pattern: /\bTODO\b/g, severity: "WARNING", label: "TODO placeholder" },
  { pattern: /\bFIXME\b/g, severity: "WARNING", label: "FIXME placeholder" },
];

const NEW_DOCS = [
  "docs/getting-started.md",
  "docs/profiles.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/phase-roadmap.md",
  "docs/PHASE-1-DOCUMENTATION-AUDIT.md",
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
  for (const doc of NEW_DOCS) {
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
    if (blockedFound) console.log("  - Blocked patterns found (absolute paths)");
    process.exitCode = 1;
  } else if (warningFound) {
    console.log("\n🟡 PASS WITH WARNINGS");
    console.log("  - Placeholder patterns found (TODO/FIXME)");
  } else {
    console.log("\n✅ PASS");
  }
}

main();
