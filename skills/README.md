# Portable skills

This directory contains the 18 sanitized skills installed for OpenCode and Codex.

Each skill is documentation with frontmatter, not an executable plugin. Runtime installers copy the directories to `skills/opencode-runtime-kit/` and generate a destination-aware registry.

Run:

```bash
pnpm codex:registry
pnpm test:all
```

Do not include private paths, credentials, logs or runtime databases.