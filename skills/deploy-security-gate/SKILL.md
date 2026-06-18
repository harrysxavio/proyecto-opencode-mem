---
name: deploy-security-gate
description: Review production deployment readiness. Trigger: deploy, release, production, credentials, hosting, or security gate.
---

# deploy-security-gate

## When to use

Review production deployment readiness. Trigger: deploy, release, production, credentials, hosting, or security gate.

## Runtime contract

Use this skill to check secrets, environment variables, auth boundaries, rollback, least privilege, and smoke tests before deploy.

## Output

Return a compact result with:

- decision or recommendation;
- evidence checked;
- risks and tradeoffs;
- next action.

## Boundaries

- Do not include private local paths in generated artifacts.
- Do not make destructive changes without an explicit user request.
- Prefer small, reviewable outputs over broad audits.