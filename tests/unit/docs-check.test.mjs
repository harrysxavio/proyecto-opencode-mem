import { describe, it } from "node:test";
import assert from "node:assert";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");

const REQUIRED_DOCS = [
  "docs/getting-started.md",
  "docs/profiles.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/phase-roadmap.md",
  "docs/decisions/0002-phase-documentation-standard.md",
];

async function fileExists(filePath) {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

describe("docs-check — required documentation", () => {
  for (const doc of REQUIRED_DOCS) {
    it(`${doc} must exist`, async () => {
      const fullPath = path.join(repoRoot, doc);
      const exists = await fileExists(fullPath);
      assert.ok(exists, `Missing required doc: ${doc}`);
    });
  }

  it("README must exist", async () => {
    const exists = await fileExists(path.join(repoRoot, "README.md"));
    assert.ok(exists, "README.md is missing");
  });
});

describe("docs-check — README sections", () => {
  let readme;
  let readmeLoaded = false;

  it("should be able to load README", async () => {
    readme = await readFile(path.join(repoRoot, "README.md"), "utf8");
    readmeLoaded = true;
  });

  const requiredSections = [
    { name: "Arquitectura Codex", pattern: /^# Arquitectura Codex/im },
    { name: "Personas no tecnicas", pattern: /^##+ .*personas no t.cnicas/im },
    { name: "Flujo completo", pattern: /^##+ .*Flujo completo/im },
    { name: "Memoria", pattern: /^##+ .*memoria/im },
    { name: "Noise Gate", pattern: /^##+ .*Noise Gate/im },
    { name: "Tokens", pattern: /^##+ .*Tokens/im },
    { name: "Memoria entre sesiones", pattern: /^##+ .*Memoria entre sesiones/im },
    { name: "Flujo explosivo", pattern: /^##+ .*Flujo explosivo/im },
    { name: "Vista tecnica", pattern: /^##+ .*Vista t.cnica/im },
    { name: "Auditoria OpenCode", pattern: /^##+ .*Auditor.a OpenCode/im },
    { name: "Puntos de mejora", pattern: /^##+ .*Puntos de mejora/im },
    { name: "Como usarlo", pattern: /^##+ .*C.mo usarlo/im },
    { name: "Estado actual", pattern: /^##+ .*Estado actual/im },
    { name: "Rollback", pattern: /^##+ .*Rollback/im },
    { name: "Como validar", pattern: /^##+ .*C.mo validar/im },
  ];

  for (const section of requiredSections) {
    it(`README should have "${section.name}" section`, () => {
      if (!readmeLoaded) {
        assert.fail("README not loaded — previous test failed");
      }
      const found = section.pattern.test(readme);
      assert.ok(found, `README is missing the "${section.name}" heading`);
    });
  }
});

describe("docs-check — forbidden patterns", () => {
  const newDocs = [
    "docs/getting-started.md",
    "docs/profiles.md",
    "docs/installation-targets.md",
    "docs/safety-and-sanitization.md",
    "docs/phase-roadmap.md",
    "docs/PHASE-1-DOCUMENTATION-AUDIT.md",
  ];

  for (const doc of newDocs) {
    it(`${doc} should not contain Windows absolute paths`, async () => {
      const fullPath = path.join(repoRoot, doc);
      const exists = await fileExists(fullPath);
      if (!exists) return; // skip silently if not yet created

      const content = await readFile(fullPath, "utf8");
      const matches = content.match(/C:[\\]Users[\\]/g);
      assert.ok(
        matches === null,
        `${doc} contains Windows drive-rooted paths`
      );
    });
  }
});

describe("docs-check ? README accuracy", () => {
  let readme;
  let codexReadme;
  let readmeLoaded = false;

  it("should be able to load README and README_CODEX", async () => {
    readme = await readFile(path.join(repoRoot, "README.md"), "utf8");
    codexReadme = await readFile(path.join(repoRoot, "README_CODEX.md"), "utf8");
    readmeLoaded = true;
  });

  it("README should mirror README_CODEX as the primary project README", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.equal(readme, codexReadme);
  });

  it("should explain Codex normal vs Codex with this architecture", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(/Codex normal/i.test(readme), "README does not explain Codex normal");
    assert.ok(/Codex con esta arquitectura/i.test(readme), "README does not explain configured Codex");
  });

  it("should document persistent memory and token-efficient orchestration", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(/memoria persistente/i.test(readme), "README missing persistent memory explanation");
    assert.ok(/memoria entre sesiones/i.test(readme), "README missing cross-session memory explanation");
    assert.ok(/Noise Gate/i.test(readme), "README missing Noise Gate explanation");
    assert.ok(/presupuesto de tokens/i.test(readme), "README missing token budget explanation");
    assert.ok(/SUBAGENT_RESULT/i.test(readme), "README missing subagent flow marker");
  });

  it("should remain portable and sanitized", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(!/[A-Z]:\\/.test(readme), "README contains Windows absolute path");
    assert.ok(!/harry/i.test(readme), "README contains personal username");
    assert.ok(!/\btu-usuario\b/.test(readme), "README contains placeholder 'tu-usuario'");
  });
});

describe("docs-check — doc accuracy", () => {
  const checkedDocs = [
    "docs/getting-started.md",
    "docs/profiles.md",
    "docs/installation-targets.md",
    "docs/safety-and-sanitization.md",
    "docs/phase-roadmap.md",
  ];

  for (const doc of checkedDocs) {
    it(`${doc} should not contain repo placeholders`, async () => {
      const fullPath = path.join(repoRoot, doc);
      const exists = await fileExists(fullPath);
      if (!exists) return;
      const content = await readFile(fullPath, "utf8");
      const placeholderRepo = /\btu-usuario\b/.test(content);
      assert.ok(!placeholderRepo, `${doc} contains 'tu-usuario' placeholder`);
    });
  }
});
