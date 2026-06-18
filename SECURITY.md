# Security Policy

## Supported surface

The repository validates both runtime overlay installers, doctors and rollbacks. Always review the dry-run and use an explicit user-owned target.

## Reporting a vulnerability

Open an issue with a sanitized reproduction. Do not include tokens, personal paths, logs, databases, backups or private runtime files.

## Controls

- installers reject known update-managed application paths;
- existing destinations are backed up before overwrite;
- rollback revalidates backup ids and receipt paths to prevent traversal;
- CI runs tests, documentation checks and sanitization;
- installation performs no network download or third-party execution.

## Data handling

This repository must not contain real runtime data, Engram databases, logs, backups or secrets. Run `pnpm sanitize:check` before sharing changes.