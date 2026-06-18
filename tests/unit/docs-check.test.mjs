import { describe, it } from "node:test";
import assert from "node:assert";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");

const REQUIRED_DOCS = [
  "docs/getting-started.md",
  "docs/installation-targets.md",
  "docs/safety-and-sanitization.md",
  "docs/decisions/0002-phase-documentation-standard.md",
  "ARCHITECTURE.md",
  "QUICKSTART_OPENCODE.md",
  "QUICKSTART_CODEX.md",
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
    { name: "Runtime Kit", pattern: /^# Runtime Kit/im },
    { name: "Contratos portables", pattern: /^##+ .*Contratos portables/im },
    { name: "Personas no tecnicas", pattern: /^##+ .*personas no t.cnicas/im },
    { name: "Arquitectura para OpenCode", pattern: /^##+ .*Arquitectura para OpenCode/im },
    { name: "Arquitectura para Codex", pattern: /^##+ .*Arquitectura para Codex/im },
    { name: "Memoria", pattern: /^##+ .*memoria/im },
    { name: "Noise Gate", pattern: /^##+ .*Noise Gate/im },
    { name: "Tokens", pattern: /^##+ .*Tokens/im },
    { name: "Memoria entre sesiones", pattern: /^##+ .*Memoria entre sesiones/im },
    { name: "Ponytail", pattern: /^##+ .*Ponytail/im },
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
    "docs/installation-targets.md",
    "docs/safety-and-sanitization.md",
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

describe("docs-check — README accuracy", () => {
  let readme;
  let readmeLoaded = false;

  it("should be able to load README", async () => {
    readme = await readFile(path.join(repoRoot, "README.md"), "utf8");
    readmeLoaded = true;
  });

  it("should reference contracts and adapters", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(/contracts\//.test(readme), "README missing contracts reference");
    assert.ok(/ARCHITECTURE\.md/.test(readme), "README missing architecture reference");
    assert.ok(/QUICKSTART_OPENCODE/.test(readme), "README missing OpenCode quickstart");
    assert.ok(/QUICKSTART_CODEX/.test(readme), "README missing Codex quickstart");
  });

  it("should document persistent memory and token-efficient orchestration", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(/memoria persistente/i.test(readme), "README missing persistent memory explanation");
    assert.ok(/memoria entre sesiones/i.test(readme), "README missing cross-session memory explanation");
    assert.ok(/Noise Gate/i.test(readme), "README missing Noise Gate explanation");
    assert.ok(/tok/.test(readme), "README missing token explanation");
  });

  it("should remain portable and sanitized", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    assert.ok(!/[A-Z]:\\/.test(readme), "README contains Windows absolute path");
    assert.ok(!/\btu-usuario\b/.test(readme), "README contains placeholder 'tu-usuario'");
  });
});

describe("docs-check — doc accuracy", () => {
  const checkedDocs = [
    "docs/getting-started.md",
    "docs/installation-targets.md",
    "docs/safety-and-sanitization.md",
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
