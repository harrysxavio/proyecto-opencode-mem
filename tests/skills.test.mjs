import test from "node:test";
import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const dir = path.dirname(fileURLToPath(import.meta.url));
const skillsDir = path.resolve(dir, "..", "skills");

test("all skills have valid frontmatter (name, description)", async () => {
  const entries = await readdir(skillsDir, { withFileTypes: true });
  const skillDirs = entries.filter(e => e.isDirectory());
  assert.ok(skillDirs.length > 0, "no skill directories found");

  for (const skillDir of skillDirs) {
    const skillPath = path.join(skillsDir, skillDir.name, "SKILL.md");
    let content;
    try { content = await readFile(skillPath, "utf8"); }
    catch { continue; } // skip dirs without SKILL.md (e.g. examples/)

    const nameMatch = content.match(/^name:\s*(.+)/m);
    assert.ok(nameMatch, `${skillDir.name}/SKILL.md: missing 'name:' in frontmatter`);

    const descMatch = content.match(/^description:\s*(.+)/m);
    assert.ok(descMatch, `${skillDir.name}/SKILL.md: missing 'description:' in frontmatter`);

    assert.ok(nameMatch[1].trim().length > 0, `${skillDir.name}: name is empty`);
    assert.ok(descMatch[1].trim().length > 0, `${skillDir.name}: description is empty`);
  }
});
