# Configuration

Use `templates/opencode.example.jsonc` as the starting point. Review and adapt placeholders before copying anything into a real OpenCode config directory.

## Placeholders

| Placeholder | Meaning |
|---|---|
| `${OPENCODE_KIT_DIR}` | Local checkout of this kit |
| `${OPENCODE_CONFIG_DIR}` | User OpenCode config directory |
| `${OPENCODE_SKILLS_DIR}` | User OpenCode skills directory |
| `${ENGRAM_DB_PATH}` | User-selected Engram database path; never stored in repo |

## Schema note

OpenCode uses `agent` and `skills.paths` in config. This kit follows that shape to avoid shipping an invalid example.
