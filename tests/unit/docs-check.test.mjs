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
    { name: "Table of contents", pattern: /^##+ .*[Tt]abla.*[Cc]ontenidos/im },
    { name: "Architecture", pattern: /^##+ .*[Aa]rquitectura/im },
    { name: "Manager", pattern: /^##+ .*[Mm]anager/im },
    { name: "SDD pipeline", pattern: /^##+ .*SDD/im },
    { name: "Engram", pattern: /^##+ .*[Ee]ngram/im },
    { name: "Ponytail", pattern: /^##+ .*[Pp]onytail/im },
    { name: "gentle-ai", pattern: /^##+ .*gentle-ai/im },
    { name: "Profiles", pattern: /^##+ .*[Pp]erfiles/im },
    { name: "Quick Start", pattern: /^##+ .*[Gg]uía [Rr]ápida/im },
    { name: "Installation targets", pattern: /^##+ .*[Dd]estinos.*[Ii]nstalación/im },
    { name: "Safety and sanitization", pattern: /^##+ .*[Ss]eguridad.*[Ss]anitización/im },
    { name: "Phase roadmap", pattern: /^##+ .*[Hh]oja.*[Rr]uta/im },
    { name: "FAQ", pattern: /^##+ .*FAQ/im },
    { name: "Glossary", pattern: /^##+ .*[Gg]losario/im },
    { name: "Environment variables", pattern: /^##+ .*[Vv]ariables.*[Ee]ntorno/im },
    { name: "Compatibility", pattern: /^##+ .*[Cc]ompatibilidad/im },
    { name: "Uninstall", pattern: /^##+ .*[Dd]esinstalación/im },
    { name: "Troubleshooting", pattern: /^##+ .*[Ss]olución.*[Pp]roblemas/im },
    { name: "Community and support", pattern: /^##+ .*[Cc]omunidad.*[Ss]oporte/im },
    { name: "Example walkthrough", pattern: /^##+ .*[Ee]jemplo.*[Gg]uiado/im },
    { name: "Contributing", pattern: /^##+ .*[Cc]ontribuir/im },
    { name: "License", pattern: /^##+ .*[Ll]icencia/im },
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

describe("docs-check — README accuracy", () => {
  let readme;
  let readmeLoaded = false;

  it("should be able to load README", async () => {
    readme = await readFile(path.join(repoRoot, "README.md"), "utf8");
    readmeLoaded = true;
  });

  it("should use real repo URL, not placeholder", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const hasPlaceholder = /\btu-usuario\b/.test(readme);
    assert.ok(!hasPlaceholder, "README contains placeholder 'tu-usuario'");
  });

  it("should use correct clone command for real repo", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const hasCorrectClone = /github\.com\/harrysxavio\/proyecto-opencode-mem\.git/.test(readme);
    assert.ok(hasCorrectClone, "README clone URL does not point to the real repo");
  });

  it("should use correct directory name in commands", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const wrongCd = /\bcd opencode-kit\b/.test(readme);
    assert.ok(!wrongCd, "README references wrong directory name 'opencode-kit'");
  });

  it("should not reference pnpm rollback without :plan suffix", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const rollbackWithoutPlan = /pnpm rollback(?!:plan)/.test(readme);
    assert.ok(!rollbackWithoutPlan, "README references pnpm rollback instead of pnpm rollback:plan");
  });

  it("should explain Ponytail as guidance-only, not auto plugin", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const autoApply = /Ponytail se aplica automáticamente/.test(readme);
    assert.ok(!autoApply, "README claims Ponytail applies automatically");
    const hasGuidance = /guidance/i.test(readme) || /template/.test(readme);
    assert.ok(hasGuidance, "README does not explain Ponytail as guidance/template");
  });

  it("should explain gentle-ai as alignment-only, not runtime", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    // Check for affirmative runtime claims (not negated or strikethrough)
    const lines = readme.split("\n");
    const affirmativeRuntime = lines.filter((l) => {
      if (!/gentle-ai.*runtime/i.test(l)) return false;
      if (/\bno\b.*gentle-ai/i.test(l)) return false;   // "no incluye gentle-ai runtime"
      if (/~~.*~~/.test(l)) return false;                // strikethrough: ~~claim~~
      return true;
    });
    assert.ok(
      affirmativeRuntime.length === 0,
      `README affirmatively claims gentle-ai is a runtime in lines: ${affirmativeRuntime.join(", ")}`,
    );
    const hasAlignmentOnly = /alignment-only/.test(readme);
    assert.ok(hasAlignmentOnly, "README does not describe gentle-ai as alignment-only");
  });

  it("should not claim Codex is currently supported", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const codexClaim = /Codex soportado(?!.*futur|.*pendiente)/.test(readme);
    assert.ok(!codexClaim, "README claims Codex is supported (should be future/pending)");
  });

  it("should have 'Qué puedes hacer hoy' section", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const hasCanDo = /Qué puedes hacer hoy/.test(readme);
    assert.ok(hasCanDo, "README missing 'Qué puedes hacer hoy' section");
  });

  it("should have 'Qué todavía NO puedes hacer' section", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const hasCannotDo = /Qué todavía NO puedes hacer/.test(readme);
    assert.ok(hasCannotDo, "README missing 'Qué todavía NO puedes hacer' section");
  });

  it("should mark Phase 1 as completed", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const phase1Completed = /Phase 1.*✅ Completada/.test(readme);
    assert.ok(phase1Completed, "Phase 1 not marked as completed in README");
  });

  it("should not claim installer real activo", () => {
    if (!readmeLoaded) assert.fail("README not loaded");
    const installerReal = /installer real/.test(readme) || /instalador real/.test(readme);
    // If mentioned, it should be in the "Qué NO puedes" section
    if (installerReal) {
      const inCannotSection = readme.indexOf("Qué todavía NO puedes") < readme.lastIndexOf("installer") ||
                              readme.indexOf("Qué todavía NO puedes") < readme.lastIndexOf("instalador");
      assert.ok(inCannotSection, "README mentions real installer outside of limitations section");
    }
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
