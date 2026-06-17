# Memory Governance

The `memory-enabled` profile provides documentation and templates for Engram memory governance. It does not install or copy real memory data.

## What it installs later

- Engram plugin template.
- Noise Gate guidance.
- `mem_context` retrieval guidance.
- F4C selector guidance.
- F4B recent session pack contract guidance.

## What it does not install

- Real Engram databases.
- Legacy memory databases.
- Real memories.
- Logs or backups.
- Private project data.

## Why real DB files are excluded

Memory databases may contain private prompts, project decisions, customer data, paths, or credentials. They must stay local and be configured manually.

## Manual configuration

1. Review the template plugin.
2. Choose a local database path outside the repo.
3. Configure Engram manually in your private OpenCode config.
4. Run a read-only memory retrieval check.

## Validate mem_context

- Query a known non-sensitive project decision.
- Confirm results are scoped to the intended project.
- Confirm no secret-like content appears in output.

## Validate Noise Gate

- Save a useful synthetic decision.
- Attempt to classify synthetic secret-like text as blocked.
- Confirm noise is skipped.
