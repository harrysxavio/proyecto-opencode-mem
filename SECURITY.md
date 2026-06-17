# Security Policy

## Supported versions

Phase 0 is a bootstrap. Treat all installer behavior as experimental and dry-run first.

## Reporting a vulnerability

Open an issue with a sanitized reproduction. Do not include tokens, personal paths, logs, databases, or private runtime files.

## Data handling

This repository must not contain real OpenCode runtime data, real Engram databases, local logs, backups, or secrets. Run `pnpm sanitize:check` before sharing changes.
