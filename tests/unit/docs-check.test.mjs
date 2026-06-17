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
