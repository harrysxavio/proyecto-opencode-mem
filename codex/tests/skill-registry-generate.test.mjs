import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, mkdir, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { generateSkillRegistry } from "../../codex/scripts/skill-registry-generate.mjs";

async function makeFixtureSkill(root, name, description) {
  const dir = path.join(root, "skills", name);
  await mkdir(dir, { recursive: true });
  await writeFile(
    path.join(dir, "SKILL.md"),
    `---\nname: ${name}\ndescription: ${description}\n---\n\n# ${name}\n\nUse this skill for ${description}.\n`,
    "utf8"
  );
}

test("generateSkillRegistry writes project skill index with relative paths", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "opencode-kit-skills-"));
  await makeFixtureSkill(root, "manager-router", "Classify requests and route work");
  await makeFixtureSkill(root, "memory-governance", "Retrieve and save useful memory");

  const result = await generateSkillRegistry(root);
  const registry = await readFile(path.join(root, ".atl", "skill-registry.md"), "utf8");

  assert.equal(result.count, 2);
  assert.match(registry, /manager-router/);
  assert.match(registry, /skills\/manager-router\/SKILL\.md/);
  assert.match(registry, /memory-governance/);
  assert.doesNotMatch(registry, /[A-Z]:\\/);
});
